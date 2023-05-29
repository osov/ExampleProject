/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-non-null-assertion */

interface ItemDataH {
    _hash: hash;
}

export function hex2rgba(hex: string, alpha = 1) {
    hex = hex.replace('#', '');
    if (hex.length == 3)
        return vmath.vector4(
            tonumber("0x" + hex.substr(0, 1))! * 17 / 255,
            tonumber("0x" + hex.substr(1, 1))! * 17 / 255,
            tonumber("0x" + hex.substr(2, 1))! * 17 / 255, alpha);

    else if (hex.length == 6)
        return vmath.vector4(
            tonumber("0x" + hex.substr(0, 2))! / 255,
            tonumber("0x" + hex.substr(2, 2))! / 255,
            tonumber("0x" + hex.substr(4, 2))! / 255, alpha);
    else {
        assert(false, 'hex not correct:' + hex);
        return vmath.vector4();
    }
}

export function set_text(name: string, text: string | number) {
    const n = gui.get_node(name);
    gui.set_text(n, text + '');
}

export function set_text_colors(list: string[], color: string, alpha = 1) {
    for (let i = 0; i < list.length; i++) {
        gui.set_color(
            gui.get_node(list[i]),
            hex2rgba(color, alpha)
        );
    }
}

export function format_string(str: string, args: any[]) {
    for (let i = 0; i < args.length; i++) {
        const it = args[i];
        str = str.split('{' + i + '}').join(it);
    }

    return str;
}

export function hide_gui_list(list: string[]) {
    for (let i = 0; i < list.length; i++) {
        gui.set_enabled(gui.get_node(list[i]), false);
    }
}

export function show_gui_list(list: string[]) {
    for (let i = 0; i < list.length; i++) {
        gui.set_enabled(gui.get_node(list[i]), true);
    }
}


export function sort_list<T>(list: T[], field: string, isAsc = true) {
    if (isAsc)
        return list.sort((a: any, b: any) => a[field] - b[field]);
    else
        return list.sort((a: any, b: any) => b[field] - a[field]);
}


function CatmullRom(t: number, p0: number, p1: number, p2: number, p3: number) {

    const v0 = (p2 - p0) * 0.5;
    const v1 = (p3 - p1) * 0.5;
    const t2 = t * t;
    const t3 = t * t2;
    return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (- 3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;

}

export function get_point_curve(t: number, points: { x: number, y: number }[], point: vmath.vector3) {
    const p = (points.length - 1) * t;

    const intPoint = Math.floor(p);
    const weight = p - intPoint;

    const p0 = points[intPoint === 0 ? intPoint : intPoint - 1];
    const p1 = points[intPoint];
    const p2 = points[intPoint > points.length - 2 ? points.length - 1 : intPoint + 1];
    const p3 = points[intPoint > points.length - 3 ? points.length - 1 : intPoint + 2];

    point.x = CatmullRom(weight, p0.x, p1.x, p2.x, p3.x);
    point.y = CatmullRom(weight, p0.y, p1.y, p2.y, p3.y);
    return point;
}




export function is_intersect_sprite(item: hash, checkPos: vmath.vector3, name = 'sprite', offset = vmath.vector3(0, 0, 0), mul_scale = vmath.vector3(1, 1, 1)) {
    const sprite_url = msg.url(undefined, item, name);
    const sprite_scale = go.get(sprite_url, "scale") as vmath.vector3;
    const size = go.get(sprite_url, "size") as vmath.vector3;
    const pos = (go.get_world_position(sprite_url) + offset) as vmath.vector3;
    const go_scale = go.get_world_scale(item);
    const scaled_size = vmath.vector3(size.x * sprite_scale.x * go_scale.x * mul_scale.x, size.y * sprite_scale.y * go_scale.y * mul_scale.y, 0);

    if (checkPos.x >= pos.x - scaled_size.x / 2 &&
        checkPos.x <= pos.x + scaled_size.x / 2 &&
        checkPos.y >= pos.y - scaled_size.y / 2 &&
        checkPos.y <= pos.y + scaled_size.y / 2) {
        return true;
    }
    return false;
}

export function parse_time(t: number) {
    const d = math.floor(t);
    const m = math.floor(d / 60);
    const s = d - m * 60;
    const mm = m < 10 ? "0" + m : m + "";
    const ss = s < 10 ? "0" + s : s + "";
    return mm + ":" + ss;
}

export function set_position_xy(item: hash, x: number, y: number) {
    const pos = go.get_position(item);
    pos.x = x;
    pos.y = y;
    go.set_position(pos, item);
}


export function is_equal_game_items(cell1: ItemDataH, cell2: ItemDataH) {
    return cell1._hash == cell2._hash;
}