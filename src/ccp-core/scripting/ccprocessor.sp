#pragma newdecls required

#define CORE

#if defined INCLUDE_DEBUG
    #define DEBUG "[CCProcessor]"
#endif

#include <ccprocessor>

ArrayList
    g_aPalette;

char g_szSection[4];

ConVar game_mode;

char mode_default_value[8];

GlobalForward
    g_fwdSkipColors,
    g_fwdRebuildString,
    g_fwdOnEngineMsg,
    g_fwdConfigParsed,
    g_fwdNewMessage,
    g_fwdAPIHandShake,
    g_fwdRebuildClients,
    g_fwdRebuildString_Post,
    g_fwdMessageEnd;

bool 
    g_bRTP,
    g_bResetByMap;

int g_iMessageCount;
int g_iMsgInProgress = -1;

public Plugin myinfo = 
{
    name        = "[CCP] Core",
    author      = "nullent?",
    description = "Color chat processor",
    version     = "3.4.0",
    url         = "discord.gg/ChTyPUG"
};

#define SZ(%0) %0, sizeof(%0)

#include "ccprocessor/defaults.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {    
    #if defined DEBUG
        DBUILD()
    #endif

    CreateNative("cc_get_APIKey",                       Native_GetAPIKey);
    CreateNative("cc_is_APIEqual",                      Native_IsAPIEqual);
    CreateNative("cc_drop_palette",                     Native_DropPalette);
    CreateNative("ccp_replaceColors",                   Native_ReplaceColors);

    CreateNative("ccp_UpdateRecipients",                Native_UpdateRecipients);
    CreateNative("ccp_SkipColors",                      Native_SkipColors);
    CreateNative("ccp_ChangeMode",                      Native_ChangeMode);
    CreateNative("ccp_StartNewMessage",                 Native_StartNewMessage);
    CreateNative("ccp_RebuildClients",                  Native_RebuildClients);
    CreateNative("ccp_RebuildMessage",                  Native_RebuildMessage);
    CreateNative("ccp_PrepareMessage",                  Native_PrepareMessage);
    CreateNative("ccp_EndMessage",                      Native_EndMessage);
    CreateNative("ccp_EngineMsgRequest",                Native_EngineMessageReq);
    
    // void()
    g_fwdConfigParsed = new GlobalForward(
        "cc_config_parsed", 
        ET_Ignore
    );

    // void(const int key)
    g_fwdAPIHandShake = new GlobalForward(
        "cc_proc_APIHandShake", 
        ET_Ignore, Param_Cell
    );

    // bool(const char[] indent, int sender)
    g_fwdSkipColors = new GlobalForward(
        "cc_proc_SkipColors", 
        ET_Event, Param_String, Param_Cell
    );

    // bool(const char[] indent, int sender, const char[] msg_key?)
    g_fwdOnEngineMsg = new GlobalForward(
        "cc_proc_HandleEngineMsg",
        ET_Event, Param_String, Param_Cell, Param_String
    );

    // void(int id, const char[] indent, int sender)
    g_fwdMessageEnd = new GlobalForward(
        "cc_proc_OnMessageEnd",
        ET_Ignore, Param_Cell, Param_String, Param_Cell
    );

    // void(int id, const char[] indent, int sender, const char[] msg_key, int[] players, int count)
    g_fwdRebuildClients = new GlobalForward(
        "cc_proc_OnRebuildClients",
        ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_String, Param_Array, Param_CellByRef
    );
    
    // bool(const char[] indent, int sender, const char[] msg_key, int[] players, int count) 
    g_fwdNewMessage = new GlobalForward(
        "cc_proc_OnNewMessage",
        ET_Event, Param_String, Param_Cell, Param_String, Param_Array, Param_Cell
    );
    
    // bool(int id, const char[] indent, int sender, int recipient, int part, int level, const char[] value)
    g_fwdRebuildString_Post = new GlobalForward(
        "cc_proc_OnRebuildString_Post",
        ET_Hook, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String
    );
    
    // Action(int id, const char[] indent, int sender, int recipient, int part, int &level, char[] value, int size)
    g_fwdRebuildString = new GlobalForward(
        "cc_proc_OnRebuildString",
        ET_Hook, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef, Param_String, Param_Cell
    );

    RegPluginLibrary("ccprocessor");

    if(late) OnAllPluginsLoaded();

    return APLRes_Success;
}

