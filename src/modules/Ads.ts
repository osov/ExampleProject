/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
//import * as instantgamesbridge from "instantgamesbridge.instantgamesbridge";
import { ADS_CONFIG } from "../main/game_config";
import * as ads_android from "../utils/ads_android";


/*
    Модуль для работы с рекламой
*/

declare global {
    const Ads: ReturnType<typeof AdsModule>;
}

export function register_ads() {
    (_G as any).Ads = AdsModule();
}

export enum BannerPos {
    POS_NONE,
    POS_TOP_LEFT,
    POS_TOP_CENTER,
    POS_TOP_RIGHT,
    POS_BOTTOM_LEFT,
    POS_BOTTOM_CENTER,
    POS_BOTTOM_RIGHT,
    POS_CENTER
}

interface SocialParams {
    isShareSupported: boolean;
    isJoinCommunitySupported: boolean;
    isInviteFriendsSupported: boolean;
    isCreatePostSupported: boolean;
    isAddToFavoritesSupported: boolean;
    isAddToHomeScreenSupported: boolean;
    isRateSupported: boolean;
}

type WebPlatform = "yandex" | "vk" | 'crazy_games';
type BridgePlatforms = 'android' | 'ios';
type CallbackAds = (state: boolean) => void;

function AdsModule() {
    let _is_ready = false;
    const ads_log = Log.get_with_prefix('Ads');
    const config = {
        ads_interval: 3 * 60,
        ads_delay: 30,
    };

    let platform: BridgePlatforms = sys.get_sys_info().system_name;
    let social_platform: WebPlatform;
    let social_params: SocialParams;
    const share_options = { 'vk': { link: '' } };
    let last_view_ads = 0;
    let is_real_reward = false;
    let cb_inter_shown: CallbackAds;
    let cb_rewarded_shown: CallbackAds;

    function init(id_banners = ['R-M-DEMO-300x250'], id_inters = ['R-M-DEMO-interstitial'], id_reward: string[] = [], banner_on_init = false, ads_interval = 4 * 60, ads_delay = 30, init_callback: InitCallback) {
        config.ads_delay = ads_delay;
        config.ads_interval = ads_interval;
        last_view_ads = System.now() - (config.ads_interval - config.ads_delay);
        // html5
        if (System.platform == "HTML5") {
            init_callback();
        }
        // android
        else if (System.platform == "Android") {
            ads_android.init(id_banners, id_inters, id_reward, banner_on_init);
            platform = "android";
            init_callback();
        }
        else {
            init_callback();
        }
    }

    function get_social_platform() {
        if (System.platform == "HTML5")
            return social_platform;
        return '';
    }

    function player_init(authorizationOptions = {}, callback: any) {
        //
    }

    function leaderboards_set_score(setScoreOptions = {}, callback: any) {
        //
    }

    function leaderboards_get_entitys(options: any, callback: any) {
        //
    }

    function feedback_request_review(callback: any) {
        //
    }

    function interstitial_state_changed(state: string) {
        if (state == "opened") {
            last_view_ads = System.now(); // fix open time
            Sound.set_pause(true);
            ads_log.log('Fix last ads time');
        } else if (state == "closed") {
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, { result: true });
            Sound.set_pause(false);
        } else if (state == "failed") {
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, { result: true });
            Sound.set_pause(false);
        }
    }

    function rewarded_state_changed(state: string) {
        if (state == "opened") {
            Sound.set_pause(true);
        } else if (state == "rewarded") {
            // получена награда
        } else if (state == "closed") {
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, { result: true });
            Sound.set_pause(false);
        } else if (state == "failed") {
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, { result: false });
            Sound.set_pause(false);
        }
    }

    function is_view_inter() {
        const now = System.now();
        return now - last_view_ads > config.ads_interval;
    }

    function _show_interstitial(is_check = true) {
        const now = System.now();
        if (System.platform == "HTML5") {
            if (!is_check || now - last_view_ads > config.ads_interval) {
                // fix time
            } else {
                ads_log.log('Wait ads time:' + (config.ads_interval - (now - last_view_ads)));
                Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, { result: false });
                return;
            }
            //
        }
        // android
        else if (System.platform == "Android") {
            ads_android.show_interstitial(!is_check ? 0 : config.ads_interval, config.ads_delay);
            Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, { result: true });
        }
        else if (System.platform == 'Windows') {
            log('fake-Inter show wait');
            timer.delay(2, false, () => {
                Manager.trigger_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, { result: true });
                log('fake-Inter show triggered');
            });
        }
    }
    function _show_reward() {
        if (System.platform == "HTML5") {
            //
        }
        else if (System.platform == "Android") {
            if (is_real_reward)
                ads_android.show_rewarded();
            else
                ads_android.show_interstitial(0, config.ads_delay);
            Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, { result: true });
        }
        else if (System.platform == 'Windows') {
            log('fake-Reward show wait');
            timer.delay(2, false, () => {
                Manager.trigger_message(ID_MESSAGES.MSG_ON_REWARDED, { result: true });
                log('fake-Reward show triggered');
            });
        }
    }

    function is_banner_supported() {
        if (platform == "android" || platform == "ios" || (System.platform == 'HTML5' && ['ok', 'vk'].includes(social_platform)))
            return true;
        else
            return false;
    }

    function _convert_positions(pos: BannerPos) {
        if (pos == BannerPos.POS_BOTTOM_CENTER)
            return yandexads.POS_BOTTOM_CENTER;
        else if (pos == BannerPos.POS_BOTTOM_LEFT)
            return yandexads.POS_BOTTOM_LEFT;
        else if (pos == BannerPos.POS_BOTTOM_RIGHT)
            return yandexads.POS_BOTTOM_RIGHT;
        else if (pos == BannerPos.POS_TOP_CENTER)
            return yandexads.POS_TOP_CENTER;
        else if (pos == BannerPos.POS_TOP_LEFT)
            return yandexads.POS_TOP_LEFT;
        else if (pos == BannerPos.POS_TOP_RIGHT)
            return yandexads.POS_TOP_RIGHT;
        else if (pos == BannerPos.POS_NONE)
            return -1;
        return -1;
    }

    function _show_banner(pos: BannerPos) {
        if (!is_banner_supported())
            return;
        const bannerOptions = {
            'vk': {
                position: 'bottom', // Необязательный параметр, по умолчанию = bottom
                layoutType: 'resize', // Необязательный параметр
                canClose: false // Необязательный параметр
            },
        };
        if (System.platform == "HTML5" && social_platform == "vk") {
            //
        } else if (System.platform == "Android") {
            ads_android.load_banner(true);
            ads_android.show_banner(_convert_positions(pos));
        } else {
            ads_log.warn("Вызов баннера вручную не поддерживается");
        }

    }
    function _hide_banner() {
        if (!is_banner_supported())
            return;
        else if (System.platform == "Android")
            ads_android.destroy_banner();
    }

    function show_reward(callback_shown?: CallbackAds) {
        if (callback_shown != null)
            cb_rewarded_shown = callback_shown;
        Manager.send("SHOW_REWARD");
    }

    function show_interstitial(is_check = true, callback_shown?: CallbackAds) {
        if (callback_shown != null)
            cb_inter_shown = callback_shown;
        Manager.send("SHOW_INTER", { is_check });
    }

    function show_banner(pos: BannerPos = BannerPos.POS_NONE) {
        Manager.send("SHOW_BANNER", { pos });
    }

    function hide_banner() {
        Manager.send("HIDE_BANNER");
    }

    function is_share_supported() {
        if (System.platform == "HTML5")
            return social_params.isShareSupported;
        else if (System.platform == "Android")
            return true;
        else
            return false;
    }

    function social_share() {
        if (System.platform == "HTML5") {
            //
        } else {
            if (share != null)
                share.text("https://play.google.com/store/apps/details?id=" + sys.get_config("android.package"));
        }
        Metrica.report('share');
    }

    function set_social_share_params(new_app_link: string) {
        share_options.vk.link = new_app_link;
    }

    function is_favorite_supported() {
        if (System.platform == "HTML5")
            return social_params.isAddToFavoritesSupported;
        else
            return false;
    }

    function add_favorite() {
        if (!is_favorite_supported())
            return;
    }

    function _on_message(_this: any, message_id: hash, message: any, sender: hash): void {
        if (message_id == hash('SHOW_REWARD'))
            _show_reward();
        if (message_id == hash('SHOW_INTER'))
            _show_interstitial(message.is_check as boolean);
        if (message_id == hash('SHOW_BANNER'))
            _show_banner(message.pos as BannerPos);
        if (message_id == hash('HIDE_BANNER'))
            _hide_banner();
    }

    function ads_init_callback() {
        _is_ready = true;
    }

    function is_ready() {
        return _is_ready;
    }

    function set_real_reward_mode(val: boolean) {
        is_real_reward = val;
    }

    function register_ads_callbacks() {
        Manager.register_message(ID_MESSAGES.MSG_ON_INTER_SHOWN, (msg: any) => {
            if (cb_inter_shown != null)
                cb_inter_shown(true);
        });
        Manager.register_message(ID_MESSAGES.MSG_ON_REWARDED, (msg: any) => {
            if (cb_rewarded_shown != null)
                cb_rewarded_shown(msg.result as boolean);
        });
    }

    init(ADS_CONFIG.id_banners, ADS_CONFIG.id_inters, ADS_CONFIG.id_reward, ADS_CONFIG.banner_on_init, ADS_CONFIG.ads_interval, ADS_CONFIG.ads_delay, ads_init_callback);

    return {
        is_ready, get_social_platform, player_init, leaderboards_set_score, feedback_request_review,
        _on_message, add_favorite, set_social_share_params, social_share, is_share_supported,
        show_reward, show_interstitial, show_banner, hide_banner, is_favorite_supported, leaderboards_get_entitys, set_real_reward_mode, is_view_inter, register_ads_callbacks
    };


}