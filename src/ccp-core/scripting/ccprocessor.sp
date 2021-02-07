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
    author      = "nyood",
    description = "Color chat processor",
    version     = "3.4.0",
    url         = "discord.gg/ChTyPUG"
};

#define SZ(%0) %0, sizeof(%0)

#include "ccprocessor/natives.sp"
#include "ccprocessor/forwards.sp"
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
    
    // int()
    CreateNative("ccp_GetMessageID",                    Native_GetMsgID);

    // bool(char[] phrase, int lang);
    CreateNative("ccp_Translate",                       Native_Translate);

    /* 
    int(int sender, ArryList params);
        param[0] = char[] indent;
        params[1] = const char[] template;
        params[2] = const char[] message;
        params[3] = const int[] players;
        params[4] = int playersNum;
    */  
    CreateNative("ccp_StartNewMessage",                 Native_StartNewMessage);

    /* 
    Action(const char[id, sender, ...] props, int propsCount, ArrayList params)
        prop[0] = int messageid;
        prop[1] = int sender;

        param[0] = const char[] indent;
        param[1] = const char[] message; ?
        param[2] = int[] players;
        param[3] = int &playersNum;
    */
    CreateNative("ccp_RebuildClients",                  Native_RebuildClients);

    /*
    Action(const char[] props, int propsCount, ArrayList params)
        prop[0] = int message id;
        prop[1] = int sender;
        prop[2] = int recipient;

        param[0] = const char[] indent;
        param[1] = const char[] template;
        param[2] = char[] name;
        param[3] = char[] msg;
        param[4] = char[] compile; 
    */
    CreateNative("ccp_RebuildMessage",                  Native_RebuildMessage);

    /*
    Action(const char[] props, int propsCount, ArrayList params)
        prop[0] = int sender;
        prop[1] = int recipient;
        prop[2] = int paramsCount;

        param[0] = char[] message;
    */
    CreateNative("ccp_HandleEngineMsg",                 Native_HandleEngineMsg);

    /*
    void(const char[] props, int propsCount, ArrayList params)
        prop[0] = int message id;
        prop[1] = int sender;

        param[0] = const char[] indent; 
    */
    CreateNative("ccp_EndMessage",                      Native_EndMessage);

    /*
    bool(const char[] props, int propsCount, ArrayList params)
        prop[0] = int message id;
        prop[1] = int sender;

        param[0] = const char[] indent; 
    */
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
    
    // bool(int sender, const char[] template, const char[] msg, char[] ident, int size, int[] players, int count) 
    g_fwdNewMessage = new GlobalForward(
        "cc_proc_OnNewMessage",
        ET_Event, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Array, Param_Cell
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

// todo
Action BuildMessage(const char[] props, int propsCount, ArrayList params) {
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
}

// todo
Action HandleEngineMsg(const char[] props, int propsCount, ArrayList params) {
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
}