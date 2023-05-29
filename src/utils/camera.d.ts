// https://github.com/britzl/defold-orthographic/blob/master/orthographic/camera.lua
/*
будут правильные
const wp = camera.screen_to_world(pos.x, pos.y); // подразумевает stretch
const inv = camera.world_to_screen(wp, gui.ADJUST_STRETCH);
*/

/** @noResolution */
export function update_window_size(): void;
export function world_to_screen(world: vmath.vector3, adjust_mode: number): vmath.vector3;
export function screen_to_world(x: number, y: number, calc_is_inv?:boolean): vmath.vector3;
export function screen_to_world_bounds(): vmath.vector4;
export function set_align(ax:number, ay:number): void;