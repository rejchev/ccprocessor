#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 0

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.1",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;
StringMap g_mMessage;

static const char indent_def[] = "ST";
static const char template[] = "#Game_Chat_Server";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("SayText"), UserMessage_SayText, true, AfterMessage);

    return APLRes_Success;
}

public void OnPluginStart() {
    g_mMessage = new StringMap();
}

public Action UserMessage_SayText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "ent_idx")) != 0)
        return Plugin_Continue;

    char szMessage[MESSAGE_LENGTH];
    if(!umType) BfReadString(msg, szMessage, sizeof(szMessage));
    else PbReadString(msg, "text", szMessage, sizeof(szMessage));

    g_mMessage.SetString("text", szMessage, true);

    if(!((!umType) ? view_as<bool>(BfReadByte(msg)) : PbReadBool(msg, "chat")))
        return Plugin_Continue;

    int clients[MAXPLAYERS+1];
    ccp_UpdateRecipients(players, clients, playersNum);
    g_mMessage.SetArray("players", clients, playersNum, true);
    g_mMessage.SetValue("playersNum", playersNum, true);

    ArrayList arr = new ArrayList(MESSAGE_LENGTH, 0);
    if(szMessage[0] == '#' && (!stock_EngineMsgReq(arr, 0, 0, szMessage) || !ccp_Translate(szMessage, 0))) {
        g_mMessage.Clear();
        delete arr;
        return Plugin_Continue;
    }

    delete arr;
   
    return Plugin_Handled;
}

public void AfterMessage(UserMsg msg_id, bool bSend)
{
    if(!bSend) {
        return;
    }

    static const int sender;

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);
    
    char szMessage[MESSAGE_LENGTH], szBuffer[MAX_LENGTH], name[NAME_LENGTH];
    g_mMessage.GetString("text", SZ(szMessage));

    int playersNum;
    g_mMessage.GetValue("playersNum", playersNum);

    int players[MAXPLAYERS+1];
    g_mMessage.GetArray("players", players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum); 

    g_mMessage.Clear();

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int id;
    if((id = stock_NewMessage(arr, sender, template, szMessage, players, playersNum, SZ(szIndent))) == -1
    || !szIndent[0]
    || stock_RebuildClients(arr, id, sender, szIndent, szMessage, players, playersNum) != Plugin_Continue) {
        stock_EndMsg(arr, id, sender, indent_def);
        delete arr;
        return;
    }

    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    char message[MESSAGE_LENGTH];
    for(int i; i < playersNum; i++) {
        szBuffer = NULL_STRING;
        message = szMessage;

        if(message[0] == '#') {
            stock_HandleEngineMsg(arr, sender, players[i], MAX_PARAMS, SZ(message));
        }

        if(stock_RebuildMsg(arr, id, sender, players[i], szIndent, template, name, message, szBuffer) != Plugin_Continue) {
            continue;
        }

        ccp_replaceColors(szBuffer, false);

        uMessage = StartMessageOne("SayText", players[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(!uMessage) {
            continue;
        }

        if(!umType) {
            BfWriteByte(uMessage, sender);
            BfWriteString(uMessage, szBuffer);
            BfWriteByte(uMessage, 1);
        } else {
            PbSetInt(uMessage, "ent_idx", sender);
            PbSetString(uMessage, "text", szBuffer);
            PbSetBool(uMessage, "chat", true);
            PbSetBool(uMessage, "textallchat", true);
        }
        
        EndMessage();
    }

    ccp_ChangeMode(players, playersNum); 

    stock_EndMsg(arr, id, sender, szIndent);
    delete arr;
}