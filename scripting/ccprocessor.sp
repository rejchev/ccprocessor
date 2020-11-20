#pragma newdecls required

#define CORE

#define TEAM_SERVER 0
#define TEAM_SPEC   1
#define TEAM_R      2
#define TEAM_B      3

#include <ccprocessor>
#include <regex>

static char g_szLogEx[MESSAGE_LENGTH] = "logs/ccprocessor"

UserMessageType umType;

// Slow solution, but I think it's worth it ....
StringMap 
    g_mPalette,
    g_mMessage;

StringMapSnapshot
    g_snapPalette;

char 
    msgPrototype[eMsg_MAX][MESSAGE_LENGTH];

ConVar game_mode;

char mode_default_value[8];

GlobalForward
    g_fwdSkipColors,
    g_fwdRebuildString,
    g_fwdOnDefMessage,
    g_fwdConfigParsed,
    g_fwdMessageUID,
    g_fwdOnMsgBuilt,
    g_fwdIdxApproval,
    g_fwdRestrictRadio,
    g_fwdAPIHandShake,
    g_fwdRebuildClients,
    g_fwdRebuildString_Post;

bool g_bRTP, g_bDBG, g_bResetByMap;

int Section, g_iMsgIdx;

public Plugin myinfo = 
{
    name        = "CCProcessor",
    author      = "nullent?",
    description = "Color chat processor",
    version     = "3.2.1",
    url         = "discord.gg/ChTyPUG"
};

#define SZ(%0) %0, sizeof(%0)

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{    
    umType = GetUserMessageType();

    HookUserMessage(GetUserMessageId("TextMsg"), UserMessage_TextMsg, true);
    HookUserMessage(GetUserMessageId("SayText"), UserMessage_SayText, true);
    HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true, SayText2_Completed);
    HookUserMessage(GetUserMessageId("RadioText"), UserMessage_RadioText, true, RadioText_Completed);

    CreateNative("cc_drop_palette", Native_DropPalette);

    // Will be removed in the next version
    CreateNative("cc_clear_allcolors", Native_ClearAllColors);
    CreateNative("ccp_replaceColors", Native_ReplaceColors);

    CreateNative("cc_get_APIKey", Native_GetAPIKey);
    CreateNative("cc_is_APIEqual", Native_IsAPIEqual);
    CreateNative("cc_call_builder", Native_CallBuilder);

    g_fwdSkipColors         = new GlobalForward("cc_proc_SkipColorsInMsg", ET_Hook, Param_Cell, Param_Cell);
    g_fwdRebuildString      = new GlobalForward(
        "cc_proc_RebuildString", ET_Ignore, Param_Cell, Param_Cell, Param_CellByRef, Param_String, Param_String, Param_Cell
    );

    g_fwdRebuildString_Post = new GlobalForward(
        "cc_proc_RebuildString_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String
    );

    g_fwdOnDefMessage       = new GlobalForward("cc_proc_OnDefMsg", ET_Hook, Param_String, Param_Cell, Param_Cell);
    g_fwdConfigParsed       = new GlobalForward("cc_config_parsed", ET_Ignore);
    g_fwdMessageUID         = new GlobalForward("cc_proc_MsgUniqueId", ET_Ignore, Param_Cell);
    g_fwdOnMsgBuilt         = new GlobalForward("cc_proc_OnMessageBuilt", ET_Ignore, Param_Cell, Param_Cell, Param_String);
    g_fwdIdxApproval        = new GlobalForward("cc_proc_IndexApproval", ET_Ignore, Param_Cell, Param_CellByRef);
    g_fwdRestrictRadio      = new GlobalForward("cc_proc_RestrictRadio", ET_Hook, Param_Cell, Param_String);
    g_fwdAPIHandShake       = new GlobalForward("cc_proc_APIHandShake", ET_Ignore, Param_Cell);
    g_fwdRebuildClients     = new GlobalForward("cc_proc_RebuildClients", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_CellByRef);

    RegPluginLibrary("ccprocessor");

    if(late) OnAllPluginsLoaded();

    return APLRes_Success;
}

