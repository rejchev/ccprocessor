#if defined _ccprocessor_included
 #endinput
#endif
#define _ccprocessor_included

#define STATUS_LENGTH       16
#define TEAM_LENGTH         64
#define PREFIX_LENGTH       64
#define NAME_LENGTH         128
#define MESSAGE_LENGTH      256
#define MAX_LENGTH          512


/* 
API key:
    The value changes if the API has been changed. 
    This is a measure against users who do not follow the changes and do not understand what is happening.

    ATTENTION: Do not change it yourself if you are not ready for the consequences!
*/

#define API_KEY             75091137

#if !defined CORE
    #define API_OOD         "The plugin module uses an outdated API. You must update it."
#endif

// Message template parts
enum
{
    BIND_PROTOTYPE = 0,

    BIND_STATUS_CO,
    BIND_STATUS,

    BIND_TEAM_CO,
    BIND_TEAM,

    BIND_PREFIX_CO,
    BIND_PREFIX,

    BIND_NAME_CO,
    BIND_NAME,

    BIND_MSG_CO,
    BIND_MSG,

    BIND_MAX
};

stock const char szBinds[BIND_MAX][] = 
{
    "{PROTOTYPE}"   ,
    
    "{STATUSCO}"    ,   "{STATUS}"  , 
    "{TEAMCO}"      ,   "{TEAM}"    , 
    "{PREFIXCO}"    ,   "{PREFIX}"  ,
    "{NAMECO}"      ,   "{NAME}"    , 
    "{MSGCO}"       ,   "{MSG}"
};

/*
 *  Skip colors in an unprepared message
 *
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  
 *  @return             true - skipping
 *                      false - otherwise
*/
forward bool cc_proc_SkipColors(const char[] indent, int sender);

/*
 *  Call when new message arrives /\
 *  
 *  @param sender       Sender index
 *  @param temp_key     Template Key
 *  @param msg          Message
 *  @param indent       Message Indent
 *  @param size         Max Size
 *  @param players      Recipient list
 *  @param playersNum   Rcipient count
 *  
 *  @return             true - allow msg / false - otherwise
*/
forward bool cc_proc_OnNewMessage(
    int sender, const char[] temp_key, const char[] msg, 
    char[] indent, int size, const int[] players, int playersNum
);

/*
 *  Streaming output for editing the recipient list
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender Index
 *  @param msg_key      Message Key
 *  @param players      Recipient list
 *  @param &playersNum  Number of recipients

 *  @noreturn
*/
forward void cc_proc_OnRebuildClients(
    int mid, const char[] indent, int sender, 
    const char[] msg_key, int[] players, int &playersNum 
);

/*
 *	Calls when building parts of the template
 *
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  @param recipient    Recipient index
 *  @param part         Part of the message template
 *  @param &pLevel      Replacement priority
 *  @param buffer       Buffer
 *  @param size         Buffer size
 *
 *  @return             Plugin_Continue - build continue,
 *                      Plugin_Handled  - build rejected (after post call),
 *                      Plugin_Stop     - build rejected immediately (with out post call)
*/
forward Action cc_proc_OnRebuildString(
    int mid, const char[] indent, int sender,
    int recipient, int part, int &level, 
    char[] buffer, int size
);

/*
 *  Call after build part of the template
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  @param recipient    Recipient index
 *  @param part         Part of the message template
 *  @param pLevel       Replacement priority
 *  @param value        Value
 *  
 *  @return             true - Block sending/false - send
*/
forward bool cc_proc_OnRebuildString_Post(
    int mid, const char[] indent, int sender,
    int recipient, int part, int level,
    const char[] value
);

/*
 *  Calls after message delivery to all recipients 
 *  
 *  @param mid          Message ID
 *  @param sender       Message Indent
 *  @param sender       Sender Index
 *  
 *  @noreturn
*/
forward void cc_proc_OnMessageEnd(
    int mid, const char[] indent, int sender
);

/*
 *  Calls when capturing an engine message from the server
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender Index
 *  @param msg          Message
 *  
 *  @return             true - handle this / false - otherwise
*/
forward bool cc_proc_HandleEngineMsg(
    const char[] indent, int sender, const char[] msg
);

/*
 *  Calls when the config reading is completed
 *  
 *  @noparam
 *  
 *  @noreturn
*/
forward void cc_config_parsed();

/*
 *  API hand shake
 *  
 *  @param api          API version key
 *  
 *  @noreturn
*/
forward void cc_proc_APIHandShake(const int api);

/*
 *  Get a pallete
 *  
 *  @noparam
 *  
 *  @return         Map: ABBR:value (the pointer is not cloned, so no closure is required.)
*/
native ArrayList cc_drop_palette();

/*
 *  Replacing colors in a string
 *  
 *  @param szBuffer     String buffer
 *  @param toNull       false - replace ABBR with code
                        true - clear ABBR&code in string
 *  
 *  @noreturn
*/
native void ccp_replaceColors(char[] szBuffer, bool toNull = true);

/*
 *  Get the API key used by the core
 *  
 *  @noparam 
 *  
 *  @return         API version key
*/
native int cc_get_APIKey();

/*
 *  API key matching
 *  
 *  @param api          API version key
 *  
 *  @return             true - equal
                        false - otherwise
*/
native bool cc_is_APIEqual(const int api);

native void ccp_UpdateRecipients(const int [] input, int[] output, int &playersNum);
native bool ccp_SkipColors(const char[] indent, int sender);
native void ccp_ChangeMode(const int[] players, int playersNum, const char[] value = NULL_STRING);

