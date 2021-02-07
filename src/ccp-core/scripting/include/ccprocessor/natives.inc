/*
 *  Get a pallete
 *  
 *  @noparam
 *  
 *  @return         Map: ABBR:value (the pointer is not cloned, so no closure is required.)
*/
native ArrayList cc_drop_palette();

/*
 *  Replacing colors in a string
 *  
 *  @param szBuffer     String buffer
 *  @param toNull       false - replace ABBR with code
                        true - clear ABBR&code in string
 *  
 *  @noreturn
*/
native void     ccp_replaceColors(char[] szBuffer, bool toNull = true);

/*
 *  Get the API key used by the core
 *  
 *  @noparam 
 *  
 *  @return         API version key
*/
native int      cc_get_APIKey();

/*
 *  API key matching
 *  
 *  @param api          API version key
 *  
 *  @return             true - equal
                        false - otherwise
*/
native bool     cc_is_APIEqual(const int api);

native void     ccp_UpdateRecipients(const int [] input, int[] output, int &playersNum);
native bool     ccp_SkipColors(const char[] indent, int sender);
native void     ccp_ChangeMode(const int[] players, int playersNum, const char[] value = NULL_STRING);

native int      ccp_GetMessageID();
native bool     ccp_Translate(char[] phrase, int recipient);

native int      ccp_StartNewMessage(int sender, ArrayList params);
native Action   ccp_RebuildClients(const char[] props, int propsCount, ArrayList params);
native Action   ccp_RebuildMessage(const char[] props, int propsCount, ArrayList params);
native Action   ccp_HandleEngineMsg(const char[] props, int propsCount, ArrayList params);
native void     ccp_EndMessage(const char[] props, int propsCount, ArrayList params);
native bool     ccp_EngineMsgRequest(const char[] props, int propsCount, ArrayList params);

#if !defined REQUIRE_PLUGIN
public void __pl_ccprocessor_SetNTVOptional()
{
    MarkNativeAsOptional("cc_drop_palette");
    MarkNativeAsOptional("ccp_replaceColors");
    MarkNativeAsOptional("cc_get_APIKey");
    MarkNativeAsOptional("cc_is_APIEqual");
    MarkNativeAsOptional("ccp_UpdateRecipients");
    MarkNativeAsOptional("ccp_SkipColors");
    MarkNativeAsOptional("ccp_ChangeMode");
    MarkNativeAsOptional("ccp_StartNewMessage");
    MarkNativeAsOptional("ccp_RebuildClients");
    MarkNativeAsOptional("ccp_RebuildMessage");
    MarkNativeAsOptional("ccp_HandleEngineMsg");
    MarkNativeAsOptional("ccp_EndMessage");
    MarkNativeAsOptional("ccp_EngineMsgRequest");
    MarkNativeAsOptional("ccp_GetMessageID");
    MarkNativeAsOptional("ccp_Translate");
}
#endif