#include "ccprocessor/ccp_saytext2.sp"
#include "ccprocessor/ccp_saytext.sp"
#include "ccprocessor/ccp_textmsg.sp"
#include "ccprocessor/ccp_radiomsg.sp"

public void OnPluginStart()
{
    LoadTranslations("ccproc.phrases");
    LoadTranslations("ccp_defmessage.phrases");

    g_mPalette = new StringMap();
    g_mMessage = new StringMap();

    {
        if(!DirExists("/cfg/ccprocessor"))
            CreateDirectory("/cfg/ccprocessor", 0x1ED);
    }
    
    (game_mode = CreateConVar("ccp_color_RTP", "0", "Enable/Disable color real time processing", _, true, 0.0, true, 1.0)).AddChangeHook(CCP_RTP);
    CCP_RTP(game_mode, NULL_STRING, NULL_STRING);

    delete game_mode;
    
    AutoExecConfig(true, "core", "ccprocessor");

    game_mode = FindConVar("game_mode");
    if(!game_mode)
        return;

    game_mode.AddChangeHook(OnModChanged);
    game_mode.GetString(mode_default_value, sizeof(mode_default_value));
}

public void OnAllPluginsLoaded()
{
    Call_StartForward(g_fwdAPIHandShake);
    Call_PushCell(API_KEY);
    Call_Finish();
}

public void OnModChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    cvar.GetString(mode_default_value, sizeof(mode_default_value));
}

public void CCP_RTP(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    g_bRTP = cvar.BoolValue;
}

public void OnMapStart()
{
    LOG_WRITE("OnMapStart(): -----------------------------------------------");

    UpdateLogFile();

#define SETTINGS_PATH "configs/ccprocessor/%s.ini"

    static char szConfig[MESSAGE_LENGTH];

    if(!szConfig[0])
    {
        GetGameFolderName(SZ(szConfig));
        Format(SZ(szConfig), SETTINGS_PATH, szConfig);

        BuildPath(Path_SM, SZ(szConfig), szConfig);
    }

    if(!FileExists(szConfig))
        SetFailState("Where is my config: %s ", szConfig);

    g_mPalette.Clear();
    Section = 0;
    
    SMCParser smParser = new SMCParser();
    smParser.OnKeyValue = OnKeyValue;
    smParser.OnEnterSection = OnEnterSection;
    smParser.OnEnd = OnCompReading;
    smParser.OnLeaveSection = OnLeave;

    int iLine;
    if(smParser.ParseFile(szConfig, iLine) != SMCError_Okay)
        LogError("An error was detected on line '%i' while reading", iLine);
    
    LOG_WRITE("OnMapStart(): Config: %s, Pallete map: %x, Parser: %x", szConfig, g_mPalette, smParser);
}

public void UpdateLogFile()
{
#define LOG_TEMPLATE "logs/ccprocessor/day_%j.log"

    FormatTime(g_szLogEx, sizeof(g_szLogEx), LOG_TEMPLATE, GetTime());
    BuildPath(Path_SM, g_szLogEx, sizeof(g_szLogEx), g_szLogEx);
}

public void OnConfigsExecuted()
{
    if(game_mode)
        game_mode.Flags |= FCVAR_REPLICATED;
}

void ChangeModeValue(int[] clients, int count, const char[] value)
{
    if(!game_mode)
        return;

    for(int i; i < count; i++)
    {
        if(IsFakeClient(clients[i]))
            SetFakeClientConVar(clients[i], "game_mode", value);
        
        else game_mode.ReplicateToClient(clients[i], value);
    }
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
    LOG_WRITE("OnEnterSection(): %s", name);
        
    Section++;

    return SMCParse_Continue;
}

