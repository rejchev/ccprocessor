#if defined _ccprocessor_pkg_included
 #endinput
#endif
#define _ccprocessor_pkg_included

enum ContextLevels {
    CALL_IGNORE = -1,
    CALL_DEFAULT
};

forward void        ccp_OnPackageAvailable(int iClient);
forward Processing  ccp_OnPackageUpdate(Handle ctx, any &level);
forward void        ccp_OnPackageUpdate_Post(Handle ctx, any level);

native Handle   ccp_GetPackage(int iClient);
native bool     ccp_SetPackage(int iClient, Handle value, any repLevel);
native bool     ccp_HasPackage(int iClient);
native bool     ccp_IsVerified(int iClient);

native bool     ccp_SetArtifact(int iClient, const char[] artifact, Handle value, any repLevel);
native bool     ccp_RemoveArtifact(int iClient, const char[] artifact, any repLevel);
native Handle   ccp_GetArtifact(int iClient, const char[] artifact);
native bool     ccp_HasArtifact(int iClient, const char[] artifact);

public SharedPlugin __pl_ccprocessor_pkg= 
{
    name = "ccprocessor_pkg",
    file = "ccp-packager.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ccprocessor_pkg_SetNTVOptional()
{
    MarkNativeAsOptional("ccp_GetPackage");
    MarkNativeAsOptional("ccp_SetPackage");
    MarkNativeAsOptional("ccp_HasPackage");
    MarkNativeAsOptional("ccp_IsVerified");
    MarkNativeAsOptional("ccp_SetArtifact");
    MarkNativeAsOptional("ccp_RemoveArtifact");
    MarkNativeAsOptional("ccp_GetArtifact");
    MarkNativeAsOptional("ccp_HasArtifact");
}
#endif