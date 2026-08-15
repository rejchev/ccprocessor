#pragma newdecls required

#include <ccprocessor>
#include <packager>
#include <shop>

#define SZ(%0) %0, sizeof(%0)

public Plugin myinfo = 
{
	name = "[CCP] Custom Chat <SHOP>",
	author = "rej.chev?",
	description = "...",
	version = "2.0.0",
	url = "discord.gg/ChTyPUG"
};

const ItemType g_IType = Item_Togglable;

static const char pkgKey[] = "shop_chat";

int levels[BIND_MAX];

bool g_bLate;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    g_bLate = late;
    return APLRes_Success;
}

public void OnPluginStart()
{    
    LoadTranslations("ccp_core.phrases");
    LoadTranslations("ccp_shop.phrases");

    manageConVars();
}

void manageConVars(bool bCreate = true) {
    char szBuffer[128];

    for(int i; i < BIND_MAX; i++) {
        FormatBind("ccp_shop_", i, 'l', szBuffer, sizeof(szBuffer)/2);
        if(bCreate){
            Format(szBuffer[strlen(szBuffer)+1], sizeof(szBuffer), "Priority level for %s", szBinds[i]);
            CreateConVar(szBuffer, "1", szBuffer[strlen(szBuffer)+1], _, true, 1.0).AddChangeHook(onChange);
        } else {
            onChange(FindConVar(szBuffer), NULL_STRING, NULL_STRING);
        }
    }
    
    if(bCreate) {
        AutoExecConfig(true, "ccp_shopchat", "ccprocessor");
    }
}

public void onChange(ConVar convar, const char[] oldVal, const char[] newVal)
{
    char szBuffer[64];
    convar.GetName(szBuffer, sizeof(szBuffer));

    int part = BindFromString(szBuffer);
    if(part == BIND_MAX)
        return;
    
    levels[part] = convar.IntValue;
}

public void pckg_OnPackageAvailable(int iClient) {
    static char config[MESSAGE_LENGTH]  = "configs/shop/ccprocessor/shop_chat.json";

    Package pack = Packager.GetPackage(iClient);

    if(!iClient) {
        
        
        if(config[0] == 'c')
            BuildPath(Path_SM, config, sizeof(config), config);
        
        if(!FileExists(config))
            SetFailState("Config file is not exists: %s", config);
    }

    pack.SetArtifact(pkgKey, (!iClient) ? Json.JsonF(config, 0) : new Json("{}"), freeAnyway);
}

public void OnMapStart() {
    // Handshake
    cc_proc_APIHandShake(cc_get_APIKey());

    manageConVars(false);

    // late load
    if(g_bLate) {
        g_bLate = false;

        for(int i = 1; i <= MaxClients; i++)
            if(Packager.GetPackage(i))
                pckg_OnPackageAvailable(i);
    }

    if(Shop_IsStarted())
        Shop_Started();
}

public void Shop_Started()
{
    OnMapEnd();
    RegisterCategorys();
}

public void OnMapEnd()
{
    Shop_UnregisterMe();
}

public void OnPluginEnd()
{
    OnMapEnd();
}

void RegisterCategorys() {
    JsonObject obj;
    if(!(obj = asJSONO(Packager.GetPackage(0).GetArtifact(pkgKey))))
        return;

    JsonArray jsonPart;
    JsonObject item;

    CategoryId id;

    for(int i; i < BIND_MAX; i++ ) {

        if(!obj.HasKey(szBinds[i]))
            continue;

        jsonPart = asJSONA(obj.Get(szBinds[i]));
        if(!jsonPart || !jsonPart.Size) {
            delete jsonPart;
            continue;
        }

        id = Shop_RegisterCategory(
            szBinds[i], szBinds[i], NULL_STRING, OnCategoryDisplayed
        );

        if(id == INVALID_CATEGORY) {
            delete jsonPart;
            continue;
        }

        for(int j; j < jsonPart.Size; j++) {
            if((item = asJSONO(jsonPart.Get(j))))
                RegisterItem(id, item);

            delete item;
        }

        delete jsonPart;
    }
    
    delete obj;
}

