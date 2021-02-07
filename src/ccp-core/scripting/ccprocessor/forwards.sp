void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

Action Call_RebuildString(const int[] props, int propsCount, int part, ArrayList params, char[] szMessage, int size) {
    Action output;
    bool block;
    int level;

    // Action Call
    Call_StartForward(g_fwdRebuildString);
    Call_PushArray(props, propsCount);
    Call_PushCell(part);
    Call_PushCell(params);
    Call_PushCellRef(level);
    Call_PushStringEx(szMessage, size, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(size);
    Call_Finish(output);

    // exclude post call
    if(output == Plugin_Stop)
        return output;

    BreakPoint(part, szMessage);

    // post call
    Call_StartForward(g_fwdRebuildString_Post);
    Call_PushArray(props, propsCount);
    Call_PushCell(part);
    Call_PushCell(params);
    Call_PushCell(level);
    Call_PushString(szMessage);
    Call_Finish(block);

    if(output == Plugin_Continue && block) {
        output++;
    } 

    return output;
}

Action Call_RebuildClients(const int[] props, int propsCount, ArrayList params) {
    Action whatNext;

    Call_StartForward(g_fwdRebuildClients);
    Call_PushArray(props, propsCount);
    Call_PushCell(propsCount);
    Call_PushCell(params);
    Call_Finish(whatNext);

    return whatNext;
}

bool Call_HandleEngineMsg(const int[] props, int propsCount, ArrayList params) {
    bool handle = true;

    Call_StartForward(g_fwdOnEngineMsg);
    Call_PushArray(props, propsCount);
    Call_PushCell(propsCount);
    Call_PushCell(params);
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

bool Call_NewMessage(int sender, ArrayList params) {
    bool start = true;

    Call_StartForward(g_fwdNewMessage);   
    Call_PushCell(sender);   
    Call_PushCell(params);
    Call_Finish(start);

    return start
}

void Call_MessageEnd(const int[] props, int propsCount, ArrayList params) {
    Call_StartForward(g_fwdMessageEnd);
    Call_PushArray(props, propsCount);
    Call_PushCell(propsCount);
    Call_PushCell(params);
    Call_Finish();
}