public any Native_GetPackage(Handle h, int a) {
    static char index[4];
    FormatEx(index, sizeof(index), "%d", GetNativeCell(1));

    if(packager.HasKey(index))
        return packager.Get(index);
    
    return 0;
}

// bool(iClient, Handle value, int level)
public any Native_SetPackage(Handle h, int a) {
    return context(h, GetNativeCell(1), NULL_STRING, asJSON(GetNativeCell(2)), GetNativeCell(3)) < Proc_Reject;
}

// bool(iClient)
public any Native_HasPackage(Handle h, int a) {
    return packager.HasKey(IndexToChar(GetNativeCell(1)));
}

// bool(iClient) : "auth"?
public any Native_IsVerified(Handle h, int a) {
    int iClient = GetNativeCell(1);
    bool ver;

    JSONObject obj;
    if((obj = asJSONO(ccp_GetPackage(iClient))) != null && obj.HasKey("auth") && !obj.IsNull("auth")) {
        char auth[64];
        auth = GetClientAuthIdEx(iClient);

        char buffer[64];
        obj.GetString("auth", buffer, sizeof(buffer));

        ver = auth[0] != 0 && strcmp(auth, buffer) == 0;
    }

    delete obj;
    
    return ver;
}

// bool(int iClient, const char[] artifact, Handle value, int repLevel)
public any Native_SetArtifact(Handle h, int a) {
    int iClient = GetNativeCell(1);

    if(!ccp_HasPackage(iClient))
        return false;

    static char artifact[PREFIX_LENGTH];
    GetNativeString(2, artifact, sizeof(artifact));

    return context(h, GetNativeCell(1), artifact, asJSON(GetNativeCell(3)), GetNativeCell(4)) < Proc_Reject;
}

// bool(int iClient, const char[] artifact, int repLevel)
public any Native_Remove(Handle h, int a) {
    int iClient = GetNativeCell(1);

    if(!ccp_HasPackage(iClient))
        return false;

    static char artifact[64];
    GetNativeString(2, artifact, sizeof(artifact));

    return context(h, GetNativeCell(1), artifact, null, GetNativeCell(3)) < Proc_Reject;
}

public any Native_GetArtifact(Handle h, int a) {
    int iClient = GetNativeCell(1);

    if(!ccp_HasPackage(iClient))
        return 0;

    static char artifact[64];
    GetNativeString(2, artifact, sizeof(artifact));

    JSONObject client;
    client = asJSONO(ccp_GetPackage(iClient));
    
    JSON obj;
    if(client.HasKey(artifact) && !client.IsNull(artifact))
        obj = client.Get(artifact);

    delete client;
    return obj;
}

public any Native_HasArtifact(Handle h, int a) {
    int iClient = GetNativeCell(1);

    if(!ccp_HasPackage(iClient))
        return false;

    static char artifact[64];
    GetNativeString(2, artifact, sizeof(artifact));

    JSONObject client;
    client = asJSONO(ccp_GetPackage(iClient));
    
    bool has = client.HasKey(artifact) && !client.IsNull(artifact);

    delete client;
    return has;
}