void GetDefaultValue(
    const char[] indent, int sender, int team, bool isAlive, 
    int recipient, int part, const char[] name,
    const char[] msg, char[] szBuffer, int size
)
{
    switch(part)
    {
        case BIND_STATUS_CO, BIND_STATUS: {
            GetStatus(sender, isAlive, recipient, part, szBuffer, size);
        }
        case BIND_TEAM_CO, BIND_TEAM: {
            GetTeam(indent, team, recipient, part, szBuffer, size);
        }
        case BIND_PREFIX_CO, BIND_PREFIX: {
            GetChatTag(sender, recipient, part, szBuffer, size);
        }
        case BIND_NAME_CO, BIND_NAME: {
            GetName(sender, recipient, part, name, szBuffer, size);
        }
        case BIND_MSG_CO, BIND_MSG: {
            GetMessage(sender, recipient, part, msg, szBuffer, size);
        }
    }        
}

void GetStatus(int sender, bool alive, int lang, int part, char[] szBuffer, int size) {

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{ALIVE}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (alive) ? "A" : "D"
    ));

    // DEF_{BIND}_D_S
    if(!sender) {
        Format(szBuffer, size, "%s_S", szBuffer);
    }

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetTeam(const char[] indent, int team, int lang, int part, char[] szBuffer, int size) {

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{TYPE}
    Format(szBuffer, size, "%s_%s", szBuffer, indent);

    // DEF_{BIND}_{TYPE}_{TEAM}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (team == 3) ? "B" : (team == 2) ? "R" : "S"
    ));

    if(!TranslationPhraseExists(szBuffer)) {
        szBuffer[0] = 0;
        return;
    }
    
    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetChatTag(int sender, int lang, int part, char[] szBuffer, int size) {
    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (sender) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetName(int sender, int lang, int part, const char[] name, char[] szBuffer, int size) {
    if(part == BIND_NAME) {
        FormatEx(szBuffer, size, "%s", name);
        return;
    }

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (sender) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}

void GetMessage(int sender, int lang, int part, const char[] msg, char[] szBuffer, int size) {
    if(part == BIND_MSG) {
        FormatEx(szBuffer, size, "%s", msg);
        return;
    }

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{BIND}_{SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, (
        (sender) ? "U" : "S"
    ));

    Format(szBuffer, size, "%T", szBuffer, lang);
}