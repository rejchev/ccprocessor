#pragma newdecls required

#include <ccprocessor/modules/channels/ccp-channels>

public Plugin myinfo = 
{
	name = "[CCP] Join Server",
	author = "rej.chev?",
	description = "Processing player connect&disconnect events",
	version = "2.0.0",
	url = "https://discord.gg/cFZ97Mzrjy"
};

static const char pkgKey[] = "join_server";

static const char objectPattern[] = "js@%x";

JsonObject jConfig;
JsonObject jMessanger;

bool g_bLate;

char currentObject[64];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    #if defined DEBUG
        DBUILD()
    #endif

    g_bLate = late;
    return APLRes_Success;
}

public void OnPluginStart() {
    // Temporary solution
    LoadTranslations("ccp-joinserver.phrases");

    HookEvent("player_connect", Events, EventHookMode_Pre);
    HookEvent("player_disconnect", Events, EventHookMode_Pre);
}

public void OnMapStart() {
    #if defined DEBUG
        DBUILD()
    #endif

    // Handshake
    cc_proc_APIHandShake(cc_get_APIKey());

    // late load
    if(g_bLate) {
        g_bLate = false;

        for(int i; i <= MaxClients; i++)
            if(Packager.GetPackage(i))
                pckg_OnPackageAvailable(i);
    }

    delete jMessanger;
    jMessanger = asJSONO(new Json("{}"));
}

public void pckg_OnPackageAvailable(int iClient) {
    static char config[MESSAGE_LENGTH]  = "configs/ccprocessor/join-server/settings.json";

    if(iClient)
        return;
    

    if(jConfig) {
        delete jConfig;
    }

    // Load from local
    if(config[0] == 'c') {
        BuildPath(Path_SM, config, sizeof(config), config);
    } 
    
    if(!FileExists(config)) {
        SetFailState("Config file is not exists: %s", config);
    }

    jConfig = asJSONO(Json.JsonF(config, 0));

    Packager.GetPackage(iClient).SetArtifact(pkgKey, jConfig);
}

public void pckg_OnPackageUpdated(Handle plugin, int iClient) {
    if(iClient)
        return;
    
    char szBuffer[MAX_NAME_LENGTH];
    GetPluginFilename(plugin, szBuffer, sizeof(szBuffer));

    if(strcmp(szBuffer, "ccp-channel-mgr.smx"))
        return;
    
    char szMyself[MAX_NAME_LENGTH];
    jConfig.GetString("identificator", szMyself, sizeof(szMyself));

    if(ccp_FindChannel(szMyself) == -1)
        ccp_AddChannel(szMyself);
}

Action Events(Event event, const char[] name, bool dbc) {
    if(!jConfig.GetBool("processing"))
        return Plugin_Continue;

    event.SetBool("silent", true);
    event.BroadcastDisabled = true;

    if(jConfig.GetBool("hideMessages"))
        return Plugin_Handled;

    // params
    char szName[NAME_LENGTH];
    event.GetString("name", szName, sizeof(szName));

    int userId = event.GetInt("userid");

    char network[NAME_LENGTH];
    event.GetString("networkid", network, sizeof(network));

    int bot = event.GetInt("bot");

    int index = -1;
    char buffer[NAME_LENGTH];
    if(name[7] == 'd')
        event.GetString("reason", buffer, sizeof(buffer));

    else {
        event.GetString("address", buffer, sizeof(buffer));
        index = event.GetInt("index");
    } 

    JsonObject message = asJSONO(new Json("{}"));
    message.SetString("event", name);
    message.SetInt("userid", userId);
    message.SetInt("index", index);
    message.SetInt("bot", bot);
    message.SetString("name", szName);
    message.SetString("network", network);
    message.SetString(name[7] == 'd' ? "reason" : "address", buffer);

    // event address
    FormatEx(szName, sizeof(szName), objectPattern, event);
    
    jMessanger.Set(szName, message);
    delete message;

    // for(int i = 1; i <= MaxClients; i++)
    //     if(IsClientInGame(i))
    //         PrintToChat(i, szName);    

    DataPack dp = new DataPack();
    dp.Reset();
    dp.WriteString(szName);

    RequestFrame(OnNextFrame, dp);
    
    return Plugin_Handled;
}

public void OnNextFrame(DataPack data)
{
    if(!data)
        return;

    data.Reset();

    char szIdent[NAME_LENGTH];
    data.ReadString(szIdent, sizeof(szIdent));

    delete data;
    
    Handle uMessage;
    UserMessageType uType = GetUserMessageType();
    for(int i = 1, j; i <= MaxClients; i++) {
        j = 1;
        if(IsClientConnected(i)) {
            if((uMessage = StartMessageOne("TextMsg", i, USERMSG_RELIABLE)) != null) {
                if(!uType) {
                    BfWriteByte(uMessage, 3);
                    BfWriteString(uMessage, szIdent);
                } else {
                    PbSetInt(uMessage, "msg_dst", 3);
                    PbAddString(uMessage, "params", szIdent);
                    while(j < 5) {
                        PbAddString(uMessage, "params", NULL_STRING);
                        j++;
                    }
                }

                EndMessage();
            }
        }
    }
}

