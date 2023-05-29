local ____exports = {}
local function is_point_in_zone(A, B, C, D, E)
    local function side(a, b, p)
        local val = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)
        if val == 0 then
            return 0
        end
        return val > 0 and 1 or -1
    end
    return side(A, B, E) == -1 and side(B, C, E) == -1 and side(C, D, E) == -1 and side(D, A, E) == -1
end
function ____exports.rotate_around(vec, angle_rad)
    local c = math.cos(angle_rad)
    local s = math.sin(angle_rad)
    local x = vec.x
    local y = vec.y
    vec.x = x * c - y * s
    vec.y = x * s + y * c
end
function ____exports.rotate_around_center(vec, center, angle_rad)
    local c = math.cos(angle_rad)
    local s = math.sin(angle_rad)
    local x = vec.x - center.x
    local y = vec.y - center.y
    vec.x = x * c - y * s + center.x
    vec.y = x * s + y * c + center.y
end
local a = vmath.vector3(0, 0, 0)
local b = vmath.vector3(0, 0, 0)
local c = vmath.vector3(0, 0, 0)
local d = vmath.vector3(0, 0, 0)
function ____exports.is_intersect_zone(check_pos, go_pos, go_size, go_angle_deg, inner_offset)
    local w = go_size.x
    local h = go_size.y
    local angle = math.rad(go_angle_deg)
    a.x = -w / 2
    a.y = h / 2
    b.x = w / 2
    b.y = h / 2
    c.x = w / 2
    c.y = -h / 2
    d.x = -w / 2
    d.y = -h / 2
    if angle ~= 0 then
        ____exports.rotate_around(a, angle)
        ____exports.rotate_around(b, angle)
        ____exports.rotate_around(c, angle)
        ____exports.rotate_around(d, angle)
    end
    if inner_offset then
        ____exports.rotate_around(inner_offset, angle)
        a.x = a.x + inner_offset.x
        a.y = a.y + inner_offset.y
        b.x = b.x + inner_offset.x
        b.y = b.y + inner_offset.y
        c.x = c.x + inner_offset.x
        c.y = c.y + inner_offset.y
        d.x = d.x + inner_offset.x
        d.y = d.y + inner_offset.y
    end
    a.x = a.x + go_pos.x
    a.y = a.y + go_pos.y
    b.x = b.x + go_pos.x
    b.y = b.y + go_pos.y
    c.x = c.x + go_pos.x
    c.y = c.y + go_pos.y
    d.x = d.x + go_pos.x
    d.y = d.y + go_pos.y
    return is_point_in_zone(
        a,
        b,
        c,
        d,
        check_pos
    )
end
function ____exports.get_debug_intersect_points()
    return {a, b, c, d}
end
return ____exports
