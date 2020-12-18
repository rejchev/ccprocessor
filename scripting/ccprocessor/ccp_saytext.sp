
/*
    This is a personal update for `level-ranks` users, which uses `SayText` for messages from the plugin.
    The hook allows you to build a message according to the internal patterns of the core.
*/

public Action UserMessage_SayText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "ent_idx")) != 0)
        return Plugin_Continue;

    static char szName[NAME_LENGTH], szMessage[MESSAGE_LENGTH], szBuffer[MAX_LENGTH];
    szName = "CONSOLE";
    szBuffer = NULL_STRING;
    szMessage = NULL_STRING;

    static int clients[MAXPLAYERS+1];
    CopyEqualArray(players, clients, playersNum);

    if(!umType) BfReadString(msg, SZ(szMessage));
    else PbReadString(msg, "text", SZ(szMessage));

    if(!((!umType) ? view_as<bool>(BfReadByte(msg)) : PbReadBool(msg, "chat")))
        return Plugin_Continue;
        
    if(!RebuildMessage(eMsg_SERVER, TEAM_SERVER, 0, szName, szMessage, SZ(szBuffer), "saytext"))
        return Plugin_Handled;

    // Call_MessageBuilt(eMsg_SERVER, TEAM_SERVER, szBuffer);

    ReplaceColors(SZ(szBuffer), false);

    Call_RebuildClients(eMsg_SERVER, TEAM_SERVER, clients, playersNum);

    StringMap uMessage = new StringMap();
    uMessage.SetValue("msg_id", msg_id);
    uMessage.SetString("text", szBuffer);
    uMessage.SetArray("clients", clients, playersNum);
    uMessage.SetValue("clients_num", playersNum);

    RequestFrame(SayText_Completed, uMessage);
    
    return Plugin_Handled;
}

public void SayText_Completed(StringMap data)
{
    UserMsg umid;
    data.GetValue("msg_id", umid);

    int numClients;
    data.GetValue("clients_num", numClients);

    int[] players = new int[numClients];
    data.GetArray("clients", players, numClients);

    char szMessage[MAX_LENGTH];
    data.GetString("text", szMessage, sizeof(szMessage));

    CopyEqualArray(players, players, numClients);

    // CloseHandle(data);
    delete data;
    
    Handle message = 
        StartMessageEx(umid, players, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

    if(message)
    {
        // Call_OnNewMessage();
        
        if(!umType)
        {
            BfWriteByte(message, TEAM_SERVER);
            BfWriteString(message, szMessage);
            BfWriteByte(message, true);
        }

        else
        {
            PbSetInt(message, "ent_idx", TEAM_SERVER);
            PbSetString(message, "text", szMessage);
            PbSetBool(message, "chat", true);
            PbSetBool(message, "textallchat", true);
        }
        
        EndMessage();
    }
}