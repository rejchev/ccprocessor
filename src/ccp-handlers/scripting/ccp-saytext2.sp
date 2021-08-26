#pragma newdecls required

#include <ccprocessor>

#define MAX_PARAMS 4

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
    name        = "[CCP] SayText2 handler",
    author      = "nyood",
    description = "...",
    version     = "1.0.5",
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


/*
    A little story about SayText2.

    It all started when I was bored. The idea flew into my head to test two technologies: protobuf & bitbuffer.
    The thought disappointed me ...

    Meet this callback. It has parameters, but it does not guarantee their professional suitability, like Valve.

    Let's go over:
    @UserMsg msg_id - message id, everything is ok here.
    @Handle msg - this thing can be null.
    @const int [] players is a crutch, just accept
    @int playersNum - may be null, note that @msg may not be null
    @... - not interested.

    Now let's move on to CS: G0. 
    Let's start with the main thing. 
    @Handle msg can be zero, while @playersNum is not, and vice versa.
    By the way of broadcasting, messages can be sent as a chain of independent ones, or in one big one. 
    This means that the length of @const int [] players can be either 1 or MAXPLAYERS + 1, respectively. 
    It is possible that the array is completely empty. 
    Keep in mind that the order of the message parameters can change randomly, 
    it gets annoying if it's bitbuffer: /

    Let's move on to bitbuffer. 
    Everything is simple here, if you are a sick bastard, then work with this for health. 

    Oh, and lastly. 
    Don't touch SourceTV unless you want to catch recursion ... recursion ... recursion ... recursion ... 

*/
public Action UserMessage_SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init) {

    if(!msg || playersNum < 1 || IsClientSourceTV(players[0])) {
        return Plugin_Continue;
    }

    StringMap mMap;
    if(!(mMap = ReadUserMessage(msg))) {
        return Plugin_Handled;
    }

    int sender;
    mMap.GetValue("ent_idx", sender);

    mMap.SetValue("recipient", players[0]);

    int chatType;
    mMap.GetValue("chatType", chatType);
    if(chatType == 2) {
        delete mMap;
        return Plugin_Continue;
    }

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
    mMessage.GetValue("ent_idx", sender);

    int recipient;
    mMessage.GetValue("recipient", recipient);
    
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

    if(!IsClientConnected(recipient)) {
        return;
    }

    int team;
    team = (sender) ? GetClientTeam(sender) : 1;

    bool alive;
    alive = (sender) ? IsPlayerAlive(sender) : false;

    ArrayList arr = new ArrayList(MAX_LENGTH, 0);

    char szIndent[NAME_LENGTH];
    strcopy(SZ(szIndent), indent_def[chatType]);

    int id;
    if((id = stock_NewMessage(arr, sender, recipient, templates[chatType], params[1], SZ(szIndent))) == -1)
    {
        delete arr;
        return;
    }

    if(!szIndent[0]) {
        stock_EndMsg(arr, id, sender, indent_def[chatType]);
        delete arr;
        return;
    }

    ccp_ChangeMode(recipient, "0");

    szBuffer = NULL_STRING;

    int j = (sender << 3|team << 1|view_as<int>(alive));

    if(stock_RebuildMsg(arr, id, j, recipient, szIndent, templates[chatType], params[0], params[1], szBuffer) <= Proc_Change) {
        // Rendering the final result 
        stock_RenderEngineCtx(arr, sender, recipient, MAX_PARAMS, SZ(szBuffer));
        ccp_replaceColors(szBuffer, false);

        Handle uMessage;
        if((uMessage = StartMessageOne("SayText2", recipient, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS)) != null) {
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

    ccp_ChangeMode(recipient); 
    stock_EndMsg(arr, id, sender, szIndent);

    delete arr;
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

    // params.SetString("msg_name", szMsgName, true);
    params.SetValue("chatType", 
        (StrContains(szMsgName, "_Name_Change", false) != -1) 
            ? 2
            : (StrContains(szMsgName, "_All", false) != -1) 
                ? 1 
                : 0, 
        true
    );

    // wahahha, i skip this shit :/
    // maybe i'll get it back later...
    // if(StrContains(szMsgName, "_Name_Change", false) != -1) {
    //     delete params;
    //     return params;
    // }

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