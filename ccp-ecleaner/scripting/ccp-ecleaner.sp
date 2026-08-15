#pragma newdecls required

#if defined INCLUDE_DEBUG
    #define DEBUG "[EngineMsg-Cleaner]"
#endif

#include <ccprocessor>

public Plugin myinfo = 
{
	name = "[CCP] EngineMsg Cleaner",
	author = "nu11ent",
	description = "...",
	version = "1.0.1",
	url = "https://t.me/nyoood"
};

ArrayList g_aEngineMsgList;

public void OnPluginStart() {
    g_aEngineMsgList = new ArrayList(MESSAGE_LENGTH, 0);
}

public void OnMapStart() {
    static char config[MESSAGE_LENGTH] = "configs/ccprocessor/enginemsg-cleaner/stash.txt";

    if(config[0] == 'c') {
        BuildPath(Path_SM, config, sizeof(config), config);
    } 

    if(!FileExists(config)) {
        SetFailState("Stash file is not exists: %s", config);
    }

    g_aEngineMsgList.Clear();

    File hFile = OpenFile(config, "r");
    if(!hFile) {
        return;
    }

    char szBuffer[MESSAGE_LENGTH];
    while(!hFile.EndOfFile() && hFile.ReadLine(szBuffer, sizeof(szBuffer))) {
        TrimString(szBuffer);

        if(!szBuffer[0] || (szBuffer[0] == '/' && szBuffer[1] == '/')) {
            continue;
        }

        g_aEngineMsgList.PushString(szBuffer);
    }

    delete hFile;
}

public Processing cc_proc_HandleEngineMsg(const int[] props, int propsCount, ArrayList params) {
    char szBuffer[MESSAGE_LENGTH];
    params.GetString(0, szBuffer, sizeof(szBuffer));

    return g_aEngineMsgList.FindString(szBuffer) == -1 ? Proc_Continue : Proc_Stop;
}