SMCResult OnLeave(SMCParser smc)
{
    LOG_WRITE("OnLeave()");

    Section--;

    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] sKey, const char[] sValue, bool bKey_Quotes, bool bValue_quotes)
{
    if(!sKey[0] || !sValue[0])
        return SMCParse_Continue;

    int iBuffer;

    if(Section > 1)
    {
        char szBuffer[STATUS_LENGTH];
        strcopy(szBuffer, sizeof(szBuffer), sValue);

        iBuffer = strlen(szBuffer);

        switch(iBuffer)
        {
            // Defined ASCII colors
            case 1, 2: Format(szBuffer, sizeof(szBuffer), "%c", StringToInt(szBuffer));

            // Colors based RGB/RGBA into HEX format: #RRGGBB/#RRGGBBAA
            case 7, 9: FormatEx(szBuffer, sizeof(szBuffer), "%c%s", (iBuffer == 7) ? 7 : 8, szBuffer[1]);

            default: 
            {
                LogError("Invalid color length for value: %s", szBuffer);
                return SMCParse_Continue;
            }
        }

        g_mPalette.SetString(sKey, szBuffer, true);

        LOG_WRITE("OnKeyValue(): ReadKey: %s, Value[0]: %s", sKey, szBuffer);
    }

    else
    {
        iBuffer =   (!strcmp(sKey, "Chat_PrototypeTeam"))   ? eMsg_TEAM : 
                    (!strcmp(sKey, "Chat_PrototypeAll"))    ? eMsg_ALL : 
                    (!strcmp(sKey, "Changename_Prototype")) ? eMsg_CNAME : 
                    (!strcmp(sKey, "Chat_ServerTemplate"))  ? eMsg_SERVER :
                    (!strcmp(sKey, "Chat_RadioText"))       ? eMsg_RADIO : -1;
        
        if(iBuffer != -1)
            strcopy(msgPrototype[iBuffer], sizeof(msgPrototype[]), sValue);
        
        else if(!strcmp(sKey, "DebugMode"))
            g_bDBG = view_as<bool>(StringToInt(sValue));
        
        else if(!strcmp(sKey, "UIDByMap"))
            g_bResetByMap = view_as<bool>(StringToInt(sValue));

        LOG_WRITE("OnKeyValue(): ReadKey: %s, Value: %s", sKey, sValue);
    }

    return SMCParse_Continue;
}

public void OnCompReading(SMCParser smc, bool halted, bool failed)
{
    smc.Close();

    Call_OnCompReading();

    if(halted || failed)
        SetFailState("There was a problem reading the configuration file");

    if(g_bResetByMap)
        g_iMsgIdx = 0;

    if(g_snapPalette)
        delete g_snapPalette;

    g_snapPalette = g_mPalette.Snapshot();
}

void ReplaceColors(char[] szBuffer, int iSize, bool bToNullStr)
{
    char szKey[STATUS_LENGTH], szColor[STATUS_LENGTH];

    for(int i; i < g_snapPalette.Length; i++)
    {
        g_snapPalette.GetKey(i, szKey, sizeof(szKey));
        g_mPalette.GetString(szKey, szColor, sizeof(szColor));

        ReplaceString(szBuffer, iSize, szKey, (!bToNullStr) ? szColor : NULL_STRING, true);

        if(bToNullStr)
            ReplaceString(szBuffer, iSize, szColor, NULL_STRING, true);
    }
}