public void OnPluginStart()
{
    #if defined DEBUG
        DWRITE("%s: OnPluginStart()", DEBUG)
    #endif

    LoadTranslations("ccp_core.phrases");
    LoadTranslations("ccp_engine.phrases");

    g_aPalette = new ArrayList(STATUS_LENGTH, 0);
 
    if(!DirExists("/cfg/ccprocessor"))
        CreateDirectory("/cfg/ccprocessor", 0x1ED);

    game_mode = FindConVar("game_mode");
    if(!game_mode)
        return;

    game_mode.AddChangeHook(OnModChanged);
    game_mode.GetString(mode_default_value, sizeof(mode_default_value));

    #if defined DEBUG
        DWRITE("%s: Game Mode(%x): %s", DEBUG, game_mode, mode_default_value);
    #endif
}

public void OnAllPluginsLoaded()
{
    Call_StartForward(g_fwdAPIHandShake);
    Call_PushCell(API_KEY);

    #if !defined DEBUG
        Call_Finish();
    #else
        DWRITE("%s: Call(g_fwdAPIHandShake) code: %d", DEBUG, Call_Finish())
    #endif
    
}

public void OnModChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    cvar.GetString(mode_default_value, sizeof(mode_default_value));

    #if defined DEBUG
        DWRITE("%s: Game Mode Changed(%x): %s", DEBUG, game_mode, mode_default_value);
    #endif
}

public void OnMapStart()
{
    #if defined DEBUG
        DBUILD()
    #endif

    #if defined DEBUG
        DWRITE("%s: OnMapStart()", DEBUG);
    #endif

    g_aPalette.Clear();
    g_szSection = NULL_STRING;

    static char szConfig[MESSAGE_LENGTH] = "configs/ccprocessor/";
    GetConfigFileByGame(szConfig, sizeof(szConfig));

    if(!FileExists(szConfig))
        SetFailState("Where is my config: '%s' ", szConfig);
    
    #if defined DEBUG
        DWRITE("%s: Game Config Path(): %s", DEBUG, szConfig);
    #endif

    int iLine;
    if(CreateParser().ParseFile(szConfig, iLine) != SMCError_Okay)
        LogError("An error was detected on line '%i' while reading", iLine);
}

void GetConfigFileByGame(char[] szConfig, int size)
{
    if(szConfig[0] == 'c')
        BuildPath(Path_SM, szConfig, size, szConfig);

    ReplaceString(szConfig, size, "\\", "/");
    int len = strlen(szConfig);

    if(szConfig[len-1] != 'i')
    {
        GetGameFolderName(szConfig[len], size - (len-1));
        Format(szConfig, size, "%s.ini", szConfig);
    }
}

SMCParser CreateParser()
{
    SMCParser smParser = new SMCParser();
    smParser.OnKeyValue = OnKeyValue;
    smParser.OnEnterSection = OnEnterSection;
    smParser.OnEnd = OnCompReading;
    smParser.OnLeaveSection = OnLeave;

    return smParser;
}

public void OnConfigsExecuted() {
    if(game_mode) game_mode.Flags |= FCVAR_REPLICATED;

    #if defined DEBUG
        DWRITE("%s: OnConfigsExecuted()", DEBUG);
    #endif
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
    g_szSection[strlen(g_szSection)] = name[0];

    #if defined DEBUG
        DWRITE("%s: OnEnterSection(%x): %s", DEBUG, smc, name);
    #endif

    return SMCParse_Continue;
}

