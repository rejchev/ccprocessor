#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 5
#define PARAM_MESSAGE 0

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] TextMsg handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.0",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

static const char indent_def[] = "TM";
static const char template[] = "#Game_Chat_Server";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("TextMsg"), UserMessage_TextMsg, true);

    return APLRes_Success;
}

public Action UserMessage_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;
    
    StringMap g_mMessage = new StringMap();

    ReadUserMessage(msg, g_mMessage);

    int clients[MAXPLAYERS+1];
    ccp_UpdateRecipients(players, clients, playersNum);
    g_mMessage.SetArray("players", clients, playersNum);
    g_mMessage.SetValue("playersNum", playersNum);

    char szMessage[MESSAGE_LENGTH];
    g_mMessage.GetString("params[0]", SZ(szMessage));

    ArrayList arr = new ArrayList(MESSAGE_LENGTH, 0);
    if(szMessage[0] == '#' && (!stock_EngineMsgReq(arr, 0, 0, szMessage) || !ccp_Translate(szMessage, 0))) {
        delete g_mMessage;
        delete arr;
        return Plugin_Continue;
    }

    delete arr;

    RequestFrame(TextMsg_Completed, g_mMessage);    
    return Plugin_Handled;
}

public void TextMsg_Completed(StringMap g_mMessage)
{
    static const int sender;

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);
    
    char params[MAX_PARAMS][MESSAGE_LENGTH], szBuffer[MAX_LENGTH], name[4];
    for(int i; i < MAX_PARAMS; i++) {
        FormatEx(szBuffer, sizeof(szBuffer), "params[%i]", i);
        g_mMessage.GetString(szBuffer, params[i], sizeof(params[]));
    }

    int playersNum;
    g_mMessage.GetValue("playersNum", playersNum);

    int players[MAXPLAYERS+1];
    g_mMessage.GetArray("players", players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);

    delete g_mMessage;

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int id;
    if((id = stock_NewMessage(arr, sender, template, params[PARAM_MESSAGE], players, playersNum, SZ(szIndent))) == -1) {
        delete arr;
        return;
    }

    if(!szIndent[0]) {
        delete arr;
        return;
    }

    if(stock_RebuildClients(arr, id, sender, szIndent, params[PARAM_MESSAGE], players, playersNum) != Plugin_Continue) {
        delete arr;
        return;
    }

    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    char message[MESSAGE_LENGTH];
    for(int i, j; i < playersNum; i++) {
        message = params[PARAM_MESSAGE];
        if(message[0] == '#') {
            stock_HandleEngineMsg(arr, sender, players[i], MAX_PARAMS, SZ(message));
        }

        if(stock_RebuildMsg(arr, id, sender, players[i], szIndent, template, name, message, szBuffer) != Plugin_Continue) {
            continue;
        }

        stock_HandleEngineMsg(arr, sender, players[i], MAX_PARAMS, SZ(szBuffer));

        ccp_replaceColors(szBuffer, false);

        uMessage = StartMessageOne("TextMsg", players[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(!uMessage) {
            continue;
        }

        j = 1;
        if(!umType) {
            BfWriteByte(uMessage, 3);
            BfWriteString(uMessage, szBuffer);
            while(j < MAX_PARAMS) {
                BfWriteString(uMessage, params[j++]);
            }
        } else {
            PbSetInt(uMessage, "msg_dst", 3);
            PbAddString(uMessage, "params", szBuffer);
            while(j < MAX_PARAMS) {
                PbAddString(uMessage, "params", params[j++]);
            }
        }
        
        EndMessage();
    }

    ccp_ChangeMode(players, playersNum);
    
    stock_EndMsg(arr, id, sender, szIndent);
    delete arr;
}

void ReadUserMessage(Handle msg, StringMap params) {
    params.Clear();

    char szParams[MAX_PARAMS][MESSAGE_LENGTH], szBuffer[64];
    int i;

    while(((!umType) ? BfGetNumBytesLeft(msg) > 1 : i < PbGetRepeatedFieldCount(msg, "params")) && i < MAX_PARAMS) {
        if(!umType) BfReadString(msg, szParams[i], sizeof(szParams[]));
        else PbReadString(msg, "params", szParams[i], sizeof(szParams[]), i);

        FormatEx(szBuffer, sizeof(szBuffer), "params[%i]", i);
        params.SetString(szBuffer, szParams[i]);

        i++;
    }
}
