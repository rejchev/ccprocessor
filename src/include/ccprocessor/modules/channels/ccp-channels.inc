#if defined _ccp_channels
 #endinput
#endif
#define _ccp_channels

stock const char CHANNEL_MGR_PKGKEY[] = "channel_mgr";

stock Json ccp_GetChannelList() {
    return asJSON(pckg_GetArtifact(0, CHANNEL_MGR_PKGKEY));
}

stock int ccp_FindChannel(const char[] szTag, bool casesens = true) {
    JsonArray channels;
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

    JsonArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null)
        if(index >= 0 && index < channels.Length)
            channels.GetString(index, szTag, sizeof(szTag));

    delete channels;
    return szTag;
}

stock void ccp_RemoveChannel(const int index) {
    JsonArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if(index >= 0 && index < channels.Length) {
            if(channels.Remove(index))
                pckg_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels);
        }
    }

    delete channels;
}

stock bool ccp_AddChannel(const char[] szTag) {
    if(ccp_FindChannel(szTag) != -1)
        return false;
    
    bool bSet;
    JsonArray channels;
    if((channels = asJSONA(ccp_GetChannelList())) != null) {
        if((bSet = channels.PushString(szTag)))
            bSet = pckg_SetArtifact(0, CHANNEL_MGR_PKGKEY, channels);            
    }

    delete channels;
    return bSet;
}
