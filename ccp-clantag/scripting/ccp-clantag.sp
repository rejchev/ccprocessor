#pragma newdecls required

#include <ccprocessor>

#include <cstrike>

public Plugin myinfo = 
{
	name = "[CCP] Clan Tag as Chat Tag",
	author = "rejchev?",
	description = "...",
	version = "1.3.3",
	url = "discord.gg/ChTyPUG"
};

public void OnPluginStart()
{
    CreateConVar("ccp_clantag_priority", "1", "Priority for replacing the prefix value", _, true, 0.0).AddChangeHook(OnConVarChanged);

    AutoExecConfig(true, "clantag", "ccprocessor");
}

public void OnMapStart()
{
    cc_proc_APIHandShake(cc_get_APIKey());

    OnConVarChanged(FindConVar("ccp_clantag_priority"), NULL_STRING, NULL_STRING);
}

int plevel;

public void OnConVarChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    plevel = cvar.IntValue;
}

public Processing  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));

    if((szIndent[0] != 'S' && szIndent[1] != 'T' && strlen(szIndent) < 3) || !SENDER_INDEX(props[1])) {
        return Proc_Continue;
    } 

    if(part != BIND_PREFIX || level > plevel)
        return Proc_Continue;
    
    char szPrefix[PREFIX_LENGTH];
    szPrefix = GetClientClanTag(SENDER_INDEX(props[1]));

    if(!szPrefix[0])
        return Proc_Continue;
    
    level = plevel;
    FormatEx(value, size, szPrefix);

    return Proc_Change;
}

char[] GetClientClanTag(int iClient)
{
    char szTag[PREFIX_LENGTH];

    CS_GetClientClanTag(iClient, szTag, sizeof(szTag));

    return szTag;
}