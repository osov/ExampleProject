local ____lualib = require("lualib_bundle")
local __TS__ArrayPush = ____lualib.__TS__ArrayPush
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local ____exports = {}
local flow = require("ludobits.m.flow")
local ____utils = require("utils.utils")
local hex2rgba = ____utils.hex2rgba
local camera = require("utils.camera")
local ____math_utils = require("utils.math_utils")
local get_debug_intersect_points = ____math_utils.get_debug_intersect_points
local is_intersect_zone = ____math_utils.is_intersect_zone
function ____exports.GoManager()
    local get_go_by_item, set_render_order_hash, get_go_sprite_size_hash, is_intersect_hash, is_intersect, get_item_from_pos, on_down, on_move, on_up, process_dragging_list, stop_dragging_list, go_list, game_items, cp, sp, down_item, cur_x, cur_y, drag_list
    function get_go_by_item(item)
        do
            local i = 0
            while i < #go_list do
                local id = go_list[i + 1]
                if id == item._hash then
                    return id
                end
                i = i + 1
            end
        end
        assert(
            false,
            "go not found(get_go_by_item)" .. tostring(item._hash)
        )
        return go_list[1]
    end
    function set_render_order_hash(_go, index)
        local pos = go.get_position(_go)
        pos.z = index * 0.001 + 0.001
        go.set_position(pos, _go)
    end
    function get_go_sprite_size_hash(_go, name)
        if name == nil then
            name = "sprite"
        end
        local sprite_url = msg.url(nil, _go, name)
        local sprite_scale = go.get(sprite_url, "scale")
        local size = go.get(sprite_url, "size")
        local go_scale = go.get_scale(_go)
        return vmath.vector3(size.x * sprite_scale.x * go_scale.x, size.y * sprite_scale.y * go_scale.y, 0)
    end
    function is_intersect_hash(pos, _go, inner_offset)
        return is_intersect_zone(
            pos,
            go.get_position(_go),
            get_go_sprite_size_hash(_go),
            go.get(_go, "euler.z"),
            inner_offset
        )
    end
    function is_intersect(pos, item, inner_offset)
        return is_intersect_hash(
            pos,
            get_go_by_item(item),
            inner_offset
        )
    end
    function get_item_from_pos(x, y)
        local tp = camera.screen_to_world(x, y)
        local results = {}
        local zlist = {}
        do
            local i = 0
            while i < #game_items do
                local gi = game_items[i + 1]
                local id = gi._hash
                if gi.is_clickable then
                    if is_intersect(tp, gi) then
                        results[#results + 1] = gi
                        local pos = go.get_world_position(id)
                        zlist[#zlist + 1] = pos.z
                    end
                end
                i = i + 1
            end
        end
        if #results > 0 then
            local result = results[1]
            local z = zlist[1]
            do
                local i = 0
                while i < #results do
                    if zlist[i + 1] >= z then
                        z = zlist[i + 1]
                        result = results[i + 1]
                    end
                    i = i + 1
                end
            end
            return {result, results}
        end
        return nil
    end
    function on_down(x, y)
        cur_x = x
        cur_y = y
        down_item = nil
        local result = get_item_from_pos(x, y)
        if not result then
            return
        end
        local item, items = unpack(result)
        down_item = item
        cp = camera.screen_to_world(x, y)
        sp = go.get_position(item._hash)
        local hashes = {}
        do
            local i = 0
            while i < #items do
                local item = items[i + 1]
                hashes[#hashes + 1] = item._hash
                i = i + 1
            end
        end
        Manager.send_game("MSG_ON_DOWN_HASHES", {hashes = hashes})
        Manager.send_game("MSG_ON_DOWN_ITEM", {item = item})
    end
    function on_move(x, y)
        cur_x = x
        cur_y = y
        process_dragging_list(x, y)
        if not down_item then
            return
        end
        if not down_item.is_dragable then
            return
        end
        local _hash = down_item._hash
        local src = go.get_position(_hash)
        local dp = camera.screen_to_world(x, y) - cp
        local np = sp + dp
        np.z = src.z
        go.set_position(np, _hash)
        Manager.send_game("MSG_ON_MOVE_ITEM", {item = down_item})
    end
    function on_up(x, y)
        cur_x = x
        cur_y = y
        local result = get_item_from_pos(x, y)
        if result then
            local item, items = unpack(result)
            local hashes = {}
            do
                local i = 0
                while i < #items do
                    local item = items[i + 1]
                    hashes[#hashes + 1] = item._hash
                    i = i + 1
                end
            end
            Manager.send_game("MSG_ON_UP_HASHES", {hashes = hashes})
        end
        if not down_item then
            return
        end
        local item = down_item
        Manager.send_game("MSG_ON_UP_ITEM", {item = item})
        down_item = nil
    end
    function process_dragging_list(x, y)
        local wp = camera.screen_to_world(x, y)
        do
            local i = 0
            while i < #drag_list do
                local dl = drag_list[i + 1]
                local _hash = dl._hash
                local dp = wp - dl.click_pos
                local np = dl.start_pos + dp
                np.z = dl.start_pos.z
                go.set_position(np, _hash)
                i = i + 1
            end
        end
    end
    function stop_dragging_list(list, reset_pos)
        if reset_pos == nil then
            reset_pos = false
        end
        do
            local i = 0
            while i < #list do
                local h = list[i + 1]
                do
                    local j = #drag_list - 1
                    while j >= 0 do
                        local dl = drag_list[j + 1]
                        if h == dl._hash then
                            if reset_pos then
                                go.set_position(dl.start_pos, dl._hash)
                            end
                            set_render_order_hash(dl._hash, dl.z_index)
                            __TS__ArraySplice(drag_list, j, 1)
                        end
                        j = j - 1
                    end
                end
                i = i + 1
            end
        end
    end
    go_list = {}
    game_items = {}
    local function make_go(name, pos, is_add_list)
        if name == nil then
            name = "cell"
        end
        if is_add_list == nil then
            is_add_list = false
        end
        local item = factory.create("/prefabs#" .. name, pos)
        if is_add_list then
            go_list[#go_list + 1] = item
        end
        return item
    end
    local function get_item_by_go(_hash)
        do
            local i = 0
            while i < #game_items do
                local item = game_items[i + 1]
                if _hash == item._hash then
                    return item
                end
                i = i + 1
            end
        end
        assert(
            false,
            "item not found(get_item_by_go)" .. tostring(_hash)
        )
        return game_items[1]
    end
    local function set_render_order(item, index)
        set_render_order_hash(
            get_go_by_item(item),
            index
        )
    end
    local function get_render_order_hash(_go)
        local pos = go.get_position(_go)
        return math.floor((pos.z - 0.001) / 0.001 + 0.5)
    end
    local function get_render_order(item)
        return get_render_order_hash(get_go_by_item(item))
    end
    local function get_sprite_hash(_go)
        return go.get(
            msg.url(nil, _go, "sprite"),
            "animation"
        )
    end
    local function set_sprite_hash(_go, id_anim)
        sprite.play_flipbook(
            msg.url(nil, _go, "sprite"),
            hash(id_anim)
        )
    end
    local function set_color_hash(_go, color, alpha, name)
        if alpha == nil then
            alpha = 1
        end
        if name == nil then
            name = "sprite"
        end
        go.set(
            msg.url(nil, _go, name),
            "tint",
            hex2rgba(color, alpha)
        )
    end
    local function set_rotation_hash(_go, deg_angle)
        go.set_rotation(
            vmath.quat_rotation_z(math.rad(deg_angle)),
            _go
        )
    end
    local function do_move_anim_hash(_go, pos, timeSec, delay, cb)
        if delay == nil then
            delay = 0
        end
        local src = go.get_position(_go)
        pos.z = src.z
        go.animate(
            _go,
            "position",
            go.PLAYBACK_ONCE_FORWARD,
            pos,
            go.EASING_LINEAR,
            timeSec,
            delay,
            cb
        )
    end
    local function do_move_anim(item, pos, timeSec, delay)
        if delay == nil then
            delay = 0
        end
        do_move_anim_hash(
            get_go_by_item(item),
            pos,
            timeSec,
            delay
        )
    end
    local function do_scale_anim_hash(_go, scale, timeSec, delay, cb)
        if delay == nil then
            delay = 0
        end
        go.animate(
            _go,
            "scale",
            go.PLAYBACK_ONCE_FORWARD,
            scale,
            go.EASING_LINEAR,
            timeSec,
            delay,
            cb
        )
    end
    local function do_scale_anim(item, scale, timeSec, delay)
        if delay == nil then
            delay = 0
        end
        do_scale_anim_hash(
            get_go_by_item(item),
            scale,
            timeSec,
            delay
        )
    end
    local function do_fade_anim_hash(_go, value, timeSec, delay, prop)
        if delay == nil then
            delay = 0
        end
        if prop == nil then
            prop = "tint"
        end
        go.animate(
            _go,
            prop .. ".w",
            go.PLAYBACK_ONCE_FORWARD,
            value,
            go.EASING_LINEAR,
            timeSec,
            delay
        )
    end
    local function do_fade_anim(item, value, timeSec, delay, prop)
        if delay == nil then
            delay = 0
        end
        if prop == nil then
            prop = "tint"
        end
        do_fade_anim_hash(
            get_go_by_item(item),
            value,
            timeSec,
            delay,
            prop
        )
    end
    local function set_position_xy_hash(_go, x, y, align_x, align_y)
        if align_x == nil then
            align_x = 0.5
        end
        if align_y == nil then
            align_y = 0.5
        end
        local pos = go.get_position(_go)
        pos.x = x
        pos.y = y
        if align_x ~= 0.5 or align_y ~= 0.5 then
            local size = get_go_sprite_size_hash(_go)
            pos.x = pos.x + (0.5 - align_x) * size.x
            pos.y = pos.y + (0.5 - align_y) * size.y
        end
        go.set_position(pos, _go)
    end
    local function set_position_xy(item, x, y, align_x, align_y)
        if align_x == nil then
            align_x = 0.5
        end
        if align_y == nil then
            align_y = 0.5
        end
        set_position_xy_hash(
            get_go_by_item(item),
            x,
            y,
            align_x,
            align_y
        )
    end
    local function move_to_with_time_hash(_go, pos, time, cb)
        local src = go.get_position(_go)
        pos.z = src.z
        go.animate(
            _go,
            "position",
            go.PLAYBACK_ONCE_FORWARD,
            pos,
            go.EASING_LINEAR,
            time,
            0,
            cb
        )
    end
    local function move_to_with_speed_hash(_go, pos, speed, cb)
        local src = go.get_position(_go)
        pos.z = src.z
        local dist = vmath.length(src - pos)
        move_to_with_time_hash(_go, pos, dist / speed, cb)
    end
    local function move_to_with_speed(item, pos, speed, cb)
        move_to_with_speed_hash(
            get_go_by_item(item),
            pos,
            speed,
            cb
        )
    end
    local tmp_items = {}
    local function draw_debug_intersect(name_prefab)
        if name_prefab == nil then
            name_prefab = "x"
        end
        local a, b, c, d = unpack(get_debug_intersect_points())
        do
            local j = 0
            while j < #tmp_items do
                local it = tmp_items[j + 1]
                go.delete(it)
                j = j + 1
            end
        end
        tmp_items = {}
        __TS__ArrayPush(
            tmp_items,
            make_go(name_prefab, a),
            make_go(name_prefab, b),
            make_go(name_prefab, c),
            make_go(name_prefab, d)
        )
    end
    local function on_click(x, y, isDown, isMove)
        if isMove == nil then
            isMove = false
        end
        if isMove then
            Manager.send_game("MSG_ON_MOVE", {x = x, y = y})
            return on_move(x, y)
        end
        if isDown then
            Manager.send_game("MSG_ON_DOWN", {x = x, y = y})
            return on_down(x, y)
        else
            on_up(x, y)
            Manager.send_game("MSG_ON_UP", {x = x, y = y})
        end
    end
    cp = vmath.vector3()
    sp = vmath.vector3()
    down_item = nil
    cur_x = 0
    cur_y = 0
    local function get_item_by_index(index)
        return game_items[index + 1]
    end
    local function add_game_item(gi, add_go_list)
        if add_go_list == nil then
            add_go_list = true
        end
        game_items[#game_items + 1] = gi
        if add_go_list then
            go_list[#go_list + 1] = gi._hash
        end
    end
    local function delete_go(_go, remove_from_scene)
        if remove_from_scene == nil then
            remove_from_scene = true
        end
        do
            local i = #go_list - 1
            while i >= 0 do
                local _go_item = go_list[i + 1]
                if _go == _go_item then
                    __TS__ArraySplice(go_list, i, 1)
                    if remove_from_scene then
                        go.delete(_go)
                    end
                    return true
                end
                i = i - 1
            end
        end
        return false
    end
    local function delete_item(item, remove_from_scene)
        if remove_from_scene == nil then
            remove_from_scene = true
        end
        do
            local i = #game_items - 1
            while i >= 0 do
                local it = game_items[i + 1]
                if it._hash == item._hash then
                    __TS__ArraySplice(game_items, i, 1)
                    delete_go(it._hash, remove_from_scene)
                    return true
                end
                i = i - 1
            end
        end
        return false
    end
    local function clear_and_remove_items()
        do
            local i = 0
            while i < #go_list do
                go.delete(go_list[i + 1])
                i = i + 1
            end
        end
        game_items = {}
        go_list = {}
        flow.frames(5)
    end
    drag_list = {}
    local function start_dragging_list(list, inc_z_index)
        if inc_z_index == nil then
            inc_z_index = 0
        end
        stop_dragging_list(list, true)
        local click_pos = camera.screen_to_world(cur_x, cur_y)
        do
            local i = 0
            while i < #list do
                local h = list[i + 1]
                local z_index = get_render_order_hash(h)
                set_render_order_hash(h, z_index + inc_z_index)
                drag_list[#drag_list + 1] = {
                    _hash = h,
                    click_pos = click_pos,
                    start_pos = go.get_position(h),
                    z_index = z_index
                }
                i = i + 1
            end
        end
    end
    local function stop_all_dragging(reset_pos)
        if reset_pos == nil then
            reset_pos = false
        end
        local tmp = {}
        do
            local i = 0
            while i < #drag_list do
                tmp[#tmp + 1] = drag_list[i + 1]._hash
                i = i + 1
            end
        end
        stop_dragging_list(tmp, reset_pos)
    end
    local function reset_dragging_list(time, cb_end)
        local is_end = false
        do
            local i = 0
            while i < #drag_list do
                local dl = drag_list[i + 1]
                move_to_with_time_hash(
                    dl._hash,
                    dl.start_pos,
                    time,
                    function()
                        if not is_end then
                            is_end = true
                            stop_all_dragging()
                            if cb_end then
                                cb_end()
                            end
                        end
                    end
                )
                i = i + 1
            end
        end
    end
    local function do_message(message_id, message, sender)
        if message_id == ID_MESSAGES.MSG_TOUCH then
            if message.pressed then
                on_click(message.x, message.y, true)
            elseif message.released then
                on_click(message.x, message.y, false)
            else
                on_click(message.x, message.y, false, true)
            end
        end
    end
    return {
        do_message = do_message,
        on_click = on_click,
        make_go = make_go,
        set_render_order = set_render_order,
        get_render_order = get_render_order,
        do_move_anim = do_move_anim,
        do_scale_anim = do_scale_anim,
        do_fade_anim = do_fade_anim,
        do_move_anim_hash = do_move_anim_hash,
        do_fade_anim_hash = do_fade_anim_hash,
        do_scale_anim_hash = do_scale_anim_hash,
        get_item_by_go = get_item_by_go,
        get_go_by_item = get_go_by_item,
        clear_and_remove_items = clear_and_remove_items,
        get_item_by_index = get_item_by_index,
        set_sprite_hash = set_sprite_hash,
        set_color_hash = set_color_hash,
        set_rotation_hash = set_rotation_hash,
        add_game_item = add_game_item,
        move_to_with_speed_hash = move_to_with_speed_hash,
        move_to_with_speed = move_to_with_speed,
        set_position_xy = set_position_xy,
        set_position_xy_hash = set_position_xy_hash,
        is_intersect = is_intersect,
        is_intersect_hash = is_intersect_hash,
        delete_item = delete_item,
        delete_go = delete_go,
        draw_debug_intersect = draw_debug_intersect,
        set_render_order_hash = set_render_order_hash,
        get_render_order_hash = get_render_order_hash,
        move_to_with_time_hash = move_to_with_time_hash,
        get_sprite_hash = get_sprite_hash,
        start_dragging_list = start_dragging_list,
        stop_all_dragging = stop_all_dragging,
        stop_dragging_list = stop_dragging_list,
        reset_dragging_list = reset_dragging_list
    }
end
return ____exports
