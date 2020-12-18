public Action UserMessage_RadioText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    static char szName[NAME_LENGTH], szKey[MESSAGE_LENGTH], szBuffer[MAX_LENGTH];
    szKey = NULL_STRING;
    szName = NULL_STRING;
    szBuffer = NULL_STRING;

    static const char szParam[2][4] = {"%s2", "%s3"};
    static const int iType = eMsg_RADIO;

    static int clients[MAXPLAYERS+1];
    CopyEqualArray(players, clients, playersNum);

    static int iIndex, /*iBackupIndex, */iRadioType;
    iIndex = /*iBackupIndex = */iRadioType = 0;

    iIndex = 
        (!umType) ? 
            ReadRadioAsBf(view_as<BfRead>(msg), iRadioType, SZ(szName), SZ(szKey)) :
            ReadRadioAsProto(view_as<Protobuf>(msg), iRadioType, SZ(szName), SZ(szKey));

    if(Call_RestrictRadioKey(iIndex, szKey))
        return Plugin_Handled;

    ReplaceColors(SZ(szName), true);

    if(!RebuildMessage(iType, iIndex, 0, szName, szKey, SZ(szBuffer), "radio"))
        return Plugin_Handled;

    // Call_MessageBuilt(iType, iIndex, szBuffer);

    ReplaceColors(SZ(szBuffer), false);

    ReplaceString(szBuffer, sizeof(szBuffer), "{MSG}", szParam[iRadioType]);

    Call_RebuildClients(iType, iIndex, clients, playersNum);

    // iBackupIndex = iIndex;

    // if(!IsFakeClient(iIndex))
    //     Call_IndexApproval(iType, iIndex);

    g_mMessage.SetValue("ent_idx", iIndex);
    // g_mMessage.SetValue("backup_idx", iBackupIndex);

    g_mMessage.SetArray("players", clients, playersNum);
    g_mMessage.SetValue("playersNum", playersNum);

    g_mMessage.SetString("msg_name", szBuffer);
    g_mMessage.SetString("msg_key", szKey);
    g_mMessage.SetValue("type", iRadioType);

    return Plugin_Handled;
}

public void RadioText_Completed(UserMsg msgid, bool send)
{
    int 
        iIndex, /*iBackupIndex,*/ iPlayersNum, iType;
    
    char
        szMessage[MAX_LENGTH], szKey[NAME_LENGTH];
    
    if(!send || !g_mMessage.GetValue("ent_idx", iIndex))
        return;
    
    g_mMessage.GetValue("ent_idx", iIndex);
    // g_mMessage.GetValue("backup_idx", iBackupIndex);
    g_mMessage.GetValue("playersNum", iPlayersNum);
    g_mMessage.GetValue("type", iType);
    g_mMessage.GetString("msg_name", szMessage, sizeof(szMessage));
    g_mMessage.GetString("msg_key", szKey, sizeof(szKey));

    int[] players = new int[iPlayersNum];
    g_mMessage.GetArray("players", players, iPlayersNum);

    g_mMessage.Clear();

    // Not equal (just fix clients array)
    CopyEqualArray(players, players, iPlayersNum);
    ChangeModeValue(players, iPlayersNum, "0");

    Handle message = 
        StartMessageEx(msgid, players, iPlayersNum, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

    if(message)
    {
        // Call_OnNewMessage();
        
        if(!umType)
        {
            BfWriteByte(message, 3);
            BfWriteByte(message, iIndex);
            BfWriteString(message, szMessage);
            BfWriteString(message, "1");
            BfWriteString(message, (iType) ? "1" : szKey);

            if(iType) BfWriteString(message, szKey);
        }

        else
        {
            PbSetInt(message, "msg_dst", 3);
            PbSetInt(message, "client", iIndex);
            PbSetString(message, "msg_name", szMessage);

            PbAddString(message, "params", NULL_STRING);
            PbAddString(message, "params", (iType) ? NULL_STRING : szKey);
            PbAddString(message, "params", (iType) ? szKey : NULL_STRING);
            PbAddString(message, "params", NULL_STRING);
        }

        EndMessage();
    }

    ChangeModeValue(players, iPlayersNum, mode_default_value);
}

int ReadRadioAsBf(BfRead message, int &iRadioType, char[] szName, int nsize, char[] szRKey, int ksize)
{
    int iIndex = message.ReadByte();

    message.ReadString(szName, nsize);

    iRadioType = view_as<int>(StrContains(szName, "_location", false) != -1);

    message.ReadString(szName, nsize);
    message.ReadString(szRKey, ksize);

    if(iRadioType)
    {
        message.ReadString(szRKey, ksize);
    }
    
    strcopy(szName, nsize, szName[FindCharInString(szName, ']')+1]);

    return iIndex;
}

int ReadRadioAsProto(Protobuf message, int &iRadioType, char[] szName, int nsize, char[] szRKey, int ksize)
{
    message.ReadString("msg_name", szName, nsize);
    iRadioType = view_as<int>(StrContains(szName, "_location", false) != -1);

    message.ReadString("params", szName, nsize, 0);

    message.ReadString("params", szRKey, ksize, (iRadioType) ? 2 : 1);

    strcopy(szName, nsize, szName[FindCharInString(szName, ']')+1]);

    return message.ReadInt("client");
}