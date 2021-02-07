void GetDefaultValue(int props, int lang, int part, ArrayList params, char[] szBuffer, int size) {
    if(part == BIND_NAME || part == BIND_MSG || part == BIND_PROTOTYPE) {
        params.GetString(
            (part == BIND_PROTOTYPE) ? 1 :
            (part == BIND_NAME) ? 2 : 3, 
            szBuffer, size
        );
        
        if(part == BIND_PROTOTYPE && TranslationPhraseExists(szBuffer)) {
            Format(szBuffer, size, "%c %T", 1, szBuffer, SENDER_INDEX(props));
        }

        #if defined DEBUG
        DWRITE("%s: GetDefaultValue(%i): \n\t\tPart: %i \n\t\tValue: %s", DEBUG, SENDER_INDEX(props), part, szBuffer);
        #endif

        return;
    }

    char indent[NAME_LENGTH];
    params.GetString(0, SZ(indent));

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{ALIVE/SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, 
        (part < BIND_TEAM_CO) 
            ? (SENDER_ALIVE(props)) 
                ? "A" 
                : "D" 
            : (part < BIND_PREFIX_CO) 
                ? indent 
                : (SENDER_INDEX(props)) 
                    ? "U" 
                    : "S"
    );

    // DEF_{ALIVE/SENDER}_{TEAM/SENDER}
    if(part < BIND_PREFIX_CO) {
        Format(szBuffer, size, "%s%s", szBuffer,
            (part < BIND_TEAM_CO) // Status & Status CO
                ? (!(SENDER_ALIVE(props))) // Died
                    ? (!SENDER_INDEX(props)) // Server
                        ? "_S"
                        : ""
                    : ""  
                : (SENDER_TEAM(props) == 2)  // Team & Team CO
                    ? "_R"
                    : (SENDER_TEAM(props) == 3)
                        ? "_B"
                        : "_S"
        );
    }

    if(!TranslationPhraseExists(szBuffer)) {
        szBuffer[0] = 0;
    } else {
        Format(szBuffer, size, "%T", szBuffer, lang);
    }

    #if defined DEBUG
    DWRITE(\
        "%s: GetDefaultValue(%i): \n\t\tIndent: %s \n\t\tPart: %i \n\t\tValue: %s", \
        DEBUG, SENDER_INDEX(props), indent, part, szBuffer\
    );
    #endif
}