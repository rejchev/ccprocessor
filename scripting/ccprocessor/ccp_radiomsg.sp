#define PARAMS_MAX 4
#define PARAMS_NAME 0

public Action UserMessage_RadioText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    static const int msgType = eMsg_RADIO;

    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    char buffer[4] = "p";
    char params[PARAMS_MAX][MESSAGE_LENGTH];
    int sender = 
        ReadRadioUsermessage(msg, params, sizeof(params), sizeof(params[]));
    int i, a;
    int clients[MAXPLAYERS+1];
    Action defMessage;

    CopyEqualArray(players, clients, playersNum);

    // #ENTNAME[#]Name
    strcopy(params[PARAMS_NAME], sizeof(params[]), params[PARAMS_NAME][(FindCharInString(params[PARAMS_NAME], ']') + 1)]);
    ReplaceColors(params[PARAMS_NAME], sizeof(params[]), true);

    a = FindDisplayMessage(params, sizeof(params));
    if(a == -1) {
        return Plugin_Handled;
    }

    if((defMessage = Call_OnDefMessage(params[a], TranslationPhraseExists(params[a]))) != Plugin_Changed) {
        return defMessage;
    }

    Call_RebuildClients(msgType, sender, clients, playersNum);

    // StringMap message = new StringMap();
    g_mMessage.SetValue("sender", sender);
    g_mMessage.SetValue("count", playersNum);
    g_mMessage.SetValue("message", a);
    g_mMessage.SetArray("clients", clients, playersNum);

    while(i < sizeof(params)) {
        buffer[1] = 48 + i;
        g_mMessage.SetString(buffer, params[i++], true);
    }

    return Plugin_Handled;
}

public void RadioText_Completed(UserMsg msgid, bool send)
{
    static const char msgName[] = "RadioText";
    static const int msgType = eMsg_RADIO;

    int sender;
    if(!send || !g_mMessage.GetValue("sender", sender))
        return;
    
    int i, playersNum, a;
    g_mMessage.GetValue("count", playersNum);
    g_mMessage.GetValue("message", a);

    int[] clients = new int[MAXPLAYERS+1];
    g_mMessage.GetArray("clients", clients, playersNum);

    char params[PARAMS_MAX][MESSAGE_LENGTH];
    char buffer[MAX_LENGTH] = "p";
    char message[MESSAGE_LENGTH];

    while(i < sizeof(params)) {
        buffer[1] = 48 + i;
        g_mMessage.GetString(buffer, params[i++], sizeof(params[]));
    }

    g_mMessage.Clear();

    // Not equal (just fix clients array)
    CopyEqualArray(clients, clients, playersNum);
    ChangeModeValue(clients, playersNum, "0");

    // optional int32 msg_dst = 1;
	// optional int32 client = 2;
	// optional string msg_name = 3;
	// repeated string params = 4;
    i = playersNum - 1;
    int team = GetClientTeam(a);
    bool alive = IsPlayerAlive(sender);

    Handle uMessage;
    int j;
    while(i >= 0) {
        // LogMessage("Send: %i, client: %i", i, clients[i]);
        FormatEx(message, sizeof(message), "%T", params[a], clients[i]);
        // LogMessage("Msg: %s", message);

        if(RebuildMessage(msgType, (sender << 3|team << 1|view_as<int>(alive)), clients[i], params[PARAMS_NAME], message, SZ(buffer), msgName)) {
            prepareDefMessge(PARAMS_MAX, clients[i], buffer, sizeof(buffer));
            ReplaceColors(SZ(buffer), false);

            uMessage = 
                StartMessageOne(msgName, clients[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

            if(uMessage) {
                j = 0;
                if(!umType) {
                    BfWriteByte(uMessage, 3);
                    BfWriteByte(uMessage, sender);
                    BfWriteString(uMessage, buffer);
                    while(j < PARAMS_MAX) {
                        BfWriteString(uMessage, params[j++]);
                    }
                    
                } else {
                    PbSetInt(uMessage, "msg_dst", 3);
                    PbSetInt(uMessage, "client", sender);
                    PbSetString(uMessage, "msg_name", buffer);
                    while(j < PARAMS_MAX)
                        PbAddString(uMessage, "params", params[j++]);
                }

                EndMessage();
            }
        }

        i--;
    }

    ChangeModeValue(clients, playersNum, mode_default_value);
}

int FindDisplayMessage(char[][] params, int count) {
    count--;

    while(count > PARAMS_NAME) {
        if(params[count][0] == '#') {
            return count;
        }

        count--;
    }

    return -1;
}

// extended textmsg :/
int ReadRadioUsermessage(Handle msg, char[][] params, int count, int size) {
    // params [0] - msg_name

    int
        sender = (!umType) ? BfReadByte(msg) : PbReadInt(msg, "client"), 
        i;

    if(!umType) {
        BfReadString(msg, params[0], size);  // msg_name
        while(BfGetNumBytesLeft(msg) > 1) {
            if(i == count) {
                break;
            }

            BfReadString(msg, params[i++], size);
        }
    } else {
        while(i < PbGetRepeatedFieldCount(msg, "params")) {
            if(i == count) {
                break;
            }

            PbReadString(msg, "params", params[i], size, i);
            // LogMessage("Param[%i]: %s", i, params[i]);

            i++;
        }
    }

    return sender;
}