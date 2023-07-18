#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 4

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText2 handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.7",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

ArrayList g_aThread;

static const char indent_def[][] = {"STP", "STA", "CN"};
static const char templates[][] = {"#Game_Chat_Team", "#Game_Chat_Public", "#Game_Chat_CUsername"};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true, SayText2_Completed);

    return APLRes_Success;
}

public void OnPluginStart() {
    g_aThread = new ArrayList(64, 0);
}

public Action UserMessage_SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {

    if(!msg || playersNum < 1 || (IsClientSourceTV(players[0]) && playersNum == 1))
        return Plugin_Continue;

    StringMap mMap;
    if(!(mMap = ReadUserMessage(msg)))
        return Plugin_Handled;

    int sender;
    mMap.GetValue("ent_idx", sender);
    mMap.SetValue("recipients_size", playersNum);
    mMap.SetArray("recipients", players, playersNum, true);

    int chatType;
    mMap.GetValue("chatType", chatType);

    char szName[NAME_LENGTH];
    mMap.GetString("params[0]", szName, sizeof(szName));

    char szMessage[MESSAGE_LENGTH];
    mMap.GetString("params[1]", szMessage, sizeof(szMessage));
    
    ccp_replaceColors(szName, true);
    mMap.SetString("params[0]", szName, true);

    if(!ccp_SkipColors(indent_def[chatType], sender)) {
        ccp_replaceColors(szMessage, true);
        mMap.SetString("params[1]", szMessage, true);
    }
    
    g_aThread.Push(mMap);
    return Plugin_Handled;
}

public void SayText2_Completed(UserMsg msgid, bool send) {
    if(!send || !g_aThread.Length)
        return;

    StringMap mMessage;
    mMessage = view_as<StringMap>(g_aThread.Get(0));
    g_aThread.Erase(0);

    if(!mMessage)
        return;

    RequestFrame(OnNextFrame, mMessage);
}

public void OnNextFrame(StringMap mMessage) {

    int sender;
    mMessage.GetValue("ent_idx", sender);

    int recipients_size;
    mMessage.GetValue("recipients_size", recipients_size);

    int[] recipients = new int[recipients_size];
    mMessage.GetArray("recipients", recipients, recipients_size);
    
    char 
        params[MAX_PARAMS][MESSAGE_LENGTH], 
        szBuffer[MAX_LENGTH];

    for(int i; i < MAX_PARAMS; i++) {
        FormatEx(szBuffer, sizeof(szBuffer), "params[%i]", i);
        mMessage.GetString(szBuffer, params[i], sizeof(params[]));
    }

    int chatType;
    mMessage.GetValue("chatType", chatType);

    delete mMessage;

    int team;
    team = (sender) ? GetClientTeam(sender) : 1;

    bool alive;
    alive = (sender) ? IsPlayerAlive(sender) : false;

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def[chatType]);

    ArrayList data = new ArrayList(MAX_LENGTH, 0);
    for(int i = 0, id, j, s = (sender << 3|team << 1|view_as<int>(alive)); i < recipients_size; i++) {

        if(!IsClientInGame(recipients[i]))
            continue;
        
        if(IsFakeClient(recipients[i]) && !IsClientSourceTV(recipients[i]))
            continue;

        if((id = stock_NewMessage(
            data, sender, recipients[i], templates[chatType], params[1], SZ(szIndent))) == -1)
            continue;
        
        if(!szIndent[0]) {
            stock_EndMsg(data, id, sender, indent_def[chatType]);
            continue;
        }

        ccp_ChangeMode(recipients[i], "0");

        szBuffer = NULL_STRING;

        if(stock_RebuildMsg(
            data, id, s, recipients[i], szIndent, templates[chatType], 
            params[0], params[1], szBuffer) <= Proc_Change) {

            // Rendering the final result 
            stock_RenderEngineCtx(data, sender, recipients[i], MAX_PARAMS, SZ(szBuffer));

            ccp_replaceColors(szBuffer, false);

            Handle uMessage;
            if((uMessage = StartMessageOne("SayText2", recipients[i], USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)) != null) {
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
        }

        ccp_ChangeMode(recipients[i]); 
        stock_EndMsg(data, id, sender, szIndent);
    }

    delete data;
}

StringMap ReadUserMessage(Handle msg) {
    StringMap params = new StringMap();

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

    if(!umType && !szMsgName[0])
        BfReadString(msg, szMsgName, sizeof(szMsgName));

    params.SetValue("chatType", 
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

    return params;
}