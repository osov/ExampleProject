/* eslint-disable no-empty */

type OnOpenCallback = (x: number, y: number, state: number, val: number) => void;

export const CellState = {
    none: 0,
    opened: 1,
    mine: 2,
    mark_mine: 3,
    mark_quest: 4
};

export function Miner() {
    const mines: number[][] = [];
    const flags: number[][] = [];
    const revealed: boolean[][] = [];
    let _on_open_callback: OnOpenCallback | undefined;
    let _on_remove_callback: OnOpenCallback | undefined;
    let gridW = 8;
    let gridH = 8;
    let numMines = 10;
    let firstClick = true;

    function setup(wdith: number, height: number, num_mines: number, on_open_cb?: OnOpenCallback, on_remove_cb?: OnOpenCallback) {
        _on_open_callback = on_open_cb;
        _on_remove_callback = on_remove_cb;
        gridW = wdith;
        gridH = height;
        numMines = num_mines;
        firstClick = true;
        for (let x = 0; x < gridW; x++) {
            mines[x] = [];
            revealed[x] = [];
            flags[x] = [];
            for (let y = 0; y < gridH; y++) {
                mines[x][y] = 0;
                revealed[x][y] = false;
                flags[x][y] = 0;
            }
        }
    }

    function place_mines() {
        let i = 0;
        while (i < numMines) {
            const x = math.random(0, gridW - 1);
            const y = math.random(0, gridH - 1);
            if (mines[x][y] == 1) { }
            else {
                mines[x][y] = 1;
                i++;
            }
        }
    }

    function clear_mines() {
        for (let x = 0; x < gridW; x++) {
            for (let y = 0; y < gridH; y++) {
                mines[x][y] = 0;
            }
        }
    }

    function open(x: number, y: number, flag = -1) {
        if (out_bounds(x, y)) return;
        // Блокируем клик туда где ячейка открыта
        if (revealed[x][y])
            return;
        // команда задать флаг
        if (flag > -1) {
            // если стоит такой же флаг, то очищаем
            if (flags[x][y] == flag) {
                const old_flag = flags[x][y];
                flags[x][y] = CellState.none;
                if (_on_remove_callback)
                    _on_remove_callback(x, y, old_flag, 0);
                return;
            }
            // переназначение на новый
            const old_flag = flags[x][y];
            flags[x][y] = flag;
            if (_on_remove_callback)
                _on_remove_callback(x, y, old_flag, 0);
            on_open(x, y);
            return;
        }

        // если стоит флаг, а клик обычный, то блочим
        if (flags[x][y] > 0) {
            return;
        }

        if (firstClick) {
            firstClick = false;
            do {
                clear_mines();
                place_mines();
            } while (mines[x][y] != 0);
        }

        if (mines[x][y] != 0) {
            on_open(x, y);
        } else {
            reveal(x, y);
        }
    }
    function out_bounds(x: number, y: number) {
        return x < 0 || y < 0 || x >= gridW || y >= gridH;
    }
    function calc_near(x: number, y: number) {
        if (out_bounds(x, y)) return 0;
        let i = 0;
        for (let oX = -1; oX <= 1; oX++) {
            for (let oY = -1; oY <= 1; oY++) {
                if (out_bounds(oX + x, oY + y)) { }
                else
                    i += mines[oX + x][oY + y];
            }
        }
        return i;
    }

    function reveal(x: number, y: number) {
        if (out_bounds(x, y)) return;
        if (revealed[x][y]) return;
        revealed[x][y] = true;
        on_open(x, y);
        if (calc_near(x, y) > 0) return;

        reveal(x - 1, y - 1);
        reveal(x - 1, y + 1);
        reveal(x + 1, y - 1);
        reveal(x + 1, y + 1);

        reveal(x - 1, y);
        reveal(x + 1, y);
        reveal(x, y - 1);
        reveal(x, y + 1);
    }

    function on_open(x: number, y: number) {
        let state = CellState.none;
        if (flags[x][y] == CellState.mark_mine)
            state = CellState.mark_mine;
        else if (flags[x][y] == CellState.mark_quest)
            state = CellState.mark_quest;
        else if (mines[x][y] != 0)
            state = CellState.mine;
        else if (revealed[x][y])
            state = CellState.opened;
        let val = 0;
        const near = calc_near(x, y);
        if (near > 0 && revealed[x][y])
            val = near;
        if (_on_open_callback)
            _on_open_callback(x, y, state, val);
    }

    function get_count_flags(id_flag: number) {
        let cnt = 0;
        for (let x = 0; x < gridW; x++) {
            for (let y = 0; y < gridH; y++) {
                if (flags[x][y] == id_flag)
                    cnt++;
            }
        }
        return cnt;
    }

    function get_mines_data() {
        return mines;
    }

    function debug() {
        let str = '';
        let str2 = '';
        for (let y = 0; y < gridH; y++) {
            str += y + ') ';
            str2 += y + ') ';
            for (let x = 0; x < gridW; x++) {
                str += mines[x][y] == 0 ? '-' : 'x';
                str += ' ';
                str2 += revealed[x][y] ? '+' : '-';
                str2 += ' ';
            }
            str += '\n';
            str2 += '\n';
        }
        log('open:\n' + str2);
        log('mines:\n' + str);
    }

    function is_win() {
        let opened = 0;
        for (let y = 0; y < gridH; y++) {
            for (let x = 0; x < gridW; x++) {
                if (revealed[x][y])
                    opened++;
            }
        }
        return (gridW * gridH == opened + numMines);
    }

    return { setup, open, debug, is_win, get_count_flags, get_mines_data };
}