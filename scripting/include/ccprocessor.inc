#if defined _ccprocessor_included
 #endinput
#endif
#define _ccprocessor_included

#define STATUS_LENGTH   	16
#define TEAM_LENGTH     	64
#define PREFIX_LENGTH   	64
#define NAME_LENGTH     	128
#define MESSAGE_LENGTH  	256
#define MAX_LENGTH      	512


/* 
API key:
	The value changes if the API has been changed. 
	This is a measure against users who do not follow the changes and do not understand what is happening.

	ATTENTION: Do not change it yourself if you are not ready for the consequences!
*/

#define API_KEY 			73138147

#if !defined CORE
	#define API_OOD 		"The plugin module uses an outdated API. You must update it."
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

enum
{
	BIND_PROTOTYPE = 0,

	BIND_STATUS,
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
	"{PROTOTYPE}",
	
	"{STATUS}", "{TEAM}", "{PREFIXCO}", "{PREFIX}",
	"{NAMECO}", "{NAME}", "{MSGCO}", 	"{MSG}"
};

/*
 *	Skip colors in an unprepared message
 *
 *  @param mType		Message type
 *	@param iClient		Client index
 *
 * 	@return				true - skipping / false - otherwise
*/
forward bool cc_proc_SkipColorsInMsg(const int mType, int iClient);

/*
 *	Counter of processed messages.
 *  Called every time when message is ready to be sent
 *
 *	@param UniqueID		Unique ID of sended msg (feature in progress...)
 *
 * 	@noreturn
*/
forward void cc_proc_MsgUniqueId(const int UniqueID);

/*
 *	Calls when building parts of the prototype
 *
 *  @param mType		Message type
 *	@param iClient		Client index
 *	@param &pLevel		Replacement priority
 *	@param szBind		Core binds ({PROTOTYPE}, {STATUS}, {TEAM}, {PREFIXCO}, {PREFIX}, {NAMECO}, {NAME}, {MSGCO}, {MSG})
 *	@param szBuffer		Buffer with value
 *	@param iSize		Size of buffer
 *
 * 	@noreturn
*/
forward void cc_proc_RebuildString(const int mType, int iClient, int &pLevel, const char[] szBind, char[] szBuffer, int iSize);

/*
 *	Call after build part of prototype
 *
 *  @param mType		Message type
 *	@param iClient		Client index
 *	@param pLevel		Replacement priority
 *	@param szBind		Core binds ({PROTOTYPE}, {STATUS}, {TEAM}, {PREFIXCO}, {PREFIX}, {NAMECO}, {NAME}, {MSGCO}, {MSG})
 *	@param szValue		Value of part
 *
 * 	@noreturn
*/
forward void cc_proc_RebuildString_Post(const int mType, int iClient, int pLevel, const char[] szBind, const char[] szValue);

/*
 *	Calls when message is build ended
 *
 *  @param mType			Message type
 *	@param iClient			Sender's index
 *	@param szMessage		Built message
 *
 * 	@noreturn
*/
forward void cc_proc_OnMessageBuilt(const int mType, int iClient, const char[] szMessage);

/*
 *	Streaming output for editing the recipient list
 *
 *  @param mType		Message type
 *	@param iClient		Real sender index
 *  @param clients[]	Recipient list
 *  @param numClients	Number of recipients

 * 	@noreturn
*/
forward void cc_proc_RebuildClients(const int mType, int iClient, int[] clients, int &numClients);

/*
 *	Approving the sender's index
 *	Calls when message is ready to send
 *
 *  @param mType				Message type
 *	@param &iClientIndex		Sender's index (<> 0)
 *
 * 	@noreturn
*/
forward void cc_proc_IndexApproval(const int mType, int &iClientIndex);

/*
 *	Calls when capturing an engine message from the server
 *
 *	@param szMessage			Key of engine message (with symbol[0] = '#')
 *	@param IsPhraseExists		If key of engine message is exists
 *	@param IsTranslated			If key of engine message is translated for LANG_SEVER
 *
 * 	@return					Plugin_Changed	- send message for core processing
								Plugin_Continue - exclude engine message processing
								Plugin_Handled 	- exclude message sending by engine
*/
forward Action cc_proc_OnDefMsg(const char[] szMessage, bool IsPhraseExists, bool IsTranslated);

/*
 *	Calls when the config reading is completed
 *
 *	@noparam
 *
 * 	@noreturn
*/
forward void cc_config_parsed();

/*
 *	Called when action is required on the radio key
 *
 *	@param iClient			Sender's index
 *	@param szRKey			Radio key
 *
 * 	@return					true - restrict, false - otherwise
*/
forward bool cc_proc_RestrictRadio(int iClient, const char[] szRKey);

/*
 *	API hand shake
 *
 *	@param api			API version key
 *
 * 	@noreturn
*/
forward void cc_proc_APIHandShake(const int api);

/*
 *	Get a pallete
 *
 *	@noparam
 *
 * 	@return				Map: ABBR:value (the pointer is not cloned, so no closure is required.)
*/
native StringMap cc_drop_palette();

/*
 *	Removing colors from a string
 *
 *	@param szBuffer		String buffer
 *	@param iSize		Size of string
 *
 * 	@noreturn
*/
native void cc_clear_allcolors(char[] szBuffer, int iSize);

/*
 *	Get the API key used by the core
 *
 *	@noparam 
 *
 * 	@return 		API version key
*/
native int cc_get_APIKey();

/*
 *	API key matching
 *
 *	@param api		API version key
 *
 * 	@return				true - equal / false - otherwise
*/
native bool cc_is_APIEqual(const int api);

/*
 *	Calling the internal message builder.
 *	Calls child forwards to get the current object settings.
 *
 *	@param iClient		Client index
 *	@param mType		Message type
 *	@param um			Unique usermessage type (or. dev)
 *	@param szName		Username value
 *	@param szMessage	User message value
 *	@param szBuffer		Buffer to store
 *	@param size			Buffer size
 *
 * 	@noreturn
*/
native void cc_call_builder(int iClient, int mType, const char[] um, const char[] szName, const char[] szMessage, char[] szBuffer, int size);

stock int BreakPoint(int iBindType, char[] szValue)
{
	static const int iMaxLength[BIND_MAX] = 
	{
		MESSAGE_LENGTH, STATUS_LENGTH, TEAM_LENGTH, 
		STATUS_LENGTH, PREFIX_LENGTH, STATUS_LENGTH, 
		NAME_LENGTH, STATUS_LENGTH, MESSAGE_LENGTH
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


// Author Wend4r: https://hlmod.ru/threads/sklad-funkcij-sourcepawn.45161/post-417351
stock void StringToLowercase(char[] sText)
{
    int i;
    while(i < strlen(sText)) {
        sText[i] = CharToLower(sText[i]);
        i++;
    }
}

// Author Wend4r: https://hlmod.ru/threads/sklad-funkcij-sourcepawn.45161/post-417351
stock void StringToUppercase(char[] sText)
{
    int i;
    while(i < strlen(sText)) {
        sText[i] = CharToUpper(sText[i]);
        i++;
    }
}

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
	MarkNativeAsOptional("cc_clear_allcolors");
	MarkNativeAsOptional("cc_get_APIKey");
	MarkNativeAsOptional("cc_is_APIEqual");
	MarkNativeAsOptional("cc_call_builder");
}
#endif