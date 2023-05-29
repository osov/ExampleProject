local ____exports = {}
local ____game_config = require("main.game_config")
local ADS_CONFIG = ____game_config.ADS_CONFIG
local config = {is_auto_init = true, banner_interval = 30}
local last_interstitial = 0
local id_banners = {}
local id_inters = {}
local id_rewards = {}
local id_timer_inter
local id_timer_banner
local banner_visible = false
local banner_pos = -1
local is_rewarded = false
local is_ready = false
local banner_index = 0
local inter_index = 0
local reward_index = 0
local function _load_banner()
    yandexads.load_banner(id_banners[banner_index + 1], 0)
end
local function _load_interstitial()
    yandexads.load_interstitial(id_inters[inter_index + 1])
end
local function _load_rewarded()
    is_rewarded = false
    yandexads.load_rewarded(id_rewards[reward_index + 1])
end
local function _update_banner()
    id_timer_banner = nil
    print("yandexads: updating banner")
    if banner_visible then
        _load_banner()
    end
end
local function _clear_banner_timer()
    if id_timer_banner ~= nil then
        print(
            "yandexads: clear timer banner",
            timer.cancel(id_timer_banner)
        )
        id_timer_banner = nil
    end
end
local function _start_refresh_banner(time)
    if time == nil then
        time = -1
    end
    _clear_banner_timer()
    id_timer_banner = timer.delay(time ~= -1 and time or config.banner_interval, false, _update_banner)
end
local function _start_refresh_inter(time)
    if time == nil then
        time = 0
    end
    if id_timer_inter ~= nil then
        print("yandexads: clear timer inter")
        timer.cancel(id_timer_inter)
        id_timer_inter = nil
    end
    id_timer_inter = timer.delay(time, false, _load_interstitial)
end
local function listener(____self, message_id, message)
    local event = message.event
    if message_id == yandexads.MSG_ADS_INITED then
        if event == yandexads.EVENT_LOADED then
            print("yandexads: MSG_ADS_INITED ok")
            is_ready = true
            if config.is_auto_init then
                if banner_visible and #id_banners > 0 then
                    _load_banner()
                end
                if #id_inters > 0 then
                    _load_interstitial()
                end
                if #id_rewards > 0 then
                    _load_rewarded()
                end
            end
        end
    elseif message_id == yandexads.MSG_BANNER then
        if event == yandexads.EVENT_LOADED then
            print(
                ("yandexads: MSG_BANNER EVENT_LOADED[" .. tostring(banner_index)) .. "]",
                banner_visible
            )
            banner_index = 0
            if banner_visible then
                yandexads.show_banner(banner_pos)
            else
                yandexads.hide_banner()
            end
            _start_refresh_banner()
        elseif event == yandexads.EVENT_ERROR_LOAD then
            print(
                ("yandexads: MSG_BANNER EVENT_ERROR_LOAD[" .. tostring(banner_index)) .. "]",
                banner_visible
            )
            banner_index = banner_index + 1
            if banner_index > #id_banners - 1 then
                banner_index = 0
            end
            _start_refresh_banner(5)
        end
    elseif message_id == yandexads.MSG_INTERSTITIAL then
        if event == yandexads.EVENT_LOADED then
            print(("yandexads: MSG_INTERSTITIAL EVENT_LOADED[" .. tostring(inter_index)) .. "]")
            inter_index = 0
        elseif event == yandexads.EVENT_ERROR_LOAD then
            print(("yandexads: MSG_INTERSTITIAL EVENT_ERROR_LOAD[" .. tostring(inter_index)) .. "]")
            inter_index = inter_index + 1
            if inter_index > #id_inters - 1 then
                inter_index = 0
            end
            _start_refresh_inter(5)
        elseif event == yandexads.EVENT_DISMISSED then
            last_interstitial = socket.gettime()
            print("yandexads: fix last show inter")
            _start_refresh_inter(2)
        end
    elseif message_id == yandexads.MSG_REWARDED then
        if event == yandexads.EVENT_LOADED then
            print(("yandexads: MSG_REWARDED EVENT_LOADED[" .. tostring(reward_index)) .. "]")
            reward_index = 0
        elseif event == yandexads.EVENT_ERROR_LOAD then
            print(("yandexads: MSG_REWARDED EVENT_ERROR_LOAD[" .. tostring(reward_index)) .. "]")
            reward_index = reward_index + 1
            if reward_index > #id_rewards - 1 then
                reward_index = 0
            end
        elseif event == yandexads.EVENT_REWARDED then
            is_rewarded = true
            print("yandexads: fix reward")
        elseif event == yandexads.EVENT_DISMISSED then
            _load_rewarded()
        end
    else
        print(
            "yandexads: NOT DEFINED",
            tostring(message_id)
        )
        pprint(message)
        return
    end
    print("yandexads: message_id:" .. tostring(message_id))
    pprint(message)
