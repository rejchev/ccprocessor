
#include <UTF-8-string>

#pragma newdecls required

#include <packager>
#include <ccprocessor>

public Plugin myinfo = 
{
	name = "[CCP] Tag changer",
	author = "rej.chev...",
	description = "...",
	version = "2.0.0",
	url = "discord.gg/ChTyPUG"
};

bool g_bLate;

static const char pkgKey[] = "tag_changer";

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
}

public void pckg_OnPackageAvailable(int iClient) {
    static char config[MESSAGE_LENGTH]  = "configs/ccprocessor/tag-changer/settings.json";

    if(iClient)
        return;

    // Load from local
    if(config[0] == 'c')
        BuildPath(Path_SM, config, sizeof(config), config);
    
    if(!FileExists(config))
        SetFailState("Config file is not exists: %s", config);

    Packager.GetPackage(iClient).SetArtifact(pkgKey, Json.JsonF(config, 0), freeAnyway);
}

public Processing  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    if(part != BIND_PREFIX && part != BIND_MSG || !value[0])
        return Proc_Continue;

    char szBuffer[MAX_LENGTH];
    params.GetString(0, szBuffer, sizeof(szBuffer));

    if(!ChannelExists(szBuffer))
        return Proc_Continue;
    
    if(level > GetReplacementLevel())
        return Proc_Continue;
    
    level = GetReplacementLevel();

    return EditedValue(value, size);
}

int GetReplacementLevel() {
    JsonObject jsObject;
    if((jsObject = asJSONO(Packager.GetPackage(0).GetArtifact(pkgKey))) == null)
        return -1;

    int level = jsObject.GetInt("level");

    delete jsObject;
    return level;
}

bool ChannelExists(const char[] channel) {
    JsonObject jsObject;
    if(!(jsObject = asJSONO(Packager.GetPackage(0).GetArtifact(pkgKey))))
        return true;
    
    JsonArray array;
    if(!(array = asJSONA(jsObject.Get("channels", true)))) {
        delete jsObject;
        return true;
    }

    bool exists = JsonArrayContainsString(array, channel);

    delete array;
    return exists;
}

Processing EditedValue(char[] value, int size) {
    char szBuffer[MAX_LENGTH];
    FormatEx(szBuffer, sizeof(szBuffer), "%s", value);

    TrimString(szBuffer);

    // LogMessage("Preprocessing: %s | %s", szBuffer, value);

    ProcessingValue(szBuffer, sizeof(szBuffer));

    // LogMessage("PostProcessing: %s | %s", szBuffer, value);

    bool cmp;
    if((cmp = UTF8strcmp(value, szBuffer, false) != 0))
        FormatEx(value, size, "%s", szBuffer);
    
    return cmp ? Proc_Change : Proc_Continue;
}

void ProcessingValue(char[] szBuffer, int size) {
    JsonObject jsObject;
    if((jsObject = asJSONO(Packager.GetPackage(0).GetArtifact(pkgKey))) == null)
        return;

    JsonObject tags;
    if((tags = asJSONO(jsObject.Get("tags", true))) == null) {
        delete jsObject;
        return;
    }
    
    JsonArray keys;
    if(!(keys = tags.Keys(JStringType)) || !keys.Size)
        return;
        
    int s, e;
    char szKey[NAME_LENGTH];
    char szValue[PREFIX_LENGTH];
    for(int i = 0; i < keys.Size; i++) {
        s = e = 0;

        if(!tags.GetString(szKey, szValue, sizeof(szValue)))
            continue;

        if((s = UTF8StrContains(szBuffer, szKey, false)) != -1 && !s && IsCtxEquals(szBuffer, szKey, s, e)) {
            RemoveString(szBuffer, size, s, s+e);
            Format(szBuffer, size, "%s%s", szValue, szBuffer);
        }

        // LogMessage("Find: s-%d | e-%d | %s", s, e, szKey);
    }
}

bool IsCtxEquals(const char[] message, const char[] input, int &s, int &e) {
    if(!message[0] || !input[0] || strlen(message) < strlen(input))
        return false;
    
    while(e < strlen(input)) {
        if(message[e] != input[e])
            return false;
        
        e++;
    }

    return true;
}

stock void RemoveString(char[] buffer, int size, int s, int e) {
    if(!buffer[0] || s == -1 || e == -1)
        return;
        
    strcopy(buffer[s], size, buffer[e]);
}

stock bool JsonArrayContainsString(const JsonArray array, const char[] str, bool casesens = true) {
    
    if(!array)
        return false;

    char buffer[512];
    for(int i = 0; i < array.Size; i++) {

        if(!array.GetString(i, buffer, sizeof(buffer)))
            continue;

        if(!strcmp(str, buffer, casesens))
            return true;
    }

    return false;
}