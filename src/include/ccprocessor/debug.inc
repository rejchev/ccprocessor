#if defined _ccprocessor_debug_included
 #endinput
#endif
#define _ccprocessor_debug_included

#if !defined DEBUG
    #endinput
#endif

#define DEBUG_INIT() g_szLog = GetDebugPath()
#define DEBUG_LOG() LogToFileEx(g_szLog, %0, %1)

stock char g_szLog[PLATFORM_MAX_PATH];

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