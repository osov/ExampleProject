/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

/*
    Модуль для хранения данных игры, при этом нужно изначально объявить конфиг(лежит в main/game_config.ts) и если 
    переменная была неизменна, то значение берется оттуда, иначе оно записывается в кеш и затем вытаскивается оттуда
    удобство модуля в том что заранее присутсвуют типы и фиксированный набор ключей, -> меньше шанс допустить ошибки 
*/

import { _GAME_CONFIG, _STORAGE_CONFIG } from "../main/game_config";

declare global {
    const GameStorage: ReturnType<typeof GameStorageModule>;
    const GAME_CONFIG: typeof _GAME_CONFIG;
}

export function register_game_storage() {
    (_G as any).GameStorage = GameStorageModule();
    (_G as any).GAME_CONFIG = _GAME_CONFIG;
}

interface KeyVal {
    [key: string]: any;
}

type GameKeys = keyof typeof _STORAGE_CONFIG;
type TGameConfig = typeof _STORAGE_CONFIG;

function GameStorageModule() {
    const default_list: KeyVal = _STORAGE_CONFIG;

    function get_key(key: GameKeys, _type = '') {
        const data = Storage.get_data('settings-' + key);
        if (data == null) {
            if (default_list[key] == undefined) {
                Log.error('Ключ не зарегистрирован:', key);
                return null;
            }
            const val = default_list[key];
            if (_type != '' && typeof val != _type) {
                Log.error('Ключ имеет неправильный тип. Ключ:' + key, 'ожидаемый тип:' + _type, 'фактический тип:' + typeof val);
            }
            return val;
        }
        return data.value;
    }

    function set<T extends GameKeys>(key: T, val: TGameConfig[T]) {
        Storage.set('settings-' + key, val);
    }

    function get<T extends GameKeys>(key: T): TGameConfig[T] {
        return get_key(key);
    }

    return { set, get };
}