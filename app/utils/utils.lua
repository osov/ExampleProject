local ____lualib = require("lualib_bundle")
local __TS__StringReplace = ____lualib.__TS__StringReplace
local __TS__StringSubstr = ____lualib.__TS__StringSubstr
local __TS__StringSplit = ____lualib.__TS__StringSplit
local __TS__ArraySort = ____lualib.__TS__ArraySort
local ____exports = {}
function ____exports.hex2rgba(hex, alpha)
    if alpha == nil then
        alpha = 1
    end
    hex = __TS__StringReplace(hex, "#", "")
    if #hex == 3 then
        return vmath.vector4(
            tonumber("0x" .. __TS__StringSubstr(hex, 0, 1)) * 17 / 255,
            tonumber("0x" .. __TS__StringSubstr(hex, 1, 1)) * 17 / 255,
            tonumber("0x" .. __TS__StringSubstr(hex, 2, 1)) * 17 / 255,
            alpha
        )
    elseif #hex == 6 then
        return vmath.vector4(
            tonumber("0x" .. __TS__StringSubstr(hex, 0, 2)) / 255,
            tonumber("0x" .. __TS__StringSubstr(hex, 2, 2)) / 255,
            tonumber("0x" .. __TS__StringSubstr(hex, 4, 2)) / 255,
            alpha
        )
    else
        assert(false, "hex not correct:" .. hex)
        return vmath.vector4()
    end
end
function ____exports.set_text(name, text)
    local n = gui.get_node(name)
    gui.set_text(
        n,
        tostring(text) .. ""
    )
end
function ____exports.set_text_colors(list, color, alpha)
    if alpha == nil then
        alpha = 1
    end
    do
        local i = 0
        while i < #list do
            gui.set_color(
                gui.get_node(list[i + 1]),
                ____exports.hex2rgba(color, alpha)
            )
            i = i + 1
        end
    end
end
function ____exports.format_string(str, args)
    do
        local i = 0
        while i < #args do
            local it = args[i + 1]
            str = table.concat(
                __TS__StringSplit(
                    str,
                    ("{" .. tostring(i)) .. "}"
                ),
                it or ","
            )
            i = i + 1
        end
    end
    return str
end
function ____exports.hide_gui_list(list)
    do
        local i = 0
        while i < #list do
            gui.set_enabled(
                gui.get_node(list[i + 1]),
                false
            )
            i = i + 1
        end
    end
end
function ____exports.show_gui_list(list)
    do
        local i = 0
        while i < #list do
            gui.set_enabled(
                gui.get_node(list[i + 1]),
                true
            )
            i = i + 1
        end
    end
end
function ____exports.sort_list(list, field, isAsc)
    if isAsc == nil then
        isAsc = true
    end
    if isAsc then
        return __TS__ArraySort(
            list,
            function(____, a, b) return a[field] - b[field] end
        )
    else
        return __TS__ArraySort(
            list,
            function(____, a, b) return b[field] - a[field] end
        )
    end
end
local function CatmullRom(t, p0, p1, p2, p3)
    local v0 = (p2 - p0) * 0.5
    local v1 = (p3 - p1) * 0.5
    local t2 = t * t
    local t3 = t * t2
    return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1
end
function ____exports.get_point_curve(t, points, point)
    local p = (#points - 1) * t
    local intPoint = math.floor(p)
    local weight = p - intPoint
    local p0 = points[(intPoint == 0 and intPoint or intPoint - 1) + 1]
    local p1 = points[intPoint + 1]
    local p2 = points[(intPoint > #points - 2 and #points - 1 or intPoint + 1) + 1]
    local p3 = points[(intPoint > #points - 3 and #points - 1 or intPoint + 2) + 1]
    point.x = CatmullRom(
        weight,
        p0.x,
        p1.x,
        p2.x,
        p3.x
    )
    point.y = CatmullRom(
        weight,
        p0.y,
        p1.y,
        p2.y,
        p3.y
    )
    return point
end
function ____exports.is_intersect_sprite(item, checkPos, name, offset, mul_scale)
    if name == nil then
        name = "sprite"
    end
    if offset == nil then
        offset = vmath.vector3(0, 0, 0)
    end
    if mul_scale == nil then
        mul_scale = vmath.vector3(1, 1, 1)
    end
    local sprite_url = msg.url(nil, item, name)
    local sprite_scale = go.get(sprite_url, "scale")
    local size = go.get(sprite_url, "size")
    local pos = go.get_world_position(sprite_url) + offset
    local go_scale = go.get_world_scale(item)
    local scaled_size = vmath.vector3(size.x * sprite_scale.x * go_scale.x * mul_scale.x, size.y * sprite_scale.y * go_scale.y * mul_scale.y, 0)
    if checkPos.x >= pos.x - scaled_size.x / 2 and checkPos.x <= pos.x + scaled_size.x / 2 and checkPos.y >= pos.y - scaled_size.y / 2 and checkPos.y <= pos.y + scaled_size.y / 2 then
        return true
    end
    return false
end
function ____exports.parse_time(t)
    local d = math.floor(t)
    local m = math.floor(d / 60)
    local s = d - m * 60
    local mm = m < 10 and "0" .. tostring(m) or tostring(m) .. ""
    local ss = s < 10 and "0" .. tostring(s) or tostring(s) .. ""
    return (mm .. ":") .. ss
end
function ____exports.set_position_xy(item, x, y)
    local pos = go.get_position(item)
    pos.x = x
    pos.y = y
    go.set_position(pos, item)
end
function ____exports.is_equal_game_items(cell1, cell2)
    return cell1._hash == cell2._hash
end
return ____exports
