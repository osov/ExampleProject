/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable no-constant-condition */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable no-empty */
/* eslint-disable @typescript-eslint/no-non-null-assertion */
/* eslint-disable prefer-const */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-empty-function */

import * as flow from 'ludobits.m.flow';
import { GoManager, IGameItem } from '../modules/GoManager';
import { CellState, Miner } from './miner';

interface CellData {
    x: number;
    y: number;
    _hash: hash;
}

export function Game() {
    const cell_size = 34;
    const cell_mul = 1.2;
    const tile_size = 32 * cell_mul;
    const top_offset = vmath.vector3(-22 + 0.5, 32 - 0.5, 0);
    const cell_scale = vmath.vector3(tile_size / cell_size);
    const null_scale = vmath.vector3(0.01, 0.01, 0.01);
    const cell_offset_x = 9;
    const cell_offset_y = 2;
    const cells: CellData[] = [];

    const gridW = 9;
    const gridH = 9;
    let num_mines = 0;
    const miner = Miner();
    const gm = GoManager();


    function init() {
        const level = GameStorage.get('level');
        num_mines = 10 + level * 2;
        miner.setup(gridW, gridH, num_mines, on_open_cell, on_remove_old_cell);
        Manager.send_raw('set_cell_size', { size: cell_mul });

        gm.set_color_hash('/game_border', '#1d1fa2', 1, 'border');
        update_ui();
        timer.delay(2, false, () => game_end(true));
        wait_event();
    }

    function get_cell_position(x: number, y: number, z = 0) {
        x += cell_offset_x;
        y += cell_offset_y;
        return vmath.vector3(top_offset.x + tile_size * x + tile_size * 0.5, top_offset.y - tile_size * y - tile_size * 0.5, z);
    }

    function in_cell(pos: vmath.vector3) {
        for (let y = 0; y < 12; y++) {
            for (let x = 0; x < 25; x++) {
                const checkPos = get_cell_position(x, y);
                if (checkPos.x >= pos.x - tile_size / 2 &&
                    checkPos.x <= pos.x + tile_size / 2 &&
                    checkPos.y >= pos.y - tile_size / 2 &&
                    checkPos.y <= pos.y + tile_size / 2) {
                    return [x, y];
                }
            }
        }
        return [-1, -1];
    }

    function wait_event() {
        while (true) {
            const [message_id, message, sender] = flow.until_any_message();
            gm.do_message(message_id, message, sender);
            if (message_id == ID_MESSAGES.MSG_ON_UP) {
                const tmp = Camera.screen_to_world(message.x, message.y);
                const [cx, cy] = in_cell(tmp);
                if (cx > -1)
                    on_click_cell(cx, cy);
            }
            if (message_id == hash('debug')) {
                miner.debug();
            }
        }
    }

    function on_click_cell(x: number, y: number) {
        let state = -1;
        if (GAME_CONFIG.id_mode_miner == 1)
            state = CellState.mark_mine;
        if (GAME_CONFIG.id_mode_miner == 2)
            state = CellState.mark_quest;
        miner.open(x, y, state);
    }

    function make_cell(x: number, y: number, state: number, val: number) {
        const cp = get_cell_position(x, y);
        const _go = gm.make_go('cell', cp);
        cells.push({ x, y, _hash: _go });
        go.set_scale(cell_scale, _go);
        if (state == CellState.mark_mine) {
            gm.set_sprite_hash(_go, 'flag');
            go.set_scale(cell_scale * (32 / 160), _go);
            label.set_text(msg.url(undefined, _go, 'label'), 'М');
        }
        else if (state == CellState.mark_quest) {
            gm.set_color_hash(_go, '#339');
            label.set_text(msg.url(undefined, _go, 'label'), '?');
        }
        else if (state == CellState.mine) {
            gm.set_sprite_hash(_go, 'mine');
            go.set_scale(cell_scale * 0.45, _go);
            if (val != -1)
                add_boom(cp);
        }
        else if (state == CellState.opened) {
            gm.set_color_hash(_go, '#339');
            if (val > 0) {
                label.set_text(msg.url(undefined, _go, 'label'), val + '');
            }
        }
        else {
            log("state", state);
        }

    }

    function on_open_cell(x: number, y: number, state: number, val: number) {
        make_cell(x, y, state, val);
        if (state == CellState.mine) {
            game_end(false);
        }
        else if (miner.is_win()) {
            game_end(true);
        }
        update_ui();
    }

    let is_end_show = false;
    function game_end(is_win: boolean) {
        if (is_end_show)
            return;
        is_end_show = true;
        if (is_win) {
            gm.do_scale_anim_hash('game_border', null_scale, 0.3, 0, () => go.delete('game_border'));
            for (let x = 0; x < gridW; x++) {
                for (let y = 0; y < gridH; y++) {
                    const h = get_hash_by_xy(x, y);
                    if (h) {
                        gm.do_scale_anim_hash(h, null_scale, 0.3, x * 0.1 + y * 0.03, () => go.delete(h));

                    }
                }
            }
            flow.delay(3);
            Manager.send_raw_ui('game_end', { is_win });
        }
        else {
            const mines = miner.get_mines_data();
            for (let x = 0; x < gridW; x++) {
                for (let y = 0; y < gridH; y++) {
                    const m = mines[x][y];
                    if (m == 1) {
                        make_cell(x, y, CellState.mine, -1);
                    }
                }
            }
            flow.delay(3);
            Manager.send_raw_ui('game_end', { is_win });
        }
    }

    function get_hash_by_xy(x: number, y: number) {
        for (let i = cells.length - 1; i >= 0; i--) {
            const cell = cells[i];
            if (cell.x == x && cell.y == y) {
                return cell._hash;
            }
        }
        return null;
    }

    function on_remove_old_cell(x: number, y: number) {
        update_ui();
        for (let i = cells.length - 1; i >= 0; i--) {
            const cell = cells[i];
            if (cell.x == x && cell.y == y) {
                go.delete(cell._hash);
                cells.splice(i, 1);
                return;
            }
        }
    }


    function add_boom(pos: vmath.vector3) {
        Sound.play('boom');
        const boom = gm.make_go('boom', pos);
        gm.set_sprite_hash(boom, 'boom');
        timer.delay(0.2, false, () => {
            gm.do_scale_anim_hash(boom, null_scale, 0.3, 0, () => go.delete(boom));
        });
    }

    function update_ui() {
        Manager.send_raw_ui('num_mines', { cnt: num_mines - miner.get_count_flags(CellState.mark_mine) });
    }



    init();

    return {};
}

