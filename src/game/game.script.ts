/* eslint-disable @typescript-eslint/no-empty-interface */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-this-alias */
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

import { Game } from './game_logic';
import * as flow from 'ludobits.m.flow';

interface props {
}

export function init(this: props) {
    msg.post('.', 'acquire_input_focus');
    flow.start(() => Game(), {});
}

export function on_message(this: props, message_id: hash, message: any, sender: any): void {
    flow.on_message(message_id, message, sender);
}

export function on_input(this: props, action_id: string | hash, action: any): void {
    if (action_id == hash('touch'))
        msg.post('.', action_id, action);
}

export function final(this: props): void {
    flow.stop();
}