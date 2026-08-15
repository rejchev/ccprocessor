/*
    Leaves an entry in the log about the engine message key, 
    in the case when it does not exist or does not have a translation for the server language in the library of phrases
*/

#pragma newdecls required

#include <ccprocessor>

public void OnMapStart()
{
    cc_proc_APIHandShake(cc_get_APIKey());
}

public Processing cc_proc_HandleEngineMsg(const int[] props, int propsCount, ArrayList params)
{
    char szMessage[MESSAGE_LENGTH];
    params.GetString(0, szMessage, sizeof(szMessage));

    LogMessage("Engine message key: %s | Is phrase exists: %b ", szMessage, ccp_Translate(szMessage, props[1]));
    
    return Proc_Continue;
}