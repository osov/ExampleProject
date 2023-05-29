/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import * as broadcast from 'ludobits.m.broadcast';

import { MessageId, Messages, VoidCallback, _SystemMessages, _ID_MESSAGES } from "./modules_const";
import { ID_YANDEX_METRICA, VK_SHARE_URL, _UserMessages } from "../main/game_config";

import { register_log, update_debug_log } from "./Log";
import { register_storage } from "./Storage";
import { register_game_storage } from "./GameStorage";
import { register_sound } from "./Sound";
import { register_lang } from "./Lang";
import { register_scene } from "./Scene";
import { register_ads } from "./Ads";
import { register_system } from "./System";
import { register_rate } from "./Rate";
import { register_metrica } from "./Metrica";
import { register_camera } from "./Camera";


/*
    Основной модуль для подгрузки остальных, доступен по объекту Manager
    также глобально доступна функция to_hash которая ограничит список доступных для отправки сообщений
    при проверке в on_message, например  if (message_id == to_hash('MANAGER_READY'))
*/

declare global {
    const Manager: ReturnType<typeof ManagerModule>;
    const to_hash: typeof _to_hash;
    type UserMessages = _UserMessages;
    type SystemMessages = _SystemMessages;
    const ID_MESSAGES: typeof _ID_MESSAGES;
}

function _to_hash<T extends MessageId>(key: T) {
    return hash(key);
}

export function register_manager() {
    (_G as any).Manager = ManagerModule();
    (_G as any).to_hash = _to_hash;
    (_G as any).ID_MESSAGES = _ID_MESSAGES;
}


function ManagerModule() {
    const MANAGER_ID = 'main:/manager';
    const UI_ID = '/ui#game';
    const LOGIC_ID = '/game_logic#game';
    let _is_ready = false;
    let broadcast_messages: (string | hash)[] = [];

    function init(callback_ready?: VoidCallback, use_custom_storage_key = false) {
        math.randomseed(socket.gettime());
        register_system();
        register_log();
        register_storage(use_custom_storage_key);
        register_game_storage();
        register_metrica();
        register_sound();
        register_lang();
        register_scene();
        register_camera();
        register_ads();
        register_rate();

        Metrica.init(ID_YANDEX_METRICA);
        Ads.set_social_share_params(VK_SHARE_URL);
        check_ready(callback_ready);
    }

    function check_ready(callback_ready?: VoidCallback) {
        const id_timer = timer.delay(0.1, true, () => {
            // список модулей с ожиданием готовности
            if (Ads.is_ready()) {
                timer.cancel(id_timer);
                _is_ready = true;
                send('MANAGER_READY');
                log('All Managers ready ver: ' + sys.get_config("project.version"));
                if (callback_ready)
                    callback_ready();
            }
        });
    }

    function is_ready() {
        return _is_ready;
    }

    // отправить сообщение
    function send_raw(message_id: string | hash, message_data?: any, receiver = MANAGER_ID) {
        msg.post(receiver, message_id, message_data);
    }

    function send_raw_ui(message_id: string | hash, message_data?: any, receiver = UI_ID) {
        send_raw(message_id, message_data, receiver);
    }

    function send_raw_game(message_id: string | hash, message_data?: any, receiver = LOGIC_ID) {
        send_raw(message_id, message_data, receiver);
    }

    function send<T extends MessageId>(message_id: T, message_data?: Messages[T], receiver = MANAGER_ID) {
        send_raw(message_id, message_data, receiver);
    }

    function on_message(_this: any, message_id: hash, message: any, sender: hash) {
        Scene._on_message(_this, message_id, message, sender);
        Sound._on_message(_this, message_id, message, sender);
        Ads._on_message(_this, message_id, message, sender);
        Rate._on_message(_this, message_id, message, sender);
    }

    function update(dt: number) {
        update_debug_log(dt);
    }

    // можно вызывать в каждом init всех gui чтобы применялись нужные методы
    function init_gui() {
        Lang.apply();
    }

    // можно вызывать в каждом on_message всех gui чтобы применялись нужные методы
    function on_message_gui(_this: any, message_id: hash, message: any, sender: hash) {
        broadcast.on_message(message_id, message, sender);
        if (message_id == to_hash('APPLY_CUSTOM_LANG')) {
            Lang.apply();
        }
    }

    function final() {
        for (let i = 0; i < broadcast_messages.length; i++) {
            const message_id = broadcast_messages[i];
            broadcast.unregister(message_id);
        }
        broadcast_messages = [];
    }

    // регистрирует слушателя на сообщение
    function register_message(message_id: string | hash, cb: MessageCallback, auto_clear = true) {
        broadcast.register(message_id, cb);
        if (auto_clear)
            broadcast_messages.push(message_id);
    }

    // посылает сообщение всем зарегистрированным слушателям
    function trigger_message(message_id: string | hash, message?: any) {
        broadcast.send(message_id, message);
    }

    return { init, on_message, send, send_raw, send_raw_game, send_raw_ui, is_ready, init_gui, on_message_gui, update, final, register_message, trigger_message, MANAGER_ID };
}


