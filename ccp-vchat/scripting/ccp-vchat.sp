#pragma newdecls required

#include <packager>
#include <vip_core>
#include <ccprocessor>
#include <clientprefs>

public Plugin myinfo = 
{
	name = "[CCP] Custom Chat <VIP>",
	author = "rej.chev?",
	description = "...",
	version = "3.0.0",
	url = "discord.gg/ChTyPUG"
};

ArrayList g_mPalette;

int level[BIND_MAX];

int g_iBindNow[MAXPLAYERS+1];

bool g_bLate;

Cookie cookie;

static const char pkgKey[] = "vip_chat";
static const char FEATURE[] = "ccp_chat";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
    g_bLate = late;
    return APLRes_Success
}

public void OnPluginStart()
{    
    LoadTranslations("ccp_core.phrases");
    LoadTranslations("vip_ccpchat.phrases");
    LoadTranslations("vip_modules.phrases");

    cookie = new Cookie(pkgKey, "", CookieAccess_Private);

    manageConVars();

    if(VIP_IsVIPLoaded())
        VIP_OnVIPLoaded();

    if(g_bLate) {
        cc_config_parsed();
        pckg_OnPackageAvailable(0);

        for(int i = 1; i <= MaxClients; i++) {
            OnClientPutInServer(i);
            if(IsClientInGame(i) && !IsFakeClient(i) && VIP_IsClientVIP(i)) {
                VIP_OnVIPClientLoaded(i);
            }
        }

        g_bLate = false;
    }
}

void manageConVars(bool bCreate = true) {
    char szBuffer[128];

    for(int i; i < BIND_MAX; i++) {
        FormatBind(FEATURE, i, 'l', szBuffer, sizeof(szBuffer)/2);
        if(bCreate){
            Format(szBuffer[strlen(szBuffer)+1], sizeof(szBuffer), "Priority level for %s", szBinds[i]);
            CreateConVar(szBuffer, "1", szBuffer[strlen(szBuffer)+1], _, true, 1.0).AddChangeHook(onChange);
        } else {
            onChange(FindConVar(szBuffer), NULL_STRING, NULL_STRING);
        }
    }
    
    if(bCreate) {
        AutoExecConfig(true, "ccp_vipchat", "ccprocessor");
    }
}

public void onChange(ConVar convar, const char[] oldVal, const char[] newVal)
{
    char szBuffer[64];
    convar.GetName(szBuffer, sizeof(szBuffer));

    int part = BindFromString(szBuffer);
    if(part == BIND_MAX)
        return;
    
    level[part] = convar.IntValue;
}

public void OnMapStart()
{
    cc_proc_APIHandShake(cc_get_APIKey());

    manageConVars(false);
}

public void pckg_OnPackageAvailable(int iClient) {
    if(iClient)
        return;
    
    static char szConfig[PLATFORM_MAX_PATH] = "data/vip/modules/chat.json";

    if(szConfig[0] == 'd')
        BuildPath(Path_SM, szConfig, sizeof(szConfig), szConfig);
    
    if(!FileExists(szConfig))
        SetFailState("Where is my config??: %s", szConfig);
    
    Packager.GetPackage(iClient).SetArtifact(pkgKey, Json.JsonF(szConfig, 0), freeAnyway);
}

public void cc_config_parsed()
{
    g_mPalette = cc_drop_palette();
}

public void VIP_OnVIPLoaded()
{
    // OnPluginEnd();
    VIP_RegisterFeature(FEATURE, BOOL, SELECTABLE, OnSelected_Feature);
}

public void OnPluginEnd()
{
    if(!CanTestFeatures() 
    || GetFeatureStatus(FeatureType_Native, "VIP_UnregisterMe") != FeatureStatus_Available)
        return;

    VIP_UnregisterMe();
}

public bool OnSelected_Feature(int iClient, const char[] szFeature) {
    partsOfMsgsMenu(iClient).Display(iClient, MENU_TIME_FOREVER);
    return false;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
    Json storage;

    char buffer[512];
    cookie.Get(iClient, buffer, sizeof(buffer));

    if(!strlen(buffer) || !(storage = new Json(buffer)))
        storage = new Json("{}");

    Packager.GetPackage(iClient).SetArtifact(pkgKey, storage, freeAnyway);
}

