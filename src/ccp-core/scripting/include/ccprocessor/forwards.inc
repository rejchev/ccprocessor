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
 *  @param sender       Message sender 
 *  @param params       Message params
 *      @params[0]      Message indent                      [String/RW]
 *      @params[1]      Message template                    [String/Read]   
 *      @params[2]      Message text                        [String/Read]
 *      @params[3]      Message recipient list              [Array/Read]
 *      @params[4]      Message recipient count             [Int/Read]      
 *  
 *  @return             true - allow msg / false - otherwise
*/
forward bool    cc_proc_OnNewMessage(int sender, ArrayList params);

/*
 *  Streaming output for editing the recipient list
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
 *  @noreturn
*/
forward Action  cc_proc_OnRebuildClients(const int[] props, int propsCount, ArrayList params);

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
 *  @return             Plugin_Continue - build continue,
 *                      Plugin_Handled  - build rejected (after post call),
 *                      Plugin_Stop     - build rejected immediately (with out post call)
*/
forward Action  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size);

/*
 *  Call after build part of the template
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
 *  @return             true - Block sending/false - send
*/
forward bool    cc_proc_OnRebuildString_Post(const int[] props, int part, ArrayList params, int level, const char[] value);

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
 *  @return             true - handle this / false - otherwise
*/
forward bool    cc_proc_HandleEngineMsg(const int[] props, int propsCount, ArrayList params);

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