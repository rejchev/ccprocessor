#pragma newdecls required

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
    g_fwdRebuildString_Post,
    g_fwdMessageEnd,
    g_fwdRebuildString_Sp;

bool 
    g_bRTP,
    g_bResetByMap;

int g_iMessageCount;
int g_iMsgInProgress = -1;

public Plugin myinfo = 
{
    name        = "[CCP] Core",
    author      = "rejchev",
    description = "Color chat processor",
    version     = "3.6.3",
    url         = "discord.gg/ChTyPUG"
};

#define SZ(%0) %0, sizeof(%0)

#include "ccprocessor/natives.sp"
#include "ccprocessor/forwards.sp"
#include "ccprocessor/defaults.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {    
    #if defined DEBUG
        DEBUG_BUILD()
    #endif

    CreateNative("cc_get_APIKey",                       Native_GetAPIKey);
    CreateNative("cc_is_APIEqual",                      Native_IsAPIEqual);
    CreateNative("cc_drop_palette",                     Native_DropPalette);
    CreateNative("ccp_replaceColors",                   Native_ReplaceColors);
    CreateNative("ccp_SkipColors",                      Native_SkipColors);
    CreateNative("ccp_ChangeMode",                      Native_ChangeMode);
    CreateNative("ccp_GetMessageID",                    Native_GetMsgID);
    CreateNative("ccp_Translate",                       Native_Translate);  
    CreateNative("ccp_StartNewMessage",                 Native_StartNewMessage);
    CreateNative("ccp_RebuildMessage",                  Native_RebuildMessage);
    CreateNative("ccp_RenderEngineCtx",                 Native_RenderEngineCtx);
    CreateNative("ccp_EndMessage",                      Native_EndMessage);
    CreateNative("ccp_EngineMsgRequest",                Native_EngineMessageReq);
    
    g_fwdConfigParsed = new GlobalForward(
        "cc_config_parsed", 
        ET_Ignore
    );

    g_fwdAPIHandShake = new GlobalForward(
        "cc_proc_APIHandShake", 
        ET_Ignore, Param_Cell
    );

    g_fwdSkipColors = new GlobalForward(
        "cc_proc_SkipColors", 
        ET_Event, Param_String, Param_Cell
    );

    g_fwdOnEngineMsg = new GlobalForward(
        "cc_proc_HandleEngineMsg",
        ET_Hook, Param_Array, Param_Cell, Param_Cell
    );

    g_fwdMessageEnd = new GlobalForward(
        "cc_proc_OnMessageEnd",
        ET_Ignore, Param_Array, Param_Cell, Param_Cell
    );
    
    g_fwdNewMessage = new GlobalForward(
        "cc_proc_OnNewMessage",
        ET_Hook, Param_Array, Param_Cell, Param_Cell
    );
    
    g_fwdRebuildString_Post = new GlobalForward(
        "cc_proc_OnRebuildString_Post",
        ET_Hook, Param_Array, Param_Cell, Param_Cell, Param_Cell, Param_String
    );
    
    g_fwdRebuildString = new GlobalForward(
        "cc_proc_OnRebuildString",
        ET_Hook, Param_Array, Param_Cell, Param_Cell, Param_CellByRef, Param_String, Param_Cell
    );

    g_fwdRebuildString_Sp = new GlobalForward(
        "cc_proc_OnRebuildString_Txt",
        ET_Ignore, Param_Array, Param_Cell, Param_Cell, Param_String, Param_Cell
    );

    RegPluginLibrary("ccprocessor");

    if(late) OnAllPluginsLoaded();

    return APLRes_Success;
}

public void OnPluginStart()
{
    #if defined DEBUG
        DEBUG_WRITE("%s: OnPluginStart()", DEBUG)
    #endif

    LoadTranslations("ccp_core.phrases");
    LoadTranslations("ccp_engine.phrases");

    g_aPalette = new ArrayList(STATUS_LENGTH, 0);
 
    game_mode = FindConVar("game_mode");
    if(!game_mode)
        return;

    game_mode.AddChangeHook(OnModChanged);
    game_mode.GetString(mode_default_value, sizeof(mode_default_value));

    #if defined DEBUG
        DEBUG_WRITE("%s: Game Mode(%x): %s", DEBUG, game_mode, mode_default_value);
    #endif
}

public void OnAllPluginsLoaded()
{
    Call_StartForward(g_fwdAPIHandShake);
    Call_PushCell(API_KEY);

    #if !defined DEBUG
        Call_Finish();
    #else
        DEBUG_WRITE("%s: Call(g_fwdAPIHandShake) code: %d", DEBUG, Call_Finish())
    #endif
    
}

public void OnModChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    cvar.GetString(mode_default_value, sizeof(mode_default_value));

    #if defined DEBUG
        DEBUG_WRITE("%s: Game Mode Changed(%x): %s", DEBUG, game_mode, mode_default_value);
    #endif
}