void RebuildMessage(int iIndex, int iType, const char[] szName, const char[] szMessage, char[] szBuffer, int iSize, const char[] um = NULL_STRING)
{
    FormatEx(szBuffer, iSize, "%c %s", 1, szBinds[BIND_PROTOTYPE]);

    LOG_WRITE("RebuildMessage(%s): Idx: %i, Type: %i, Name: %s, In: %s, Out: %s, size: %i", um, iIndex, iType, szName, szMessage, szBuffer, iSize);
    
    int iTeam = TEAM_SPEC;
    bool IsAlive;

    char szOther[MESSAGE_LENGTH];

    if(iType != eMsg_SERVER)
    {
        iTeam = GetClientTeam(iIndex);
        IsAlive = IsPlayerAlive(iIndex);
    }
    
    // Not sure, but the server should survive this. Yes there will be a flood...
    for(int i, level; i < BIND_MAX; i++)
    {
        szOther = NULL_STRING;

        if(iType == eMsg_RADIO && i == BIND_MSG)
            continue;

        GetDefaultValue(i, LANG_SERVER, iType, iTeam, IsAlive, szName, szMessage, SZ(szOther));
        
        Call_RebuildString(iType, iIndex, level, szBinds[i], szOther, sizeof(szOther));

        BreakPoint(i, szOther);
        
        if(i == BIND_MSG || !i)
        {
            TrimString(szOther);

            if(!szOther[0])
            {
                szBuffer[0] = 0;
                return;
            }
        }

        Call_RebuildString_Post(iType, iIndex, level, szBinds[i], szOther);

        ReplaceString(szBuffer, iSize, szBinds[i], szOther, true);
    }

    LOG_WRITE("RebuildedMessage(): %s", szBuffer);

    // Fake messages on the way
    if(um[0] == 'd' && um[1] == 'e' && um[2] == 'v' && strlen(um) == 3)
        szBuffer[0] = 0;
}

void GetDefaultValue(int iBind, int iLangValue, int iMessageType, int iSenderTeam, bool bAlive, const char[] szName, const char[] szMessage, char[] szBuffer, int size)
{
    switch(iBind)
    {
        case BIND_PROTOTYPE: {
            strcopy(szBuffer, size, msgPrototype[iMessageType]);
        }
        case BIND_STATUS_CO, BIND_STATUS: {
            GetStatusDefault(iBind, iLangValue, iMessageType, bAlive, szBuffer, size);
        }
        case BIND_TEAM_CO, BIND_TEAM: {
            GetTeamDefault(iBind, iLangValue, iSenderTeam, iMessageType, szBuffer, size);
        }
        case BIND_PREFIX_CO, BIND_PREFIX: {
            GetPrefixDefault(iBind, iLangValue, iMessageType, szBuffer, size);
        }
        case BIND_NAME_CO, BIND_NAME: {
            GetNameDefault(iBind, iLangValue, iMessageType, szName, szBuffer, size);
        }
        case BIND_MSG_CO, BIND_MSG: {
            GetMsgDefault(iBind, iLangValue, iMessageType, szMessage, szBuffer, size);
        }
    }        
}

void GetStatusDefault(int part, int lang, int mtype, bool alive, char[] szBuffer, int size) {

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{ALIVE}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (alive) ? "A" : "D"
    ));

    // DEF_{BIND}_D_S
    if(mtype == eMsg_SERVER) {
        Format(szBuffer, size, "%s_S", szBuffer);
    }

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetTeamDefault(int part, int iLangI, int iTeam, int iType, char[] szBuffer, int size) {

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{TYPE}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (iType == eMsg_TEAM)    ? "P" : 
        (iType == eMsg_ALL)     ? "A" :
        (iType == eMsg_CNAME)   ? "C" :
        (iType == eMsg_RADIO)   ? "R" : "S"
    ));

    // DEF_{BIND}_{TYPE}_{TEAM}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (iTeam == TEAM_B) ? "B" : (iTeam == TEAM_R) ? "R" : "S"
    ));

    if(!TranslationPhraseExists(szBuffer)) {
        szBuffer[0] = 0;
        return;
    }
    
    Format(szBuffer, size, "%T", szBuffer, iLangI);
}

