/*
 *  Skip colors in an unprepared message
 *
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  
 *  @return             true - skipping
 *                      false - otherwise
*/
forward bool    cc_proc_SkipColors(const char[] indent, int sender);

/*
 *  Call when new message arrives /\
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
 *  @return             Proc_Continue - continue,
 *                      Proc_Change - Indent changed & continue,
 *                      Proc_Reject - Reject message generation 
*/
forward Processing    cc_proc_OnNewMessage(const int[] props, int propsCount, ArrayList params);

/*
 *	Calls when building parts of the template
 *
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Message buffer (pkg: senderID << 3|senderTeam << 1|senderAlive)
 *      @props[2]       Message recipient
 *
 *  @param part         Template part
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *      @params[1]      Message template                    [String/Read]
 *      @params[2]      Message sender name                 [String/RW]
 *      @params[3]      Message text                        [String/RW] 
 *      @params[4]      Message compile                     [String/RW]    
 *
 *  @param &level       Replacement priority   
 *  @param value        Value buffer    
 *  @param size         Value Size     
 *
 *  @return             Proc_Continue - continue with out changes,
 *                      Proc_Change - value changed & continue,
 *                      Proc_Reject - build rejected (after post call)
 *                      Proc_Stop - build rejected immediately (before post call)
*/
forward Processing  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size);


/*
 *  Special call after build part
 *    
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Message buffer (pkg: senderID << 3|senderTeam << 1|senderAlive)
 *      @props[2]       Message recipient
 *
 *  @param part         Template part
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *      @params[1]      Message template                    [String/Read]
 *      @params[2]      Message sender name                 [String/Read]
 *      @params[3]      Message text                        [String/Read] 
 *      @params[4]      Message compile                     [String/Read]    
 *
 *  @param value        Value buffer    
 *  @param size         Value Size     
 *
 *  @noreturn
*/
forward void    cc_proc_OnRebuildString_Txt(const int[] props, int part, ArrayList params, char[] value, int size);


/*
 *  Call after special call
 *  
 *  @param props        Message props
 *      @props[0]       Message ID
 *      @props[1]       Message buffer (pkg: senderID << 3|senderTeam << 1|senderAlive)
 *      @props[2]       Message recipient
 *
 *  @param part         Template part
 *
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/Read]  
 *      @params[1]      Message template                    [String/Read]
 *      @params[2]      Message sender name                 [String/RW]
 *      @params[3]      Message text                        [String/RW] 
 *      @params[4]      Message compile                     [String/RW]    
 *
 *  @param level        Replacement priority   
 *  @param value        Value buffer  
 *  
 *  @return             Proc_Continue/Proc_Change - continue processing,
 *                      Proc_Reject/Proc_Stop - reject current message
*/
forward Processing    cc_proc_OnRebuildString_Post(const int[] props, int part, ArrayList params, int level, const char[] value);

/*
 *  Calls after message delivery to all recipients 
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
 *  @noreturn
*/
forward void    cc_proc_OnMessageEnd(const int[] props, int propsCount, ArrayList params);

/*
 *  Calls when capturing an engine message from the server
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
 *  @return             Proc_Continue - continue processing,
 *                      Proc_Stop - reject processing
*/
forward Processing    cc_proc_HandleEngineMsg(const int[] props, int propsCount, ArrayList params);

/*
 *  Calls when the config reading is completed
 *  
 *  @noparam
 *  
 *  @noreturn
*/
forward void    cc_config_parsed();

/*
 *  API hand shake
 *  
 *  @param api          API version key
 *  
 *  @noreturn
*/
forward void    cc_proc_APIHandShake(const int api);