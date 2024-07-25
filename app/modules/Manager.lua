local ____exports = {}
local ManagerModule
local broadcast = require("ludobits.m.broadcast")
local ____modules_const = require("modules.modules_const")
local _ID_MESSAGES = ____modules_const._ID_MESSAGES
local ____game_config = require("main.game_config")
local ID_YANDEX_METRICA = ____game_config.ID_YANDEX_METRICA
local VK_SHARE_URL = ____game_config.VK_SHARE_URL
local ____Log = require("modules.Log")
local register_log = ____Log.register_log
local update_debug_log = ____Log.update_debug_log
local ____Storage = require("modules.Storage")
local register_storage = ____Storage.register_storage
local ____GameStorage = require("modules.GameStorage")
local register_game_storage = ____GameStorage.register_game_storage
local ____Sound = require("modules.Sound")
local register_sound = ____Sound.register_sound
local ____Lang = require("modules.Lang")
local register_lang = ____Lang.register_lang
local ____Scene = require("modules.Scene")
local register_scene = ____Scene.register_scene
local ____Ads = require("modules.Ads")
local register_ads = ____Ads.register_ads
local ____System = require("modules.System")
local register_system = ____System.register_system
local ____Rate = require("modules.Rate")
local register_rate = ____Rate.register_rate
local ____Metrica = require("modules.Metrica")
local register_metrica = ____Metrica.register_metrica
local ____Camera = require("modules.Camera")
local register_camera = ____Camera.register_camera
function ManagerModule()
    local check_ready, send_raw, send, MANAGER_ID, _is_ready
    function check_ready(callback_ready)
        local id_timer
        id_timer = timer.delay(
            0.1,
            true,
            function()
                if Ads.is_ready() then
                    timer.cancel(id_timer)
                    _is_ready = true
                    send("MANAGER_READY")
                    log("All Managers ready ver: " .. sys.get_config("project.version"))
                    if callback_ready then
                        callback_ready()
                    end
                end
            end
        )
    end
    function send_raw(message_id, message_data, receiver)
        if receiver == nil then
            receiver = MANAGER_ID
        end
        msg.post(receiver, message_id, message_data)
    end
    function send(message_id, message_data, receiver)
        if receiver == nil then
            receiver = MANAGER_ID
        end
        send_raw(message_id, message_data, receiver)
    end
    MANAGER_ID = "main:/manager"
    local UI_ID = "/ui#game"
    local LOGIC_ID = "/game_logic#game"
    _is_ready = false
    local broadcast_messages = {}
    local function init(callback_ready, use_custom_storage_key)
        if use_custom_storage_key == nil then
            use_custom_storage_key = false
        end
        math.randomseed(socket.gettime())
        register_system()
        register_log()
        register_storage(use_custom_storage_key)
        register_game_storage()
        register_metrica()
        register_sound()
        register_lang()
        register_scene()
        register_camera()
        register_ads()
        register_rate()
        Metrica.init(ID_YANDEX_METRICA)
        Ads.set_social_share_params(VK_SHARE_URL)
        check_ready(callback_ready)
    end
    local function is_ready()
        return _is_ready
    end
    local function send_raw_ui(message_id, message_data, receiver)
        if receiver == nil then
            receiver = UI_ID
        end
        send_raw(message_id, message_data, receiver)
    end
    local function send_raw_game(message_id, message_data, receiver)
        if receiver == nil then
            receiver = LOGIC_ID
        end
        send_raw(message_id, message_data, receiver)
    end
    local function send_game(message_id, message_data, receiver)
        if receiver == nil then
            receiver = LOGIC_ID
        end
        send_raw(message_id, message_data, receiver)
    end
    local function on_message(_this, message_id, message, sender)
        Scene._on_message(_this, message_id, message, sender)
        Sound._on_message(_this, message_id, message, sender)
        Ads._on_message(_this, message_id, message, sender)
        Rate._on_message(_this, message_id, message, sender)
    end
    local function update(dt)
        update_debug_log(dt)
    end
    local function init_gui()
        Lang.apply()
    end
    local function on_message_gui(_this, message_id, message, sender)
        broadcast.on_message(message_id, message, sender)
        if message_id == to_hash("APPLY_CUSTOM_LANG") then
            Lang.apply()
        end
    end
    local function final()
        do
            local i = 0
            while i < #broadcast_messages do
                local message_id = broadcast_messages[i + 1]
                broadcast.unregister(message_id)
                i = i + 1
            end
        end
        broadcast_messages = {}
    end
    local function register_message(message_id, cb, auto_clear)
        if auto_clear == nil then
            auto_clear = true
        end
        broadcast.register(message_id, cb)
        if auto_clear then
            broadcast_messages[#broadcast_messages + 1] = message_id
        end
    end
    local function trigger_message(message_id, message)
        broadcast.send(message_id, message)
    end
    return {
        init = init,
        on_message = on_message,
        send = send,
        send_raw = send_raw,
        send_game = send_game,
        send_raw_game = send_raw_game,
        send_raw_ui = send_raw_ui,
        is_ready = is_ready,
        init_gui = init_gui,
        on_message_gui = on_message_gui,
        update = update,
        final = final,
        register_message = register_message,
        trigger_message = trigger_message,
        MANAGER_ID = MANAGER_ID
    }
end
local function _to_hash(key)
    return hash(key)
end
function ____exports.register_manager()
    _G.Manager = ManagerModule()
    _G.to_hash = _to_hash
    _G.ID_MESSAGES = _ID_MESSAGES
end
return ____exports
