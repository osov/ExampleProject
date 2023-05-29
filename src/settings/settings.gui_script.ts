/* eslint-disable @typescript-eslint/no-empty-function */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import * as druid from 'druid.druid';
import { hide_gui_list, set_text, set_text_colors, show_gui_list } from '../utils/utils';


interface props {
    druid: DruidClass;
}

export function init(this: props): void {
    Manager.init_gui();
    this.druid = druid.new(this);
    this.druid.new_button('btnHome', () => {
        Scene.load('menu');
    });
    this.druid.new_button('easy', () => set_level(0));
    this.druid.new_button('is_easy', () => set_level(0));
    this.druid.new_button('norm', () => set_level(1));
    this.druid.new_button('is_norm', () => set_level(1));
    this.druid.new_button('hard', () => set_level(2));
    this.druid.new_button('is_hard', () => set_level(2));
    this.druid.new_button('snd', () => toggle_snd());


    update_ui();
}

export function on_input(this: props, action_id: string | hash, action: unknown): void {
    return this.druid.on_input(action_id, action);
}

export function update(this: props, dt: number): void {
    this.druid.update(dt);
}

export function on_message(this: props, message_id: string | hash, message: any, sender: string | hash | url): void {
    Manager.on_message_gui(this, message_id, message, sender);
    this.druid.on_message(message_id, message, sender);
}

export function final(this: props): void {
    this.druid.final();
}

function update_ui() {
    const level = GameStorage.get('level');
    const is_snd = Sound.is_active();
    hide_gui_list(['is_easy_ok', 'is_norm_ok', 'is_hard_ok', 'snd_off']);
    if (level == 0)
        show_gui_list(['is_easy_ok']);
    if (level == 1)
        show_gui_list(['is_norm_ok']);
    if (level == 2)
        show_gui_list(['is_hard_ok']);
    if (!is_snd)
        show_gui_list(['snd_off']);
}

function set_level(level: number) {
    GameStorage.set('level', level);
    update_ui();
}

function toggle_snd() {
    Sound.set_active(!Sound.is_active());
    update_ui();
}
