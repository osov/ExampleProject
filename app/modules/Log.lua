local ____lualib = require("lualib_bundle")
local __TS__ArrayIndexOf = ____lualib.__TS__ArrayIndexOf
local __TS__StringSplit = ____lualib.__TS__StringSplit
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local ____exports = {}
local log_worker, LogModule, LogScreenModule, log_priority, worker, screen_text, screen_color, log_position
local ____utils = require("utils.utils")
local hex2rgba = ____utils.hex2rgba
function log_worker()
    local function show(prefix, level, log_level, text)
        if prefix == nil then
            prefix = ""
        end
        local is_logging = __TS__ArrayIndexOf(log_priority, level) >= __TS__ArrayIndexOf(log_priority, log_level)
        if not is_logging then
            return
        end
        local time = os.date(
            "%H:%M:%S",
            os.time()
        )
        local str = ((((("[" .. time) .. "-") .. level) .. (prefix == "" and "" or (" _" .. prefix) .. "_ ")) .. "] ") .. text
        if level == "error" then
            local stack = debug.traceback()
            local tmp = __TS__StringSplit(stack, "\n")
            __TS__ArraySplice(tmp, 0, 4)
            str = str .. ("\n" .. "stack:") .. table.concat(tmp, "\n")
        end
        print(str)
        if System.platform == "HTML5" then
            html5.run(("console.log(" .. json.encode(str)) .. ")")
        end
    end
    return {show = show}
end
function LogModule(_prefix, _log_level)
    if _prefix == nil then
        _prefix = ""
    end
    if _log_level == nil then
        _log_level = "notice"
    end
    local function get_with_prefix(prefix, log_level)
        if log_level == nil then
            log_level = "notice"
        end
        return LogModule(prefix, log_level)
    end
    local function send(level, _args)
        local str = ""
        for k in pairs(_args) do
            local a = _args[k]
            if type(a) == "table" then
                str = str .. json.encode(a) .. ", "
            else
                str = str .. tostring(a) .. ", "
            end
        end
        if str ~= "" then
            str = string.sub(str, 0, -3)
        end
        worker.show(_prefix, level, _log_level, str)
    end
    local function notice(...)
        local _args = {...}
        send("notice", _args)
    end
    local function log(...)
        local _args = {...}
        send("log", _args)
    end
    local function warn(...)
        local _args = {...}
        send("warn", _args)
    end
    local function ____error(...)
        local _args = {...}
        send("error", _args)
    end
    return {
        get_with_prefix = get_with_prefix,
        notice = notice,
        log = log,
        warn = warn,
        error = ____error
    }
end
function LogScreenModule()
    local function log(...)
        local _args = {...}
        local str = ""
        for k in pairs(_args) do
            local a = _args[k]
            if type(a) == "table" then
                str = str .. json.encode(a) .. " "
            else
                str = str .. tostring(a) .. " "
            end
        end
        if str ~= "" then
            str = string.sub(str, 0, -3)
        end
        screen_text = screen_text .. str .. "\n"
    end
    local function clear()
        screen_text = ""
    end
    local function set_color(color)
        if color == nil then
            color = "#f00"
        end
        screen_color = hex2rgba(color)
    end
    local function set_position(x, y)
        log_position.x = x
        log_position.y = y
    end
    return {log = log, clear = clear, set_color = set_color, set_position = set_position}
end
function ____exports.register_log()
    _G.Log = LogModule()
    _G.log = Log.log
    _G.LogScreen = LogScreenModule()
end
log_priority = {
    "notice",
    "log",
    "info",
    "warn",
    "error"
}
worker = log_worker()
screen_text = ""
screen_color = hex2rgba("#f00")
log_position = vmath.vector3(10, 530, 0)
function ____exports.update_debug_log(dt)
    if screen_text ~= "" then
        msg.post("@render:", "draw_debug_text", {text = screen_text, position = log_position, color = screen_color})
    end
end
return ____exports
