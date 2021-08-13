#if defined _ccprocessor_stocks_included
 #endinput
#endif
#define _ccprocessor_stocks_included

/*
 *  Template parts(string values)
 *       
*/
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
 *  Break string points for all of the parts
 *       
*/
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

/*
 *  Request to start processing a new message 
 *  
 *  @param a            Buffer array 
 *  @param s            Sender index
 *  @param s            Recipient index
 *  @param t            Message template
 *  @param m            Message text
 *  @param ind          Message indent
 *  @param l            Message indent size       
 *  
 *  @return         ID or -1 if unsuccessful  
*/
stock int stock_NewMessage(ArrayList a, int s, int r, const char[] t, const char[] m, char[] ind, int l) {
    static const int propsCount = 2;
    static const int rw;

    int[] props = new int[propsCount]
    props[0] = s;
    props[1] = r;

    a.Clear();
    a.PushString(ind);
    a.PushString(t);
    a.PushString(m);

    if((s = ccp_StartNewMessage(props, propsCount, a)) != -1) {
        a.GetString(rw, ind, l);
    } 

    return s;
}

/*
 *  Request to start rebuilding recipient list
 *  
 *  @param a            Buffer array 
 *  @param id           Message ID
 *  @param s            Message sender
 *  @param ind          Message indent
 *  @param m            Message text
 *  @param p            Message recipient list
 *  @param c            Message recipient count       
 *  
 *  @return             Proc_Continue - with out changes,
 *                      Proc_Change - recipients have been changed,
 *                      Proc_Reject - message rejected
*/
// stock Processing stock_RebuildClients(ArrayList a, int id, int s, const char[] ind, const char[] m, int[] p, int &c) {
//     static const int propsCount = 2;
//     int[] props = new int[propsCount]
//     props[0] = id;
//     props[1] = s;

//     a.Clear();
//     a.PushString(ind);
//     a.PushString(m);
//     a.PushArray(p, c);
//     a.Push(c);

//     Processing next;
//     if((next = ccp_RebuildClients(props, propsCount, a)) == Proc_Change) {
//         c = a.Get(3);
//         a.GetArray(2, p, c);
//     }

//     return next;
// }

/*
 *  Request to start rebuilding message
 *  
 *  @param a            Buffer array 
 *  @param i            Message ID
 *  @param s            Message buffer (pkg: senderID << 3|senderTeam << 1|senderAlive)
 *  @param r            Message recipient
 *  @param ind          Message indent
 *  @param t            Message template
 *  @param n            Message sender name
 *  @param m            Message text
 *  @param o            Message compile 
 *  
 *  @return             Proc_Continue - continue with out changes,
 *                      Proc_Change - value has been changed & continue,
 *                      Proc_Reject - build rejected (after post call)
 *                      Proc_Stop - build rejected immediately (before post call)
*/
stock Processing stock_RebuildMsg(ArrayList a, int i, int s, int r, const char[] ind, const char[] t, char[] n, char[] m, char[] o) {
    static const int propsCount = 3;
    int[] props = new int[propsCount]
    props[0] = i;
    props[1] = s;
    props[2] = r;

    a.Clear();
    a.PushString(ind);
    a.PushString(t);
    a.PushString(n);
    a.PushString(m);
    a.PushString(o);

    Processing next;
    if((next = ccp_RebuildMessage(props, propsCount, a)) <= Proc_Change) {
        a.GetString(2, n, NAME_LENGTH);
        a.GetString(3, m, MESSAGE_LENGTH);
        a.GetString(4, o, MAX_LENGTH);
    }

    return next;
}

/*
 *  Renders engine messages 
 *  
 *  @param a            Buffer array 
 *  @param s            Message sender
 *  @param r            Message recipient
 *  @param c            Text params count
 *  @param m            Message text
 *  @param l            Message size     
 *  
 *  @noreturn
*/
stock void stock_RenderEngineCtx(ArrayList a, int s, int r, int c, char[] m, int l) {
    static const int propsCount = 3;
    // int[] props = new int[propsCount];
    int[] props = new int[propsCount]
    props[0] = s;
    props[1] = r;
    props[2] = c;

    // LogMessage("Count: %d : %d : %s", props[2], c, props);

    a.Clear();
    a.PushString(m);

    ccp_RenderEngineCtx(props, propsCount, a);

    a.GetString(0, m, l);
} 

/*
 *  End message request
 *  
 *  @param a            Buffer array 
 *  @param id           Message ID
 *  @param s            Message sender
 *  @param ind          Message indent
 *  
 *  @noreturn
*/
stock void stock_EndMsg(ArrayList a, int id, int s, const char[] ind) {
    static const int propsCount = 3;
    int[] props = new int[propsCount]
    props[0] = id;
    props[1] = s;

    a.Clear();
    a.PushString(ind);

    ccp_EndMessage(props, propsCount, a);
}

