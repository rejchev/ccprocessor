#define MAX_PARAMS 5

public int Native_GetMsgID(Handle hPlugin, int params) {
    return g_iMsgInProgress;
}

public int Native_Translate(Handle hPlugin, int params) {
    char szPhrase[MESSAGE_LENGTH];
    GetNativeString(1, SZ(szPhrase));

    bool exist = TranslationPhraseExists(szPhrase);

    #if defined DEBUG
    DWRITE("%s: ccp_Translate(%s): %b", DEBUG, szPhrase, exist);
    #endif

    if(exist) {
        Format(SZ(szPhrase), "%T", szPhrase, GetNativeCell(2));
        SetNativeString(1, SZ(szPhrase));
    }

    return exist;
}

public int Native_EngineMessageReq(Handle hPlugin, int params) {
    int props[4];
    GetNativeArray(1, props, GetNativeCell(2));

    static bool handle;
    handle = Call_HandleEngineMsg(props, GetNativeCell(2), GetNativeCell(3));

    #if defined DEBUG
    DWRITE("%s: ccp_EngineMsgRequest(): %b", DEBUG, handle);
    #endif

    return handle;
}

public int Native_UpdateRecipients(Handle hPlugin, int params) {
    int playersNum = GetNativeCellRef(3);
    int[] players = new int[playersNum];

    GetNativeArray(1, players, playersNum);

    int a;
    for(int i; i < playersNum; i++) {
        if(IsClientConnected(players[i]) && (IsClientSourceTV(players[i]) || !IsFakeClient(players[i]))) {
            players[a++] = players[i];  

            #if defined DEBUG
            DWRITE("%s: ccp_UpdateRecipients(%i): valid", DEBUG, players[i]);
            #endif
        }
    }

    SetNativeArray(2, players, a);
    SetNativeCellRef(3, a);   
}

public int Native_SkipColors(Handle hPlugin, int params) {
    char szIndent[64];
    GetNativeString(1, szIndent, sizeof(szIndent));

    static bool skip;
    skip = Call_IsSkipColors(szIndent, GetNativeCell(2));

    #if defined DEBUG
    DWRITE("%s: ccp_UpdateRecipients(%s): %b", DEBUG, szIndent, skip);
    #endif

    return skip;    
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
    if(g_iMsgInProgress != -1 || !Call_NewMessage(GetNativeCell(1), GetNativeCell(2))) {
        #if defined DEBUG
        DWRITE("%s: ccp_StartNewMessage(%i): message aborted", DEBUG, g_iMsgInProgress);
        #endif

        return -1;
    }

    g_iMessageCount++;
    g_iMsgInProgress = g_iMessageCount;

    #if defined DEBUG
    DWRITE("%s: ccp_StartNewMessage(%i): start", DEBUG, g_iMsgInProgress);
    #endif

    return g_iMsgInProgress;
}

public any Native_RebuildClients(Handle hPlugin, int params) {
    int props[4];
    GetNativeArray(1, props, GetNativeCell(2));

    #if defined DEBUG
    DWRITE("%s: ccp_RebuildClients()", DEBUG);
    #endif
    
    return Call_RebuildClients(props, GetNativeCell(2), GetNativeCell(3));
}

public any Native_RebuildMessage(Handle hPlugin, int params) {
    int props[4];
    GetNativeArray(1, props, GetNativeCell(2));

    #if defined DEBUG
    DWRITE("%s: ccp_RebuildMessage()", DEBUG);
    #endif

    return BuildMessage(props, GetNativeCell(2), GetNativeCell(3));
}

public any Native_HandleEngineMsg(Handle hPlugin, int params) {
    int props[4];
    GetNativeArray(1, props, GetNativeCell(2));

    #if defined DEBUG
    DWRITE("%s: ccp_HandleEngineMsg()", DEBUG);
    #endif
    
    return HandleEngineMsg(props, GetNativeCell(2), GetNativeCell(3));
}

public int Native_EndMessage(Handle hPlugin, int params) {
    int props[4];
    GetNativeArray(1, props, GetNativeCell(2));

    #if defined DEBUG
    DWRITE("%s: ccp_EndMessage()", DEBUG);
    #endif

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