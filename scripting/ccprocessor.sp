#pragma newdecls required

#define CORE

#define TEAM_SERVER 0
#define TEAM_SPEC   1
#define TEAM_R      2
#define TEAM_B      3

#include <ccprocessor>

UserMessageType umType;

StringMap 
    g_mMessage;

ArrayList
    g_aPalette;

char 
    msgPrototype[eMsg_MAX][MESSAGE_LENGTH],
    g_szSection[4];

ConVar game_mode;

char mode_default_value[8];

GlobalForward
    g_fwdSkipColors,
    g_fwdRebuildString,
    g_fwdOnDefMessage,
    g_fwdConfigParsed,
    g_fwdMessageUID,
    g_fwdAPIHandShake,
    g_fwdRebuildClients,
    g_fwdRebuildString_Post;

bool 
    g_bRTP,
    g_bResetByMap;

int g_iMsgIdx;

public Plugin myinfo = 
{
    name        = "CCProcessor",
    author      = "nullent?",
    description = "Color chat processor",
    version     = "3.3.3",
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

    CreateNative("cc_get_APIKey",                       Native_GetAPIKey);
    CreateNative("cc_is_APIEqual",                      Native_IsAPIEqual);
    CreateNative("cc_drop_palette",                     Native_DropPalette);
    CreateNative("cc_call_builder",                     Native_CallBuilder);
    CreateNative("ccp_replaceColors",                   Native_ReplaceColors);

    g_fwdConfigParsed       = 
        new GlobalForward("cc_config_parsed",           ET_Ignore);
    g_fwdAPIHandShake       = 
        new GlobalForward("cc_proc_APIHandShake",       ET_Ignore, Param_Cell);
    g_fwdSkipColors         = 
        new GlobalForward("cc_proc_SkipColorsInMsg",    ET_Hook, Param_Cell, Param_Cell);
    g_fwdOnDefMessage       = 
        new GlobalForward("cc_proc_OnDefMsg",           ET_Hook, Param_String, Param_Cell);
    g_fwdRebuildClients     = 
        new GlobalForward("cc_proc_RebuildClients",     ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_CellByRef);
    g_fwdRebuildString_Post = 
        new GlobalForward("cc_proc_RebuildString_Post", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
    g_fwdMessageUID         = 
        new GlobalForward("cc_proc_MsgUniqueId",        ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Cell);
    g_fwdRebuildString      = 
        new GlobalForward("cc_proc_RebuildString",      ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef, Param_String, Param_Cell);

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

    g_aPalette = new ArrayList(STATUS_LENGTH, 0);
    g_mMessage = new StringMap();

    {
        if(!DirExists("/cfg/ccprocessor"))
            CreateDirectory("/cfg/ccprocessor", 0x1ED);
    }

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

public void OnMapStart()
{
    g_aPalette.Clear();
    g_szSection = NULL_STRING;

    static char szConfig[MESSAGE_LENGTH] = "configs/ccprocessor/";
    GetConfigFileByGame(szConfig, sizeof(szConfig));
        
    if(!FileExists(szConfig))
        SetFailState("Where is my config: '%s' ", szConfig);

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
    g_szSection[strlen(g_szSection)] = name[0];
    return SMCParse_Continue;
}

SMCResult OnLeave(SMCParser smc)
{
    g_szSection[strlen(g_szSection)-1] = 0;
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] sKey, const char[] sValue, bool bKey_Quotes, bool bValue_quotes)
{
    if(!sKey[0] || !sValue[0])
        return SMCParse_Continue;

    int iBuffer;

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
        iBuffer =   (!strcmp(sKey, "Channel_Team"))         ? eMsg_TEAM     : 
                    (!strcmp(sKey, "Channel_All"))          ? eMsg_ALL      : 
                    (!strcmp(sKey, "Channel_NameChange"))   ? eMsg_CNAME    : 
                    (!strcmp(sKey, "Channel_Server"))       ? eMsg_SERVER   :
                    (!strcmp(sKey, "Channel_Radio"))        ? eMsg_RADIO    : -1;
        
        if(iBuffer != -1)
            strcopy(msgPrototype[iBuffer], sizeof(msgPrototype[]), sValue);

        else if(!strcmp(sKey, "UIDByMap"))
            g_bResetByMap = view_as<bool>(StringToInt(sValue));

        else if(!strcmp(sKey, "RTCP"))
            g_bRTP = view_as<bool>(StringToInt(sValue));
    }

    return SMCParse_Continue;
}

public void OnCompReading(SMCParser smc, bool halted, bool failed)
{
    delete smc;

    g_szSection = NULL_STRING;

    Call_OnCompReading();

    if(halted || failed)
        SetFailState("There was a problem reading the configuration file");

    if(g_bResetByMap)
        g_iMsgIdx = 0;
}

void ReplaceColors(char[] szBuffer, int iSize, bool bToNullStr)
{
    char
        szKey[STATUS_LENGTH],
        szColor[STATUS_LENGTH];

    int i;
    while(i < g_aPalette.Length) {
        g_aPalette.GetString(i, szKey, sizeof(szKey));
        g_aPalette.GetString(i+1, szColor, sizeof(szColor));

        ReplaceString(szBuffer, iSize, szKey, (!bToNullStr) ? szColor : NULL_STRING, true);
        if(bToNullStr)
            ReplaceString(szBuffer, iSize, szColor, NULL_STRING, true);

        i+=2;
    }
}

