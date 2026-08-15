#pragma newdecls required

// jansson | packager | ccprocessor
#include <ccprocessor/modules/channels/ccp-channels>

#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[CCP] Synchronizer",
	author = "rej.chev?",
	description = "...",
	version = "2.0.0",
	url = "https://discord.gg/cFZ97Mzrjy"
};

static const char pkgKey[] = "synchronizer";

bool g_bLate;

int nextSyncTick;

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

    nextSyncTick = GetGameTickCount();

    SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}

public void OnThinkPost(int ent) {
    if(ent == -1) {
        SDKUnhook(ent, SDKHook_ThinkPost, OnThinkPost);
        return;
    }

    static Package pck;
    if(!pck && !(pck = Packager.GetPackage(0)))
        return;

    static int currentTick;
    currentTick = GetGameTickCount();

    static char szBuffer[4];

    if(currentTick >= nextSyncTick) {
        JsonObject obj;
        
        if(!pck.HasArtifact(pkgKey))
            return;
        
        obj = asJSONO(pck.GetArtifact(pkgKey));
        
        nextSyncTick = currentTick + obj.GetInt("delay") * RoundFloat(getTickrate());

        delete obj;

        JsonArray channels;
        if(!(channels = asJSONA(ccp_GetChannelList(0))))
            return;

        ArrayList arr = new ArrayList(MAX_LENGTH, 0);
        static char channel[PREFIX_LENGTH];

        for(int i = 1, a; i <= MaxClients; i++) {
            if(IsClientInGame(i)) {
                
                a = i<<3|GetClientTeam(i)<<1|view_as<int>(IsPlayerAlive(i));

                for(int j; j < channels.Size; j++) {
                    channels.GetString(j, channel, sizeof(channel));
                    
                    stock_RebuildMsg(arr, -1, a, i, channel, NULL_STRING, szBuffer, szBuffer, szBuffer);
                }
            }
        }

        delete arr;
        delete channels;
    }
}

public void pckg_OnPackageAvailable(int iClient) {
    
    static char config[MESSAGE_LENGTH]  
        = "configs/ccprocessor/synchronizer/settings.json";
    
    Package pack = Packager.GetPackage(iClient);

    if(!iClient) {

        // Load from local
        if(config[0] == 'c')
            BuildPath(Path_SM, config, sizeof(config), config);
        
        if(!FileExists(config))
            SetFailState("Config file is not exists: %s", config);
    }

    if(!pack.SetArtifact(pkgKey, (!iClient) ? Json.JsonF(config) : new Json("{}"), freeAnyway))
        SetFailState("Something went wrong on set artifact '%s' for client %d", pkgKey, iClient);
}


public Processing cc_proc_OnRebuildString_Post(const int[] props, int part, ArrayList params, int level, const char[] value) {
    Package pack;
    if(!(pack = Packager.GetPackage(SENDER_INDEX(props[1]))))
        return Proc_Continue;

    char szBuffer[64];
    params.GetString(1, szBuffer, sizeof(szBuffer));
    
    JsonObject obj;

    // this is not the pseudo call ;/
    if(szBuffer[0])
        return Proc_Continue;
    
    params.GetString(0, szBuffer, sizeof(szBuffer));
    
    if(!(obj = asJSONO(pack.GetArtifact(pkgKey))))
        return Proc_Continue;

    JsonObject ch;

    ch = !obj.HasKey(szBuffer) 
            ? asJSONO(new Json("{}"))
            : asJSONO(obj.Get(szBuffer));

    ch.SetString(szBinds[part], value);

    obj.Set(szBuffer, ch);
    delete ch;

    pack.SetArtifact(pkgKey, obj, freeAnyway);

    return Proc_Continue;
}

stock float getTickrate() {
    return (1/GetTickInterval());
}