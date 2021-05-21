#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 0

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.4",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

static const char indent_def[] = "ST";
static const char template[] = "#Game_Chat_Server";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("SayText"), UserMessage_SayText, true);

    return APLRes_Success;
}

public Action UserMessage_SayText(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {
    if(!msg
    || ((!umType) ? BfReadByte(msg) : PbReadInt(msg, "ent_idx")) != 0 
    || playersNum < 1
    || IsClientSourceTV(players[0])) {
        return Plugin_Continue;
    }

    StringMap g_mMessage = new StringMap();

    char szMessage[MESSAGE_LENGTH];
    if(!umType) BfReadString(msg, szMessage, sizeof(szMessage));
    else PbReadString(msg, "text", szMessage, sizeof(szMessage));

    g_mMessage.SetString("text", szMessage, true);

    if(!((!umType) ? view_as<bool>(BfReadByte(msg)) : PbReadBool(msg, "chat")))
        return Plugin_Continue;

    g_mMessage.SetValue("recipient", players[0]);

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
   
    RequestFrame(OnNextFrame, g_mMessage);
    return Plugin_Handled;
}

public void OnNextFrame(StringMap g_mMessage) {
    static const int sender;

    char szMessage[MESSAGE_LENGTH], szBuffer[MAX_LENGTH], name[NAME_LENGTH];
    g_mMessage.GetString("text", SZ(szMessage));

    int recipient;
    g_mMessage.GetValue("recipient", recipient);

    delete g_mMessage;

    if(!IsClientConnected(recipient)) {
        return;
    }

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int id;
    if((id = stock_NewMessage(arr, sender, recipient, template, szMessage, SZ(szIndent))) == -1)
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
    szBuffer = NULL_STRING;
    message = szMessage;

    if(message[0] == '#') {
        ccp_Translate(message, recipient);
        stock_RenderEngineCtx(arr, sender, recipient, MAX_PARAMS, SZ(message));
    }

    if(stock_RebuildMsg(arr, id, sender, recipient, szIndent, template, name, message, szBuffer) <= Proc_Change) {
        
        ccp_replaceColors(szBuffer, false);

        uMessage = StartMessageOne("SayText", recipient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        if(uMessage) {
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

    }

    ccp_ChangeMode(recipient); 
    stock_EndMsg(arr, id, sender, szIndent);
    
    delete arr;
}