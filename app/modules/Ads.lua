local ____lualib = require("lualib_bundle")
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local ____exports = {}
local AdsModule
local ____game_config = require("main.game_config")
local ADS_CONFIG = ____game_config.ADS_CONFIG
local ads_android = require("utils.ads_android")
function AdsModule()
    local _is_ready = false
    local ads_log = Log.get_with_prefix("Ads")
    local config = {ads_interval = 3 * 60, ads_delay = 30}
    local platform = sys.get_sys_info().system_name
    local social_platform
    local social_params
    local share_options = {vk = {link = ""}}
    local last_view_ads = 0
    local is_real_reward = false
    local cb_inter_shown
    local cb_rewarded_shown
    local function init(id_banners, id_inters, id_reward, banner_on_init, ads_interval, ads_delay, init_callback)
        if id_banners == nil then
            id_banners = {"R-M-DEMO-300x250"}
        end
        if id_inters == nil then
            id_inters = {"R-M-DEMO-interstitial"}
        end
        if id_reward == nil then
            id_reward = {}
        end
        if banner_on_init == nil then
            banner_on_init = false
        end
        if ads_interval == nil then
            ads_interval = 4 * 60
        end
        if ads_delay == nil then
            ads_delay = 30
        end
        config.ads_delay = ads_delay
        config.ads_interval = ads_interval
        last_view_ads = System.now() - (config.ads_interval - config.ads_delay)
        if System.platform == "HTML5" then
            init_callback()
        elseif System.platform == "Android" then
            ads_android.init(id_banners, id_inters, id_reward, banner_on_init)
            platform = "android"
            init_callback()
        else
            init_callback()
        end
    end
    local function get_social_platform()
        if System.platform == "HTML5" then
            return social_platform
        end
        return ""
    end
    local function player_init(authorizationOptions, callback)
        if authorizationOptions == nil then
            authorizationOptions = {}
        end
    end
    local function leaderboards_set_score(setScoreOptions, callback)
        if setScoreOptions == nil then
            setScoreOptions = {}
        end
    end
    local function leaderboards_get_entitys(options, callback)
    end
    local function feedback_request_review(callback)
    end
    local function interstitial_state_changed(state)
        if state == "opened" then
            last_view_ads = System.now()
            Sound.set_pause(true)
            ads_log.log("Fix last ads time")
        elseif state == "closed" then
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, {result = true})
            Sound.set_pause(false)
        elseif state == "failed" then
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, {result = true})
            Sound.set_pause(false)
        end
    end
    local function rewarded_state_changed(state)
        if state == "opened" then
            Sound.set_pause(true)
        elseif state == "rewarded" then
        elseif state == "closed" then
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, {result = true})
            Sound.set_pause(false)
        elseif state == "failed" then
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, {result = false})
            Sound.set_pause(false)
        end
    end
    local function is_view_inter()
        local now = System.now()
        return now - last_view_ads > config.ads_interval
    end
    local function _show_interstitial(is_check)
        if is_check == nil then
            is_check = true
        end
        local now = System.now()
        if System.platform == "HTML5" then
            if not is_check or now - last_view_ads > config.ads_interval then
            else
                ads_log.log("Wait ads time:" .. tostring(config.ads_interval - (now - last_view_ads)))
                Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, {result = false})
                return
            end
        elseif System.platform == "Android" then
            ads_android.show_interstitial(not is_check and 0 or config.ads_interval, config.ads_delay)
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, {result = true})
        elseif System.platform == "Windows" then
            log("fake-Inter show wait")
            timer.delay(
                2,
                false,
                function()
                    Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, {result = true})
                    log("fake-Inter show triggered")
                end
            )
        end
    end
    local function _show_reward()
        if System.platform == "HTML5" then
        elseif System.platform == "Android" then
            if is_real_reward then
                ads_android.show_rewarded()
            else
                ads_android.show_interstitial(0, config.ads_delay)
            end
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, {result = true})
        elseif System.platform == "Windows" then
            log("fake-Reward show wait")
            timer.delay(
                2,
                false,
                function()
                    Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, {result = true})
                    log("fake-Reward show triggered")
                end
            )
        end
    end
    local function is_banner_supported()
        if platform == "android" or platform == "ios" or System.platform == "HTML5" and __TS__ArrayIncludes({"ok", "vk"}, social_platform) then
            return true
        else
            return false
        end
    end
    local function _convert_positions(pos)
        if pos == ____exports.BannerPos.POS_BOTTOM_CENTER then
            return yandexads.POS_BOTTOM_CENTER
        elseif pos == ____exports.BannerPos.POS_BOTTOM_LEFT then
            return yandexads.POS_BOTTOM_LEFT
        elseif pos == ____exports.BannerPos.POS_BOTTOM_RIGHT then
            return yandexads.POS_BOTTOM_RIGHT
        elseif pos == ____exports.BannerPos.POS_TOP_CENTER then
            return yandexads.POS_TOP_CENTER
        elseif pos == ____exports.BannerPos.POS_TOP_LEFT then
            return yandexads.POS_TOP_LEFT
        elseif pos == ____exports.BannerPos.POS_TOP_RIGHT then
            return yandexads.POS_TOP_RIGHT
        elseif pos == ____exports.BannerPos.POS_NONE then
            return -1
        end
        return -1
    end
    local function _show_banner(pos)
        if not is_banner_supported() then
            return
        end
        local bannerOptions = {vk = {position = "bottom", layoutType = "resize", canClose = false}}
        if System.platform == "HTML5" and social_platform == "vk" then
        elseif System.platform == "Android" then
            ads_android.load_banner(true)
            ads_android.show_banner(_convert_positions(pos))
        else
            ads_log.warn("Вызов баннера вручную не поддерживается")
        end
    end
    local function _hide_banner()
        if not is_banner_supported() then
            return
        elseif System.platform == "Android" then
            ads_android.destroy_banner()
        end
    end
    local function show_reward(callback_shown)
        if callback_shown ~= nil then
            cb_rewarded_shown = callback_shown
        end
        Manager.send("SHOW_REWARD")
    end
    local function show_interstitial(is_check, callback_shown)
        if is_check == nil then
            is_check = true
        end
        if callback_shown ~= nil then
            cb_inter_shown = callback_shown
        end
        Manager.send("SHOW_INTER", {is_check = is_check})
    end
    local function show_banner(pos)
        if pos == nil then
            pos = ____exports.BannerPos.POS_NONE
        end
        Manager.send("SHOW_BANNER", {pos = pos})
    end
    local function hide_banner()
        Manager.send("HIDE_BANNER")
    end
    local function is_share_supported()
        if System.platform == "HTML5" then
            return social_params.isShareSupported
        elseif System.platform == "Android" then
            return true
        else
            return false
        end
    end
    local function social_share()
        if System.platform == "HTML5" then
        else
            if share ~= nil then
                share.text("https://play.google.com/store/apps/details?id=" .. sys.get_config("android.package"))
            end
        end
        Metrica.report("share")
    end
    local function set_social_share_params(new_app_link)
        share_options.vk.link = new_app_link
    end
    local function is_favorite_supported()
        if System.platform == "HTML5" then
            return social_params.isAddToFavoritesSupported
        else
            return false
        end
    end
    local function add_favorite()
        if not is_favorite_supported() then
            return
        end
    end
    local function _on_message(_this, message_id, message, sender)
        if message_id == hash("SHOW_REWARD") then
            _show_reward()
        end
        if message_id == hash("SHOW_INTER") then
            _show_interstitial(message.is_check)
        end
        if message_id == hash("SHOW_BANNER") then
            _show_banner(message.pos)
        end
        if message_id == hash("HIDE_BANNER") then
            _hide_banner()
        end
    end
    local function ads_init_callback()
        _is_ready = true
    end
    local function is_ready()
        return _is_ready
    end
    local function set_real_reward_mode(val)
        is_real_reward = val
    end
    local function register_ads_callbacks()
        Manager.register_message(
            ID_MESSAGES.MSG_ON_INTER_SHOWN,
            function(msg)
                if cb_inter_shown ~= nil then
                    cb_inter_shown(true)
                end
            end
        )
        Manager.register_message(
            ID_MESSAGES.MSG_ON_REWARDED,
            function(msg)
                if cb_rewarded_shown ~= nil then
                    cb_rewarded_shown(msg.result)
                end
            end
        )
    end
    init(
        ADS_CONFIG.id_banners,
        ADS_CONFIG.id_inters,
        ADS_CONFIG.id_reward,
        ADS_CONFIG.banner_on_init,
        ADS_CONFIG.ads_interval,
        ADS_CONFIG.ads_delay,
        ads_init_callback
    )
    return {
        is_ready = is_ready,
        get_social_platform = get_social_platform,
        player_init = player_init,
        leaderboards_set_score = leaderboards_set_score,
        feedback_request_review = feedback_request_review,
        _on_message = _on_message,
        add_favorite = add_favorite,
        set_social_share_params = set_social_share_params,
        social_share = social_share,
        is_share_supported = is_share_supported,
        show_reward = show_reward,
        show_interstitial = show_interstitial,
        show_banner = show_banner,
        hide_banner = hide_banner,
        is_favorite_supported = is_favorite_supported,
        leaderboards_get_entitys = leaderboards_get_entitys,
        set_real_reward_mode = set_real_reward_mode,
        is_view_inter = is_view_inter,
        register_ads_callbacks = register_ads_callbacks
    }