void prepareDefMessge(int params, int recipient, char[] szMessage, int size)
{
    char szNum[8];
    if(szMessage[0] == '#')
        Format(szMessage, size, "%T", szMessage, recipient);

    if(!params) {
        return;
    }
    
    for(int i = 1; i < params; i++)
    {
        FormatEx(szNum, sizeof(szNum), "{%i}", i);
        ReplaceString(szMessage, size, szNum, (i == 1) ? "%s1" : (i == 2) ? "%s2" : (i == 3) ? "%s3" : "%s4");
    }
}

// Edited
bool RebuildMessage(
    int msgType,
    int msgSender,
    int msgRecipient,

    const char[] name,
    const char[] msg,

    char[] buffer,
    int size,

    const char[] option = NULL_STRING
)
{
    FormatEx(buffer, size, "%c %s", 1, szBinds[BIND_PROTOTYPE]);
    
    static bool isAlive;
    static int team;
    static char value[MESSAGE_LENGTH];

    isAlive = (msgType != eMsg_SERVER) ? view_as<bool>(msgSender & 0x01) : false;
    team = (msgType != eMsg_SERVER) ? (msgSender >> 1) & 0x03 : TEAM_SPEC;

    msgSender >>= 3;
    
    for(int i; i < BIND_MAX; i++)
    {
        value = NULL_STRING;

        GetDefaultValue(i, msgRecipient, msgType, team, isAlive, name, msg, SZ(value));
        
        if(Call_RebuildString(msgType, msgSender, msgRecipient, i, SZ(value)) != Plugin_Continue)
            return false;

        ReplaceString(buffer, size, szBinds[i], value, true);
    }

    return !(option[0] == 'd' && option[1] == 'e' && option[2] == 'v' && strlen(option) == 3);
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

void UpdateRecipients(const any[] input, any[] output, int &count)
{
    int a;

    for(int i; i < count; i++) {
        if(!IsClientConnected(input[i]) || (IsFakeClient(input[i]) && !IsClientSourceTV(input[i]))) {
            continue;
        }

        output[a++] = input[i];  
    }

    count = a;        
}

stock void ClearCharArray(char[][] array, int size)
{
    for(int i; i < size; i++)
        array[i][0] = 0;
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
    return g_aPalette;
}

public int Native_CallBuilder(Handle hPlugin, int iArgs)
{
    int
        iClient = GetNativeCell(2),
        iType = GetNativeCell(1),
        iRecipient = GetNativeCell(3);
    
    char
        szName[NAME_LENGTH],
        szMessage[MESSAGE_LENGTH],
        szBuffer[MAX_LENGTH],
        szUM[64];
    
    // Not now
    // GetNativeString(3, szUM, sizeof(szUM));
    if(!szUM[0])
        szUM = "dev";

    GetNativeString(5, szName, sizeof(szName));
    GetNativeString(6, szMessage, sizeof(szMessage));

    RebuildMessage(iType, iClient, iRecipient, szName, szMessage, szBuffer, sizeof(szBuffer), szUM);

    SetNativeString(7, szBuffer, sizeof(szBuffer));
}

void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

Action Call_RebuildString(const int mType, const int sender, const int recipient, const int iBind, char[] szMessage, int iSize)
{
    Action output;
    bool block;
    int level;

    // Action Call
    Call_StartForward(g_fwdRebuildString);
    Call_PushCell(mType);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(iBind);
    Call_PushCellRef(level);
    Call_PushStringEx(szMessage, iSize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(iSize);
    Call_Finish(output);

    // exclude post call
    if(output == Plugin_Stop)
        return output;

    BreakPoint(iBind, szMessage);

    // post call
    Call_StartForward(g_fwdRebuildString_Post);
    Call_PushCell(mType);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(iBind);
    Call_PushCell(level);
    Call_PushString(szMessage);
    Call_Finish(block);

    if(output == Plugin_Continue && block) {
        output++;
    } 

    return output;
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

Action Call_OnDefMessage(const char[] szMessage, bool IsPhraseExists)
{
    Action Send = (IsPhraseExists) ? Plugin_Changed : Plugin_Continue;

    Call_StartForward(g_fwdOnDefMessage);

    Call_PushString(szMessage);
    Call_PushCell(IsPhraseExists);

    Call_Finish(Send);

    return Send;
}

bool Call_IsSkipColors(const int mType, int iClient)
{
    bool skip = g_bRTP;

    Call_StartForward(g_fwdSkipColors);
    Call_PushCell(mType);
    Call_PushCell(iClient);
    Call_Finish(skip);

    return skip;
}

void Call_OnNewMessage(const int mType, const int sender, const char[] message, const int[] clients, int count)
{
    g_iMsgIdx++;

    Call_StartForward(g_fwdMessageUID);
    
    Call_PushCell(mType);
    Call_PushCell(sender);
    Call_PushCell(g_iMsgIdx);
    Call_PushString(message);
    Call_PushArray(clients, count);
    Call_PushCell(count);

    Call_Finish();
}