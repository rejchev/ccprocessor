#define MAX_PARAMS 5

public int Native_GetMsgID(Handle hPlugin, int params) {
    return g_iMsgInProgress;
}

public int Native_Translate(Handle hPlugin, int params) {
    char szPhrase[MESSAGE_LENGTH];
    GetNativeString(1, SZ(szPhrase));

    if(!TranslationPhraseExists(szPhrase)) {
        return false;
    }

    Format(SZ(szPhrase), "%T", szPhrase, GetNativeCell(2));
    SetNativeString(1, SZ(szPhrase));
    return true;
}

public int Native_EngineMessageReq(Handle hPlugin, int params) {
    char props[16];
    GetNativeString(1, SZ(props));

    return Call_HandleEngineMsg(props, GetNativeCell(2), GetNativeCell(3));
}

public int Native_UpdateRecipients(Handle hPlugin, int params) {
    int players[MAXPLAYERS+1];
    int output[MAXPLAYERS+1];
    int playersNum = GetNativeCellRef(3);
    GetNativeArray(1, players, playersNum);

    int a;
    for(int i; i < playersNum; i++) {
        if(IsClientConnected(players[i]) 
        && (IsClientSourceTV(players[i]) || !IsFakeClient(players[i]))) {
            output[a++] = players[i];  
        }
    }

    SetNativeArray(2, output, a);
    SetNativeCellRef(3, a);   
}

public int Native_SkipColors(Handle hPlugin, int params) {
    char szIndent[64];
    GetNativeString(1, szIndent, sizeof(szIndent));

    return Call_IsSkipColors(szIndent, GetNativeCell(2));    

}

public int Native_ChangeMode(Handle hPlugin, int params) {
    if(!game_mode) {
        return;
    }

    int players[MAXPLAYERS+1];
    int playersNum = GetNativeCell(2);
    GetNativeArray(1, players, playersNum);

    char szValue[4];
    GetNativeString(3, szValue, sizeof(szValue));

    if(!szValue[0]) {
        strcopy(szValue, sizeof(szValue), mode_default_value);
    }

    for(int i; i < playersNum; i++) {
        #if defined DEBUG
            DWRITE("%s: ChangeModeValue(%N): %s", DEBUG, players[i], szValue);
        #endif

        if(IsFakeClient(players[i]))
            SetFakeClientConVar(players[i], "game_mode", szValue);
        
        else game_mode.ReplicateToClient(players[i], szValue);
    }
}

public int Native_StartNewMessage(Handle hPlugin, int params) {
    if(g_iMsgInProgress != -1) {
        return -1;
    }

    if(!Call_NewMessage(GetNativeCell(1), GetNativeCell(2))) {
        return -1;
    }

    g_iMessageCount++;
    g_iMsgInProgress = g_iMessageCount;

    return g_iMsgInProgress;
}

public any Native_RebuildClients(Handle hPlugin, int params) {
    char props[16];
    GetNativeString(1, SZ(props));
    
    return Call_RebuildClients(props, GetNativeCell(2), GetNativeCell(3));
}

public any Native_RebuildMessage(Handle hPlugin, int params) {
    char props[16];
    GetNativeString(1, SZ(props));

    return BuildMessage(props, GetNativeCell(2), GetNativeCell(3));
}

public any Native_HandleEngineMsg(Handle hPlugin, int params) {
    char props[16];
    GetNativeString(1, SZ(props));
    
    return HandleEngineMsg(props, GetNativeCell(2), GetNativeCell(3));
}

public int Native_EndMessage(Handle hPlugin, int params) {
    char props[16];
    GetNativeString(1, SZ(props));

    Call_MessageEnd(props, GetNativeCell(2), GetNativeCell(3));

    g_iMsgInProgress = -1;
}

public int Native_ReplaceColors(Handle hPlugin, int iArgs)
{
    char szBuffer[MAX_LENGTH];
    GetNativeString(1, szBuffer, sizeof(szBuffer));

    bool allTags = view_as<bool>(GetNativeCell(2));
    
    #if defined DEBUG
        DWRITE("%s: ReplaceColors(%b): %s", DEBUG, allTags, szBuffer);
    #endif

    if(!szBuffer[0]) {
        return;
    }

    char szKey[STATUS_LENGTH], szColor[STATUS_LENGTH];

    int i;
    while(i < g_aPalette.Length) {
        g_aPalette.GetString(i, szKey, sizeof(szKey));
        g_aPalette.GetString(i+1, szColor, sizeof(szColor));

        ReplaceString(SZ(szBuffer), szKey, (!allTags) ? szColor : NULL_STRING, true);
        if(allTags)
            ReplaceString(SZ(szBuffer), szColor, NULL_STRING, true);

        i+=2;
    }

    #if defined DEBUG
        DWRITE("%s: ReplaceColors Output(%b): %s", DEBUG, allTags, szBuffer);
    #endif

    SetNativeString(1, SZ(szBuffer));
}

public int Native_GetAPIKey(Handle hPlugin, int iArgs) {
    return API_KEY;
}

public int Native_IsAPIEqual(Handle hPlugin, int iArgs) {
    return GetNativeCell( 1 ) == API_KEY;
}

public any Native_DropPalette(Handle hPlugin, int iArgs) {
    return g_aPalette;
}