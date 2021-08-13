#pragma newdecls required

#define INCLUDE_RIPJSON

#if defined INCLUDE_DEBUG
    #define DEBUG "[Packager]"
#endif

#include <ccprocessor>

public Plugin myinfo = 
{
	name = "[CCP] JSON Packager",
	author = "rej.chev",
	description = "...",
	version = "1.1.0",
	url = "discord.gg/ChTyPUG"
};

bool g_bLate;

JSONObject packager;

GlobalForward
    fwdPackageUpdate_Post,
    fwdPackageUpdate,
    fwdPackageAvailable;

#include "packager/forwards.sp"
#include "packager/context.sp"
#include "packager/natives.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    #if defined DEBUG
    DBUILD()
    #endif

    CreateNative("ccp_GetPackage", Native_GetPackage);
    CreateNative("ccp_SetPackage", Native_SetPackage);
    CreateNative("ccp_HasPackage", Native_HasPackage);
    CreateNative("ccp_IsVerified", Native_IsVerified);
    CreateNative("ccp_SetArtifact", Native_SetArtifact);
    CreateNative("ccp_RemoveArtifact", Native_Remove);
    CreateNative("ccp_GetArtifact", Native_GetArtifact);
    CreateNative("ccp_HasArtifact", Native_HasArtifact);

    // Processing(Handle initiator, int Client,const char[] artifact, Handle value, int repLevel = -1)
    // level = -1 is default replacement level for this plugin.
    // don't change value with this replacement level...
    fwdPackageUpdate = new GlobalForward(
        "ccp_OnPackageUpdate", 
        ET_Hook, Param_Cell, Param_CellByRef
    );

    fwdPackageUpdate_Post = new GlobalForward(
        "ccp_OnPackageUpdate_Post", 
        ET_Ignore, Param_Cell, Param_Cell
    );

    fwdPackageAvailable = new GlobalForward(
        "ccp_OnPackageAvailable", 
        ET_Ignore, Param_Cell
    );

    RegPluginLibrary("ccprocessor_pkg");

    g_bLate = late;
}

bool Initialization(int iClient, const char[] auth = "STEAM_ID_SERVER") {
    JSONObject obj;

    if(ccp_HasPackage(iClient))
        ccp_SetPackage(iClient, obj, -1);
    
    obj = new JSONObject();
    obj.SetString("auth", auth);
    obj.SetInt("uid", (iClient) ? GetClientUserId(iClient) : 0);

    bool success = ccp_SetPackage(iClient, obj, -1);
    delete obj;

    return success;
}

public void OnPluginStart() {
    packager = new JSONObject();

    if(g_bLate) {
        g_bLate = false;
        for(int i = 1; i <= MaxClients; i++) {
            if(IsClientConnected(i) && IsClientAuthorized(i)) {
                OnClientAuthorized(i, GetClientAuthIdEx(i));
            }
        }
    }
}

public void OnMapStart() {
    #if defined DEBUG
    DBUILD()
    #endif

    OnClientAuthorized(0, "STEAM_ID_SERVER");
}

public void OnClientAuthorized(int iClient, const char[] auth) {
    if(iClient && (IsFakeClient(iClient) || IsClientSourceTV(iClient)))
        return;

    if(!ccp_SetPackage(iClient, null, -1) || !Initialization(iClient, auth))
        SetFailState("What the fuck are u doing?");

    Call_StartForward(fwdPackageAvailable);
    Call_PushCell(iClient);
    Call_Finish();
}

char[] GetClientAuthIdEx(int iClient) {
    static char auth[64];

    if(!GetClientAuthId(iClient, AuthId_Steam2, auth, sizeof(auth)))
        auth = NULL_STRING;

    return auth;
}

char[] IndexToChar(int iClient) {
    static char index[4];
    FormatEx(index, sizeof(index), "%d", iClient);

    return index;
}