end
function ____exports.register_ads()
    _G.Ads = AdsModule()
end
____exports.BannerPos = BannerPos or ({})
____exports.BannerPos.POS_NONE = 0
____exports.BannerPos[____exports.BannerPos.POS_NONE] = "POS_NONE"
____exports.BannerPos.POS_TOP_LEFT = 1
____exports.BannerPos[____exports.BannerPos.POS_TOP_LEFT] = "POS_TOP_LEFT"
____exports.BannerPos.POS_TOP_CENTER = 2
____exports.BannerPos[____exports.BannerPos.POS_TOP_CENTER] = "POS_TOP_CENTER"
____exports.BannerPos.POS_TOP_RIGHT = 3
____exports.BannerPos[____exports.BannerPos.POS_TOP_RIGHT] = "POS_TOP_RIGHT"
____exports.BannerPos.POS_BOTTOM_LEFT = 4
____exports.BannerPos[____exports.BannerPos.POS_BOTTOM_LEFT] = "POS_BOTTOM_LEFT"
____exports.BannerPos.POS_BOTTOM_CENTER = 5
____exports.BannerPos[____exports.BannerPos.POS_BOTTOM_CENTER] = "POS_BOTTOM_CENTER"
____exports.BannerPos.POS_BOTTOM_RIGHT = 6
____exports.BannerPos[____exports.BannerPos.POS_BOTTOM_RIGHT] = "POS_BOTTOM_RIGHT"
____exports.BannerPos.POS_CENTER = 7
____exports.BannerPos[____exports.BannerPos.POS_CENTER] = "POS_CENTER"
return ____exports
