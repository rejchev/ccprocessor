#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 4
#define PARAM_NAME 0

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] RadioText handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.1",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

StringMap g_mMessage;

static const char indent_def[] = "RT";
stock const char template[] = "#Game_Chat_Radio"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("RadioText"), UserMessage_Radio, true, AfterMessage);

    return APLRes_Success;
}

public void OnPluginStart() {
    g_mMessage = new StringMap();
}

public Action UserMessage_Radio(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    if(!ReadUserMessage(msg, g_mMessage)) {
        return Plugin_Handled;
    }

    int a;
    g_mMessage.GetValue("display", a);
    
    int sender;
    g_mMessage.GetValue("client", sender);

    char szBuffer[MESSAGE_LENGTH], szComp[MESSAGE_LENGTH];
    FormatEx(SZ(szComp), "params[%i]", a);
    g_mMessage.GetString(szComp, SZ(szBuffer));

    ArrayList arr = new ArrayList(MESSAGE_LENGTH, 0);
    any b = -1;
    if(!stock_EngineMsgReq(arr, sender, sender, szBuffer)) {
        b = Plugin_Handled;
    } 

    delete arr;
    
    if(b == -1 && !ccp_Translate(szBuffer, 0)) {
        b = Plugin_Continue
    }

    if(b != -1) {
        g_mMessage.Clear();
        return view_as<Action>(b);
    }

    int clients[MAXPLAYERS+1];
    ccp_UpdateRecipients(players, clients, playersNum);
    g_mMessage.SetArray("players", clients, playersNum, true);
    g_mMessage.SetValue("playersNum", playersNum, true);

    // #ENTNAME[#]Name
    g_mMessage.GetString("params[0]", SZ(szBuffer));
    strcopy(SZ(szBuffer), szBuffer[(FindCharInString(szBuffer, ']') + 1)]);
    ccp_replaceColors(szBuffer, true);
    g_mMessage.SetString("params[0]", szBuffer, true);
    
    return Plugin_Handled;
}

public void AfterMessage(UserMsg msgid, bool send)
{
    int sender;
    if(!send || !g_mMessage.GetValue("client", sender)) {
        return;
    }
    
    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int display;
    g_mMessage.GetValue("display", display);
    
    char    params[MAX_PARAMS][MESSAGE_LENGTH],
            szBuffer[MAX_LENGTH];

    for(int i; i < MAX_PARAMS; i++) {
        FormatEx(SZ(szBuffer), "params[%i]", i);
        g_mMessage.GetString(szBuffer, params[i], sizeof(params[]));
    }
    
    int playersNum;
    g_mMessage.GetValue("playersNum", playersNum);

    int players[MAXPLAYERS+1];
    g_mMessage.GetArray("players", players, playersNum);
    ccp_UpdateRecipients(players, players, playersNum);
    
    g_mMessage.Clear();

    int team = GetClientTeam(sender);
    bool alive = IsPlayerAlive(sender);

    int id;
    if((id = stock_NewMessage(arr, sender, template, params[display], players, playersNum, SZ(szIndent))) == -1
    || !szIndent[0]
    || stock_RebuildClients(arr, id, sender, szIndent, params[display], players, playersNum) != Plugin_Continue) {
        stock_EndMsg(arr, id, sender, indent_def);
        delete arr;
        return;
    }

    ccp_UpdateRecipients(players, players, playersNum);
    ccp_ChangeMode(players, playersNum, "0");

    Action next;
    Handle uMessage;
    char message[MESSAGE_LENGTH];
    for(int i, j; i < playersNum; i++) {
        szBuffer = NULL_STRING;
        message = params[display];
        j = (sender << 3|team << 1|view_as<int>(alive));

        if((next = stock_HandleEngineMsg(arr, sender, players[i], PARAM_NAME, SZ(message))) == Plugin_Stop) {
            continue;
        }

        // translation phrase is not exists
        if(next == Plugin_Handled) {
            FormatEx(SZ(message), "{%i}", display+1);
        }

        if((next = stock_RebuildMsg(arr, id, j, players[i], szIndent, template, params[PARAM_NAME], message, szBuffer)) != Plugin_Continue) {
            continue;
        }

        stock_HandleEngineMsg(arr, sender, players[i], MAX_PARAMS, SZ(szBuffer));

        ccp_replaceColors(szBuffer, false);

        if(!(uMessage = StartMessageOne("RadioText", players[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS))) {
            continue;
        }

        j = 0;
        if(!umType) {
            BfWriteByte(uMessage, 3);
            BfWriteByte(uMessage, sender);
            BfWriteString(uMessage, szBuffer);
            while(j < MAX_PARAMS) {
                BfWriteString(uMessage, params[j++]);
            }
            
        } else {
            PbSetInt(uMessage, "msg_dst", 3);
            PbSetInt(uMessage, "client", sender);
            PbSetString(uMessage, "msg_name", szBuffer);
            while(j < MAX_PARAMS)
                PbAddString(uMessage, "params", params[j++]);
        }
        
        EndMessage();
    }

    ccp_ChangeMode(players, playersNum);
    stock_EndMsg(arr, id, sender, szIndent);

    delete arr;
}

bool ReadUserMessage(Handle msg, StringMap params) {
    params.Clear();

    int sender = (!umType) 
                    ? BfReadByte(msg) 
                    : PbReadInt(msg, "client");
    params.SetValue("client", sender, true);
    
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
        if(!umType) BfReadString(msg, szParams[i], sizeof(szParams[]));
        else PbReadString(msg, "params", szParams[i], sizeof(szParams[]), i);

        FormatEx(szMsgName, sizeof(szMsgName), "params[%i]", i);
        params.SetString(szMsgName, szParams[i]);

        i++;
    }

    params.GetString("msg_name", SZ(szMsgName));
    if((i = FindDisplayMessage(szParams, MAX_PARAMS, sizeof(szParams[]))) == -1
    || StrContains(szParams[i], "Game_radio", false) != -1) {
        // Stop sending... 
        if(StrContains(szMsgName, "Game_radio", false) != -1) {
            params.Clear();
            return false;
        }
        
        // {1} - name
        // {2} - location
        // {3} - msg
        // {4} - auto (optional)
        strcopy(szParams[(i = 2)], sizeof(szParams[]), szMsgName);
        params.SetString("params[2]", szParams[i], true);
    }

    params.SetValue("display", i, true);
    return true;
}

int FindDisplayMessage(char[][] params, int count, int size = 0) {
    for(int i = PARAM_NAME+1; i < count; i++) {
        if(params[i][0] == '#') {
            return i;
        }
    }

    return -1;
}