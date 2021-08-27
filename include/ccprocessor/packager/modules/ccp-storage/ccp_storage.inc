#if defined _ccp_storage_included
 #endinput
#endif
#define _ccp_storage_included

native Handle   ccp_storage_ReadValue(int iClient, const char[] key);
native bool     ccp_storage_WriteValue(int iClient, const char[] key, Handle value);
native bool     ccp_storage_RemoveValue(int iClient, const char[] key);


public SharedPlugin __pl_ccp_storage= 
{
    name = "ccp_storage",
    file = "ccp-storage.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl__ccp_storage_SetNTVOptional()
{
    MarkNativeAsOptional("ccp_storage_WriteValue");
    MarkNativeAsOptional("ccp_storage_ReadValue");
    MarkNativeAsOptional("ccp_storage_RemoveValue");
}
#endif