void RegisterItem(CategoryId cid, JsonObject item)
{
    char szBuffer[NAME_LENGTH];
    item.GetString("value", szBuffer, sizeof(szBuffer));

    if(Shop_StartItem(cid, szBuffer))
    {
        Shop_SetInfo(szBuffer, NULL_STRING, item.GetInt("price"), item.GetInt("sellprice"), g_IType, item.GetInt("duration"));
        Shop_SetCallbacks(OnItemRegistered, OnItemToogle, _, OnItemDisplay, _, _, OnItemBuy, OnItemSell);
            
        Shop_EndItem();
    }
}

public void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
    // ...
}

public ShopAction OnItemToogle(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
    Package pack;
    JsonObject obj;
    if((pack = Packager.GetPackage(iClient)))
        obj = asJSONO(pack.GetArtifact(pkgKey));
    
    char szValue[MESSAGE_LENGTH];        
    int part = BindFromString(category);

    if(obj && IsPartValid(obj, part))
        obj.GetString(szBinds[part], szValue, sizeof(szValue));

    if(!obj)
        obj = asJSONO(new Json("{}"));

    if(szValue[0])
    {
        if(!StrEqual(item, szValue))
            Shop_ToggleClientItem(iClient, Shop_GetItemId(category_id, szValue), Toggle_Off);

        szValue = NULL_STRING;
    }

    if(!(isOn || elapsed))
        strcopy(szValue, sizeof(szValue), item);
    
    if(szValue[0]) {
        obj.SetString(szBinds[part], szValue);
    } else obj.Set(szBinds[part], null);

    pack.SetArtifact(pkgKey, obj, freeAnyway);

    return (isOn || elapsed) ? Shop_UseOff : Shop_UseOn;
}

public bool OnItemDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
    int part = BindFromString(category);

    FormatEx(buffer, maxlen, "%T", name, client);

    ccp_replaceColors(buffer, true);

    if(part == BIND_PREFIX)
        Format(buffer, maxlen, "%T", "tag_display", client, buffer);

    return true;
}

public bool OnCategoryDisplayed(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen, ShopMenu menu)
{
    FormatEx(buffer, maxlen, "%T", name, client);
    return true;
}

public bool OnItemBuy(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int price, int sell_price, int value) {
    return true;  
}

public bool OnItemSell(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int sell_price)
{
    Package pack;
    if(!(pack = Packager.GetPackage(client)))
        return false;

    char szValue[MESSAGE_LENGTH];
    int part = BindFromString(category);

    JsonObject obj;
    if(!(obj = asJSONO(pack.GetArtifact(pkgKey))))
        return false;

    if(IsPartValid(obj, part))
        obj.GetString(szBinds[part], szValue, sizeof(szValue));

    if(szValue[0] && StrEqual(szValue, item, false))
        obj.Remove(szBinds[part]);

    return pack.SetArtifact(pkgKey, obj, freeAnyway);
}

JsonObject objModel;

public Processing  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {
    if(!SENDER_INDEX(props[1]) || level > levels[part]) {
        return Proc_Continue;
    }

    Package serverPack;
    if(!(serverPack = Packager.GetPackage(0)))
        return Proc_Continue;

    Package clientPack;
    if(!(clientPack = Packager.GetPackage(SENDER_INDEX(props[1]))))
        return Proc_Continue;

    objModel = asJSONO(serverPack.GetArtifact(pkgKey));
    if(!objModel.HasKey("channels")) {
        delete objModel;
        return Proc_Continue;
    }

    JsonArray channels = asJSONA(objModel.Get("channels", true));

    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));
    if(!JsonArrayContainsString(channels, szIndent, true)) {
        delete channels;
        return Proc_Continue;
    }

    delete channels;

    objModel = asJSONO(clientPack.GetArtifact(pkgKey));
    if(!objModel || !IsPartValid(objModel, part)) {
        delete objModel;
        return Proc_Continue;
    }

    static char szValue[MESSAGE_LENGTH];
    if(!objModel.GetString(szBinds[part], szValue, sizeof(szValue)) || !szValue[0]) {
        delete objModel;
        return Proc_Continue;
    }

    if(part == BIND_PREFIX && TranslationPhraseExists(szValue)) {
        Format(szValue, sizeof(szValue), "%T", szValue, props[2]);
    }

    level = levels[part];
    FormatEx(value, size, szValue);

    delete objModel;
    return Proc_Change;
}

stock bool IsPartValid(JsonObject model, int part) {

    JsonType type = model.GetType(szBinds[part]);

    return type != JInvalidType && type != JNullType;
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