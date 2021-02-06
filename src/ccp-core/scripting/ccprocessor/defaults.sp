void GetDefaultValue(
    const char[] indent, int props, int lang, 
    int part, const char[] input, char[] szBuffer, int size
)
{
    if(part == BIND_NAME || part == BIND_MSG || part == BIND_PROTOTYPE) {
        if(part != BIND_PROTOTYPE) FormatEx(szBuffer, size, "%s", input);
        else FormatEx(szBuffer, size, "%c %T", 1, input, (props >> 3));
        return;
    }

    // DEF_{BIND}
    FormatBind("DEF_", part, 'u', szBuffer, size);

    // DEF_{ALIVE/SENDER}
    Format(szBuffer, size, "%s_%s", szBuffer, 
        (part < BIND_TEAM_CO) 
            ? (view_as<bool>(props & 0x01)) 
                ? "A" 
                : "D" 
            : (part < BIND_PREFIX_CO) 
                ? indent 
                : ((props >> 3)) 
                    ? "U" 
                    : "S"
    );

    // DEF_{ALIVE/SENDER}_{TEAM/SENDER}
    if(part < BIND_PREFIX_CO) {
        Format(szBuffer, size, "%s%s", szBuffer,
            (part < BIND_TEAM_CO) // Status & Status CO
                ? (!(view_as<bool>(props & 0x01))) // Died
                    ? (!(props >> 3)) // Server
                        ? "_S"
                        : ""
                    : ""  
                : (((props >> 1) & 0x03) == 2)  // Team & Team CO
                    ? "_R"
                    : (((props >> 1) & 0x03) == 3)
                        ? "_B"
                        : "_S"
        );
    }

    if(!TranslationPhraseExists(szBuffer)) {
        szBuffer[0] = 0;
        return;
    }

    Format(szBuffer, size, "%T", szBuffer, lang);    
}