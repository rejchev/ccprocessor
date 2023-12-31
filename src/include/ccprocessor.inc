#if defined _ccprocessor_included
 #endinput
#endif
#define _ccprocessor_included

#define API_KEY             19072023
#define API_OOD             "The plugin module uses an outdated API. You must update it."

#define STATUS_LENGTH       16
#define TEAM_LENGTH         64
#define PREFIX_LENGTH       64
#define NAME_LENGTH         128
#define MESSAGE_LENGTH      256
#define MAX_LENGTH          512

// OnRebuildString
#define SENDER_INDEX(%0)    (%0 >> 3)
#define SENDER_TEAM(%0)     ((%0 >> 1) & 0x03)
#define SENDER_ALIVE(%0)    view_as<bool>((%0 & 0x01)) 

// Message template parts
enum
{
    BIND_PROTOTYPE = 0,

    BIND_STATUS_CO,
    BIND_STATUS,

    BIND_TEAM_CO,
    BIND_TEAM,

    BIND_PREFIX_CO,
    BIND_PREFIX,

    BIND_NAME_CO,
    BIND_NAME,

    BIND_MSG_CO,
    BIND_MSG,

    BIND_MAX
};

enum Processing
{
    Proc_Continue = 0,
    Proc_Change,
    Proc_Reject,
    Proc_Stop
};

#include "ccprocessor/natives.inc"
#include "ccprocessor/forwards.inc"
#include "ccprocessor/stocks.inc"
#include "ccprocessor/debug.inc"

public SharedPlugin __pl_ccprocessor= 
{
    name = "ccprocessor",
    file = "ccprocessor.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};
