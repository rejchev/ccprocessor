#pragma newdecls required

#include <ccprocessor/modules/channels/ccp-channels>

public Plugin myinfo = 
{
    name = "[CCP] Channels Filter",
    author = "rej.chev",
    description = "...",
    version = "2.0.0",
    url = "https://t.me/nyoood"
};

static const char pkgKey[] = "channels_filter";

bool g_bLate;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    g_bLate = late;
    return APLRes_Success;
}

public void OnPluginStart() {
    LoadTranslations("ccp_channels.phrases");
    RegConsoleCmd("sm_channels", cmd);
}

public void OnMapStart() {
    // Handshake
    cc_proc_APIHandShake(cc_get_APIKey());

    // late load
    if(g_bLate) {
        g_bLate = false;

        for(int i; i <= MaxClients; i++)
            if(Packager.GetPackage(i))
                pckg_OnPackageAvailable(i);
    }
}

public void pckg_OnPackageAvailable(int iClient) {
    if(!iClient)
        return;

    if(!Packager.GetPackage(iClient).SetArtifact(pkgKey, new Json("[]"), freeAnyway))
        SetFailState("Something went wrong on set artifact '%s' for client %d", pkgKey, iClient);
}

Action cmd(int iClient, int args) {
    if(!iClient || !IsClientInGame(iClient))
        return Plugin_Handled;

    Package pack;
    if(!(pack = Packager.GetPackage(iClient)))
        return Plugin_Handled;

    JsonArray objChannels;
    JsonArray objClientFilter;

    if(!(objChannels = asJSONA(ccp_GetChannelList())) 
    || !objChannels.Size
    || !(objClientFilter = asJSONA(pack.GetArtifact(pkgKey)))) {
        delete objChannels;
        delete objClientFilter;

        return Plugin_Handled;
    }

    Menu hMenu;
    hMenu = new Menu(MenuCallBack);
    hMenu.SetTitle("%T \n \n", "title", iClient);
    
    char szBuffer[MESSAGE_LENGTH], szValue[MESSAGE_LENGTH];
    for(int i; i < objChannels.Size; i++) {
        objChannels.GetString(i, szValue, sizeof(szValue));
        FormatEx(
            szBuffer, sizeof(szBuffer), "%T", 
            (!objClientFilter || GetIndexOfIndent(objClientFilter, szValue) == -1)
                ? "enabled"
                : "disabled",
            iClient
        );

        Format(szValue, sizeof(szValue), "%T", szValue, iClient);
        Format(szBuffer, sizeof(szBuffer), "%c%T", i+1, "item_channel", iClient, szValue, szBuffer);

        hMenu.AddItem(szBuffer, szBuffer[1]);
    }
    
    delete objChannels;
    delete objClientFilter;

    hMenu.Display(iClient, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int MenuCallBack(Menu hMenu, MenuAction action, int iClient, int option)
{
    switch(action)
    {
        case MenuAction_End: delete hMenu;
        case MenuAction_Select: {
            char szBuffer[MESSAGE_LENGTH];
            hMenu.GetItem(option, szBuffer, sizeof(szBuffer));

            int item = szBuffer[0] - 1;
            
            Package pack = Packager.GetPackage(iClient);

            JsonArray objChannels = asJSONA(ccp_GetChannelList());
            JsonArray objClientFilter = asJSONA(pack.GetArtifact(pkgKey));

            char szValue[MESSAGE_LENGTH];
            objChannels.GetString(item, szValue, sizeof(szValue));
            delete objChannels;

            item = GetIndexOfIndent(objClientFilter, szValue);

            if(item == -1) {
                objClientFilter.PushString(szValue);

            } else {
                objClientFilter.Remove(item);
            }

            pack.SetArtifact(pkgKey, objClientFilter, freeAnyway);

            FormatEx(szBuffer, sizeof(szBuffer), "%T", (item != -1) ? "enabled" : "disabled", iClient);
            Format(szValue, sizeof(szValue), "%T", szValue, iClient);

            PrintToChat(iClient, "%T", "chat_setvalue", iClient, szValue, szBuffer);
            cmd(iClient, 0);
        }
    }
}

public Processing cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    
    if(part != BIND_PROTOTYPE)
        return Proc_Continue;

    static char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));

    Package pack;
    JsonArray channelList;
    for(int i, a; i < 2; i++) {
        a = ((!i) ? SENDER_INDEX(props[i+1]) : props[i+1]);

        if(!a || !(pack = Packager.GetPackage(a))) 
            continue;
            
        if(!(channelList = asJSONA(pack.GetArtifact(pkgKey))))
            continue;

        if(channelList.Size && GetIndexOfIndent(channelList, szIndent) != -1) {
            delete channelList;
            return Proc_Stop;
        }

        delete channelList;
    }

    return Proc_Continue;
}

stock int GetIndexOfIndent(JsonArray obj, const char[] indent) {
    static char szBuffer[64];
    for(int i; i < obj.Size; i++) {
        obj.GetString(i, szBuffer, sizeof(szBuffer));

        if(!strcmp(szBuffer, indent)) {
            return i;
        }
    }

    return -1;
}