SMCResult OnLeave(SMCParser smc)
{
    g_szSection[strlen(g_szSection)-1] = 0;

    #if defined DEBUG
        DWRITE("%s: OnLeave From Section(%x)", DEBUG, smc);
    #endif

    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] sKey, const char[] sValue, bool bKey_Quotes, bool bValue_quotes)
{
    if(!sKey[0] || !sValue[0])
        return SMCParse_Continue;

    int iBuffer;

    #if defined DEBUG
        DWRITE("%s: OnKeyValue(%x): Key: %s, Value: %s", DEBUG, smc, sKey, sValue);
    #endif

    // chat -> [p]alette
    if(g_szSection[1] == 'p' || g_szSection[1] == 'P')
    {
        char szBuffer[STATUS_LENGTH];
        strcopy(szBuffer, sizeof(szBuffer), sValue);
        
        iBuffer = strlen(szBuffer);
        
        szBuffer[0] =   (szBuffer[0] == '#')
                            ? (iBuffer == 7) 
                                ? 7 
                                : 8
                            : StringToInt(szBuffer); 
        if(iBuffer < 3) 
            szBuffer[1] = 0;
        
        g_aPalette.PushString(sKey);
        g_aPalette.PushString(szBuffer);
    }

    else
    {
        if(!strcmp(sKey, "UIDByMap"))
            g_bResetByMap = view_as<bool>(StringToInt(sValue));

        else if(!strcmp(sKey, "RTCP"))
            g_bRTP = view_as<bool>(StringToInt(sValue));
    }

    return SMCParse_Continue;
}

public void OnCompReading(SMCParser smc, bool halted, bool failed)
{
    delete smc;

    #if defined DEBUG
        DWRITE("%s: OnCompReading(%x): Halted: %b, Failed: %b", DEBUG, smc, halted, failed);
    #endif

    g_szSection = NULL_STRING;

    Call_OnCompReading();

    if(halted || failed)
        SetFailState("There was a problem reading the configuration file");

    if(g_bResetByMap)
        g_iMessageCount = 0;
}

public int Native_EngineMessageReq(Handle hPlugin, int params) {
    char szIndent[64];
    GetNativeString(1, SZ(szIndent));

    int sender = GetNativeCell(2);

    char szMessage[MESSAGE_LENGTH];
    GetNativeString(3, SZ(szMessage));

    return Call_HandleEngineMsg(szIndent, sender, szMessage);
}

public int Native_UpdateRecipients(Handle hPlugin, int params) {
    int players[MAXPLAYERS+1];
    int output[MAXPLAYERS+1];
    int playersNum = GetNativeCellRef(3);
    GetNativeArray(1, players, playersNum);

    int a;
    for(int i; i < playersNum; i++) {
        if(IsClientConnected(players[i]) 
        && (IsClientSourceTV(players[i]) || !IsFakeClient(players[i]))) {
            output[a++] = players[i];  
        }
    }

    SetNativeArray(2, output, a);
    SetNativeCellRef(3, a);   
}

public int Native_SkipColors(Handle hPlugin, int params) {
    char szIndent[64];
    GetNativeString(1, szIndent, sizeof(szIndent));

    return Call_IsSkipColors(szIndent, GetNativeCell(2));    

}

public int Native_ChangeMode(Handle hPlugin, int params) {
    if(!game_mode) {
        return;
    }

    int players[MAXPLAYERS+1];
    int playersNum = GetNativeCell(2);
    GetNativeArray(1, players, playersNum);

    char szValue[4];
    GetNativeString(3, szValue, sizeof(szValue));

    if(!szValue[0]) {
        strcopy(szValue, sizeof(szValue), mode_default_value);
    }

    for(int i; i < playersNum; i++) {
        #if defined DEBUG
            DWRITE("%s: ChangeModeValue(%N): %s", DEBUG, players[i], szValue);
        #endif

        if(IsFakeClient(players[i]))
            SetFakeClientConVar(players[i], "game_mode", szValue);
        
        else game_mode.ReplicateToClient(players[i], szValue);
    }
}

public int Native_StartNewMessage(Handle hPlugin, int params) {
    if(g_iMsgInProgress != -1) {
        return -1;
    }

    char szIndent[64];
    GetNativeString(1, SZ(szIndent));

    int sender = GetNativeCell(2);

    char szMsgName[NAME_LENGTH];
    GetNativeString(3, SZ(szMsgName));

    int players[MAXPLAYERS+1];
    int playersNum = GetNativeCell(5);
    GetNativeArray(4, players, playersNum);

    if(!Call_NewMessage(szIndent, sender, szMsgName, players, playersNum)) {
        return -1;
    }

    g_iMessageCount++;
    g_iMsgInProgress = g_iMessageCount;

    return g_iMsgInProgress;
}

