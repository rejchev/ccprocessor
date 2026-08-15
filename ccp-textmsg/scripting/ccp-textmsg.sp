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
    version     = "1.0.6",
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

public Action UserMessage_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {
    
    if(!msg 
    || ((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3 
    || playersNum < 1
    || !IsClientInGame(players[0])
    || IsClientSourceTV(players[0])) {
        return Plugin_Continue;
    }
    
    StringMap g_mMessage;
    if(!(g_mMessage = ReadUserMessage(msg))) {
        return Plugin_Handled;
    }

    g_mMessage.SetValue("recipient", players[0]);

    char szMessage[MESSAGE_LENGTH];
    g_mMessage.GetString("params[0]", SZ(szMessage));

    if(szMessage[0] == '#') {
        ArrayList arr = new ArrayList(MESSAGE_LENGTH, 0);
        any a = -1;
        if(stock_EngineMsgReq(arr, 0, players[0], szMessage) == Proc_Stop) {
            a = Plugin_Handled;
        } 

        delete arr;
        
        if(a == -1 && !ccp_Translate(szMessage, players[0])) {
            a = Plugin_Continue
        }

        if(a != -1) {
            delete g_mMessage;
            return view_as<Action>(a);
        }
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

    int recipient;
    g_mMessage.GetValue("recipient", recipient);

    delete g_mMessage;

    if(!IsClientInGame(recipient))
        return;

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int id;
    if((id = stock_NewMessage(arr, sender, recipient, template, params[PARAM_MESSAGE], SZ(szIndent))) == -1)
    {
        delete arr;
        return;
    }

    if(!szIndent[0]) {
        stock_EndMsg(arr, id, sender, indent_def);
        delete arr;
        return;
    }

    ccp_ChangeMode(recipient, "0");

    Handle uMessage;
    char message[MESSAGE_LENGTH];

    message = params[PARAM_MESSAGE];
    if(message[0] == '#') {
        ccp_Translate(message, recipient);
        stock_RenderEngineCtx(arr, sender, recipient, MAX_PARAMS, SZ(message));
    }

    if(stock_RebuildMsg(arr, id, sender, recipient, szIndent, template, name, message, szBuffer) <= Proc_Change) {
        
        stock_RenderEngineCtx(arr, sender, recipient, MAX_PARAMS, SZ(szBuffer));
        ccp_replaceColors(szBuffer, false);

        uMessage = StartMessageOne("TextMsg", recipient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(uMessage) {
            int j = 1;
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

    }


    ccp_ChangeMode(recipient);
    
    stock_EndMsg(arr, id, sender, szIndent);
    delete arr;
}

StringMap ReadUserMessage(Handle msg) {

    StringMap map = new StringMap();

    int i;
    char szParams[MAX_PARAMS][MESSAGE_LENGTH], szBuffer[64];

    while(((!umType) ? BfGetNumBytesLeft(msg) > 1 : i < PbGetRepeatedFieldCount(msg, "params")) && i < MAX_PARAMS) {
        if(!umType) BfReadString(msg, szParams[i], sizeof(szParams[]));
        else PbReadString(msg, "params", szParams[i], sizeof(szParams[]), i);

        FormatEx(szBuffer, sizeof(szBuffer), "params[%i]", i);
        map.SetString(szBuffer, szParams[i]);

        i++;
    }

    return map;
}
