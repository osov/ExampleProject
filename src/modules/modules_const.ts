/* eslint-disable @typescript-eslint/ban-types */
/* eslint-disable @typescript-eslint/no-empty-interface */
export type VoidCallback = () => void;
export type Messages = UserMessages & SystemMessages;
export type MessageId = keyof Messages;

export interface VoidMessage { }

export interface NameMessage extends VoidMessage { name: string; }
export interface InterMessage extends VoidMessage { is_check: boolean; }
export interface ValMessage extends VoidMessage { val: boolean; }
export interface SndMessage extends NameMessage { volume: number; speed: number }

export type _SystemMessages = {
    PLAY_SND: SndMessage,
    STOP_SND: NameMessage,
    ON_SOUND_PAUSE: ValMessage,
    LOAD_SCENE: NameMessage,
    SHOW_RATE: VoidMessage,
    APPLY_CUSTOM_LANG: VoidMessage,
    SCENE_LOADED: NameMessage,
    MANAGER_READY: VoidMessage,
    SHOW_REWARD: VoidMessage,
    SHOW_INTER: InterMessage,
    SHOW_BANNER: VoidMessage,
    HIDE_BANNER: VoidMessage,
};

export const _ID_MESSAGES = {
    MSG_TOUCH: hash('touch'),
    MSG_ON_MOVE: hash('on_move'),
    MSG_ON_DOWN: hash('on_down'),
    MSG_ON_UP: hash('on_up'),
    MSG_ON_DOWN_HASH: hash('down_hash'),
    MSG_ON_UP_HASH: hash('up_hash'),
    MSG_ON_MOVE_HASH: hash('move_hash'),
    MSG_ON_REWARDED: hash('on_rewarded')
};