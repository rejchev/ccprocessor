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

    delete data;

    Call_OnNewMessage(msgType, 0, params[PARAM_MESSAGE], clients, playersNum);
    Call_RebuildClients(eMsg_SERVER, TEAM_SERVER, clients, playersNum);

    CopyEqualArray(clients, clients, playersNum);
    
    Handle uMessage;
    playersNum--;
    while(playersNum >= 0) {
        FormatEx(SZ(message), params[PARAM_MESSAGE]);

        if(message[0] == '#') {
            prepareDefMessge(MAX_PARAMS, clients[playersNum], message, sizeof(message));
        }       

        if(RebuildMessage(msgType, 2, clients[playersNum], name, message, SZ(buffer), msgName)) {
            ReplaceColors(SZ(buffer), false);

            uMessage = 
                StartMessageOne(msgName, clients[playersNum], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

            if(uMessage) {
                i = 1;
                if(!umType) {
                    BfWriteByte(uMessage, 3);
                    BfWriteString(uMessage, buffer)
                    while(i < MAX_PARAMS)
                        BfWriteString(uMessage, params[i++]);
                } else {
                    PbSetInt(uMessage, "msg_dst", 3);
                    PbAddString(uMessage, "params", buffer);
                    while(i < MAX_PARAMS)
                        PbAddString(uMessage, "params", params[i++]);
                }
                
                EndMessage();
            }
        }
        
        playersNum--;
    }
}

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

