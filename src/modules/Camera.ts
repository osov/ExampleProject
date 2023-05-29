/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

/*
    Модуль для работы с камерой и преобразованиями
*/
import * as camera from '../utils/camera';

declare global {
    const Camera: ReturnType<typeof CameraModule>;
}

export function register_camera() {
    (_G as any).Camera = CameraModule();
}

function CameraModule() {
    let is_gui_projection = false;

    function set_gui_projection(value: boolean) {
        is_gui_projection = value;
        msg.post("@render:", "use_only_projection", { value });
    }

    function screen_to_world(screen_x: number, screen_y: number) {
        return camera.screen_to_world(screen_x, screen_y);
    }


    function transform_input_action(action: any) {
        if (is_gui_projection && action.x !== undefined) {
            const tp = camera.screen_to_world(action.x as number, action.y as number);
            const [window_x, window_y] = window.get_size();
            const stretch_x = window_x / gui.get_width();
            const stretch_y = window_y / gui.get_height();
            action.x = tp.x / stretch_x;
            action.y = tp.y / stretch_y;
        }
    }

    function set_go_prjection(anchor_x: number, anchor_y: number) {
        // вверх прижаты элементы
        msg.post("@render:", "use_width_projection", { anchor_x, anchor_y, near: -1, far: 1 });
        camera.set_align(anchor_x, anchor_y);
        camera.update_window_size();
    }

    function get_ltrb() {
        return camera.screen_to_world_bounds();
    }

    return { set_gui_projection, transform_input_action, set_go_prjection, get_ltrb, screen_to_world };
}