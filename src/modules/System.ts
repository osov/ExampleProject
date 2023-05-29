/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

import { IS_DEBUG_MODE } from "../main/game_config";

/*
    Модуль для системных функций
*/

declare global {
    const System: ReturnType<typeof SystemModule>;
}

export function register_system() {
    (_G as any).System = SystemModule();
}

type PlatformType = "Darwin" | "Linux" | "Windows" | "HTML5" | "Android" | "iPhone OS";

function SystemModule() {
    const info = sys.get_sys_info();
    const platform: PlatformType = info.system_name;

    function init() {
        // Обработчики ошибок
        const src_assert = assert;
        _G.assert = function <V, A extends any[]>(v: V, ...args: A): LuaMultiReturn<[Exclude<V, undefined | null | false>, ...A]> {
            if (!v) {
                const text = "Assert:" + args[0] + '\n' + debug.traceback();
                Log.error(text);
                // если отладочная версия и есть шаринг, то шарим и выдаем юзеру ошибку
                if (IS_DEBUG_MODE) {
                    if (share != null)
                        share.text(text);
                }
            }
            return src_assert(v, ...args);
        };
        sys.set_error_handler(function (source: string, message: string, traceback: string) {
            Log.error('SystemError:', message, '\n', source, '\n', traceback);
        });
        if (platform == 'HTML5')
            html5.run(`document.oncontextmenu = function(e){return false}`);
    }

    function now() {
        return socket.gettime();
    }

    init();
    return { platform, now };
}