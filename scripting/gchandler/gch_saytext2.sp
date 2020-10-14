public Action UserMessage_SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    static int iIndex, MsgType, iBackupIndex;
    iIndex = iBackupIndex = MsgType = 0;

    static char szName[NAME_LENGTH], szMessage[MESSAGE_LENGTH], szBuffer[MAX_LENGTH];
    szName = NULL_STRING;
    szBuffer = NULL_STRING;
    szMessage = NULL_STRING;

    static int clients[MAXPLAYERS+1];
    CopyEqualArray(players, clients, playersNum);

    iIndex = 
        (!umType) ? 
            ReadBfMessage(view_as<BfRead>(msg), MsgType, SZ(szName), SZ(szMessage)) :
            ReadProtoMessage(view_as<Protobuf>(msg), MsgType, SZ(szName), SZ(szMessage));
            
    // If a player has added colors into his nickname
    ReplaceColors(SZ(szName), true);

    // If a player has added colors into his msg
    if(!Call_IsSkipColors(MsgType, iIndex))
        ReplaceColors(SZ(szMessage), true);
    
    RebuildMessage(iIndex, MsgType, szName, szMessage, SZ(szBuffer), "saytext2");

    if(!szBuffer[0])
        return Plugin_Handled;
    
    Call_MessageBuilt(MsgType, iIndex, szBuffer);

    ReplaceColors(SZ(szBuffer), false);

    Call_RebuildClients(MsgType, iIndex, clients, playersNum);

    iBackupIndex = iIndex;

    if(!IsFakeClient(iIndex))
        Call_IndexApproval(MsgType, iIndex);

    g_mMessage.SetValue("ent_idx", iIndex);
    g_mMessage.SetValue("backup_idx", iBackupIndex);

    g_mMessage.SetArray("players", clients, playersNum);
    g_mMessage.SetValue("playersNum", playersNum);

    g_mMessage.SetString("msg_name", szBuffer);
    g_mMessage.SetValue("type", MsgType);

    return Plugin_Handled;
}

public void SayText2_Completed(UserMsg msgid, bool send)
{
    int 
        iIndex, iBackupIndex, iPlayersNum, iType;
    
    char
        szMessage[MAX_LENGTH];

    if(!send || !g_mMessage.GetValue("ent_idx", iIndex))
        return;
    
    g_mMessage.GetValue("backup_idx", iBackupIndex);
    g_mMessage.GetValue("playersNum", iPlayersNum);
    g_mMessage.GetValue("type", iType);
    g_mMessage.GetString("msg_name", szMessage, sizeof(szMessage));
    
    int[] players = new int[iPlayersNum];
    g_mMessage.GetArray("players", players, iPlayersNum);

    g_mMessage.Clear();

    // Not equal (just fix clients array)
    CopyEqualArray(players, players, iPlayersNum);
    ChangeModeValue(players, iPlayersNum, "0");

    Handle uMessage = 
        StartMessageEx(msgid, players, iPlayersNum, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

    if(uMessage)
    {
        Call_OnNewMessage();
        
        if(!umType)
        {
            BfWriteByte(uMessage, iIndex);
            BfWriteByte(uMessage, true);
            BfWriteString(uMessage, szMessage);
        }

        else
        {
            PbSetInt(uMessage, "ent_idx", iIndex);
            PbSetBool(uMessage, "chat", true);
            PbSetString(uMessage, "msg_name", szMessage);
            PbSetBool(uMessage, "textallchat", view_as<bool>(iType));

            for(int i; i < 4; i++)
                PbAddString(uMessage, "params", NULL_STRING);
        }
        
        EndMessage();
    }

    ChangeModeValue(players, iPlayersNum, mode_default_value);
}

int ReadProtoMessage(Protobuf message, int &iMsgType, char[] szSenderName, int sn_size, char[] szSenderMsg, int sm_size)
{   
    message.ReadString("msg_name", szSenderName, sn_size);
    iMsgType = GetSayTextType(szSenderName);

    message.ReadString("params", szSenderName, sn_size, 0);
    message.ReadString("params", szSenderMsg, sm_size, 1);

    return message.ReadInt("ent_idx");
}

int ReadBfMessage(BfRead message, int &iMsgType, char[] szSenderName, int sn_size, char[] szSenderMsg, int sm_size)
{
    // Sender
    int iSender = message.ReadByte();
    
    // Is chat
    message.ReadByte();
    
    // msg_name
    message.ReadString(szSenderName, sn_size);
    iMsgType = GetSayTextType(szSenderName);

    // param 0
    message.ReadString(szSenderName, sn_size);

    // param 1
    message.ReadString(szSenderMsg, sm_size);

    return iSender;   
}

int GetSayTextType(char[] szMsgPhrase)
{
    return (StrContains(szMsgPhrase, "Cstrike_Name_Change") != -1) ? eMsg_CNAME : view_as<int>(StrContains(szMsgPhrase, "_All") != -1); 
}