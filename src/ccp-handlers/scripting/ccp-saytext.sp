#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 0

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.0",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;
StringMap g_mMessage;

static const char indent[] = "ST";
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

    if(szMessage[0] == '#' && !ccp_EngineMsgRequest(indent, 0, szMessage)) {
        g_mMessage.Clear();
        return Plugin_Continue;
    }
   
    return Plugin_Handled;
}

public void AfterMessage(UserMsg msg_id, bool bSend)
{
    if(!bSend) {
        return;
    }

    static const int sender;
    
    char szMessage[MESSAGE_LENGTH], szBuffer[MAX_LENGTH], name[4];
    g_mMessage.GetString("text", SZ(szMessage));

    int playersNum;
    g_mMessage.GetValue("playersNum", playersNum);

    int players[MAXPLAYERS+1];
    g_mMessage.GetArray("players", players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);

    g_mMessage.Clear();

    int id;
    if((id = ccp_StartNewMessage(indent, sender, template, szMessage, players, playersNum)) == -1) {
        return;
    }

    ccp_RebuildClients(id, indent, sender, template, players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    char prepare[MESSAGE_LENGTH];
    for(int i; i < playersNum; i++) {
        prepare = szMessage;
        if(prepare[0] == '#') {
            ccp_PrepareMessage(indent, sender, players[i], MAX_PARAMS, prepare);
        }

        if(!ccp_RebuildMessage(id, indent, sender, players[i], template, name, prepare, SZ(szBuffer))) {
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
    ccp_EndMessage(id, indent, sender);
}