#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 4

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText2 handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.0",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

StringMap g_mMessage;

static const char indent[] = "ST2";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true, SayText2_Completed);

    return APLRes_Success;
}

public void OnPluginStart() {
    g_mMessage = new StringMap();
}

public Action UserMessage_SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
    ReadUserMessage(msg, g_mMessage);

    int clients[MAXPLAYERS+1];
    ccp_UpdateRecipients(players, clients, playersNum);
    g_mMessage.SetArray("players", clients, playersNum);
    g_mMessage.SetValue("playersNum", playersNum);

    int sender;
    g_mMessage.GetValue("ent_idx", sender);

    char szName[NAME_LENGTH];
    g_mMessage.GetString("params[0]", szName, sizeof(szName));

    char szMessage[MESSAGE_LENGTH];
    g_mMessage.GetString("params[1]", szMessage, sizeof(szMessage));
    
    ccp_replaceColors(szName, true);
    g_mMessage.SetString("params[0]", szName, true);

    if(!ccp_SkipColors(indent, sender)) {
        ccp_replaceColors(szMessage, true);
        g_mMessage.SetString("params[1]", szMessage, true);
    }
    
    return Plugin_Handled;
}

public void SayText2_Completed(UserMsg msgid, bool send)
{
    int sender;
    if(!send || !g_mMessage.GetValue("ent_idx", sender)) {
        return;
    }
    
    char szMsgName[MESSAGE_LENGTH], params[MAX_PARAMS][MESSAGE_LENGTH], szBuffer[MAX_LENGTH];
    for(int i; i < MAX_PARAMS; i++) {
        FormatEx(szMsgName, sizeof(szMsgName), "params[%i]", i);
        g_mMessage.GetString(szMsgName, params[i++], sizeof(params[]));
    }

    g_mMessage.GetString("msg_name", szMsgName, sizeof(szMsgName));

    int playersNum;
    g_mMessage.GetValue("playersNum", playersNum);

    int players[MAXPLAYERS+1];
    g_mMessage.GetArray("players", players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);

    int team;
    team = GetClientTeam(sender);

    bool alive;
    alive = (sender) ? IsPlayerAlive(sender) : false;

    g_mMessage.Clear();

    int id;
    if((id = ccp_StartNewMessage(indent, sender, szMsgName, players, playersNum)) == -1) {
        return;
    }

    ccp_RebuildClients(id, indent, sender, szMsgName, players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    for(int i, j; i < playersNum; i++) {
        j = (sender << 3|team << 1|view_as<int>(alive));

        if(!ccp_RebuildMessage(id, indent, j, players[i], szMsgName, params[0], params[1], szBuffer, sizeof(szBuffer))) {
            continue;
        }

        ccp_PrepareMessage(id, indent, sender, players[i], MAX_PARAMS, szBuffer);
        ccp_replaceColors(szBuffer, false);

        uMessage = StartMessageOne("SayText2", players[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(!uMessage) {
            continue;
        }

        j = 0;
        if(!umType) {
            BfWriteByte(uMessage, sender);
            BfWriteByte(uMessage, true);
            BfWriteString(uMessage, szBuffer);
            while(j < MAX_PARAMS) {
                BfWriteString(uMessage, params[j++]);
            }
        } else {
            PbSetInt(uMessage, "ent_idx", sender);
            PbSetBool(uMessage, "chat", true);
            PbSetString(uMessage, "msg_name", szBuffer);
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

    int sender = (!umType) 
                    ? BfReadByte(msg) 
                    : PbReadInt(msg, "ent_idx");
    params.SetValue("ent_idx", sender);
    
    // bool IsChat = view_as<bool>();
    params.SetValue(
        "chat", 
        (!umType) ? BfReadByte(msg) : PbReadInt(msg, "chat"), 
        true
    );
    
    char szMsgName[MESSAGE_LENGTH];
    if(!umType) {
        BfReadString(msg, szMsgName, sizeof(szMsgName));
    } else {
        PbReadString(msg, "msg_name", szMsgName, sizeof(szMsgName));
    }

    params.SetString("msg_name", szMsgName, true);

    char szParams[MAX_PARAMS][MESSAGE_LENGTH];
    int i;

    while(((!umType) ? BfGetNumBytesLeft(msg) > 1 : i < PbGetRepeatedFieldCount(msg, "params")) && i < MAX_PARAMS) {
        if(!umType) BfReadString(msg, szParams[i++], sizeof(szParams[]));
        else PbReadString(msg, "params", szParams[i], sizeof(szParams[]), i++);

        FormatEx(szMsgName, sizeof(szMsgName), "params[%i]", i);
        params.SetString(szMsgName, szParams[i]);
    }
}