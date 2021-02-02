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

#define API_KEY             51374615

#if !defined CORE
    #define API_OOD         "The plugin module uses an outdated API. You must update it."
#endif

// Message type
enum
{
    eMsg_TEAM = 0,
    eMsg_ALL,
    eMsg_CNAME,

    /* The bind '{MSG}' is not called for this type*/
    eMsg_RADIO,	

    eMsg_SERVER,
    
    eMsg_MAX
};

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

// Temporarily, later there will be a separate interface for communication channels
stock const char szMsgTypes[eMsg_MAX][] = 
{
    "<TEAM>", "<ALL>", "<CNAME>", "<RADIO>", "<SERVER>"
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
 *  @param mType        Message type
 *  @param iClient      Client index
 *  
 *  @return             true - skipping
 *                      false - otherwise
*/
forward bool cc_proc_SkipColorsInMsg(const int mType, int iClient);

/*
 *  Counter of processed messages.
 *  Called every time when message is ready to be sent
 *  
 *  @param mType        Type of message
 *  @param sender       Sender index
 *  @param msgId        Message ID
 *  @param message      Message
 *  @param clients      Recipient list
 *  @param count        Recipient count
 *  
 *  @noreturn
*/
forward void cc_proc_MsgUniqueId(int mType, int sender, int msgId, const char[] message, const int[] clients, int count);

/*
 *  Streaming output for editing the recipient list
 *  
 *  @param mType        Message type
 *  @param iClient      Real sender index
 *  @param clients[]    Recipient list (rewritable)
 *  @param &numClients  Number of recipients

 *  @noreturn
*/
forward void cc_proc_RebuildClients(const int mType, int iClient, int[] clients, int &numClients);

/*
 *	Calls when building parts of the template
 *
 *  @param mType        Message type
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
forward Action cc_proc_RebuildString(const int mType, int sender, int recipient, int part, int &pLevel, char[] buffer, int size);

/*
 *  Call after build part of the template
 *  
 *  @param mType        Message type
 *  @param sender       Sender index
 *  @param recipient    Recipient index
 *  @param part         Part of the message template
 *  @param pLevel       Replacement priority
 *  @param szValue      Value of part
 *  
 *  @return             true - Block sending/false - send
*/
forward bool cc_proc_RebuildString_Post(const int mType, int sender, int recipient, int part, int pLevel, const char[] szValue);

/*
 *  Calls when capturing an engine message from the server
 *  
 *  @param szMessage        Key of engine message (with symbol[0] = '#')
 *  @param IsPhraseExists   If key of engine message is exists
 *  
 *  @return                 Plugin_Changed	- send message for core processing
                            Plugin_Continue - exclude engine message processing
                            Plugin_Handled 	- exclude message sending by engine
*/
forward Action cc_proc_OnDefMsg(const char[] szMessage, bool IsPhraseExists);

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

/*
 *  Calling the internal message builder.
 *  Calls child forwards to get the current object settings.
 *  
 *  @param iClient      Client index
 *  @param mType        Message type
 *  @param um           Unique usermessage type (or. dev)
 *  @param szName       Username value
 *  @param szMessage    User message value
 *  @param szBuffer     Buffer to store
 *  @param size         Buffer size
 *  
 *  @noreturn
*/
native void cc_call_builder(int mType, int iClient, int iRecipient, const char[] um, const char[] szName, const char[] szMessage, char[] szBuffer, int size);

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
    MarkNativeAsOptional("cc_call_builder");
}
#endif