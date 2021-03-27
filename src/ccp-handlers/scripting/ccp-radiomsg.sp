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
    version     = "1.0.3",
    url         = "discord.gg/ChTyPUG"
};

UserMessageType umType;

ArrayList g_aThread;

static const char indent_def[] = "RT";
stock const char template[] = "#Game_Chat_Radio"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();
    HookUserMessage(GetUserMessageId("RadioText"), UserMessage_Radio, true, AfterMessage);

    return APLRes_Success;
}

public void OnPluginStart() {
    g_aThread = new ArrayList(36, 0);
}

public Action UserMessage_Radio(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {
    if(((!umType) ? BfReadByte(msg) : PbReadInt(msg, "msg_dst")) != 3)
        return Plugin_Continue;

    StringMap mMessage;
    if(!(mMessage = ReadUserMessage(msg))) {
        return Plugin_Handled;
    }

    int a;
    mMessage.GetValue("display", a);
    
    int sender;
    mMessage.GetValue("client", sender);

    mMessage.SetValue("recipient", players[0]);

    char szBuffer[MESSAGE_LENGTH], szComp[MESSAGE_LENGTH];
    FormatEx(SZ(szComp), "params[%i]", a);
    mMessage.GetString(szComp, SZ(szBuffer));

    ArrayList arr = new ArrayList(MESSAGE_LENGTH, 0);
    any b = -1;
    if(stock_EngineMsgReq(arr, sender, sender, szBuffer) == Proc_Stop) {
        b = Plugin_Handled;
    } 

    delete arr;

    if(b != -1) {
        delete mMessage;
        return view_as<Action>(b);
    }
    
    // #ENTNAME[#]Name
    mMessage.GetString("params[0]", SZ(szBuffer));
    strcopy(SZ(szBuffer), szBuffer[(FindCharInString(szBuffer, ']') + 1)]);
    ccp_replaceColors(szBuffer, true);
    mMessage.SetString("params[0]", szBuffer, true);
    

    g_aThread.Push(mMessage);
    return Plugin_Handled;
}

public void AfterMessage(UserMsg msgid, bool send)
{
    if(!send || !g_aThread.Length) {
        return;
    }

    StringMap mMessage;
    mMessage = view_as<StringMap>(g_aThread.Get(0));
    g_aThread.Erase(0);

    if(!mMessage) {
        return;
    }

    int sender;
    mMessage.GetValue("client", sender);
    
    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def);

    int display;
    mMessage.GetValue("display", display);
    
    char    params[MAX_PARAMS][MESSAGE_LENGTH],
            szBuffer[MAX_LENGTH];

    for(int i; i < MAX_PARAMS; i++) {
        FormatEx(SZ(szBuffer), "params[%i]", i);
        mMessage.GetString(szBuffer, params[i], sizeof(params[]));
    }
    
    int recipient;
    mMessage.GetValue("recipient", recipient);
    
    delete mMessage;

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    int team = GetClientTeam(sender);
    bool alive = IsPlayerAlive(sender);

    int id;
    if((id = stock_NewMessage(arr, sender, recipient, template, params[display], SZ(szIndent))) == -1)
    {
        delete arr;
        return;
    }
    
    if(!szIndent[0]) {
        stock_EndMsg(arr, id, sender, szIndent);
        delete arr;
        return;
    }

    ccp_ChangeMode(recipient, "0");

    Processing next;
    Handle uMessage;
    char message[MESSAGE_LENGTH];
    
    szBuffer = NULL_STRING;
    message = params[display];
    int j = (sender << 3|team << 1|view_as<int>(alive));

    if(message[0] == '#') {
        if((next = stock_EngineMsgReq(arr, sender, recipient, message)) == Proc_Stop) {
            ccp_ChangeMode(recipient);
            stock_EndMsg(arr, id, sender, szIndent);
            delete arr;
            return;
        }

        next = (ccp_Translate(message, recipient)) ? Proc_Change : Proc_Continue;
    }
    
    // Attempting to render message text (Its a useless thing ... )
    stock_RenderEngineCtx(arr, sender, recipient, PARAM_NAME, SZ(message));

    // translation phrase is not exists
    if(next == Proc_Continue) {
        FormatEx(SZ(message), "{%i}", display+1);
    }

    if((next = stock_RebuildMsg(arr, id, j, recipient, szIndent, template, params[PARAM_NAME], message, szBuffer)) <= Proc_Change) {
        
        // Rendering the final result 
        stock_RenderEngineCtx(arr, sender, recipient, MAX_PARAMS, SZ(szBuffer));
        ccp_replaceColors(szBuffer, false);

        if((uMessage = StartMessageOne("RadioText", recipient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)) != null) {
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

    }


    ccp_ChangeMode(recipient);
    stock_EndMsg(arr, id, sender, szIndent);

    delete arr;
}

StringMap ReadUserMessage(Handle msg) {
    StringMap params = new StringMap();

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
    if((i = FindDisplayMessage(szParams, MAX_PARAMS)) == -1
    || StrContains(szParams[i], "Game_radio", false) != -1) {
        // Stop sending... 
        if(StrContains(szMsgName, "Game_radio", false) != -1) {
            delete params
            return params;
        }
        
        // {1} - name
        // {2} - location
        // {3} - msg
        // {4} - auto (optional)
        strcopy(szParams[(i = 2)], sizeof(szParams[]), szMsgName);
        params.SetString("params[2]", szParams[i], true);
    }

    params.SetValue("display", i, true);
    return params;
}

int FindDisplayMessage(char[][] params, int count) {
    for(int i = PARAM_NAME+1; i < count; i++) {
        if(params[i][0] == '#') {
            return i;
        }
    }

    return -1;
}