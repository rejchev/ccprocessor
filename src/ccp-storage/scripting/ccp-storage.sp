#pragma newdecls required

#define INCLUDE_RIPJSON

#include <ccprocessor>

public Plugin myinfo = 
{
	name = "[CCP] Storage",
	author = "rej.chev?",
	description = "...",
	version = "1.0.0",
	url = "discord.gg/ChTyPUG"
};

static const char location[] = "data/ccprocessor/cache/%s.json";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
    CreateNative("ccp_storage_WriteValue",  Native_Write);
    CreateNative("ccp_storage_ReadValue",   Native_Read);
    CreateNative("ccp_storage_RemoveValue", Native_Remove);

    RegPluginLibrary("ccp_storage");
    return APLRes_Success
}

public any Native_Write(Handle h, int a) {
    int iClient = GetNativeCell(1);

    JSON storage;

    if((storage = getStorage(iClient)) == null)
        return false;
    
    char key[PREFIX_LENGTH];
    GetNativeString(2, key, sizeof(key));

    if(asJSONO(storage).HasKey(key)) {
        delete storage;
        return false;
    }

    JSON value = asJSON(GetNativeCell(3));

    asJSONO(storage).Set(key, value);
    storage.ToFile(getStoragePath(getAuth(iClient), location), 0);

    delete storage;
    return true;
}

public any Native_Read(Handle h, int a) {
    int iClient = GetNativeCell(1);

    JSON storage;

    if((storage = getStorage(iClient)) == null)
        return storage;
    
    char key[PREFIX_LENGTH];
    GetNativeString(2, key, sizeof(key));

    if(!asJSONO(storage).HasKey(key)) {
        delete storage;
        return storage;
    }

    JSON value;

    value = asJSONO(storage).Get(key);
    delete storage;

    return value;
}

public any Native_Remove(Handle h, int a) {
    int iClient = GetNativeCell(1);

    JSON storage;

    if((storage = getStorage(iClient)) == null)
        return false;
    
    char key[PREFIX_LENGTH];
    GetNativeString(2, key, sizeof(key));

    if(!asJSONO(storage).HasKey(key)) {
        delete storage;
        return false;
    }

    asJSONO(storage).Remove(key);
    storage.ToFile(getStoragePath(getAuth(iClient), location), 0);
    delete storage;

    return true;
}

public void ccp_OnPackageAvailable(int iClient) {
    static char path[MESSAGE_LENGTH];

    path = getStoragePath(getAuth(iClient), location);

    if(!FileExists(path)) {
        JSONObject buffer = new JSONObject();
        asJSON(buffer).ToFile(path, 0);

        delete buffer;
    }
}

stock char[] getAuth(int iClient) {
    JSONObject obj = asJSONO(ccp_GetPackage(iClient));

    char auth[PREFIX_LENGTH];
    obj.GetString("auth", auth, sizeof(auth));

    delete obj;
    return auth;
}

stock char[] getStoragePath(const char[] auth, const char[] loc) {
    static char buffer[MESSAGE_LENGTH];
    strcopy(buffer, sizeof(buffer), auth);

    ReplaceString(buffer, sizeof(buffer), ":", "");
    ReplaceString(buffer, sizeof(buffer), "[", "");
    ReplaceString(buffer, sizeof(buffer), "]", "");

    BuildPath(Path_SM, buffer, sizeof(buffer), loc, buffer);

    return buffer;
}

stock JSON getStorage(int iClient) {
    char path[MESSAGE_LENGTH];
    path = getStoragePath(getAuth(iClient), location);

    if(!FileExists(path))
        return null;

    return asJSON(JSONObject.FromFile(path, 0));
}