public int Native_RebuildClients(Handle hPlugin, int params) {
    int id = GetNativeCell(1);
    
    char szIndent[64];
    GetNativeString(2, SZ(szIndent));

    int sender = GetNativeCell(3);

    char szMessage[64];
    GetNativeString(4, SZ(szMessage));

    int playersNum = GetNativeCellRef(6);
    int players[MAXPLAYERS+1];
    GetNativeArray(5, players, playersNum);

    Call_RebuildClients(id, szIndent, sender, szMessage, players, playersNum);

    SetNativeArray(5, players, playersNum);
    SetNativeCellRef(6, playersNum);
}

public int Native_RebuildMessage(Handle hPlugin, int params) {
    int id = GetNativeCell(1);
    
    char szIndent[64];
    GetNativeString(2, SZ(szIndent));

    int sender = GetNativeCell(3);
    int recipient = GetNativeCell(4);

    char szTemplate[64];
    GetNativeString(5, SZ(szTemplate));

    char szName[NAME_LENGTH];
    GetNativeString(6, SZ(szName));

    char szMessage[MESSAGE_LENGTH];
    GetNativeString(7, SZ(szMessage));

    char szBuffer[MAX_LENGTH];
    GetNativeString(8, SZ(szBuffer));

    int     backup;
    char    value[MESSAGE_LENGTH];

    backup  =   sender;
    sender  >>= 3;

    FormatEx(SZ(szBuffer), "%s", szBinds[BIND_PROTOTYPE]);

    #if defined DEBUG
        DWRITE( \
            "%s: RebuildMessage(%s): => \
                \n\t\tID: %d \
                \n\t\tSender: %N \
                \n\t\tRecepient: %N \
                \n\t\tName: %s \
                \n\t\tMessage: %s \
                \n\t\tTemplate: %s", \
            DEBUG, szIndent, id, sender, recipient, szName, szMessage, szBuffer\
        );
    #endif
    
    for(int i; i < BIND_MAX; i++) {
        value = NULL_STRING;

        GetDefaultValue(
            szIndent, backup, recipient, i, 
            (i == BIND_NAME) 
                ? szName 
                : (i == BIND_MSG) 
                    ? szMessage
                    : szTemplate, 
            SZ(value)
        );
        
        if(Call_RebuildString(id, szIndent, sender, recipient, i, SZ(value)) != Plugin_Continue) {
            #if defined DEBUG
                DWRITE("%s: RebuildMessage(%N) Output: Sending discarded", DEBUG, recipient);
            #endif

            return false;
        }

        ReplaceString(SZ(szBuffer), szBinds[i], value, true);
    }

    #if defined DEBUG
        DWRITE( \
            "%s: RebuildMessage(%s) Output: => \
                \n\t\tType: %d \
                \n\t\tSender: %N \
                \n\t\tRecepient: %N \
                \n\t\tName: %s \
                \n\t\tMessage: %s \
                \n\t\tTemplate: %s", \
            DEBUG, szIndent, id, sender, recipient, szName, szMessage, szBuffer\
        );
    #endif

    SetNativeString(6, SZ(szName));
    SetNativeString(7, SZ(szMessage));
    SetNativeString(8, SZ(szBuffer));
    return true;
}

public int Native_PrepareMessage(Handle hPlugin, int params) {
    char szIndent[64];
    GetNativeString(1, SZ(szIndent));

    int sender = GetNativeCell(2);
    int recipient = GetNativeCell(3)
    int max_params = GetNativeCell(4);

    char szBuffer[MAX_LENGTH];
    GetNativeString(5, SZ(szBuffer));

    char szNum[8];
    if(szBuffer[0] == '#') {
        if(!Call_HandleEngineMsg(szIndent, sender, szBuffer)) {
            return false;
        }
        
        Format(SZ(szBuffer), "%T", szBuffer, recipient);
    }

    if(max_params) {
        for(int i; i < max_params; i++) {
            FormatEx(szNum, sizeof(szNum), "{%i}", i+1);
            ReplaceString(
                SZ(szBuffer), szNum, 
                (i == 0) ? "%s1" 
                : (i == 1) ? "%s2" 
                : (i == 2) ? "%s3" 
                : (i == 3) ? "%s4" 
                : "%s5"
            );
        }
    }
    
    SetNativeString(5, SZ(szBuffer));
    return true;
}

