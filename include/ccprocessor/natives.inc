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
 *  Request to skip color tags for author msg 
 *  
 *  @param input        Recipient list
 *  @param output       buffer        
 *  @param playersNum   Recipient count
 *  
 *  @return             true - Allowed to skip/false - otherwise 
*/
native bool     ccp_SkipColors(const char[] indent, int sender);

/*
 *  Changes the current game mode 
 *  
 *  @param iClient      Client Index     
 *  @param value        Game mode value (NULL_STRING to default)   
 *  
 *  @noreturn
*/
native void     ccp_ChangeMode(int iClient, const char[] value = NULL_STRING);

/*
 *  Get the ID of the current message
 *  
 *  @noparam 
 *  
 *  @return         ID (-1 if none are in progress) 
*/
native int      ccp_GetMessageID();

/*
 *  Translation of a phrase 
 *  
 *  @param phrase       Buffer with phrase 
 *  @param recipient    Recipient index          
 *  
 *  @return         true - Translation done/false - Phrases missing 
*/
native bool     ccp_Translate(char[] phrase, int recipient);

/*
 *  Request to start processing a new message 
 *  
 *  @param props        Message props
 *      @props[0]       Message Sender
 *      @props[1]       Message Recipient
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/RW]
 *      @params[1]      Message template                    [String/Read]   
 *      @params[2]      Message text                        [String/Read]           
 *  
 *  @return         ID or -1 if unsuccessful  
*/
native int      ccp_StartNewMessage(const int[] props, int propsCount, ArrayList params);

/*
 *  Request to start rebuilding recipient list
 *  
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Message sender
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *      @params[1]      Message text                        [String/Read]
 *      @params[2]      Message recipient list              [Array/RW]
 *      @params[3]      Message recipient count             [Int/RW]             
 *  
 *  @return             Proc_Continue - with out changes,
 *                      Proc_Change - recipients have been changed,
 *                      Proc_Reject - rejected
*/
// native Processing   ccp_RebuildClients(const int[] props, int propsCount, ArrayList params);

/*
 *  Request to start rebuilding message
 *  
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Message buffer (pkg: senderID << 3|senderTeam << 1|senderAlive)
 *      @props[2]       Message recipient
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *      @params[1]      Message template                    [String/Read]
 *      @params[2]      Message sender name                 [String/RW]
 *      @params[3]      Message text                        [String/RW] 
 *      @params[4]      Message compile                     [String/RW]            
 *  
 *  @return             Proc_Continue - continue with out changes,
 *                      Proc_Change - value has been changed & continue,
 *                      Proc_Reject - build rejected (after post call)
 *                      Proc_Stop - build rejected immediately (before post call)
*/
native Processing   ccp_RebuildMessage(const int[] props, int propsCount, ArrayList params);

/*
 *  Renders engine messages 
 *  
 *  @param props        Message props
 *      @props[0]       Sender index
 *      @props[1]       Recipient index
 *      @props[2]       Text params count
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message text                      [String/RW]  
 *           
 *  
 *  @noreturn             
*/
native void   ccp_RenderEngineCtx(const int[] props, int propsCount, ArrayList params);

/*
 *  End message request
 *  
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Sender index
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *           
 *  
 *  @noreturn
*/
native void     ccp_EndMessage(const int[] props, int propsCount, ArrayList params);

/*
 *  Obtaining permission for processing engine msg
 *  
 *  @param props        Message props
 *      @props[0]       Sender index
 *      @props[1]       Recipient index
 *
 *  @param propsCount   Props count
 *
 *  @param params       Message params
 *      @params[0]      Message text                      [String/Read]  
 *           
 *  
 *  @return             Proc_Continue - processing continue,
 *                      Proc_Stop - processing rejected
*/
native Processing     ccp_EngineMsgRequest(const int[] props, int propsCount, ArrayList params);

#if !defined REQUIRE_PLUGIN
public void __pl_ccprocessor_SetNTVOptional()
{
    MarkNativeAsOptional("cc_drop_palette");
    MarkNativeAsOptional("ccp_replaceColors");
    MarkNativeAsOptional("cc_get_APIKey");
    MarkNativeAsOptional("cc_is_APIEqual");
    MarkNativeAsOptional("ccp_SkipColors");
    MarkNativeAsOptional("ccp_ChangeMode");
    MarkNativeAsOptional("ccp_StartNewMessage");
    MarkNativeAsOptional("ccp_RebuildMessage");
    MarkNativeAsOptional("ccp_HandleEngineMsg");
    MarkNativeAsOptional("ccp_EndMessage");
    MarkNativeAsOptional("ccp_EngineMsgRequest");
    MarkNativeAsOptional("ccp_GetMessageID");
    MarkNativeAsOptional("ccp_Translate");
}
#endif