public Processing cc_proc_OnNewMessage(const int[] props, int propsCount, ArrayList params) {
    static const char parentChannel[] = "TM";
    
    char szBuffer[MESSAGE_LENGTH];
    params.GetString(0, szBuffer, sizeof(szBuffer));

    currentObject = NULL_STRING;
    
    if(strcmp(szBuffer, parentChannel) != 0 || IsClientSourceTV(props[1]))
        return Proc_Continue;

    // message object
    params.GetString(2, szBuffer, sizeof(szBuffer));
    if(!jMessanger.HasKey(szBuffer))
        return Proc_Continue;

    FormatEx(currentObject, sizeof(currentObject), "%s", szBuffer);

    JsonObject msg = asJSONO(jMessanger.Get(szBuffer));
    int sender = GetClientOfUserId(msg.GetInt("userid"));    

    jConfig.GetString("identificator", szBuffer, sizeof(szBuffer));
    params.SetString(0, szBuffer);

    msg.GetString("event", szBuffer, sizeof(szBuffer));

    char reason[NAME_LENGTH] = "no reason";
    if(szBuffer[7] == 'd')
        msg.GetString("reason", reason, sizeof(reason));

    char network[NAME_LENGTH];
    msg.GetString("network", network, sizeof(network));

    if(sender && IsClientConnected(sender) && jConfig.GetBool("useLog"))
        LogAction(
            sender, -1, "\"%L\" %s the game (%s). Network ID: %s", 
            sender, szBuffer[7] == 'd' ? "disconnected from" : "connected to", reason, network
        );

    delete msg;
    return Proc_Change;
}

public Processing cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    static char szIdent[64];
    params.GetString(0, szIdent, sizeof(szIdent));

    static char szBuffer[MESSAGE_LENGTH];
    jConfig.GetString("identificator", szBuffer, sizeof(szBuffer));

    // LogMessage("Ident(now): %s, Ident(expected): %s, MessagerHas: %b", szIdent, szBuffer, jMessanger.HasKey(currentObject));

    if(strcmp(szIdent, szBuffer) != 0 || !currentObject[0] || !jMessanger.HasKey(currentObject)) {
        return Proc_Continue;
    }

    int priority = jConfig.GetInt("priority");
    if(level > priority)
        return Proc_Continue;

    level = priority;
    // LogMessage("Level now: %d", level);

    JsonObject message = asJSONO(jMessanger.Get(currentObject));

    static char event[NAME_LENGTH];
    message.GetString("event", event, sizeof(event));

    static char szBot[NAME_LENGTH];
    FormatEx(szBot, sizeof(szBot), "%T", message.GetInt("bot") ? "js_bot" : "js_player", props[2]);

    static char name[NAME_LENGTH];
    message.GetString("name", name, sizeof(name));

    static char network[NAME_LENGTH];
    message.GetString("network", network, sizeof(network));

    static char buffer[MESSAGE_LENGTH];
    message.GetString(event[7] == 'd' ? "reason" : "address", buffer, sizeof(buffer));

    delete message;

    JsonArray jValues;

    switch(part) {
        case BIND_PROTOTYPE: {
            if(jConfig.HasKey(szBinds[part]) && jConfig.GetString(szBinds[part], value, size)) {
                Format(value, size, "%c %T", 1, value, props[2]); // because the template contains the body of the message, not the tag
            }
        }

        case BIND_STATUS, BIND_STATUS_CO, BIND_NAME_CO, BIND_MSG_CO, BIND_PREFIX_CO: {
            if(jConfig.GetString(szBinds[part], value, size) && TranslationPhraseExists(value)) {
            
                if(part != BIND_STATUS) 
                    Format(value, size, "%T", value, props[2]);
                
                else Format(value, size, "%T", value, props[2], szBot, network);
            }
        }
            
        case BIND_PREFIX: 
        {
            if(jConfig.GetString(szBinds[part], value, size) && TranslationPhraseExists(value))
                Format(value, size, "%T", value, props[2]);
        }

        case BIND_NAME:
            FormatEx(value, size, "%s", name);

        case BIND_MSG: {
            if(jConfig.HasKey(szBinds[part]) && (jValues = asJSONA(jConfig.Get(szBinds[part]))) && jValues.Size) {
                jValues.GetString(event[7] == 'd', value, size);
                
                if(TranslationPhraseExists(value))
                    Format(value, size, "%T", value, props[2], buffer);
            }
        }
    }

    delete jValues;
    return Proc_Change;
}
