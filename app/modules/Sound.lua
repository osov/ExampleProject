local ____exports = {}
local SoundModule
local druid = require("druid.druid")
function SoundModule()
    local is_active, set_active, play
    function is_active()
        return Storage.get_bool("is_sound", true)
    end
    function set_active(active)
        Storage.set("is_sound", active)
        sound.set_group_gain("master", active and 1 or 0)
    end
    function play(name, speed, volume)
        if speed == nil then
            speed = 1
        end
        if volume == nil then
            volume = 1
        end
        Manager.send("PLAY_SND", {name = name, speed = speed, volume = volume})
    end
    local function init()
        set_active(is_active())
        play("empty")
    end
    local function attach_druid_click(name)
        if name == nil then
            name = "btn"
        end
        druid.set_sound_function(function() return play(name) end)
    end
    local function _on_message(_this, message_id, _message, sender)
        if message_id == to_hash("STOP_SND") then
            local message = _message
            sound.stop("/sounds#" .. message.name)
        end
        if message_id == to_hash("PLAY_SND") then
            local message = _message
            sound.play("/sounds#" .. message.name, {speed = message.speed, gain = message.volume})
        end
    end
    local function stop(name)
        Manager.send("STOP_SND", {name = name})
    end
    local function set_pause(val)
        local scene_name = Scene.get_current_name()
        if scene_name ~= "" then
            Manager.send("ON_SOUND_PAUSE", {val = val}, (scene_name .. ":/ui#") .. scene_name)
        end
        if not is_active() then
            return
        end
        sound.set_group_gain("master", val and 0 or 1)
    end
    init()
    return {
        _on_message = _on_message,
        is_active = is_active,
        set_active = set_active,
        play = play,
        stop = stop,
        set_pause = set_pause,
        attach_druid_click = attach_druid_click
    }
end
function ____exports.register_sound()
    _G.Sound = SoundModule()
end
return ____exports
