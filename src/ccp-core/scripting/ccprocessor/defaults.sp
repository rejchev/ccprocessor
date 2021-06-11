void GetDefaultValue(const int[] props, const int propsCount, int part, ArrayList params, char[] szBuffer, int size) {
    if(propsCount < 2) 
        SetFailState("Anchor");

    if(part == BIND_NAME || part == BIND_MSG || part == BIND_PROTOTYPE) {
        params.GetString(
            (part == BIND_PROTOTYPE) ? 1 :
            (part == BIND_NAME) ? 2 : 3, 
            szBuffer, size
        );
        
        if(part == BIND_PROTOTYPE && TranslationPhraseExists(szBuffer)) {
            // Fixed:
            // Now, template format depends on the recipient
            Format(szBuffer, size, "%c %T", 1, szBuffer, props[2]);
        }

        #if defined DEBUG
        DWRITE("%s: Template:
                \n\t\tSender: %N
                \n\t\tRecipient: %N
                \n\t\tPart: %s
                \n\t\tOutput: %s", DEBUG, SENDER_INDEX(props[1]), props[2], szBinds[part], szBuffer);
        #endif

        return;
    }

    static char indent[NAME_LENGTH];
    params.GetString(0, SZ(indent));

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{ALIVE/SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, 
        (part < BIND_TEAM_CO) 
            ? (SENDER_ALIVE(props[1])) 
                ? "A" 
                : "D" 
            : (part < BIND_PREFIX_CO) 
                ? indent 
                : (SENDER_INDEX(props[1])) 
                    ? "U" 
                    : "S"
    );

    // DEF_{ALIVE/SENDER}_{TEAM/SENDER}
    if(part < BIND_PREFIX_CO) {
        Format(szBuffer, size, "%s%s", szBuffer,
            (part < BIND_TEAM_CO) // Status & Status CO
                ? (!(SENDER_ALIVE(props[1]))) // Died
                    ? (!SENDER_INDEX(props[1])) // Server
                        ? "_S"
                        : ""
                    : ""  
                : (SENDER_TEAM(props[1]) == 2)  // Team & Team CO
                    ? "_R"
                    : (SENDER_TEAM(props[1]) == 3)
                        ? "_B"
                        : "_S"
        );
    }

    if(!TranslationPhraseExists(szBuffer)) {
        szBuffer[0] = 0;
    } else {
        Format(szBuffer, size, "%T", szBuffer, props[2]);
    }

    #if defined DEBUG
    DWRITE("%s: Template:
            \n\t\tSender: %N
            \n\t\tRecipient: %N
            \n\t\tPart: %s
            \n\t\tOutput: %s", DEBUG, SENDER_INDEX(props[1]), props[2], szBinds[part], szBuffer);
    #endif
}