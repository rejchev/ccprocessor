#if defined _ccprocessor_stocks_included
 #endinput
#endif
#define _ccprocessor_stocks_included

stock const char szBinds[BIND_MAX][] = 
{
    "{PROTOTYPE}"   ,
    
    "{STATUSCO}"    ,   "{STATUS}"  , 
    "{TEAMCO}"      ,   "{TEAM}"    , 
    "{PREFIXCO}"    ,   "{PREFIX}"  ,
    "{NAMECO}"      ,   "{NAME}"    , 
    "{MSGCO}"       ,   "{MSG}"
};

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

stock int stock_NewMessage(ArrayList a, int s, const char[] t, const char[] m, const int[] p, int c, char[] ind, int l) {
    static const int rw;

    a.Clear();
    a.PushString(ind);
    a.PushString(t);
    a.PushString(m);
    a.PushArray(p, c);
    a.Push(c);

    if((s = ccp_StartNewMessage(s, a)) != -1) {
        a.GetString(rw, ind, l);
    } 

    return s;
}

stock Action stock_RebuildClients(ArrayList a, int id, int s, const char[] ind, const char[] m, int[] p, int &c) {
    char props[4];
    props[0] = id;
    props[1] = s;

    a.Clear();
    a.PushString(ind);
    a.PushString(m);
    a.PushArray(p, c);
    a.Push(c);

    Action next;
    if((next = ccp_RebuildClients(props, strlen(props), a)) == Plugin_Continue) {
        a.Get(3, c);
        a.GetArray(2, p, c);
    }

    return next;
}

stock Action stock_RebuildMsg(ArrayList a, int i, int s, int r, const char[] ind, const char[] t, char[] n, char[] m, char[] o) {
    char props[4];
    props[0] = i;
    props[1] = s;
    props[2] = r;

    a.Clear();
    a.PushString(ind);
    a.PushString(t);
    a.PushString(n);
    a.PushString(m);
    a.PushString(o);

    Action next;
    if((next = ccp_RebuildMessage(props, strlen(props), a)) == Plugin_Continue) {
        a.GetString(2, n, NAME_LENGTH);
        a.GetString(3, m, MESSAGE_LENGTH);
        a.GetString(4, o, MAX_LENGTH);
    }

    return next;
}

stock Action stock_HandleEngineMsg(ArrayList a, int s, int r, int c, char[] m, int l) {
    char props[4];
    props[0] = s;
    props[1] = r;
    props[2] = c;

    a.Clear();
    a.PushString(m);

    Action next;
    if((next = ccp_HandleEngineMsg(props, strlen(props), a)) < Plugin_Stop) {
        a.GetString(0, m, l);
    }

    return next;
} 

stock void stock_EndMsg(ArrayList a, int id, int s, const char[] ind) {
    char props[4];
    props[0] = id;
    props[1] = s;

    a.Clear();
    a.PushString(ind);

    ccp_EndMessage(props, strlen(props), a);
}

stock bool stock_EngineMsgReq(ArrayList a, int s, int r, const char[] m) {
    char props[4];
    props[0] = s;
    props[1] = r;

    a.Clear();
    a.PushString(m);

    return ccp_EngineMsgRequest(props, strlen(props), a);
}

#if !defined CORE
public void cc_proc_APIHandShake(const int key)
{
    if(key != API_KEY) SetFailState(API_OOD);
}
#endif

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