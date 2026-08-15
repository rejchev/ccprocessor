#pragma newdecls required

#include <ccprocessor/modules/channels/ccp-channels>

public Plugin myinfo = 
{
	name = "[CCP] Admin channel",
	author = "rej.chev",
	description = "...",
	version = "2.0.0",
	url = "https://discord.gg/cFZ97Mzrjy"
};

static const char pkgKey[] = "admin_channel";

JsonObject jConfig;
JsonObject jMessager;

int counter;

bool g_bLate;

static const char ROOT[] = "z";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    #if defined DEBUG
        DBUILD()
    #endif

    g_bLate = late;
    return APLRes_Success;
}

public void OnPluginStart() {
    LoadTranslations("admin-channel.phrases");
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

    counter = 0;

    delete jMessager;
    jMessager = asJSONO(new Json("{}"));
}

public void pckg_OnPackageAvailable(int iClient) {
    static char config[MESSAGE_LENGTH]  
        = "configs/ccprocessor/admins-channel/settings.json";

    if(iClient)
        return;
    
    // Load from local
    if(config[0] == 'c') {
        BuildPath(Path_SM, config, sizeof(config), config);
    } 
    
    if(!FileExists(config)) {
        SetFailState("Config file is not exists: %s", config);
    }

    delete jConfig;

    if(!Packager.GetPackage(iClient).SetArtifact(pkgKey, (jConfig = Json.JsonF(config, 0))))
        SetFailState("Something went wrong on set artifact '%s' for client %d", pkgKey, iClient);
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

public Action OnClientSayCommand(int iClient, const char[] cmd, const char[] args) {
    static int rootFlag;
    if(!rootFlag) {
        rootFlag = ReadFlagString(ROOT);
    }

    if(!iClient || !IsClientInGame(iClient) || IsChatTrigger()) {
        return Plugin_Continue;
    }

    static char buffer[MAX_LENGTH];
    FormatEx(buffer, sizeof(buffer), "%s", args);

    TrimString(buffer);

    static char trigger[4];
    jConfig.GetString("channelTrigger", trigger, sizeof(trigger));

    if(buffer[0] == trigger[0]) {
        Format(buffer, sizeof(buffer), "%s", buffer[1]);
            
        TrimString(buffer);
        
        if(!buffer[0]) {
            return Plugin_Continue;
        }

        static int clientFlags;
        clientFlags = GetUserFlagBits(iClient);

        static int accessFlag;
        jConfig.GetString("accessFlag", trigger, sizeof(trigger));
        accessFlag = ReadFlagString(trigger);

        static bool playersCanComplain;
        playersCanComplain = jConfig.GetBool("playersCanComplain");

        if(accessFlag && ((clientFlags & accessFlag) || (clientFlags & rootFlag) || playersCanComplain)) {
            JsonObject message = asJSONO(new Json("{}"));

            static char clientName[NAME_LENGTH];
            GetClientName(iClient, clientName, sizeof(clientName));

            message.SetInt("senderId", GetClientUserId(iClient));
            message.SetString("senderName", clientName);
            message.SetBool("isAdmin", ((clientFlags & accessFlag) || (clientFlags & rootFlag)));
            message.SetString("body", buffer);

            static char msgPointer[MESSAGE_LENGTH];
            FormatEx(msgPointer, sizeof(msgPointer), "msgObject@%d", counter++);

            jMessager.Set(msgPointer, message);
            delete message;

            for(int i = 1, a; i <= MaxClients; i++) {
                if(IsClientInGame(i)) {
                    a = GetUserFlagBits(i);
                    if((a & accessFlag) || (a & rootFlag)) {
                        PrintToChat(i, msgPointer);
                    }
                }
            }

            // don't post call
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

char nextMessage[MESSAGE_LENGTH];

public Processing cc_proc_OnNewMessage(const int[] props, int propsCount, ArrayList params) {
    static const char parentChannel[] = "TM";
    
    char szBuffer[MESSAGE_LENGTH];
    params.GetString(0, szBuffer, sizeof(szBuffer));

    nextMessage = NULL_STRING;
    
    if(strcmp(szBuffer, parentChannel) != 0 ||  IsClientSourceTV(props[1])) {
        return Proc_Continue;
    }

    // message body
    params.GetString(2, szBuffer, sizeof(szBuffer));
    if(!jMessager.HasKey(szBuffer)) {
        return Proc_Continue;
    } 

    FormatEx(nextMessage, sizeof(nextMessage), "%s", szBuffer);

    JsonObject msg = asJSONO(jMessager.Get(szBuffer));
    int sender = GetClientOfUserId(msg.GetInt("senderId"));    

    jConfig.GetString("identificator", szBuffer, sizeof(szBuffer));
    params.SetString(0, szBuffer);

    msg.GetString("body", szBuffer, sizeof(szBuffer));

    if(jConfig.GetBool("useLog")) {
        LogAction(sender, -1, "\"%L\" (%s) used admin channel (text %s)", sender, msg.GetBool("isAdmin") ? "Admin" : "Player", szBuffer);
    }

    delete msg;
    return Proc_Change;
}

public Processing cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    static int rootFlag;
    if(!rootFlag) {
        rootFlag = ReadFlagString(ROOT);
    }

    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));

    char szBuffer[MESSAGE_LENGTH];
    jConfig.GetString("identificator", szBuffer, sizeof(szBuffer));

    if(strcmp(szIndent, szBuffer) || !nextMessage[0] || !jMessager.HasKey(nextMessage)) {
        return Proc_Continue;
    }

    JsonObject message = asJSONO(jMessager.Get(nextMessage));

    static int senderId;
    senderId = GetClientOfUserId(message.GetInt("senderId"));

    static bool isSenderAdmin;
    isSenderAdmin = message.GetBool("isAdmin");

    static char senderName[NAME_LENGTH];
    message.GetString("senderName", senderName, sizeof(senderName));

    static char msgBody[MESSAGE_LENGTH];
    message.GetString("body", msgBody, sizeof(msgBody));

    delete message;

    static bool isSenderAlive;
    isSenderAlive = senderId && IsClientInGame(senderId) && IsPlayerAlive(senderId);

    if(jConfig.HasKey("priority")) {
        int prio = jConfig.GetInt("priority");

        if(prio < level) {
            return Proc_Continue;
        }

        level = prio;
    }

    JsonArray jValues;

    // level = 99;

    switch(part) {
        case BIND_PROTOTYPE: {
            if(jConfig.HasKey(szBinds[part]) && jConfig.GetString(szBinds[part], value, size)) {
                Format(value, size, "%c %T", 1, value, senderId);
            }
        }

        case BIND_STATUS, BIND_STATUS_CO: {
            if(jConfig.HasKey(szBinds[part]) && (jValues = asJSONA(jConfig.Get(szBinds[part]))) && jValues.Size) {
                jValues.GetString(view_as<int>(isSenderAlive), value, size);
                Format(value, size, "%T", value, props[2]);
            }
        }

        case BIND_TEAM, BIND_TEAM_CO: {

            if(jConfig.HasKey(szBinds[part]) && (jValues = asJSONA(jConfig.Get(szBinds[part]))) && jValues.Size) {
                jValues.GetString(
                    // view: admin to admin
                    (isSenderAdmin) 
                        ? 0 :
                        // view: sender - user and how he sees this msg
                        (!isSenderAdmin && senderId == props[2]) 
                            ? 2 
                            // view: other options
                            : 1, 
                    value, size
                );

                Format(value, size, "%T", value, props[2]);
            }
        }

        case BIND_NAME: {
            FormatEx(value, size, "%s", senderName);
        }

        case BIND_MSG: {
            FormatEx(value, size, "%s", msgBody);
        }

        default: {
            if(jConfig.HasKey(szBinds[part]) && jConfig.GetString(szBinds[part], value, size)) {
                FormatEx(value, size, "%T", value, props[2]);
            }

            Package pack;
            JsonObject jArtifact;
            JsonObject jSync;

            if((pack = Packager.GetPackage(0)) && pack.HasArtifact("synchronizer")) {
                jArtifact = asJSONO(pack.GetArtifact("synchronizer"));

                if(jArtifact.HasKey(szIndent))
                    jSync = asJSONO(jArtifact.Get(szIndent));
                
                delete jArtifact;

                // Delegating values from the main message thread
                if(jSync && jSync.HasKey(szBinds[part]))
                    if(part == BIND_PREFIX || jConfig.GetBool("delegate")) 
                        jSync.GetString(szBinds[part], value, size);

                delete jSync;
            }
        }
    }

    delete jValues;
    return Proc_Change;
}