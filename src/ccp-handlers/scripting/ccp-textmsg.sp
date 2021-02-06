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

static const char indent[] = "TM";
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

    if(szMessage[0] == '#' && !ccp_EngineMsgRequest(indent, 0, szMessage)) {
        delete g_mMessage;
        return Plugin_Continue;
    }

    RequestFrame(TextMsg_Completed, g_mMessage);    
    return Plugin_Handled;
}

public void TextMsg_Completed(StringMap g_mMessage)
{
    static const int sender;
    
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

    int id;
    if((id = ccp_StartNewMessage(indent, sender, template, players, playersNum)) == -1) {
        return;
    }

    ccp_RebuildClients(id, indent, sender, template, players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    char message[MESSAGE_LENGTH];
    for(int i, j; i < playersNum; i++) {
        message = params[PARAM_MESSAGE];
        if(message[0] == '#') {
            ccp_PrepareMessage(indent, sender, players[i], MAX_PARAMS, message);
        }

        if(!ccp_RebuildMessage(id, indent, sender, players[i], template, name, message, szBuffer, sizeof(szBuffer))) {
            continue;
        }

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
    ccp_EndMessage(id, indent, sender);
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
