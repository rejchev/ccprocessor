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
 *  @param sender       Sender index
 *  @param temp_key     Template Key
 *  @param msg          Message
 *  @param indent       Message Indent
 *  @param size         Max Size
 *  @param players      Recipient list
 *  @param playersNum   Rcipient count
 *  
 *  @return             true - allow msg / false - otherwise
*/
forward bool    cc_proc_OnNewMessage(int sender, ArrayList params);

/*
 *  Streaming output for editing the recipient list
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender Index
 *  @param msg_key      Message Key
 *  @param players      Recipient list
 *  @param &playersNum  Number of recipients

 *  @noreturn
*/
forward Action  cc_proc_OnRebuildClients(const int[] props, int propsCount, ArrayList params);

/*
 *	Calls when building parts of the template
 *
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  @param recipient    Recipient index
 *  @param part         Part of the message template
 *  @param &pLevel      Replacement priority
 *  @param buffer       Buffer
 *  @param size         Buffer size
 *
 *  @return             Plugin_Continue - build continue,
 *                      Plugin_Handled  - build rejected (after post call),
 *                      Plugin_Stop     - build rejected immediately (with out post call)
*/
forward Action  cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size);

/*
 *  Call after build part of the template
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender index
 *  @param recipient    Recipient index
 *  @param part         Part of the message template
 *  @param pLevel       Replacement priority
 *  @param value        Value
 *  
 *  @return             true - Block sending/false - send
*/
forward bool    cc_proc_OnRebuildString_Post(const int[] props, int part, ArrayList params, int level, const char[] value);

/*
 *  Calls after message delivery to all recipients 
 *  
 *  @param mid          Message ID
 *  @param sender       Message Indent
 *  @param sender       Sender Index
 *  
 *  @noreturn
*/
forward void    cc_proc_OnMessageEnd(const int[] props, int propsCount, ArrayList params);

/*
 *  Calls when capturing an engine message from the server
 *  
 *  @param mid          Message ID
 *  @param indent       Message Indent
 *  @param sender       Sender Index
 *  @param msg          Message
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