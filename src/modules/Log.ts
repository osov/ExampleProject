/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

import { hex2rgba } from "../utils/utils";

/*
    Модуль для логирования как в логи редактора, так и в консоль браузера если это хтмл5
    доступен глобальный метод log либо
    экземпляр Log с методами и уровнями лога, типа Log.warn(...), если вызов идет Log.error то показывает также стек
*/

declare global {
    const Log: ReturnType<typeof LogModule>;
    const LogScreen: ReturnType<typeof LogScreenModule>;
    const log: (..._args: any) => void;
}

export function register_log() {
    (_G as any).Log = LogModule();
    (_G as any).log = Log.log;
    (_G as any).LogScreen = LogScreenModule();
}


type LogLevels = 'notice' | 'log' | 'info' | 'warn' | 'error' | 'screen';
const log_priority = ['notice', 'log', 'info', 'warn', 'error'];
const worker = log_worker();

function log_worker() {

    function show(prefix = '', level: LogLevels, log_level: LogLevels, text: string) {
        const is_logging = log_priority.indexOf(level) >= log_priority.indexOf(log_level);
        if (!is_logging)
            return;
        const time = os.date("%H:%M:%S", os.time());
        let str = '[' + time + '-' + level + (prefix == '' ? '' : ' _' + prefix + '_ ') + '] ' + text;
        if (level == 'error') {
            const stack = debug.traceback();
            const tmp = stack.split('\n');
            tmp.splice(0, 4);
            str += '\n' + 'stack:' + tmp.join('\n');
        }
        print(str);
        if (System.platform == 'HTML5')
            html5.run("console.log(" + json.encode(str) + ")");
    }

    return { show };
}



function LogModule(_prefix = '', _log_level: LogLevels = 'notice') {

    function get_with_prefix(prefix: string, log_level: LogLevels = 'notice') {
        return LogModule(prefix, log_level);
    }

    function send(level: LogLevels, _args: any) {
        let str = '';
        for (const k in _args) {
            const a = _args[k];
            if (typeof a == 'object') {
                str += json.encode(a) + ', ';
            }
            else
                str += a + ', ';
        }
        if (str != '')
            str = string.sub(str, 0, -3);

        worker.show(_prefix, level, _log_level, str);
    }

    function notice(..._args: any) {
        send('notice', _args);
    }

    function log(..._args: any) {
        send('log', _args);
    }

    function warn(..._args: any) {
        send('warn', _args);
    }

    function error(..._args: any) {
        send('error', _args);
    }




    return { get_with_prefix, notice, log, warn, error };
}

let screen_text = '';
let screen_color = hex2rgba('#f00');
const log_position = vmath.vector3(10, 530, 0);

export function update_debug_log(dt: number) {
    if (screen_text != '')
        msg.post("@render:", "draw_debug_text", { text: screen_text, position: log_position, color: screen_color });
}

function LogScreenModule() {

    function log(..._args: any) {
        let str = '';
        for (const k in _args) {
            const a = _args[k];
            if (typeof a == 'object') {
                str += json.encode(a) + ' ';
            }
            else
                str += a + ' ';
        }
        if (str != '')
            str = string.sub(str, 0, -3);
        screen_text += str + '\n';
    }

    function clear() {
        screen_text = '';
    }

    function set_color(color = '#f00') {
        screen_color = hex2rgba(color);
    }

    function set_position(x: number, y: number) {
        log_position.x = x;
        log_position.y = y;
    }

    return { log, clear, set_color, set_position };

}