native int  ccp_StartNewMessage(
    int sender, const char[] msg_key, 
    const char[] msg, char[] indent, int size, 
    const int[] players, int playersNum
);

native void ccp_RebuildClients(
    int mid, const char[] indent, int sender,
    const char[] msg_key, int[] players, int &playersNum 
);

native bool ccp_RebuildMessage(
    int mid, const char[] indent, int props,
    int recipient, const char[] msg_key, 
    char[] name, char[] msg, char[] buffer, int size
);

native bool ccp_PrepareMessage(
    const char[] indent, int sender,
    int recipient, int max_params, char[] buffer
);

native void ccp_EndMessage(int mid, const char[] indent, int sedner);

native bool ccp_EngineMsgRequest(const char[] indent, int sender, const char[] buffer);

stock int BreakPoint(int iBindType, char[] szValue)
{
    static const int iMaxLength[BIND_MAX] = 
    {
        MESSAGE_LENGTH  ,
        STATUS_LENGTH   ,   STATUS_LENGTH   ,
        STATUS_LENGTH   ,   TEAM_LENGTH     ,
        STATUS_LENGTH   ,   PREFIX_LENGTH   ,
        STATUS_LENGTH   ,   NAME_LENGTH     ,
        STATUS_LENGTH   ,   MESSAGE_LENGTH
    };

    if(strlen(szValue) >= iMaxLength[iBindType])
        szValue[iMaxLength[iBindType]] = 0;

    return iMaxLength[iBindType];
}

#if !defined CORE
public void cc_proc_APIHandShake(const int key)
{
    if(key != API_KEY) SetFailState(API_OOD);
}
#endif

// Stocks

stock void BreakString_stock(char[] szValue, int MaxSmb)
{
    for(int i, a, b; i < strlen(szValue); i++)
    {
        if(a >= MaxSmb)
        {
            szValue[i] = 0;
            break;
        }

        if((b = IsCharMB(szValue[i])))
            i += b-1;
        
        a++;
    }
}

stock int numlts_stock(const char[] str)
{
    int a;

    for(int i, b; i < strlen(str); i++)
    {
        if((b = IsCharMB(szValue[i])))
            i += b-1;
        
        a++;
    }

    return a;
}

stock int BindFromString(const char[] inputString)
{
    char szBuffer[NAME_LENGTH];
    
    for(int i; i < BIND_MAX; i++)
    {
        FormatBind(NULL_STRING, i, _, szBuffer, sizeof(szBuffer));

        if(StrContains(inputString, szBuffer, false) != -1)
            return i;
    }

    return BIND_MAX;
}

stock void FormatBind(const char[] prefix, const int iBind, const char to = 0, char[] szBuffer, int size)
{
    if(iBind < 0 || iBind >= BIND_MAX)
        return;

    strcopy(szBuffer, size, szBinds[iBind]);

    ReplaceString(szBuffer, size, "{", "");
    ReplaceString(szBuffer, size, "}", "");

    if(prefix[0])
        Format(szBuffer, size, "%s%s", prefix, szBuffer);

    if(to)
    {
        if(to == 'l' || to == 'L')
            StringToLowercase(szBuffer);
        
        else if(to == 'u' || to == 'U')
            StringToUppercase(szBuffer);
    }
}

stock void StringToLowercase(char[] sText)
{
    int i;
    while(i < strlen(sText)) {
        sText[i] = CharToLower(sText[i]);
        i++;
    }
}

stock void StringToUppercase(char[] sText)
{
    int i;
    while(i < strlen(sText)) {
        sText[i] = CharToUpper(sText[i]);
        i++;
    }
}

#if defined DEBUG
char g_szLog[MESSAGE_LENGTH];

stock char[] GetDebugPath() {
    char szBuffer[MESSAGE_LENGTH] = "logs/ccprocessor";
    BuildPath(Path_SM, szBuffer, sizeof(szBuffer), szBuffer);

    if(!DirExists(szBuffer))
        CreateDirectory(szBuffer, 0x1ED);

    char szLog[64];
    FormatTime(szLog, sizeof(szLog), "/%j.log", GetTime());
    Format(szBuffer, sizeof(szBuffer), "%s%s", szBuffer, szLog);

    return szBuffer;    
}

#define DBUILD() g_szLog = GetDebugPath();
#define DWRITE(%0,%1) LogToFileEx(g_szLog, %0, %1)

#endif

public SharedPlugin __pl_ccprocessor= 
{
    name = "ccprocessor",
    file = "ccprocessor.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ccprocessor_SetNTVOptional()
{
    MarkNativeAsOptional("cc_drop_palette");
    MarkNativeAsOptional("ccp_replaceColors");
    MarkNativeAsOptional("cc_get_APIKey");
    MarkNativeAsOptional("cc_is_APIEqual");
    MarkNativeAsOptional("ccp_UpdateRecipients");
    MarkNativeAsOptional("ccp_SkipColors");
    MarkNativeAsOptional("ccp_ChangeMode");
    MarkNativeAsOptional("ccp_StartNewMessage");
    MarkNativeAsOptional("ccp_RebuildClients");
    MarkNativeAsOptional("ccp_RebuildMessage");
    MarkNativeAsOptional("ccp_PrepareMessage");
    MarkNativeAsOptional("ccp_EndMessage");
    MarkNativeAsOptional("ccp_EngineMsgRequest");
}
#endif