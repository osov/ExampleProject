local ____exports = {}
____exports.CellState = {
    none = 0,
    opened = 1,
    mine = 2,
    mark_mine = 3,
    mark_quest = 4
}
function ____exports.Miner()
    local out_bounds, calc_near, reveal, on_open, mines, flags, revealed, _on_open_callback, gridW, gridH
    function out_bounds(x, y)
        return x < 0 or y < 0 or x >= gridW or y >= gridH
    end
    function calc_near(x, y)
        if out_bounds(x, y) then
            return 0
        end
        local i = 0
        do
            local oX = -1
            while oX <= 1 do
                do
                    local oY = -1
                    while oY <= 1 do
                        if out_bounds(oX + x, oY + y) then
                        else
                            i = i + mines[oX + x + 1][oY + y + 1]
                        end
                        oY = oY + 1
                    end
                end
                oX = oX + 1
            end
        end
        return i
    end
    function reveal(x, y)
        if out_bounds(x, y) then
            return
        end
        if revealed[x + 1][y + 1] then
            return
        end
        revealed[x + 1][y + 1] = true
        on_open(x, y)
        if calc_near(x, y) > 0 then
            return
        end
        reveal(x - 1, y - 1)
        reveal(x - 1, y + 1)
        reveal(x + 1, y - 1)
        reveal(x + 1, y + 1)
        reveal(x - 1, y)
        reveal(x + 1, y)
        reveal(x, y - 1)
        reveal(x, y + 1)
    end
    function on_open(x, y)
        local state = ____exports.CellState.none
        if flags[x + 1][y + 1] == ____exports.CellState.mark_mine then
            state = ____exports.CellState.mark_mine
        elseif flags[x + 1][y + 1] == ____exports.CellState.mark_quest then
            state = ____exports.CellState.mark_quest
        elseif mines[x + 1][y + 1] ~= 0 then
            state = ____exports.CellState.mine
        elseif revealed[x + 1][y + 1] then
            state = ____exports.CellState.opened
        end
        local val = 0
        local near = calc_near(x, y)
        if near > 0 and revealed[x + 1][y + 1] then
            val = near
        end
        if _on_open_callback then
            _on_open_callback(x, y, state, val)
        end
    end
    mines = {}
    flags = {}
    revealed = {}
    local _on_remove_callback
    gridW = 8
    gridH = 8
    local numMines = 10
    local firstClick = true
    local function setup(wdith, height, num_mines, on_open_cb, on_remove_cb)
        _on_open_callback = on_open_cb
        _on_remove_callback = on_remove_cb
        gridW = wdith
        gridH = height
        numMines = num_mines
        firstClick = true
        do
            local x = 0
            while x < gridW do
                mines[x + 1] = {}
                revealed[x + 1] = {}
                flags[x + 1] = {}
                do
                    local y = 0
                    while y < gridH do
                        mines[x + 1][y + 1] = 0
                        revealed[x + 1][y + 1] = false
                        flags[x + 1][y + 1] = 0
                        y = y + 1
                    end
                end
                x = x + 1
            end
        end
    end
    local function place_mines()
        local i = 0
        while i < numMines do
            local x = math.random(0, gridW - 1)
            local y = math.random(0, gridH - 1)
            if mines[x + 1][y + 1] == 1 then
            else
                mines[x + 1][y + 1] = 1
                i = i + 1
            end
        end
    end
    local function clear_mines()
        do
            local x = 0
            while x < gridW do
                do
                    local y = 0
                    while y < gridH do
                        mines[x + 1][y + 1] = 0
                        y = y + 1
                    end
                end
                x = x + 1
            end
        end
    end
    local function open(x, y, flag)
        if flag == nil then
            flag = -1
        end
        if out_bounds(x, y) then
            return
        end
        if revealed[x + 1][y + 1] then
            return
        end
        if flag > -1 then
            if flags[x + 1][y + 1] == flag then
                local old_flag = flags[x + 1][y + 1]
                flags[x + 1][y + 1] = ____exports.CellState.none
                if _on_remove_callback then
                    _on_remove_callback(x, y, old_flag, 0)
                end
                return
            end
            local old_flag = flags[x + 1][y + 1]
            flags[x + 1][y + 1] = flag
            if _on_remove_callback then
                _on_remove_callback(x, y, old_flag, 0)
            end
            on_open(x, y)
            return
        end
        if flags[x + 1][y + 1] > 0 then
            return
        end
        if firstClick then
            firstClick = false
            repeat
                do
                    clear_mines()
                    place_mines()
                end
            until not (mines[x + 1][y + 1] ~= 0)
        end
        if mines[x + 1][y + 1] ~= 0 then
            on_open(x, y)
        else
            reveal(x, y)
        end
    end
    local function get_count_flags(id_flag)
        local cnt = 0
        do
            local x = 0
            while x < gridW do
                do
                    local y = 0
                    while y < gridH do
                        if flags[x + 1][y + 1] == id_flag then
                            cnt = cnt + 1
                        end
                        y = y + 1
                    end
                end
                x = x + 1
            end
        end
        return cnt
    end
    local function get_mines_data()
        return mines
    end
    local function ____debug()
        local str = ""
        local str2 = ""
        do
            local y = 0
            while y < gridH do
                str = str .. tostring(y) .. ") "
                str2 = str2 .. tostring(y) .. ") "
                do
                    local x = 0
                    while x < gridW do
                        str = str .. (mines[x + 1][y + 1] == 0 and "-" or "x")
                        str = str .. " "
                        str2 = str2 .. (revealed[x + 1][y + 1] and "+" or "-")
                        str2 = str2 .. " "
                        x = x + 1
                    end
                end
                str = str .. "\n"
                str2 = str2 .. "\n"
                y = y + 1
            end
        end
        log("open:\n" .. str2)
        log("mines:\n" .. str)
    end
    local function is_win()
        local opened = 0
        do
            local y = 0
            while y < gridH do
                do
                    local x = 0
                    while x < gridW do
                        if revealed[x + 1][y + 1] then
                            opened = opened + 1
                        end
                        x = x + 1
                    end
                end
                y = y + 1
            end
        end
        return gridW * gridH == opened + numMines
    end
    return {
        setup = setup,
        open = open,
        debug = ____debug,
        is_win = is_win,
        get_count_flags = get_count_flags,
        get_mines_data = get_mines_data
    }
end
return ____exports
