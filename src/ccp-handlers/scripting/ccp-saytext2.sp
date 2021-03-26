#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 4

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText2 handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.2",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

StringMap g_mMessage;

static const char indent_def[][] = {"STP", "STA", "CN"};
static const char templates[][] = {"#Game_Chat_Team", "#Game_Chat_Public", "#Game_Chat_CUsername"};

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

    int chatType;
    g_mMessage.GetValue("chatType", chatType);

    char szName[NAME_LENGTH];
    g_mMessage.GetString("params[0]", szName, sizeof(szName));

    char szMessage[MESSAGE_LENGTH];
    g_mMessage.GetString("params[1]", szMessage, sizeof(szMessage));
    
    ccp_replaceColors(szName, true);
    g_mMessage.SetString("params[0]", szName, true);

    if(!ccp_SkipColors(indent_def[chatType], sender)) {
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
        g_mMessage.GetString(szMsgName, params[i], sizeof(params[]));
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

    int chatType;
    g_mMessage.GetValue("chatType", chatType);

    g_mMessage.Clear();

    if(playersNum < 1) {
        return;
    }

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def[chatType]);

    int id;
    if((id = stock_NewMessage(arr, sender, templates[chatType], params[1], players, playersNum, SZ(szIndent))) == -1)
    {
        delete arr;
        return;
    }

    if(!szIndent[0]
    || stock_RebuildClients(arr, id, sender, szIndent, params[1], players, playersNum) == Proc_Reject) {
        stock_EndMsg(arr, id, sender, indent_def[chatType]);
        delete arr;
        return;
    }

    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Handle uMessage;
    char message[MESSAGE_LENGTH], name[MESSAGE_LENGTH];
    for(int i, j; i < playersNum; i++) {
        szBuffer = NULL_STRING;
        name = params[0];
        message = params[1];

        j = (sender << 3|team << 1|view_as<int>(alive));

        if(stock_RebuildMsg(arr, id, j, players[i], szIndent, templates[chatType], name, message, szBuffer) > Proc_Change) {
            continue;
        }

        // Rendering the final result 
        stock_RenderEngineCtx(arr, sender, players[i], MAX_PARAMS, SZ(szBuffer));
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
    stock_EndMsg(arr, id, sender, szIndent);

    delete arr;
}

void ReadUserMessage(Handle msg, StringMap params) {
    params.Clear();

    int sender = (!umType) 
                    ? BfReadByte(msg) 
                    : PbReadInt(msg, "ent_idx");
    params.SetValue("ent_idx", sender);

    char szMsgName[MESSAGE_LENGTH];
    if(!umType) {
        BfReadString(msg, szMsgName, sizeof(szMsgName));
    } else {
        PbReadString(msg, "msg_name", szMsgName, sizeof(szMsgName));
    }

    params.SetString("msg_name", szMsgName, true);
    g_mMessage.SetValue("chatType", 
        (StrContains(szMsgName, "_Name_Change", false) != -1) 
            ? 2
            : (StrContains(szMsgName, "_All", false) != -1) 
                ? 1 
                : 0, 
        true
    );

    char szParams[MAX_PARAMS][MESSAGE_LENGTH];
    int i;

    while(((!umType) ? BfGetNumBytesLeft(msg) > 1 : i < PbGetRepeatedFieldCount(msg, "params")) && i < MAX_PARAMS) {
        if(!umType) BfReadString(msg, szParams[i], sizeof(szParams[]));
        else PbReadString(msg, "params", szParams[i], sizeof(szParams[]), i);

        FormatEx(szMsgName, sizeof(szMsgName), "params[%i]", i);
        params.SetString(szMsgName, szParams[i], true);

        i++;
    }
}