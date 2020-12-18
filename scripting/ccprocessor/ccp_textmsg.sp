#define MAX_PARAMS 5
// #define DEFAULT_NAME "CONSOLE"
#define PARAM_MESSAGE 0

public Action UserMessage_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    char params[MAX_PARAMS][MESSAGE_LENGTH];

    Action defMessage;

    int clients[MAXPLAYERS+1];

    CopyEqualArray(players, clients, playersNum);

    ReadMessage(msg, params, sizeof(params), sizeof(params[]));

    if(params[PARAM_MESSAGE][0] == '#')
    {
        if((defMessage = Call_OnDefMessage(params[PARAM_MESSAGE], TranslationPhraseExists(params[PARAM_MESSAGE]))) != Plugin_Changed) {
            return defMessage;
        }
    }

    Call_RebuildClients(eMsg_SERVER, TEAM_SERVER, clients, playersNum);

    StringMap uMessage = new StringMap();
    
    char iter[4] = "p";
    int i;

    while(i < MAX_PARAMS) {
        iter[1] = i+48;
        uMessage.SetString(iter, params[i++]);
    }

    uMessage.SetArray("clients", clients, playersNum);
    uMessage.SetValue("playersnum", playersNum);

    RequestFrame(TextMsg_Completed, uMessage);
    return Plugin_Handled;
}

public void TextMsg_Completed(StringMap data)
{
    static const char msgName[] = "TextMsg";

    char buffer[MAX_LENGTH] = "p";
    char message[MESSAGE_LENGTH];
    char name[4];
    char params[MAX_PARAMS][MESSAGE_LENGTH];

    const int msgType = eMsg_SERVER;
    int i;

    while(i < MAX_PARAMS) {
        buffer[1] = i + 48;
        data.GetString(buffer, params[i++], sizeof(params[]));
        // LogMessage("buffer: %s, params: %s", buffer, params[i-1]);
    }

    int playersNum;
    data.GetValue("playersnum", playersNum);

    int[] clients = new int[MAXPLAYERS+1];
    data.GetArray("clients", clients, playersNum);
    CopyEqualArray(clients, clients, playersNum);

    delete data;

    Handle uMessage;
    playersNum--;
    while(playersNum >= 0) {
        FormatEx(SZ(message), params[PARAM_MESSAGE]);

        if(message[0] == '#') {
            prepareDefMessge(clients[playersNum], message, sizeof(message));
        }       

        if(!RebuildMessage(msgType, 2, clients[playersNum], name, message, SZ(buffer), msgName))
            continue;

        ReplaceColors(SZ(buffer), false);

        uMessage = 
            StartMessageOne(msgName, clients[playersNum], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

        if(!uMessage)
            continue;
        
        i = 1;
        if(!umType)
        {
            BfWriteByte(uMessage, 3);
            BfWriteString(uMessage, buffer)
            while(i < MAX_PARAMS)
                BfWriteString(uMessage, params[i++]);
        }
        else
        {
            PbSetInt(uMessage, "msg_dst", 3);
            PbAddString(uMessage, "params", buffer);
            while(i < MAX_PARAMS)
                PbAddString(uMessage, "params", params[i++]);
        }
        
        EndMessage();

        playersNum--;
    }
}

// iam fuck this
void ReadMessage(Handle msg, char[][] params, int count, int size)
{
    int i;

    if(umType) {
        while(i < PbGetRepeatedFieldCount(msg, "params")) {
            if(i == count) {
                break;
            }

            PbReadString(msg, "params", params[i], size, i);
            i++;
        }
    } else {
        while(BfGetNumBytesLeft(msg) > 1)
        {
            if(i == count)
                break;
            
            BfReadString(msg, params[i++], size);
        }
    }
}

void prepareDefMessge(int recipient, char[] szMessage, int size)
{
    char szNum[8];
    Format(szMessage, size, "%T", szMessage, recipient);

    for(int i = 1; i < MAX_PARAMS; i++)
    {
        FormatEx(szNum, sizeof(szNum), "{%i}", i);
        ReplaceString(szMessage, size, szNum, (i == 1) ? "%s1" : (i == 2) ? "%s2" : (i == 3) ? "%s3" : "%s4");
    }
}