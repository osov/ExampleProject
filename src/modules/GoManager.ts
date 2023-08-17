/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-non-null-assertion */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-empty-function */
/* eslint-disable prefer-const */

import * as flow from 'ludobits.m.flow';
import { hex2rgba } from '../utils/utils';
import * as camera from '../utils/camera';
import { get_debug_intersect_points, is_intersect_zone } from '../utils/math_utils';
import { IGameItem } from './modules_const';

interface DragData {
    _hash: hash;
    click_pos: vmath.vector3;
    start_pos: vmath.vector3;
    z_index: number;
}

type CallbackFunction = () => void;

export function GoManager() {

    let go_list: hash[] = [];
    let game_items: IGameItem[] = [];

    function make_go(name = 'cell', pos: vmath.vector3, is_add_list = false) {
        const item = factory.create("/prefabs#" + name, pos);
        if (is_add_list)
            go_list.push(item);
        return item;
    }


    function get_go_by_item(item: IGameItem) {
        for (let i = 0; i < go_list.length; i++) {
            const id = go_list[i];
            if (id == item._hash)
                return id;
        }
        assert(false, 'go not found(get_go_by_item)' + item._hash);
        return go_list[0];
    }

    function get_item_by_go(_hash: hash) {
        for (let i = 0; i < game_items.length; i++) {
            const item = game_items[i];
            if (_hash == item._hash)
                return item;
        }
        assert(false, 'item not found(get_item_by_go)' + _hash);
        return game_items[0];
    }


    function set_render_order_hash(_go: hash, index: number) {
        const pos = go.get_position(_go);
        pos.z = index * 0.001 + 0.001;
        go.set_position(pos, _go);
    }

    function set_render_order(item: IGameItem, index: number) {
        set_render_order_hash(get_go_by_item(item), index);
    }

    function get_render_order_hash(_go: hash) {
        const pos = go.get_position(_go);
        return math.floor((pos.z - 0.001) / 0.001 + 0.5);
    }

    function get_render_order(item: IGameItem) {
        return get_render_order_hash(get_go_by_item(item));
    }

    function get_sprite_hash(_go: hash) {
        return go.get(msg.url(undefined, _go, "sprite"), "animation") as hash;
    }

    function set_sprite_hash(_go: hash, id_anim: string) {
        sprite.play_flipbook(msg.url(undefined, _go, "sprite"), hash(id_anim));
    }

    function set_color_hash(_go: hash, color: string, alpha = 1, name = 'sprite') {
        go.set(msg.url(undefined, _go, name), "tint", hex2rgba(color, alpha));
    }

    function set_rotation_hash(_go: hash, deg_angle: number) {
        go.set_rotation(vmath.quat_rotation_z(math.rad(deg_angle)), _go);
    }

    function do_move_anim_hash(_go: hash, pos: vmath.vector3, timeSec: number, delay = 0, cb?: CallbackFunction) {
        const src = go.get_position(_go);
        pos.z = src.z;
        go.animate(_go, 'position', go.PLAYBACK_ONCE_FORWARD, pos, go.EASING_LINEAR, timeSec, delay, cb);
    }

    function do_move_anim(item: IGameItem, pos: vmath.vector3, timeSec: number, delay = 0) {
        do_move_anim_hash(get_go_by_item(item), pos, timeSec, delay);
    }

    function do_scale_anim_hash(_go: hash, scale: vmath.vector3, timeSec: number, delay = 0, cb?: CallbackFunction) {
        go.animate(_go, 'scale', go.PLAYBACK_ONCE_FORWARD, scale, go.EASING_LINEAR, timeSec, delay, cb);
    }

    function do_scale_anim(item: IGameItem, scale: vmath.vector3, timeSec: number, delay = 0) {
        do_scale_anim_hash(get_go_by_item(item), scale, timeSec, delay);
    }

    function do_fade_anim_hash(_go: hash, value: number, timeSec: number, delay = 0, prop = 'tint') {
        go.animate(_go, prop + '.w', go.PLAYBACK_ONCE_FORWARD, value, go.EASING_LINEAR, timeSec, delay);
    }

    function do_fade_anim(item: IGameItem, value: number, timeSec: number, delay = 0, prop = 'tint') {
        do_fade_anim_hash(get_go_by_item(item), value, timeSec, delay, prop);
    }

    function set_position_xy_hash(_go: hash, x: number, y: number, align_x = 0.5, align_y = 0.5) {
        const pos = go.get_position(_go);
        pos.x = x;
        pos.y = y;
        if (align_x != 0.5 || align_y != 0.5) {
            const size = get_go_sprite_size_hash(_go);
            pos.x += (0.5 - align_x) * size.x;
            pos.y += (0.5 - align_y) * size.y;
        }
        go.set_position(pos, _go);
    }

    function set_position_xy(item: IGameItem, x: number, y: number, align_x = 0.5, align_y = 0.5) {
        set_position_xy_hash(get_go_by_item(item), x, y, align_x, align_y);
    }

    function move_to_with_time_hash(_go: hash, pos: vmath.vector3, time: number, cb?: CallbackFunction) {
        const src = go.get_position(_go);
        pos.z = src.z;
        go.animate(_go, 'position', go.PLAYBACK_ONCE_FORWARD, pos, go.EASING_LINEAR, time, 0, cb);
    }

    function move_to_with_speed_hash(_go: hash, pos: vmath.vector3, speed: number, cb?: CallbackFunction) {
        const src = go.get_position(_go);
        pos.z = src.z;
        const dist = vmath.length((src - pos) as vmath.vector3);
        move_to_with_time_hash(_go, pos, dist / speed, cb);
    }

    function move_to_with_speed(item: IGameItem, pos: vmath.vector3, speed: number, cb?: CallbackFunction) {
        move_to_with_speed_hash(get_go_by_item(item), pos, speed, cb);
    }

    function get_go_sprite_size_hash(_go: hash, name = 'sprite') {
        const sprite_url = msg.url(undefined, _go, name);
        const sprite_scale = go.get(sprite_url, "scale") as vmath.vector3;
        const size = go.get(sprite_url, "size") as vmath.vector3;
        const go_scale = go.get_scale(_go);
        return vmath.vector3(size.x * sprite_scale.x * go_scale.x, size.y * sprite_scale.y * go_scale.y, 0);
    }


    function is_intersect_hash(pos: vmath.vector3, _go: hash, inner_offset?: vmath.vector3) {
        return is_intersect_zone(pos, go.get_position(_go), get_go_sprite_size_hash(_go), go.get(_go, 'euler.z'), inner_offset);
    }

    // debug info
    let tmp_items: hash[] = [];
    function draw_debug_intersect(name_prefab = 'x') {
        const [a, b, c, d] = get_debug_intersect_points();
        for (let j = 0; j < tmp_items.length; j++) {
            const it = tmp_items[j];
            go.delete(it);
        }
        tmp_items = [];
        tmp_items.push(make_go(name_prefab, a), make_go(name_prefab, b), make_go(name_prefab, c), make_go(name_prefab, d));

    }

    function is_intersect(pos: vmath.vector3, item: IGameItem, inner_offset?: vmath.vector3) {
        return is_intersect_hash(pos, get_go_by_item(item), inner_offset);
    }

    function get_item_from_pos(x: number, y: number): null | [IGameItem, IGameItem[]] {
        const tp = camera.screen_to_world(x, y);
        const results = [];
        const zlist = [];

        for (let i = 0; i < game_items.length; i++) {
            const gi = game_items[i];
            const id = gi._hash;
            if (gi.is_clickable) {
                if (is_intersect(tp, gi)) {
                    results.push(gi);
                    const pos = go.get_world_position(id);
                    zlist.push(pos.z);
                }
            }
        }
        if (results.length > 0) {
            let result = results[0];
            let z = zlist[0];
            for (let i = 0; i < results.length; i++) {
                if (zlist[i] >= z) {
                    z = zlist[i];
                    result = results[i];
                }
            }
            return [result, results];
        }
        return null;
    }

    function on_click(x: number, y: number, isDown: boolean, isMove = false) {
        if (isMove) {
            Manager.send_game('MSG_ON_MOVE', { x, y });
            return on_move(x, y);
        }
        if (isDown) {
            Manager.send_game('MSG_ON_DOWN', { x, y });
            return on_down(x, y);
        }
        else {
            on_up(x, y);
            Manager.send_game('MSG_ON_UP', { x, y });
        }
    }

    let cp = vmath.vector3();
    let sp = vmath.vector3();
    let down_item: IGameItem | null = null;
    let cur_x = 0; let cur_y = 0;
    function on_down(x: number, y: number) {
        // todo debug
        //const tmp = camera.screen_to_world(x, y);
        //set_position_xy_hash('point', tmp.x, tmp.y);
        cur_x = x;
        cur_y = y;
        down_item = null;
        const result = get_item_from_pos(x, y);
        if (!result)
            return;
        const [item, items] = result;
        down_item = item;
        cp = camera.screen_to_world(x, y);
        sp = go.get_position(item._hash);
        const hashes: hash[] = [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            hashes.push(item._hash);
        }
        Manager.send_game('MSG_ON_DOWN_HASHES', { hashes });
        Manager.send_game('MSG_ON_DOWN_ITEM', { item });
    }

    function on_move(x: number, y: number) {
        cur_x = x;
        cur_y = y;
        process_dragging_list(x, y);
        if (!down_item)
            return;
        if (!down_item.is_dragable)
            return;
        const _hash = down_item._hash;
        const src = go.get_position(_hash);
        const dp = ((camera.screen_to_world(x, y) - cp)) as vmath.vector3;
        const np = (sp + dp) as vmath.vector3;
        np.z = src.z;
        go.set_position(np, _hash);
        Manager.send_game('MSG_ON_MOVE_ITEM', { item: down_item });
    }

    function on_up(x: number, y: number) {
        cur_x = x;
        cur_y = y;
        const result = get_item_from_pos(x, y);
        if (result) {
            const [item, items] = result;
            const hashes: hash[] = [];
            for (let i = 0; i < items.length; i++) {
                const item = items[i];
                hashes.push(item._hash);

            }
            Manager.send_game('MSG_ON_UP_HASHES', { hashes });
        }

        if (!down_item)
            return;
        const item = down_item;
        Manager.send_game('MSG_ON_UP_ITEM', { item });
        down_item = null;
    }

    function get_item_by_index(index: number) {
        return game_items[index];
    }


    function add_game_item<T extends IGameItem>(gi: T, add_go_list = true) {
        game_items.push(gi);
        if (add_go_list)
            go_list.push(gi._hash);
    }

    function delete_go(_go: hash, remove_from_scene = true) {
        for (let i = go_list.length - 1; i >= 0; i--) {
            const _go_item = go_list[i];
            if (_go == _go_item) {
                go_list.splice(i, 1);
                if (remove_from_scene)
                    go.delete(_go);
                return true;
            }
        }
        return false;
    }

    function delete_item(item: IGameItem, remove_from_scene = true) {
        for (let i = game_items.length - 1; i >= 0; i--) {
            const it = game_items[i];
            if (it._hash == item._hash) {
                game_items.splice(i, 1);
                delete_go(it._hash, remove_from_scene);
                return true;
            }
        }
        return false;
    }

    function clear_and_remove_items() {
        for (let i = 0; i < go_list.length; i++) {
            go.delete(go_list[i]);
        }
        game_items = [];
        go_list = [];
        flow.frames(5);
    }



    let drag_list: DragData[] = [];
    function start_dragging_list(list: hash[], inc_z_index = 0) {
        stop_dragging_list(list, true);
        const click_pos = camera.screen_to_world(cur_x, cur_y);
        for (let i = 0; i < list.length; i++) {
            const h = list[i];
            const z_index = get_render_order_hash(h);
            set_render_order_hash(h, z_index + inc_z_index);
            drag_list.push({ _hash: h, click_pos, start_pos: go.get_position(h), z_index });
        }
    }

    function process_dragging_list(x: number, y: number) {
        const wp = camera.screen_to_world(x, y);
        for (let i = 0; i < drag_list.length; i++) {
            const dl = drag_list[i];
            const _hash = dl._hash;
            const dp = ((wp - dl.click_pos)) as vmath.vector3;
            const np = (dl.start_pos + dp) as vmath.vector3;
            np.z = dl.start_pos.z;
            go.set_position(np, _hash);
        }
    }

    function stop_dragging_list(list: hash[], reset_pos = false) {
        for (let i = 0; i < list.length; i++) {
            const h = list[i];
            for (let j = drag_list.length - 1; j >= 0; j--) {
                const dl = drag_list[j];
                if (h == dl._hash) {
                    if (reset_pos)
                        go.set_position(dl.start_pos, dl._hash);
                    set_render_order_hash(dl._hash, dl.z_index);
                    drag_list.splice(j, 1);
                }
            }
        }
    }

    function stop_all_dragging(reset_pos = false) {
        const tmp: hash[] = [];
        for (let i = 0; i < drag_list.length; i++) {
            tmp.push(drag_list[i]._hash);
        }
        stop_dragging_list(tmp, reset_pos);
    }

    function reset_dragging_list(time: number, cb_end?: CallbackFunction) {
        let is_end = false;
        for (let i = 0; i < drag_list.length; i++) {
            const dl = drag_list[i];
            move_to_with_time_hash(dl._hash, dl.start_pos, time, () => {
                if (!is_end) {
                    is_end = true;
                    stop_all_dragging();
                    if (cb_end)
                        cb_end();
                }
            });
        }
    }


    // ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // 
    // ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

    function do_message(message_id: hash, message: any, sender: hash) {
        if (message_id == ID_MESSAGES.MSG_TOUCH) {
            if (message.pressed)
                on_click(message.x, message.y, true);
            else if (message.released)
                on_click(message.x, message.y, false);
            else
                on_click(message.x, message.y, false, true);
        }
    }




    return {
        do_message, on_click, make_go, set_render_order, get_render_order, do_move_anim, do_scale_anim, do_fade_anim, do_move_anim_hash, do_fade_anim_hash, do_scale_anim_hash,
        get_item_by_go, get_go_by_item, clear_and_remove_items, get_item_by_index, set_sprite_hash, set_color_hash, set_rotation_hash, add_game_item,
        move_to_with_speed_hash, move_to_with_speed, set_position_xy, set_position_xy_hash, is_intersect, is_intersect_hash, delete_item, delete_go, draw_debug_intersect, set_render_order_hash, get_render_order_hash,
        move_to_with_time_hash, get_sprite_hash, start_dragging_list, stop_all_dragging, stop_dragging_list, reset_dragging_list
    };
}

/*

MSG_ON_DOWN
MSG_ON_DOWN_HASHES
MSG_ON_DOWN_ITEM

MSG_ON_MOVE
MSG_ON_MOVE_ITEM

MSG_ON_UP_HASHES
MSG_ON_UP_ITEM
MSG_ON_UP

*/