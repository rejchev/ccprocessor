void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

Action Call_RebuildString(
    int id, const char[] indent,
    int sender, int recipient,
    int part, char[] szMessage, int iSize
) {
    Action output;
    bool block;
    int level;

    // Action Call
    Call_StartForward(g_fwdRebuildString);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(part);
    Call_PushCellRef(level);
    Call_PushStringEx(szMessage, iSize, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(iSize);
    Call_Finish(output);

    // exclude post call
    if(output == Plugin_Stop)
        return output;

    BreakPoint(part, szMessage);

    // post call
    Call_StartForward(g_fwdRebuildString_Post);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushCell(recipient);
    Call_PushCell(part);
    Call_PushCell(level);
    Call_PushString(szMessage);
    Call_Finish(block);

    if(output == Plugin_Continue && block) {
        output++;
    } 

    return output;
}

void Call_RebuildClients(
    int id, const char[] indent, 
    int sender, const char[] msg_key, 
    int[] clients, int &numClients
) {
    Call_StartForward(g_fwdRebuildClients);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushString(msg_key);
    Call_PushArrayEx(clients, numClients, SM_PARAM_COPYBACK);
    Call_PushCellRef(numClients);
    Call_Finish();
}

bool Call_HandleEngineMsg(const char[] indent, int sender, const char[] buffer) {
    bool handle = TranslationPhraseExists(buffer);

    Call_StartForward(g_fwdOnEngineMsg);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_PushString(buffer);
    Call_Finish(handle);

    return handle;
}

bool Call_IsSkipColors(const char[] indent, int sender) {
    bool skip = g_bRTP;

    Call_StartForward(g_fwdSkipColors);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_Finish(skip);

    return skip;
}

bool Call_NewMessage(int sender, const char[] msg_key, const char[] msg, char[] indent, int size, int[] players, int playersNum) {
    bool start = true;

    Call_StartForward(g_fwdNewMessage);   
    Call_PushCell(sender);
    Call_PushString(msg_key);
    Call_PushString(msg);
    Call_PushStringEx(indent, size, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(size);
    Call_PushArray(players, playersNum);
    Call_PushCell(playersNum);
    Call_Finish(start);

    return start
}

void Call_MessageEnd(int id, const char[] indent, int sender) {
    Call_StartForward(g_fwdMessageEnd);
    Call_PushCell(id);
    Call_PushString(indent);
    Call_PushCell(sender);
    Call_Finish();
}