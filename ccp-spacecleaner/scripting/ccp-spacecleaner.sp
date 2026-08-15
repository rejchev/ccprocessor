#pragma newdecls required

#include <jansson>
#include <ccprocessor>

public Plugin myinfo = 
{
	name = "[CCP] Space Messages",
	author = "nullent?",
	description = "...",
	version = "2.0.0",
	url = "discord.gg/ChTyPUG"
};

JsonObject objConfig;

public void OnMapStart() {
    cc_proc_APIHandShake(cc_get_APIKey());

    static char szBuffer[MESSAGE_LENGTH] = "configs/ccprocessor/space-msgs/settings.json";
    if(szBuffer[0] == 'c') {
        BuildPath(Path_SM, szBuffer, sizeof(szBuffer), szBuffer);
    } else if(!FileExists(szBuffer)) {
        SetFailState("Where is my config: %s", szBuffer);
    }

    delete objConfig;
    objConfig = asJSONO(Json.JsonF(szBuffer, 0));
}

public Processing cc_proc_OnRebuildString_Post(const int[] props, int part, ArrayList params, int level, const char[] value) {
    if(part != BIND_MSG) {
        return Proc_Continue;
    }

    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));
    if(!objConfig.HasKey(szIndent)) {
        LogMessage("'%s' channel skipped. Add this channel to: configs/ccprocessor/space-msgs/settings.json", szIndent);
        return Proc_Continue;
    }

    if(!objConfig.GetBool(szIndent)) {
        for(int i; i < strlen(value); i++) {
            if(value[i] >= 33) {
                return Proc_Continue;
            }
        }

        return Proc_Stop;
    }

    return Proc_Continue;
}