Menu partsOfMsgsMenu(int iClient) {
    g_iBindNow[iClient] = BIND_MAX;

    Menu menu;

    char szBuffer[MESSAGE_LENGTH];
    VIP_GetClientVIPGroup(iClient, szBuffer, sizeof(szBuffer));

    JsonObject artifact = asJSONO(Packager.GetPackage(0).GetArtifact(pkgKey));
    JsonObject group;
    
    if(!(group = asJSONO(artifact.Get(szBuffer, true))))
        delete artifact;

    JsonArray keys = group.Keys(JStringType);
    
    delete group;

    menu = new Menu(partsOfMsgsMenu_CallBack);
    menu.SetTitle("%T %T \n \n", "parts_ofMsg_title_tag", iClient, "parts_ofMsg_title", iClient);

    group = asJSONO(Packager.GetPackage(iClient).GetArtifact(pkgKey));
    
    char szValue[MESSAGE_LENGTH], out[MESSAGE_LENGTH];
    for(int i = 0; i < keys.Size; i++) {
        keys.GetString(i, szBuffer, sizeof(szBuffer));

        szValue = NULL_STRING;

        if(group.HasKey(szBuffer))
            group.GetString(szBuffer, szValue, sizeof(szValue));

        if(!szValue[0])
            FormatEx(szValue, sizeof(szValue), "%T", "empty_value", iClient);
        
        if(TranslationPhraseExists(szValue))
            Format(szValue, sizeof(szValue), "%T", szValue, iClient);

        ccp_replaceColors(szValue, true);

        FormatEx(out, sizeof(out), "%c%T [%s]", BindFromString(szBuffer) + 1, szBuffer, iClient, szValue);

        menu.AddItem(out, out[1]);
    }

    menu.ExitButton = true;
    menu.ExitBackButton = true;

    if(!menu.ItemCount)
        delete menu;

    delete keys;
    delete group;

    return menu;
}

public int partsOfMsgsMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iOpt2)
{
    switch(action)
    {
        case MenuAction_End: delete hMenu;
        case MenuAction_Cancel:
        {
            if(iOpt2 == MenuCancel_ExitBack)
            {
                VIP_SendClientVIPMenu(iClient, false);
            }
        }
        case MenuAction_Select:
        {
            char szOption[MESSAGE_LENGTH];
            hMenu.GetItem(iOpt2, szOption, sizeof(szOption));

            int part = szOption[0] - 1;
            if(part == BIND_MAX)
                return;
            
            FeatureMenu(iClient, part).Display(iClient, MENU_TIME_FOREVER);
        }
    }
}

