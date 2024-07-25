local ____exports = {}
local SystemModule
local ____game_config = require("main.game_config")
local IS_DEBUG_MODE = ____game_config.IS_DEBUG_MODE
function SystemModule()
    local info = sys.get_sys_info()
    local platform = info.system_name
    local function init()
        local src_assert = assert
        _G.assert = function(v, ...)
            local args = {...}
            if not v then
                local text = (("Assert:" .. tostring(args[1])) .. "\n") .. debug.traceback()
                Log.error(text)
                if IS_DEBUG_MODE then
                    if share ~= nil then
                        share.text(text)
                    end
                end
            end
            return src_assert(
                v,
                unpack(args)
            )
        end
        sys.set_error_handler(function(source, message, traceback)
            Log.error(
                "SystemError:",
                message,
                "\n",
                source,
                "\n",
                traceback
            )
        end)
        if platform == "HTML5" then
            html5.run("document.oncontextmenu = function(e){return false}")
        end
    end
    local function now()
        return socket.gettime()
    end
    init()
    return {platform = platform, now = now}
end
function ____exports.register_system()
    _G.System = SystemModule()
end
return ____exports
