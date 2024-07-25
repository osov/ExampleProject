local ____exports = {}
local SceneModule
local ____utils = require("utils.utils")
local hex2rgba = ____utils.hex2rgba
function SceneModule()
    local wait_load_scene = ""
    local last_loading_scene = ""
    local last_scene = ""
    local _wait_ready_manager = false
    local function init()
        if System.platform == "HTML5" then
            html5.run("window.set_light = function(val){document.body.style.backgroundColor = val}")
        end
    end
    local function set_bg(color)
        msg.post(
            "@render:",
            "clear_color",
            {color = hex2rgba(color, 0)}
        )
        if System.platform == "HTML5" then
            html5.run(("set_light('" .. color) .. "')")
        end
    end
    local function load(name, wait_ready_manager)
        if wait_ready_manager == nil then
            wait_ready_manager = false
        end
        _wait_ready_manager = wait_ready_manager
        Manager.send("LOAD_SCENE", {name = name})
    end
    local function restart()
        Manager.send("RESTART_SCENE")
    end
    local is_restarting_scene = false
    local function _on_message(_this, message_id, _message, sender)
        if message_id == to_hash("MANAGER_READY") then
            if wait_load_scene == "" then
                return
            end
            Manager.send("LOAD_SCENE", {name = wait_load_scene})
        end
        if message_id == to_hash("RESTART_SCENE") then
            if last_scene == "" then
                return Log.warn("Сцена для перезагрузки не найдена")
            end
            local n = (Manager.MANAGER_ID .. "#") .. last_scene
            msg.post(n, "disable")
            msg.post(n, "final")
            msg.post(n, "unload")
            is_restarting_scene = true
        end
        if message_id == to_hash("LOAD_SCENE") then
            local message = _message
            if _wait_ready_manager and not Manager.is_ready() then
                wait_load_scene = message.name
                return
            end
            wait_load_scene = ""
            last_loading_scene = message.name
            msg.post((Manager.MANAGER_ID .. "#") .. message.name, "load")
        end
        if message_id == hash("proxy_unloaded") then
            if is_restarting_scene and last_scene ~= "" then
                last_loading_scene = last_scene
                msg.post((Manager.MANAGER_ID .. "#") .. last_scene, "load")
            end
        end
        if message_id == hash("proxy_loaded") then
            if last_scene ~= "" and not is_restarting_scene then
                local n = (Manager.MANAGER_ID .. "#") .. last_scene
                msg.post(n, "disable")
                msg.post(n, "final")
                msg.post(n, "unload")
                last_scene = ""
            end
            is_restarting_scene = false
            msg.post(sender, "init")
            msg.post(sender, "enable")
            last_scene = last_loading_scene
            last_loading_scene = ""
            Manager.send("SCENE_LOADED", {name = last_scene})
        end
    end
    local function get_current_name()
        return last_scene
    end
    init()
    return {
        _on_message = _on_message,
        restart = restart,
        load = load,
        set_bg = set_bg,
        get_current_name = get_current_name
    }
end
function ____exports.register_scene()
    _G.Scene = SceneModule()
end
return ____exports
