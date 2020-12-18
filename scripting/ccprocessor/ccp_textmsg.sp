#define MAX_PARAMS 5
#define DEFAULT_NAME "CONSOLE"

public Action UserMessage_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    static char params[MAX_PARAMS][MAX_LENGTH];
    ClearCharArray(params, MAX_PARAMS);

    static char szBuffer[MESSAGE_LENGTH];
    szBuffer = NULL_STRING;

    static Action defMessage;
    defMessage = Plugin_Continue;

    static int clients[MAXPLAYERS+1];
    CopyEqualArray(players, clients, playersNum);

    if(!umType) ReadMessageAsBf(view_as<BfRead>(msg), params, sizeof(params), sizeof(params[]));
    else ReadMessageAsPb(view_as<Protobuf>(msg), params, sizeof(params), sizeof(params[]));

    strcopy(szBuffer, sizeof(szBuffer), params[0]);

    if(szBuffer[0] == '#')
    {
        defMessage = Call_OnDefMessage(szBuffer, TranslationPhraseExists(szBuffer), IsTranslatedForLanguage(szBuffer, GetServerLanguage()));

        if(defMessage == Plugin_Changed)
            PrepareDefMessage(szBuffer, sizeof(szBuffer));
        
        else return defMessage;
    }

    if(!RebuildMessage(eMsg_SERVER, TEAM_SERVER, 0, DEFAULT_NAME, szBuffer, params[0], sizeof(params[]), "textmsg"))
        return Plugin_Handled;

    // Call_MessageBuilt(eMsg_SERVER, TEAM_SERVER, params[0]);

    ReplaceColors(params[0], sizeof(params[]), false);

    Call_RebuildClients(eMsg_SERVER, TEAM_SERVER, clients, playersNum);

    StringMap uMessage = new StringMap();
    uMessage.SetValue("msg_id", msg_id);
    
    for(int i; i < MAX_PARAMS; i++)
    {
        FormatEx(szBuffer, sizeof(szBuffer), "param[%i]", i);
        uMessage.SetString(szBuffer, params[i]);
    }

    uMessage.SetArray("clients", clients, playersNum);
    uMessage.SetValue("clients_num", playersNum);

    RequestFrame(TextMsg_Completed, uMessage);
    
    return Plugin_Handled;
}

public void TextMsg_Completed(StringMap data)
{
    UserMsg umid;
    data.GetValue("msg_id", umid);

    int numClients;
    data.GetValue("clients_num", numClients);

    int[] players = new int[numClients];
    data.GetArray("clients", players, numClients);

    char params[MAX_PARAMS][MAX_LENGTH];
    for(int i; i < MAX_PARAMS; i++)
    {
        FormatEx(params[i], sizeof(params[]), "param[%i]", i);
        if(!data.GetString(params[i], params[i], sizeof(params[])))
            params[i] = NULL_STRING;
    }

    CopyEqualArray(players, players, numClients);

    delete data;
    
    Handle message = StartMessageEx(umid, players, numClients, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

    if(message)
    {
        // Call_OnNewMessage();
        
        if(!umType)
        {
            BfWriteByte(message, 3);
            for(int i; i < MAX_PARAMS; i++)
                BfWriteString(message, params[i]);
        }
        else
        {
            PbSetInt(message, "msg_dst", 3);

            for(int i; i < MAX_PARAMS; i++)
                PbAddString(message, "params", params[i]);
        }

        EndMessage();
    }
}

void ReadMessageAsBf(BfRead message, char[][] params, int count, int size)
{
    int a;

    while(message.BytesLeft > 1)
    {
        if(a == count)
            break;

        message.ReadString(params[a++], size);
    }
}

void ReadMessageAsPb(Protobuf message, char[][] params, int count, int size)
{
    for(int i; i < message.GetRepeatedFieldCount("params"); i++)
        if(i < count)
            message.ReadString("params", params[i], size, i);
}

void PrepareDefMessage(char[] szMessage, int size)
{
    char szNum[8];

    Format(szMessage, size, "%T", szMessage, LANG_SERVER);

    for(int i = 1; i < MAX_PARAMS; i++)
    {
        FormatEx(szNum, sizeof(szNum), "{%i}", i);
        ReplaceString(szMessage, size, szNum, (i == 1) ? "%s1" : (i == 2) ? "%s2" : (i == 3) ? "%s3" : "%s4");
    }
}