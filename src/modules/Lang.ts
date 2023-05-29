/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */

import { lang_data } from "../main/langs";

/*
    Модуль для работы с переводами
*/

declare global {
    const Lang: ReturnType<typeof LangModule>;
}


interface ILangData {
    [k: string]: string;
}

export function register_lang() {
    (_G as any).Lang = LangModule();
}

function LangModule() {

    let cur_lang = 'en';
    const langs_data: { [k: string]: ILangData } = {};


    function init() {
        add_lang_list(lang_data);
        const save_lang = Storage.get_string('lang', '');
        if (save_lang != '')
            set_lang(save_lang, false, false);
        else
            set_lang(get_app_lang(), false, false);
    }

    function get_font() {
        return cur_lang == 'ar' ? 'myFont_ar' : 'myFont';
    }

    function get_app_lang() {
        let lang = get_system_lang();
        if (!has_lang(lang)) {
            Log.warn('язык не найден:', lang, 'применяем англ');
            lang = 'en';
        }
        return lang;
    }

    function get_system_lang() {
        const info = sys.get_sys_info();
        const code = info.language as string;
        if (['ru', 'be', 'kk', 'uk', 'uz'].includes(code))
            return 'ru';
        else
            return code;
    }

    function has_lang(code: string) {
        return langs_data[code] !== undefined;
    }

    function get_lang() {
        return cur_lang;
    }

    function get_text(code: string) {
        const data = langs_data[cur_lang];
        if (!data) {
            Log.warn('нет языкового набора:', cur_lang);
            return '';
        }
        if (data[code] == undefined) {
            Log.warn('код не найден:', code);
            return '';
        }
        return data[code];
    }

    function add_lang_data(lang: string, data: ILangData) {
        langs_data[lang] = data;
        //print('register lang:', lang);
    }

    function set_lang(lang: string, save_lang = false, apply_lang = true) {
        if (save_lang)
            Storage.set('lang', lang);
        cur_lang = lang;
        if (apply_lang)
            apply();
    }

    function set_custom_lang(code: string) {
        if (!has_lang(code)) {
            Log.warn('язык не найден среди переводов:', code);
            code = 'en';
        }
        cur_lang = code;
        const name = Scene.get_current_name();

        if (name != "")
            Manager.send('APPLY_CUSTOM_LANG', {}, name + ':/ui#' + name);
    }


    function apply() {
        const data = langs_data[cur_lang];
        if (!data)
            return Log.warn('язык не применен:', cur_lang);
        const keys = Object.keys(langs_data[cur_lang]);

        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            const val = data[k];
            const [ok, node] = pcall(gui.get_node, k);
            if (ok)
                gui.set_text(node, val);
        }
    }

    function add_lang_list(data: any) {
        const tmp = data as { [k: string]: { [k: string]: string } };
        const langs: { [k: string]: { [k: string]: string } } = {};
        for (const keys in tmp) {
            const list = tmp[keys];
            for (const tl in list) {
                const tmp = tl.split('-');
                if (tmp.length == 2) {
                    const l = tmp[1];
                    const val = list[tl].split("\r\n").join('\n').split("\\n").join('\n').split("\\ n").join('\n').split("\\ N").join('\n');
                    if (langs[l] == undefined)
                        langs[l] = {};
                    const keys_list = keys.split(' ');
                    for (let id = 0; id < keys_list.length; id++) {
                        const k = keys_list[id];
                        langs[l][k] = val;
                    }
                }
            }
        }
        let max = 0;
        for (const l in langs) {
            max = math.max(max, Object.keys(langs).length);
        }

        for (const l in langs) {
            const len = Object.keys(langs).length;
            if (len != max)
                Log.error('Язык не заполнен целиком:' + l + ' = ' + max + '/' + len);
            add_lang_data(l, langs[l]);
        }
    }

    function is_gdpr() {
        const info = sys.get_sys_info();
        const code = info.language as string;
        return !(['ru', 'az', 'hy', 'be', 'uz', 'kk', 'ky', 'tk', 'tg', 'uk'].includes(code));
    }
    init();

    return { get_font, get_text, is_gdpr, apply, set_custom_lang, get_lang };


}