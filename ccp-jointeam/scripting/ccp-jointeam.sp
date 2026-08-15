#include <UTF-8-string>

#pragma newdecls required

#include <ccprocessor/modules/channels/ccp-channels>

public Plugin myinfo = 
{
	name = "[CCP] Join team",
	author = "rej.chev?",
	description = "...",
	version = "1.1.0",
	url = "https://discord.gg/cFZ97Mzrjy"
};

static const char pkgKey[] = "join_team";

static const char objectPattern[] = "joinTeam@%d";

int counter;

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
    LoadTranslations("ccp-jointeam.phrases");

    HookEvent("player_team", EventTeam, EventHookMode_Pre);
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

    delete jMessanger;
    jMessanger = asJSONO(new Json("{}"));
}

public void pckg_OnPackageAvailable(int iClient) {
    // static const char cloud[]           = "cloud";
    static char config[MESSAGE_LENGTH]  = "configs/ccprocessor/join-team/settings.json";

    if(iClient)
        return;
    

    if(jConfig) {
        delete jConfig;
    }

    // Loaded from cloud
    // if(objPackage.HasKey(pkgKey) && objPackage.HasKey(cloud) && objPackage.GetBool(cloud)) {
    //     if(!iClient) {
    //         jConfig = asJSONO(objPackage.Get(pkgKey));    
    //     }

    //     return;
    // }

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

Action EventTeam(Event event, const char[] name, bool dbc) {
    if(!jConfig.GetBool("processing")) {
        return Plugin_Continue;
    }

    event.SetBool("silent", true);

    if(event.GetInt("disconnect") || jConfig.GetBool("hideMessages")) {
        return Plugin_Changed;
    }

    int userId;
    userId = event.GetInt("userid");

    int iTeam;
    iTeam = event.GetInt("team");

    JsonArray teamVisibility = asJSONA(jConfig.Get("hide"));
    if(teamVisibility.Size > iTeam && iTeam >= 0 && teamVisibility.GetBool(iTeam)) {
        delete teamVisibility;
        return Plugin_Changed;
    }

    delete teamVisibility;

    char szName[NAME_LENGTH];
    GetClientName(GetClientOfUserId(userId), szName, sizeof(szName));

    JsonObject message = asJSONO(new Json("{}"));
    message.SetInt("userId", userId);
    message.SetInt("team", iTeam);
    message.SetString("userName", szName);

    FormatEx(szName, sizeof(szName), objectPattern, counter++);
    
    jMessanger.Set(szName, message);
    delete message;

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            PrintToChat(i, szName);
        }
    }    
    
    return Plugin_Changed;
}

public Processing cc_proc_OnNewMessage(const int[] props, int propsCount, ArrayList params) {
    static const char parentChannel[] = "TM";
    
    char szBuffer[MESSAGE_LENGTH];
    params.GetString(0, szBuffer, sizeof(szBuffer));

    currentObject = NULL_STRING;
    
    if(strcmp(szBuffer, parentChannel) != 0 || IsClientSourceTV(props[1])) {
        return Proc_Continue;
    }

    // message object
    params.GetString(2, szBuffer, sizeof(szBuffer));
    if(!jMessanger.HasKey(szBuffer)) {
        return Proc_Continue;
    } 

    FormatEx(currentObject, sizeof(currentObject), "%s", szBuffer);

    JsonObject msg = asJSONO(jMessanger.Get(szBuffer));
    int sender = GetClientOfUserId(msg.GetInt("userId"));    

    jConfig.GetString("identificator", szBuffer, sizeof(szBuffer));
    params.SetString(0, szBuffer);

    if(sender && IsClientConnected(sender) && jConfig.GetBool("useLog")) {
        LogAction(sender, -1, "\"%L\" connected to %d team", sender, msg.GetInt("team"));
    }

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

    static int team;
    team = message.GetInt("team");

    static char userName[NAME_LENGTH];
    message.GetString("userName", userName, sizeof(userName));

    delete message;

    JsonArray jValues;

    switch(part) {
        case BIND_PROTOTYPE: {
            if(jConfig.HasKey(szBinds[part]) && jConfig.GetString(szBinds[part], value, size)) {
                Format(value, size, "%c %T", 1, value, props[2]); // because the template contains the body of the message, not the tag
            }
        }

        case BIND_STATUS, BIND_STATUS_CO: {
            if(jConfig.HasKey(szBinds[part]) && (jValues = asJSONA(jConfig.Get(szBinds[part]))) && jValues.Size) {
                jValues.GetString(1, value, size); // server is always alive :/
                Format(value, size, "%T", value, props[2]);
            }
        }

        case BIND_TEAM, BIND_TEAM_CO: {
            if(jConfig.HasKey(szBinds[part]) && (jValues = asJSONA(jConfig.Get(szBinds[part]))) && jValues.Size) {
                jValues.GetString(team, value, size);
                Format(value, size, "%T", value, props[2]);
            }
        }

        case BIND_NAME: {
            FormatEx(value, size, "%s", userName);
        }

        default: {
            if(jConfig.HasKey(szBinds[part]) && jConfig.GetString(szBinds[part], value, size)) {
                FormatEx(value, size, "%T", value, props[2]);
            }
        }
    }

    delete jValues;
    return Proc_Change;
}
