#if defined _ccp_channels
 #endinput
#endif
#define _ccp_channels

stock const char CHANNEL_MGR_PKGKEY[] = "channel_mgr";

stock JSON ccp_GetChannelList() {
    return asJSON(ccp_GetArtifact(0, CHANNEL_MGR_PKGKEY));
}

stock int ccp_FindChannel(const char[] szTag, bool casesens = true) {
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        char szBuffer[PREFIX_LENGTH];
        for(int i; i < channels.Length; i++) {
            channels.GetString(i, szBuffer, sizeof(szBuffer));
            if(!strcmp(szTag, szBuffer, casesens)) {
                delete channels;
                return i;
            }
        }
    }

    delete channels;
    return -1;
}

stock char[] ccp_GetChannelTag(const int index) {
    char szTag[PREFIX_LENGTH];

    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null)
        if(index >= 0 && index < channels.Length)
            channels.GetString(index, szTag, sizeof(szTag));

    delete channels;
    return szTag;
}

stock void ccp_RemoveChannel(const int index) {
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if(index >= 0 && index < channels.Length) {
            if(channels.Remove(index))
                ccp_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels, 0);
        }
    }

    delete channels;
}

stock bool ccp_AddChannel(const char[] szTag) {
    if(ccp_FindChannel(szTag) != -1)
        return false;
    
    bool bSet;
    JSONArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if((bSet = channels.PushString(szTag)))
            bSet = ccp_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels, 0);            
    }

    delete channels;
    return bSet;
}