void GetPrefixDefault(int part, int lang, int mtype, char[] szBuffer, int size) {
    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (mtype != eMsg_SERVER) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetNameDefault(int part, int lang, int mtype, const char[] name, char[] szBuffer, int size) {
    if(part == BIND_NAME) {
        strcopy(szBuffer, size, name);
        return;
    }

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (mtype != eMsg_SERVER) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetMsgDefault(int part, int lang, int mtype, const char[] msg, char[] szBuffer, int size) {
    if(part == BIND_MSG) {
        strcopy(szBuffer, size, msg);
        return;
    }

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (mtype != eMsg_SERVER) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void LOG_WRITE(const char[] szMessage, any ...)
{
    if(!g_bDBG)
        return;

    static Regex hExp;
    if(!hExp)
        hExp = new Regex("\\%\\d*?\\.?\\d*?[idsfcxNLt]", PCRE_CASELESS|PCRE_UTF8);

    if(!FileExists(g_szLogEx))
    {
        ReplaceString(g_szLogEx, sizeof(g_szLogEx), "\\", "/");

        int pos = FindCharInString(g_szLogEx, '/', true);

        g_szLogEx[pos] = 0;

        if(!DirExists(g_szLogEx))
            CreateDirectory(g_szLogEx, 0x1ED);
        
        g_szLogEx[pos] = '/';
    }
    
    static char szBuffer[1024];

    VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);

    int MhCount = hExp.MatchAll(szBuffer);

    if(MhCount > 0)
    {
        char szMatch[32], szRp[8];

        for(int i; i < MhCount; i++)
        {
            if(hExp.GetSubString(0, szMatch, sizeof(szMatch), i))
            {
                TrimString(szMatch);
                FormatEx(szRp, sizeof(szRp), "{%s}", szMatch[strlen(szMatch) - 1]);
                ReplaceString(szBuffer, sizeof(szBuffer), szMatch, szRp);
            }  
        }
    }

    LogToFileEx(g_szLogEx, szBuffer);
}

void CopyEqualArray(const any[] input, any[] output, int &count)
{
    int a;

    for(int i; i < count; i++)
    {
        if(IsClientConnected(input[i]) && (!IsFakeClient(input[i]) || IsClientSourceTV(input[i])))
            output[a++] = input[i];
    }

    count = a;        
}

void ClearCharArray(char[][] array, int size)
{
    for(int i; i < size; i++)
        array[i][0] = 0;
}

// Will be removed in the next version
public int Native_ClearAllColors(Handle hPlugin, int iArgs)
{
    char szBuffer[MESSAGE_LENGTH];
    GetNativeString(1, SZ(szBuffer));

    ReplaceColors(SZ(szBuffer), true);

    SetNativeString(1, SZ(szBuffer));
}

public int Native_ReplaceColors(Handle hPlugin, int iArgs)
{
    char szBuffer[MAX_LENGTH];
    GetNativeString(1, SZ(szBuffer));

    ReplaceColors(SZ(szBuffer), view_as<bool>(GetNativeCell(2)));

    SetNativeString(1, SZ(szBuffer));
}

public int Native_GetAPIKey(Handle hPlugin, int iArgs)
{
    return API_KEY;
}

public int Native_IsAPIEqual(Handle hPlugin, int iArgs)
{
    return GetNativeCell( 1 ) == API_KEY;
}

public any Native_DropPalette(Handle hPlugin, int iArgs)
{
    return g_mPalette;
}

public int Native_CallBuilder(Handle hPlugin, int iArgs)
{
    LOG_WRITE("Native_CallBuilder(%x)", hPlugin);

    int
        iClient = GetNativeCell(1),
        iType = GetNativeCell(2);
    
    char
        szName[NAME_LENGTH],
        szMessage[MESSAGE_LENGTH],
        szBuffer[MAX_LENGTH],
        szUM[64];
    
    // Not now
    // GetNativeString(3, szUM, sizeof(szUM));
    if(!szUM[0])
        szUM = "dev";

    GetNativeString(4, szName, sizeof(szName));
    GetNativeString(5, szMessage, sizeof(szMessage));

    RebuildMessage(iClient, iType, szName, szMessage, szBuffer, sizeof(szBuffer), szUM);

    SetNativeString(6, szBuffer, sizeof(szBuffer));
}

void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

void Call_RebuildString(const int mType, int iClient, int &pLevel, const char[] szBind, char[] szMessage, int iSize)
{
    pLevel = 0;

    LOG_WRITE("Call_RebuildString(%i:%i -> %s): %s [%i]", iClient, mType, szBind, szMessage, iSize);

    Call_StartForward(g_fwdRebuildString);
    Call_PushCell(mType);
    Call_PushCell(iClient);
    Call_PushCellRef(pLevel);
    Call_PushString(szBind);
    Call_PushStringEx(szMessage, iSize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(iSize);
    Call_Finish();
}

void Call_RebuildString_Post(const int mType, int iClient, int pLevel, const char[] szBind, const char[] szMessage)
{
    LOG_WRITE("Call_RebuildString_Post(%i:%i:%i -> %s): %s [%i]", iClient, mType, pLevel, szBind, szMessage, strlen(szMessage));

    Call_StartForward(g_fwdRebuildString_Post);
    
    Call_PushCell(mType);
    Call_PushCell(iClient);
    Call_PushCell(pLevel);
    Call_PushString(szBind);
    Call_PushString(szMessage);

    Call_Finish();
}

void Call_RebuildClients(const int mType, int iClient, int[] clients, int &numClients)
{
    Call_StartForward(g_fwdRebuildClients);

    Call_PushCell(mType);
    Call_PushCell(iClient);
    Call_PushArrayEx(clients, numClients, SM_PARAM_COPYBACK);
    Call_PushCellRef(numClients);

    Call_Finish();
}

Action Call_OnDefMessage(const char[] szMessage, bool IsPhraseExists, bool IsTranslated)
{
    Action Send = (IsTranslated && IsPhraseExists) ? Plugin_Changed : Plugin_Continue;

    Call_StartForward(g_fwdOnDefMessage);
    Call_PushString(szMessage);
    Call_PushCell(IsPhraseExists);
    Call_PushCell(IsTranslated);

    Call_Finish(Send);

    LOG_WRITE("Call_OnDefMessage(): %s, %b, %b, result: %d", szMessage, IsPhraseExists, IsTranslated, Send);

    return Send;
}

bool Call_IsSkipColors(const int mType, int iClient)
{
    bool skip = g_bRTP;

    Call_StartForward(g_fwdSkipColors);
    Call_PushCell(mType);
    Call_PushCell(iClient);
    Call_Finish(skip);

    LOG_WRITE("Call_IsSkipColors(): %i, %b", iClient, skip);

    return skip;
}

void Call_OnNewMessage()
{
    g_iMsgIdx++;

    LOG_WRITE("Call_OnNewMsg(): %i", g_iMsgIdx);

    Call_StartForward(g_fwdMessageUID);
    Call_PushCell(g_iMsgIdx);
    Call_Finish();
}

void Call_IndexApproval(const int mType, int &iIndex)
{
    int back = iIndex;

    Call_StartForward(g_fwdIdxApproval);
    Call_PushCell(mType);
    Call_PushCellRef(iIndex);
    Call_Finish();

    if(iIndex < 1)
        iIndex = back;

    LOG_WRITE("Call_IndexApproval(): %i, %i", iIndex, back);
}

void Call_MessageBuilt(const int mType, int iIndex, const char[] BuiltMessage)
{
    LOG_WRITE("Call_MessageBuilt(): %i, %s", iIndex, BuiltMessage);

    Call_StartForward(g_fwdOnMsgBuilt);
    Call_PushCell(mType);
    Call_PushCell(iIndex);
    Call_PushString(BuiltMessage)
    Call_Finish();
}

bool Call_RestrictRadioKey(int iIndex, const char[] szKey)
{
    LOG_WRITE("Call_RestrictRadioKey(): %i, %s", iIndex, szKey);

    bool restrict;

    Call_StartForward(g_fwdRestrictRadio);
    Call_PushCell(iIndex);
    Call_PushString(szKey)
    Call_Finish(restrict);

    return restrict;
}