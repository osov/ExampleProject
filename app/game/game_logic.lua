local ____lualib = require("lualib_bundle")
local __TS__ArraySplice = ____lualib.__TS__ArraySplice
local ____exports = {}
local flow = require("ludobits.m.flow")
local ____GoManager = require("modules.GoManager")
local GoManager = ____GoManager.GoManager
local ____miner = require("game.miner")
local CellState = ____miner.CellState
local Miner = ____miner.Miner
function ____exports.Game()
    local get_cell_position, in_cell, wait_event, on_click_cell, make_cell, on_open_cell, game_end, get_hash_by_xy, on_remove_old_cell, add_boom, update_ui, tile_size, top_offset, cell_scale, null_scale, cell_offset_x, cell_offset_y, cells, gridW, gridH, num_mines, miner, gm, is_end_show
    function get_cell_position(x, y, z)
        if z == nil then
            z = 0
        end
        x = x + cell_offset_x
        y = y + cell_offset_y
        return vmath.vector3(top_offset.x + tile_size * x + tile_size * 0.5, top_offset.y - tile_size * y - tile_size * 0.5, z)
    end
    function in_cell(pos)
        do
            local y = 0
            while y < 12 do
                do
                    local x = 0
                    while x < 25 do
                        local checkPos = get_cell_position(x, y)
                        if checkPos.x >= pos.x - tile_size / 2 and checkPos.x <= pos.x + tile_size / 2 and checkPos.y >= pos.y - tile_size / 2 and checkPos.y <= pos.y + tile_size / 2 then
                            return {x, y}
                        end
                        x = x + 1
                    end
                end
                y = y + 1
            end
        end
        return {-1, -1}
    end
    function wait_event()
        while true do
            local message_id, message, sender = flow.until_any_message()
            gm.do_message(message_id, message, sender)
            if message_id == ID_MESSAGES.MSG_ON_UP then
                local tmp = Camera.screen_to_world(message.x, message.y)
                local cx, cy = unpack(in_cell(tmp))
                if cx > -1 then
                    on_click_cell(cx, cy)
                end
            end
            if message_id == hash("debug") then
                miner.debug()
            end
        end
    end
    function on_click_cell(x, y)
        local state = -1
        if GAME_CONFIG.id_mode_miner == 1 then
            state = CellState.mark_mine
        end
        if GAME_CONFIG.id_mode_miner == 2 then
            state = CellState.mark_quest
        end
        miner.open(x, y, state)
    end
    function make_cell(x, y, state, val)
        local cp = get_cell_position(x, y)
        local _go = gm.make_go("cell", cp)
        cells[#cells + 1] = {x = x, y = y, _hash = _go}
        go.set_scale(cell_scale, _go)
        if state == CellState.mark_mine then
            gm.set_sprite_hash(_go, "flag")
            go.set_scale(cell_scale * (32 / 160), _go)
            label.set_text(
                msg.url(nil, _go, "label"),
                "М"
            )
        elseif state == CellState.mark_quest then
            gm.set_color_hash(_go, "#339")
            label.set_text(
                msg.url(nil, _go, "label"),
                "?"
            )
        elseif state == CellState.mine then
            gm.set_sprite_hash(_go, "mine")
            go.set_scale(cell_scale * 0.45, _go)
            if val ~= -1 then
                add_boom(cp)
            end
        elseif state == CellState.opened then
            gm.set_color_hash(_go, "#339")
            if val > 0 then
                label.set_text(
                    msg.url(nil, _go, "label"),
                    tostring(val) .. ""
                )
            end
        else
            log("state", state)
        end
    end
    function on_open_cell(x, y, state, val)
        make_cell(x, y, state, val)
        if state == CellState.mine then
            game_end(false)
        elseif miner.is_win() then
            game_end(true)
        end
        update_ui()
    end
    function game_end(is_win)
        if is_end_show then
            return
        end
        is_end_show = true
        if is_win then
            gm.do_scale_anim_hash(
                "game_border",
                null_scale,
                0.3,
                0,
                function() return go.delete("game_border") end
            )
            do
                local x = 0
                while x < gridW do
                    do
                        local y = 0
                        while y < gridH do
                            local h = get_hash_by_xy(x, y)
                            if h then
                                gm.do_scale_anim_hash(
                                    h,
                                    null_scale,
                                    0.3,
                                    x * 0.1 + y * 0.03,
                                    function() return go.delete(h) end
                                )
                            end
                            y = y + 1
                        end
                    end
                    x = x + 1
                end
            end
            flow.delay(3)
            Manager.send_raw_ui("game_end", {is_win = is_win})
        else
            local mines = miner.get_mines_data()
            do
                local x = 0
                while x < gridW do
                    do
                        local y = 0
                        while y < gridH do
                            local m = mines[x + 1][y + 1]
                            if m == 1 then
                                make_cell(x, y, CellState.mine, -1)
                            end
                            y = y + 1
                        end
                    end
                    x = x + 1
                end
            end
            flow.delay(3)
            Manager.send_raw_ui("game_end", {is_win = is_win})
        end
    end
    function get_hash_by_xy(x, y)
        do
            local i = #cells - 1
            while i >= 0 do
                local cell = cells[i + 1]
                if cell.x == x and cell.y == y then
                    return cell._hash
                end
                i = i - 1
            end
        end
        return nil
    end
    function on_remove_old_cell(x, y)
        update_ui()
        do
            local i = #cells - 1
            while i >= 0 do
                local cell = cells[i + 1]
                if cell.x == x and cell.y == y then
                    go.delete(cell._hash)
                    __TS__ArraySplice(cells, i, 1)
                    return
                end
                i = i - 1
            end
        end
    end
    function add_boom(pos)
        Sound.play("boom")
        local boom = gm.make_go("boom", pos)
        gm.set_sprite_hash(boom, "boom")
        timer.delay(
            0.2,
            false,
            function()
                gm.do_scale_anim_hash(
                    boom,
                    null_scale,
                    0.3,
                    0,
                    function() return go.delete(boom) end
                )
            end
        )
    end
    function update_ui()
        Manager.send_raw_ui(
            "num_mines",
            {cnt = num_mines - miner.get_count_flags(CellState.mark_mine)}
        )
    end
    local cell_size = 34
    local cell_mul = 1.2
    tile_size = 32 * cell_mul
    top_offset = vmath.vector3(-22 + 0.5, 32 - 0.5, 0)
    cell_scale = vmath.vector3(tile_size / cell_size)
    null_scale = vmath.vector3(0.01, 0.01, 0.01)
    cell_offset_x = 9
    cell_offset_y = 2
    cells = {}
    gridW = 9
    gridH = 9
    num_mines = 0
    miner = Miner()
    gm = GoManager()
    local function init()
        local level = GameStorage.get("level")
        num_mines = 8 + level * 3
        miner.setup(
            gridW,
            gridH,
            num_mines,
            on_open_cell,
            on_remove_old_cell
        )
        Manager.send_raw("set_cell_size", {size = cell_mul})
        gm.set_color_hash("/game_border", "#1d1fa2", 1, "border")
        update_ui()
        wait_event()
    end
    is_end_show = false
    init()
    return {}
end
return ____exports
