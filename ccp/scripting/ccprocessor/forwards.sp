void Call_OnCompReading()
{
    Call_StartForward(g_fwdConfigParsed);
    Call_Finish();
}

Processing Call_RebuildString(const int[] props, int propsCount, int part, ArrayList params, char[] szMessage, int size) {
    Processing output;
    Processing block;
    int level;

    static char szBuffer[MESSAGE_LENGTH];
    FormatEx(SZ(szBuffer), "%s", szMessage);

    // Action Call
    Call_StartForward(g_fwdRebuildString);
    Call_PushArray(props, propsCount);
    Call_PushCell(part);
    Call_PushCell(params);
    Call_PushCellRef(level);
    Call_PushStringEx(szMessage, size, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(size);
    Call_Finish(output);

    if(output == Proc_Continue)
        FormatEx(szMessage, size, "%s", szBuffer);

    ArrayList doNotChange = params.Clone();
    Call_StartForward(g_fwdRebuildString_Sp);
    Call_PushArray(props, propsCount);
    Call_PushCell(part);
    Call_PushCell(doNotChange);
    Call_PushStringEx(szMessage, size, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(size);
    Call_Finish();

    delete doNotChange;

    // exclude post call
    if(output == Proc_Stop)
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

    if(output < block) {
        output = block;
    } 

    return output;
}

Processing Call_HandleEngineMsg(const int[] props, int propsCount, ArrayList params) {
    Processing handle;

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

Processing Call_NewMessage(const int[] props, int propsCount, ArrayList params) {
    Processing start;

    char szIndent[64];
    params.GetString(0, szIndent, sizeof(szIndent));

    Call_StartForward(g_fwdNewMessage);   
    Call_PushArray(props, propsCount);
    Call_PushCell(propsCount);
    Call_PushCell(params);
    Call_Finish(start);

    if(start == Proc_Continue) {
        params.SetString(0, szIndent);
    }

    return start;
}

void Call_MessageEnd(const int[] props, int propsCount, ArrayList params) {
    Call_StartForward(g_fwdMessageEnd);
    Call_PushArray(props, propsCount);
    Call_PushCell(propsCount);
    Call_PushCell(params);
    Call_Finish();
}