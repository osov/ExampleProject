local ____exports = {}
local RateModule
function RateModule()
    local _is_shown = false
    local function show()
        if System.platform == "Windows" or System.platform == "Android" or System.platform == "HTML5" and Ads.get_social_platform() == "yandex" then
            msg.post(
                "main:/rate#rate",
                to_hash("SHOW_RATE")
            )
        end
    end
    local function _mark_shown()
        _is_shown = true
    end
    local function is_shown()
        local tmp = _is_shown
        _is_shown = false
        return tmp
    end
    local function _on_message(_this, message_id, _message, sender)
        if message_id == to_hash("MANAGER_READY") then
            msg.post(
                "main:/rate#rate",
                to_hash("MANAGER_READY")
            )
        end
    end
    return {show = show, is_shown = is_shown, _mark_shown = _mark_shown, _on_message = _on_message}
end
function ____exports.register_rate()
    _G.Rate = RateModule()
end
return ____exports
