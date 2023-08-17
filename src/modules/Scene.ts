/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

import { hex2rgba } from "../utils/utils";
import { Messages } from "./modules_const";

/*
    Модуль для работы со сценой
*/

declare global {
    const Scene: ReturnType<typeof SceneModule>;
}

export function register_scene() {
    (_G as any).Scene = SceneModule();
}


function SceneModule() {
    let wait_load_scene = '';
    let last_loading_scene = '';
    let last_scene = '';
    let _wait_ready_manager = false;

    function init() {
        if (System.platform == 'HTML5')
            html5.run(`window.set_light = function(val){document.body.style.backgroundColor = val}`);
    }

    function set_bg(color: string) {
        msg.post("@render:", "clear_color", { color: hex2rgba(color, 0) });
        if (System.platform == 'HTML5')
            html5.run(`set_light('` + color + `')`);
    }

    // загрузить сцену с именем. wait_ready_manager - ждать ли сначала полной загрузки менеджера
    function load(name: string, wait_ready_manager = false) {
        _wait_ready_manager = wait_ready_manager;
        Manager.send('LOAD_SCENE', { name });
    }

    function restart() {
        Manager.send('RESTART_SCENE');
    }

    let is_restarting_scene = false;
    function _on_message(_this: any, message_id: hash, _message: any, sender: hash) {
        if (message_id == to_hash('MANAGER_READY')) {
            // еще не поступала никакая сцена на загрузку значит ничего не делаем
            if (wait_load_scene == '')
                return;
            Manager.send('LOAD_SCENE', { name: wait_load_scene });
        }
        if (message_id == to_hash('RESTART_SCENE')) {
            if (last_scene == '')
                return Log.warn('Сцена для перезагрузки не найдена');
            const n = Manager.MANAGER_ID + "#" + last_scene;
            msg.post(n, "disable");
            msg.post(n, "final");
            msg.post(n, "unload");
            is_restarting_scene = true;
        }
        if (message_id == to_hash('LOAD_SCENE')) {
            const message = _message as Messages['LOAD_SCENE'];
            // ждем готовности модулей
            if (_wait_ready_manager && !Manager.is_ready()) {
                wait_load_scene = message.name;
                return;
            }
            wait_load_scene = '';
            last_loading_scene = message.name;
            msg.post(Manager.MANAGER_ID + "#" + message.name, "load");
        }
        if (message_id == hash("proxy_unloaded")) {
            if (is_restarting_scene && last_scene != '') {
                last_loading_scene = last_scene;
                msg.post(Manager.MANAGER_ID + "#" + last_scene, "load");
            }
        }
        if (message_id == hash("proxy_loaded")) {
            if (last_scene != '' && !is_restarting_scene) {
                const n = Manager.MANAGER_ID + "#" + last_scene;
                msg.post(n, "disable");
                msg.post(n, "final");
                msg.post(n, "unload");
                last_scene = '';
            }
            is_restarting_scene = false;
            msg.post(sender, "init");
            msg.post(sender, "enable");
            last_scene = last_loading_scene;
            last_loading_scene = '';
            Manager.send('SCENE_LOADED', { name: last_scene });
        }
    }

    function get_current_name() {
        return last_scene;
    }

    init();

    return { _on_message, restart, load, set_bg, get_current_name };
}