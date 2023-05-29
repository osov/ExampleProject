/* eslint-disable @typescript-eslint/no-empty-function */
/* eslint-disable prefer-const */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import * as druid from 'druid.druid';
import { hex2rgba, hide_gui_list, parse_time, set_text, set_text_colors, show_gui_list } from '../utils/utils';

interface props {
    druid: DruidClass;
}

export function init(this: props): void {
    Manager.init_gui();
    this.druid = druid.new(this);
    this.druid.new_button('btnHome', function () {
        Scene.load('menu');
    });
    this.druid.new_blocker('vic_popup');
    this.druid.new_blocker('fail_popup');
    this.druid.new_button('btnNext', close_popup);
    this.druid.new_button('btnNext2', close_popup);
    Camera.set_gui_projection(true);

    this.druid.new_button('btnClick', () => set_miner_mode(0));
    this.druid.new_button('btnFlag', () => set_miner_mode(1));
    this.druid.new_button('btnQuest', () => set_miner_mode(2));
    set_miner_mode(GAME_CONFIG.id_mode_miner);
}

export function on_input(this: props, action_id: string | hash, action: unknown): void {
    Camera.transform_input_action(action);
    return this.druid.on_input(action_id, action);
}

export function update(this: props, dt: number): void {
    this.druid.update(dt);
}

export function on_message(this: props, message_id: string | hash, message: any, sender: string | hash | url): void {
    Manager.on_message_gui(this, message_id, message, sender);
    this.druid.on_message(message_id, message, sender);
    if (message_id == hash('game_end')) {
        const is_win = message.is_win as boolean;
        Sound.play(is_win ? 'vic' : 'fail');

        show_gui_list([is_win ? 'vic_popup' : 'fail_popup']);
        update_stats(is_win);
    }

    if (message_id == hash('num_mines'))
        set_text('cnt_mines', message.cnt);


}

export function final(this: props): void {
    this.druid.final();
    Camera.set_gui_projection(false);
}


function close_popup() {
    hide_gui_list(['vic_popup', 'fail_popup']);
    Scene.load('menu');
}

function update_stats(is_win: boolean) {
    if (is_win)
        GameStorage.set('wins', GameStorage.get('wins') + 1);
    else
        GameStorage.set('fails', GameStorage.get('fails') + 1);
}

function set_miner_mode(id_mode: number) {
    const buttons = ['btnClick', 'btnFlag', 'btnQuest'];
    set_text_colors(buttons, '#fff');
    set_text_colors([buttons[id_mode]], '#babae1');
    GAME_CONFIG.id_mode_miner = id_mode;
}