public int Native_EndMessage(Handle hPlugin, int params) {
    int id = GetNativeCell(1);
    
    char szIndent[64];
    GetNativeString(2, SZ(szIndent));

    int sender = GetNativeCell(3);

    Call_MessageEnd(id, szIndent, sender);

    g_iMsgInProgress = -1;
}

public int Native_ReplaceColors(Handle hPlugin, int iArgs)
{
    char szBuffer[MAX_LENGTH];
    GetNativeString(1, szBuffer, sizeof(szBuffer));

    bool allTags = view_as<bool>(GetNativeCell(2));
    
    #if defined DEBUG
        DWRITE("%s: ReplaceColors(%b): %s", DEBUG, allTags, szBuffer);
    #endif

    if(!szBuffer[0]) {
        return;
    }

    char szKey[STATUS_LENGTH], szColor[STATUS_LENGTH];

    int i;
    while(i < g_aPalette.Length) {
        g_aPalette.GetString(i, szKey, sizeof(szKey));
        g_aPalette.GetString(i+1, szColor, sizeof(szColor));

        ReplaceString(SZ(szBuffer), szKey, (!allTags) ? szColor : NULL_STRING, true);
        if(allTags)
            ReplaceString(SZ(szBuffer), szColor, NULL_STRING, true);

        i+=2;
    }

    #if defined DEBUG
        DWRITE("%s: ReplaceColors Output(%b): %s", DEBUG, allTags, szBuffer);
    #endif

    SetNativeString(1, SZ(szBuffer));
}

public int Native_GetAPIKey(Handle hPlugin, int iArgs) {
    return API_KEY;
}

public int Native_IsAPIEqual(Handle hPlugin, int iArgs) {
    return GetNativeCell( 1 ) == API_KEY;
}

public any Native_DropPalette(Handle hPlugin, int iArgs) {
    return g_aPalette;
}

void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

Action Call_RebuildString(
    int id, const char[] indent,
    int sender, int recipient,
    int part, char[] szMessage, int iSize
) {
    Action output;
    bool block;
    int level;

    // Action Call
    Call_StartForward(g_fwdRebuildString);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(part);
    Call_PushCellRef(level);
    Call_PushStringEx(szMessage, iSize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(iSize);
    Call_Finish(output);

    // exclude post call
    if(output == Plugin_Stop)
        return output;

    BreakPoint(part, szMessage);

    // post call
    Call_StartForward(g_fwdRebuildString_Post);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(part);
    Call_PushCell(level);
    Call_PushString(szMessage);
    Call_Finish(block);

    if(output == Plugin_Continue && block) {
        output++;
    } 

    return output;
}

void Call_RebuildClients(
    int id, const char[] indent, 
    int sender, const char[] msg_key, 
    int[] clients, int &numClients
) {
    Call_StartForward(g_fwdRebuildClients);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushString(msg_key);
    Call_PushArrayEx(clients, numClients, SM_PARAM_COPYBACK);
    Call_PushCellRef(numClients);
    Call_Finish();
}

bool Call_HandleEngineMsg(const char[] indent, int sender, const char[] buffer) {
    bool handle = TranslationPhraseExists(buffer);

    Call_StartForward(g_fwdOnEngineMsg);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushString(buffer);
    Call_Finish(handle);

    return handle;
}

bool Call_IsSkipColors(const char[] indent, int sender) {
    bool skip = g_bRTP;

    Call_StartForward(g_fwdSkipColors);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_Finish(skip);

    return skip;
}

bool Call_NewMessage(const char[] indent, int sender, const char[] msg_key, int[] players, int playersNum) {
    bool start = true;

    Call_StartForward(g_fwdNewMessage);   
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushString(msg_key);
    Call_PushArray(players, playersNum);
    Call_PushCell(playersNum);
    Call_Finish(start);

    return start
}

void Call_MessageEnd(int id, const char[] indent, int sender) {
    Call_StartForward(g_fwdMessageEnd);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_Finish();
}