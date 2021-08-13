#if defined _ripext_included_
    #endinput
#endif
#define _ripext_included_

#define asJSON(%0)  view_as<JSON>(%0)
#define asJSONO(%0) view_as<JSONObject>(%0)
#define asJSONA(%0) view_as<JSONArray>(%0)
#define asJSONK(%0) view_as<JSONObjectKeys>(%0)

#include <jansson>
#include <ripext/http>

/**
 * Do not edit below this line!
 */
public Extension __ext_rip =
{
    name = "REST in Pawn",
    file = "rip.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};
