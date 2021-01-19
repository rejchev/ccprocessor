
/*
    This is a personal update for `level-ranks` users, which uses `SayText` for messages from the plugin.
    The hook allows you to build a message according to the internal patterns of the core.
*/

#define MAX_PARAMS_SAYTXT 0

public Action UserMessage_SayText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "ent_idx")) != 0)
        return Plugin_Continue;

    char params[MESSAGE_LENGTH];
    Action defMessage;
    int clients[MAXPLAYERS+1];

    CopyEqualArray(players, clients, playersNum);

    if(!umType) BfReadString(msg, SZ(params));
    else PbReadString(msg, "text", SZ(params));

    if(!((!umType) ? view_as<bool>(BfReadByte(msg)) : PbReadBool(msg, "chat")))
        return Plugin_Continue;
        
    if(params[0] == '#')
    {
        if((defMessage = Call_OnDefMessage(params, TranslationPhraseExists(params))) != Plugin_Changed) {
            return defMessage;
        }
    }

    StringMap uMessage = new StringMap();
    // uMessage.SetValue("msg_id", msg_id);
    uMessage.SetString("text", params);
    uMessage.SetArray("clients", clients, playersNum);
    uMessage.SetValue("playersnum", playersNum);

    RequestFrame(SayText_Completed, uMessage);
    return Plugin_Handled;
}

public void SayText_Completed(StringMap data)
{
    static const char msgName[] = "SayText";
    static const int msgType = eMsg_SERVER;
    static const int sender;

    int playersNum;
    data.GetValue("playersnum", playersNum);

    int[] clients = new int[playersNum];
    data.GetArray("clients", clients, playersNum);

    char params[MESSAGE_LENGTH];
    data.GetString("text", SZ(params));

    delete data;

    Call_OnNewMessage(msgType, sender, params, clients, playersNum);
    Call_RebuildClients(msgType, sender, clients, playersNum);

    CopyEqualArray(clients, clients, playersNum);
    
    char buffer[MAX_LENGTH], message[MESSAGE_LENGTH];

    Handle uMessage;
    for(int i; i < playersNum; i++) {
        message = params;

        if(message[0] == '#') {
            prepareDefMessge(MAX_PARAMS_SAYTXT, clients[i], SZ(message));
        }

        if(!RebuildMessage(msgType, sender, clients[i], NULL_STRING, message, SZ(buffer), msgName)) {
            continue;
        }

        ReplaceColors(SZ(buffer), false);

        uMessage = StartMessageOne(msgName, clients[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(!uMessage) {
            continue;
        }

        if(!umType)
        {
            BfWriteByte(uMessage, sender);
            BfWriteString(uMessage, buffer);
            BfWriteByte(uMessage, true);
        }

        else
        {
            PbSetInt(uMessage, "ent_idx", sender);
            PbSetString(uMessage, "text", buffer);
            PbSetBool(uMessage, "chat", true);
            PbSetBool(uMessage, "textallchat", true);
        }
        
        EndMessage();
    }
}