public void OnMapStart()
{
    #if defined DEBUG
        DBUILD()
    #endif

    #if defined DEBUG
        DEBUG_WRITE("%s: OnMapStart()", DEBUG);
    #endif
    
    static char dirs[][MESSAGE_LENGTH] = {
        "/cfg/ccprocessor", "data/ccprocessor"
    };

    if(dirs[1][0] == 'd')
        BuildPath(Path_SM, dirs[1], sizeof(dirs[]), dirs[1]);

    for(int i; i < sizeof(dirs); i++)
        if(!DirExists(dirs[i]))
            CreateDirectory(dirs[i], 0x1ED);
       

    g_aPalette.Clear();
    g_szSection = NULL_STRING;

    static char szConfig[MESSAGE_LENGTH] = "configs/ccprocessor/";
    GetConfigFileByGame(szConfig, sizeof(szConfig));

    if(!FileExists(szConfig))
        SetFailState("Where is my config: '%s' ", szConfig);
    
    #if defined DEBUG
        DEBUG_WRITE("%s: Game Config Path(): %s", DEBUG, szConfig);
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
        DEBUG_WRITE("%s: OnConfigsExecuted()", DEBUG);
    #endif
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
    g_szSection[strlen(g_szSection)] = name[0];

    #if defined DEBUG
        DEBUG_WRITE("%s: OnEnterSection(%x): %s", DEBUG, smc, name);
    #endif

    return SMCParse_Continue;
}

SMCResult OnLeave(SMCParser smc)
{
    g_szSection[strlen(g_szSection)-1] = 0;

    #if defined DEBUG
        DEBUG_WRITE("%s: OnLeave From Section(%x)", DEBUG, smc);
    #endif

    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] sKey, const char[] sValue, bool bKey_Quotes, bool bValue_quotes)
{
    if(!sKey[0] || !sValue[0])
        return SMCParse_Continue;

    int iBuffer;

    #if defined DEBUG
        DEBUG_WRITE("%s: OnKeyValue(%x): Key: %s, Value: %s", DEBUG, smc, sKey, sValue);
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
        DEBUG_WRITE("%s: OnCompReading(%x): Halted: %b, Failed: %b", DEBUG, smc, halted, failed);
    #endif

    g_szSection = NULL_STRING;

    Call_OnCompReading();

    if(halted || failed)
        SetFailState("There was a problem reading the configuration file");

    if(g_bResetByMap) {
        g_iMsgInProgress = -1;
        g_iMessageCount = 0;
    }
}

Processing BuildMessage(const int[] props, int propsCount, ArrayList params) {
    static const int compile = 4;

    char value[MESSAGE_LENGTH];

    Processing whatNext;

    char szBuffer[MAX_LENGTH];
    FormatEx(SZ(szBuffer), "%s", szBinds[BIND_PROTOTYPE]);
    
    for(int i; i < BIND_MAX; i++) {
        value = NULL_STRING;

        GetDefaultValue(props, propsCount, i, params, SZ(value));
        
        if((whatNext = Call_RebuildString(props, propsCount, i, params, SZ(value))) > Proc_Change) {
            #if defined DEBUG
                DEBUG_WRITE("%s: MessageBuilder(Rejected): \
                        \n\t\t\tSender: %d \
                        \n\t\t\tRecipient: %N \
                        \n\t\t\tPart: %s, \
                        \n\t\t\tCode: %d", DEBUG, SENDER_INDEX(props[1]), props[2], szBinds[i], whatNext);
            #endif

            return whatNext;
        }

        ReplaceString(SZ(szBuffer), szBinds[i], value, true);
    }

    #if defined DEBUG
    DEBUG_WRITE("%s: RebuildMessage(%N) out: %s", DEBUG, SENDER_INDEX(props[1]), szBuffer);
    #endif

    params.SetString(compile, szBuffer);
    return whatNext;
}

void RenderEngineCtx(const int[] props, int propsCount, ArrayList params) {
    static const int compile;
    
    char szMessage[MESSAGE_LENGTH];
    params.GetString(compile, SZ(szMessage));

    #if defined DEBUG
    DEBUG_WRITE("%s: HandleEngineMsg(%i) in: %s", DEBUG, props[0], szMessage);
    #endif

    char szNum[8];
    for(int i; i < props[2]; i++) {
        FormatEx(SZ(szNum), "{%i}", i+1);
            ReplaceString( 
                SZ(szMessage), szNum, 
                (i == 0) ? "%s1" 
                : (i == 1) ? "%s2" 
                : (i == 2) ? "%s3" 
                : (i == 3) ? "%s4" 
                : "%s5"
        );
    }

    #if defined DEBUG
    DEBUG_WRITE("%s: HandleEngineMsg(%i) out: %s", DEBUG, props[0], szMessage);
    #endif

    params.SetString(compile, szMessage);
}