Menu FeatureMenu(int iClient, const int msgPart)
{
    g_iBindNow[iClient] = BIND_MAX;

    Menu hMenu;

    char szBuffer[MESSAGE_LENGTH];
    VIP_GetClientVIPGroup(iClient, szBuffer, sizeof(szBuffer));

    Json items = getItemsList(szBuffer, szBinds[msgPart]);

    if(!items)
        return null;
    
    char szOption[MESSAGE_LENGTH], szValue[MESSAGE_LENGTH];
    JsonObject client = asJSONO(Packager.GetPackage(iClient).GetArtifact(pkgKey));

    if(!(client.GetString(szBinds[msgPart], szValue, sizeof(szValue), true)))
        delete client;

    hMenu = new Menu(FeatureMenu_CallBack);
    hMenu.SetTitle("%T %T \n \n", "feature_title", iClient, szBinds[msgPart], iClient);

    for(int i, a, iDrawType; i < asJSONA(items).Size; i++)
    {
        szBuffer = NULL_STRING;
        a = -1;

        asJSONA(items).GetString(i, szBuffer, sizeof(szBuffer));
        
        if(StrContains(szBuffer, "disable", false) != -1) {
            iDrawType = (szValue[0]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
            a = 0;
        } else if(StrContains(szBuffer, "custom", false) != -1) {
            iDrawType = ITEMDRAW_DEFAULT;
            a = 1;
        } else {
            iDrawType = (!strcmp(szBuffer, szValue)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT;
        }

        Format(szBuffer, sizeof(szBuffer), "%c%c%T", msgPart+1, i+1, szBuffer, iClient);

        ccp_replaceColors(szBuffer[2], true);

        if(a != -1)
            Format(szBuffer, sizeof(szBuffer), "%s \n \n", szBuffer);
        
        hMenu.AddItem(szBuffer, szBuffer[2], iDrawType);
    } 

    hMenu.ExitButton = true;
    hMenu.ExitBackButton = true;

    if(!hMenu.ItemCount) {
        delete hMenu;
    }

    delete items;

    return hMenu; 
}

public int FeatureMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iOpt2)
{
    switch(action)
    {
        case MenuAction_End: delete hMenu;
        case MenuAction_Cancel:
        {
            if(iOpt2 == MenuCancel_ExitBack)
            {
                partsOfMsgsMenu(iClient).Display(iClient, MENU_TIME_FOREVER);
            }
        }
        case MenuAction_Select:
        {
            char szOption[NAME_LENGTH];
            hMenu.GetItem(iOpt2, szOption, sizeof(szOption));

            int part = szOption[0] - 1;
            int idx = szOption[1] - 1;

            VIP_GetClientVIPGroup(iClient, szOption, sizeof(szOption));

            JsonArray items = asJSONA(getItemsList(szOption, szBinds[part]));

            items.GetString(idx, szOption, sizeof(szOption));
            delete items;
            
            if(!strcmp(szOption, "custom")) {
                g_iBindNow[iClient] = part;

                PrintToChat(iClient, "%T", "wait_custom_value", iClient);
                return;
            }

            Package pack = Packager.GetPackage(iClient);

            JsonObject artifact = asJSONO(pack.GetArtifact(pkgKey));

            if(!strcmp(szOption, "disable")) {
                artifact.Remove(szBinds[part]);
                szOption = NULL_STRING;
            }
            else artifact.SetString(szBinds[part], szOption);

            if(pack.SetArtifact(pkgKey, artifact, freeAnyway)) {
                
                artifact = asJSONO(pack.GetArtifact(pkgKey));

                char szBuffer[1024];
                if(!asJSON(artifact).Dump(szBuffer, sizeof(szBuffer), 0, true))
                    delete artifact;

                cookie.Set(iClient,szBuffer);
            }
            
            FeatureMenu(iClient, part).Display(iClient, MENU_TIME_FOREVER);
        }
    }
}

public void OnClientPutInServer(int iClient) {
    g_iBindNow[iClient] = BIND_MAX;
}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] args)
{
    if(!iClient || !IsClientInGame(iClient) || IsFakeClient(iClient) || IsChatTrigger())
        return Plugin_Continue;

    if(g_iBindNow[iClient] != BIND_MAX)
    {
        char szBuffer[MESSAGE_LENGTH];
        strcopy(szBuffer, sizeof(szBuffer), args);

        TrimString(szBuffer);

        if(g_iBindNow[iClient] != BIND_PREFIX && g_mPalette.FindString(szBuffer) == -1)
        {
            BreakPoint(g_iBindNow[iClient], szBuffer);
            PrintToChat(iClient, "%T", "invalid_color_value", iClient, szBuffer);

            return Plugin_Handled;
        }

        Package pack;
        JsonObject model;

        if(!(pack = Packager.GetPackage(iClient)) || !(model = asJSONO(pack.GetArtifact(pkgKey)))) {
            g_iBindNow[iClient] = BIND_MAX;
            return Plugin_Handled;
        }

        model.SetString(szBinds[g_iBindNow[iClient]], szBuffer);

        if(pack.SetArtifact(pkgKey, model, freeAnyway)) {

            model = asJSONO(pack.GetArtifact(pkgKey));

            char szCookie[1024];
            if(!asJSON(model).Dump(szCookie, sizeof(szCookie), 0, true))
                delete model;

            cookie.Set(iClient, szCookie);
        }

        PrintToChat(iClient, "%T", "ccp_custom_success", iClient);

        FeatureMenu(iClient, g_iBindNow[iClient]).Display(iClient, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Processing  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &pLevel, char[] value, int size) {
    if(!SENDER_INDEX(props[1]) || pLevel > level[part])
        return Proc_Continue;

    Package clientPack;
    if(!(clientPack = Packager.GetPackage(SENDER_INDEX(props[1]))))
        return Proc_Continue;
    
    Package serverPack;
    JsonObject objModel;
    if(!(serverPack = Packager.GetPackage(0)) || !(objModel = asJSONO(serverPack.GetArtifact(pkgKey))))
        return Proc_Continue;

    JsonArray channels;
    
    if(!(channels = asJSONA(objModel.Get("channels", true)))) {
        delete objModel;
        return Proc_Continue;
    }
        
    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));

    if(!JsonArrayContainsString(channels, szIndent, true)) {
        delete channels;
        return Proc_Continue;
    }

    delete channels;

    if(!(objModel = asJSONO(clientPack.GetArtifact(pkgKey))))
        return Proc_Continue;

    static char szValue[MESSAGE_LENGTH];
    if(!objModel.GetString(szBinds[part], szValue, sizeof(szValue), true) || !szValue[0]) {
        delete objModel;
        return Proc_Continue;
    }

    if(part == BIND_PREFIX && TranslationPhraseExists(szValue))
        Format(szValue, sizeof(szValue), "%T", szValue, props[2]);

    pLevel = level[part];
    FormatEx(value, size, szValue);

    return Proc_Change;
}

stock Json getItemsList(const char[] group, const char[] msgPart) {
    Json first;
    Json second;

    first = asJSON(Packager.GetPackage(0).GetArtifact(pkgKey));

    if(!asJSONO(first).HasKey(group)) {
        delete first;
        return first;
    }

    second = asJSON(asJSONO(first).Get(group));
    delete first;

    if(!asJSONO(second).HasKey(msgPart)) {
        delete second;
        return second;
    }

    first = asJSON(asJSONO(second).Get(msgPart));
    delete second;

    return first;
}

stock bool JsonArrayContainsString(const JsonArray array, const char[] str, bool casesens = true) {
    
    if(!array)
        return false;

    char buffer[512];
    for(int i = 0; i < array.Size; i++) {

        if(!array.GetString(i, buffer, sizeof(buffer)))
            continue;

        if(!strcmp(str, buffer, casesens))
            return true;
    }

    return false;
}