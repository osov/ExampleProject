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

export interface IGameItem {
    _hash: hash;
    is_clickable?: boolean;
    is_dragable?: boolean;
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

    function set_position_xy_hash(_go: hash, x: number, y: number) {
        const pos = go.get_position(_go);
        pos.x = x;
        pos.y = y;
        go.set_position(pos, _go);
    }

    function set_position_xy(item: IGameItem, x: number, y: number) {
        set_position_xy_hash(get_go_by_item(item), x, y);
    }

    function move_to_with_time_hash(id: hash, pos: vmath.vector3, time: number, cb?: CallbackFunction) {
        const src = go.get_position(id);
        pos.z = src.z;
        go.animate(id, 'position', go.PLAYBACK_ONCE_FORWARD, pos, go.EASING_LINEAR, time, 0, cb);
    }

    function move_to_with_speed_hash(id: hash, pos: vmath.vector3, speed: number, cb?: CallbackFunction) {
        const src = go.get_position(id);
        pos.z = src.z;
        const dist = vmath.length((src - pos) as vmath.vector3);
        move_to_with_time_hash(id, pos, dist / speed, cb);
    }

    function move_to_with_speed(item: IGameItem, pos: vmath.vector3, speed: number, cb?: CallbackFunction) {
        move_to_with_speed_hash(get_go_by_item(item), pos, speed, cb);
    }

    function get_go_sprite_size_hash(_go: hash, name = 'sprite') {
        const sprite_url = msg.url(undefined, _go, name);
        const sprite_scale = go.get(sprite_url, "scale") as vmath.vector3;
        const size = go.get(sprite_url, "size") as vmath.vector3;
        const go_scale = go.get_world_scale(_go);
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

    function get_item_from_pos(x: number, y: number) {
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
            return result;
        }
        return null;
    }

    function send(id_message: hash, message: any) {
        msg.post('/game_logic#game', id_message, message);
    }

    function on_click(x: number, y: number, isDown: boolean, isMove = false) {
        if (isMove) {
            send(ID_MESSAGES.MSG_ON_MOVE, { x, y });
            return on_move(x, y);
        }
        if (isDown) {
            send(ID_MESSAGES.MSG_ON_DOWN, { x, y });
            return on_down(x, y);
        }
        else {
            send(ID_MESSAGES.MSG_ON_UP, { x, y });
            return on_up(x, y);
        }
    }

    let cp = vmath.vector3();
    let sp = vmath.vector3();
    let down_item: IGameItem | null = null;
    function on_down(x: number, y: number) {
        // todo debug
        //const tmp = camera.screen_to_world(x, y);
        //set_position_xy_hash('point', tmp.x, tmp.y);

        down_item = null;
        const item = get_item_from_pos(x, y);
        if (!item)
            return;
        down_item = item;
        cp = camera.screen_to_world(x, y);
        sp = go.get_position(item._hash);
        send(ID_MESSAGES.MSG_ON_DOWN_HASH, { hash: item._hash });
    }

    function on_move(x: number, y: number) {
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
        send(ID_MESSAGES.MSG_ON_MOVE_HASH, { hash: _hash });
    }

    function on_up(x: number, y: number) {
        if (!down_item)
            return;
        const item = down_item;
        send(ID_MESSAGES.MSG_ON_UP_HASH, { hash: item._hash });
        down_item = null;
    }

    function get_item_by_index(index: number) {
        return game_items[index];
    }

    function add_game_item(gi: IGameItem, add_go_list = true) {
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
        move_to_with_time_hash
    };
}