end
local function is_check(sub)
    if sub == nil then
        sub = ""
    end
    if not yandexads then
        print("yandexads: not installed", sub)
        return false
    end
    if not is_ready then
        print("yandexads: not ready", sub)
        return false
    end
    return true
end
function ____exports.init(_id_banners, _id_inters, _id_rewards, _banner_visible)
    if _id_banners == nil then
        _id_banners = {}
    end
    if _id_inters == nil then
        _id_inters = {}
    end
    if _id_rewards == nil then
        _id_rewards = {}
    end
    if _banner_visible == nil then
        _banner_visible = false
    end
    if not yandexads then
        print("yandexads: not installed")
        return
    end
    id_banners = _id_banners
    id_inters = _id_inters
    id_rewards = _id_rewards
    banner_visible = _banner_visible
    yandexads.set_callback(listener)
    yandexads.initialize()
    if ADS_CONFIG.is_mediation then
        local gdpr = Storage.get_int("gdpr", -1)
        if gdpr ~= -1 then
            yandexads.set_user_consent(gdpr == 1)
        end
    end
end
function ____exports.load_banner(visible)
    if visible == nil then
        visible = false
    end
    if not is_check("load_banner") then
        return false
    end
    banner_visible = visible
    _load_banner()
    return true
end
function ____exports.show_banner(pos)
    if pos == nil then
        pos = -1
    end
    banner_pos = pos == -1 and yandexads.POS_BOTTOM_CENTER or pos
    if not is_check("show_banner") then
        return false
    end
    banner_visible = true
    if not yandexads.is_banner_loaded() then
        print("yandexads: show_banner, banner not loaded ")
        return false
    end
    yandexads.show_banner(banner_pos)
    print("yandexads: show_banner", banner_pos)
    return true
end
function ____exports.hide_banner()
    if not is_check("hide_banner") then
        return false
    end
    banner_visible = false
    if not yandexads.is_banner_loaded() then
        print("yandexads: hide_banner, banner not loaded ")
        return false
    end
    yandexads.hide_banner()
    print("yandexads: hide_banner")
    return true
end
function ____exports.destroy_banner()
    if not is_check("destroy_banner") then
        return false
    end
    banner_visible = false
    yandexads.destroy_banner()
    print("yandexads: destroy_banner")
    return true
end
function ____exports.show_interstitial(time, first_delay)
    if time > 0 and last_interstitial == 0 and first_delay > 0 then
        last_interstitial = socket.gettime() - (time - first_delay)
    end
    if not is_check("show_interstitial") then
        return false
    end
    if not yandexads.is_interstitial_loaded() then
        print("yandexads: show_interstitial, interstitial not loaded")
        return false
    end
    local dt = socket.gettime() - last_interstitial
    if dt < time then
        print("yandexads: wait inter:", time - dt)
        return false
    end
    yandexads.show_interstitial()
    return true
end
function ____exports.show_rewarded()
    if not is_check("show_rewarded") then
        return false
    end
    if not yandexads.is_rewarded_loaded() then
        print("yandexads: show_rewarded, rewarded not loaded")
        return false
    end
    is_rewarded = false
    yandexads.show_rewarded()
    return true
end
return ____exports