/*
 *  Obtaining permission for processing engine msg
 * 
 *  @param a            Buffer array 
 *  @param s            Message sender
 *  @param r            Message recipient 
 *  @param m            Message text 
 *  
 *  @return             Proc_Continue - processing continue,
 *                      Proc_Stop - processing rejected
*/
stock Processing stock_EngineMsgReq(ArrayList a, int s, int r, const char[] m) {
    static const int propsCount = 3;
    int[] props = new int[propsCount]
    props[0] = s;
    props[1] = r;

    a.Clear();
    a.PushString(m);

    return ccp_EngineMsgRequest(props, propsCount, a);
}

/*
 *  Enable API handshake for modules not defined as CORE
 * 
 *  @define CORE
*/
#if !defined CORE
public void cc_proc_APIHandShake(const int key)
{
    if(key != API_KEY) SetFailState(API_OOD);
}
#endif


/*
 *  Limits a string by the number of characters (ignores byte ownership)
 * 
 *  @param szValue      Buffer
 *  @param smbMax       maxLength
 *  
 *  @noreturn           
*/
stock void BreakString_stock(char[] szValue, int maxLength)
{
    for(int i, a, b; i < strlen(szValue); i++)
    {
        if(a >= maxLength)
        {
            szValue[i] = 0;
            break;
        }

        if((b = IsCharMB(szValue[i])))
            i += b-1;
        
        a++;
    }
}

/*
 *  Counting the number of letters in buffer (ignores byte ownership)
 * 
 *  @param str          Buffer
 *  
 *  @return             Length           
*/
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

/*
 *  Gets part of the pattern from input string 
 * 
 *  @param inputString   Buffer
 *  
 *  @return             part value           
*/
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

/*
 *  Formats part of the template according to the specified rules 
 * 
 *  @param prefix       Any tag or NULL_STRING
 *  @param iBind        part index (BIND_PROTOTYPE, BIND_NAME, ..., etc)
 *  @param to           l/L - lowercase, U/u - uppercase
 *  @param szBuffer     Buffer
 *  @param size         Buffer size
 *  
 *  @noreturn         
*/
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

/*
 *  Find string in array
 *
 *  @return             Index or -1         
*/
stock int FindChannelInChannels(const char[][] array, int count, const char[] channel, bool casesens = true) {
    for(int i = 0; i < count; i++) {
        if(!strcmp(channel, array[i], casesens)) {
            return i;
        }
    }

    return -1;
}


/*
 *  Find string in json array
 *
 *  @return             Index or -1         
*/
#if defined INCLUDE_RIPJSON
stock int FindChannelInChannels_json(JSONArray jsonArray, const char[] channel, bool casesens = true) {
    static char buffer[64];
    
    for(int i = 0; i < jsonArray.Length; i++) {
        jsonArray.GetString(i, buffer, sizeof(buffer));

        if(!strcmp(buffer, channel, casesens)) {
            return i;
        }
    }

    return -1;
}

// from context
public const char CHANNEL_MGR_PKGKEY[] = "channel_mgr";

stock JSON ccp_GetChannelList() {
    return ccp_GetArtifact(0, CHANNEL_MGR_PKGKEY);
}

stock int FindChannel(const char[] szTag, bool casesens = true) {
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        char szBuffer[PREFIX_LENGTH];
        for(int i; i < channels.Length; i++) {
            channels.GetString(i, szBuffer, sizeof(szBuffer));
            if(!strcmp(szTag, szBuffer, casesens)) {
                delete channels;
                return i;
            }
        }
    }

    delete channels;
    return -1;
}

stock char[] ccp_GetChannelTag(const int index) {
    char szTag[PREFIX_LENGTH];

    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null)
        if(index >= 0 && index < channels.Length)
            channels.GetString(index, szTag, sizeof(szTag));

    delete channels;
    return szTag;
}

stock void ccp_RemoveChannel(const int index) {
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if(index >= 0 && index < channels.Length) {
            if(channels.Remove(index))
                ccp_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels, 0);
        }
    }

    delete channels;
}

stock bool ccp_AddChannel(const char[] szTag) {
    if(ccp_FindChannel(szTag) != -1)
        return false;
    
    bool bSet;
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if((bSet = channels.PushString(szTag)))
            bSet = ccp_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels, 0);            
    }

    delete channels;
    return bSet;
}

#endif

/*
 *  DEBUG 
 *
 *  @define DEBUG      
*/
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