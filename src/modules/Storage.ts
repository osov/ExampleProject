/* eslint-disable @typescript-eslint/no-unsafe-argument */
/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

/*
    Модуль для хранения данных игрока, бывший PlayerPrefs
    если нужно сменить ключ хранения(на некоторых проектах он задан другим, то вызываем 1 раз метод apply_custom_key)
*/

declare global {
    const Storage: ReturnType<typeof StorageModule>;
}

let use_custom_storage_key = false;
export function register_storage(_use_custom_storage_key: boolean) {
    use_custom_storage_key = _use_custom_storage_key;
    (_G as any).Storage = StorageModule();
}

function StorageModule(file_key = 'sys_save_load') {

    // Очень важно чтобы использовалось только если в проекте уже был такой способ хранения
    function apply_custom_key() {
        file_key = "sys_save_load_" + sys.get_config("android.package");
    }

    function set_data(key: string, tab: any) {
        const filename = sys.get_save_file(file_key, key);
        sys.save(filename, tab);
    }

    function get_data(key: string) {
        const filename = sys.get_save_file(file_key, key);
        const data = sys.load(filename);
        const [nx] = next(data);
        if (nx == null)
            return null;
        return data;
    }

    function get(key: string) {
        const data = get_data(key);
        if (data == null)
            return null;
        else
            return data.value;
    }

    function set(key: string, val: any) {
        set_data(key, { value: val });
    }

    function get_int<T>(key: keyof T, def = 0): number {
        const data = get_data(key as string);
        if (data == null)
            return def;
        return data.value;
    }

    function get_bool(key: string, def = false): boolean {
        const val: any = get_int(key, -1);
        if (val == -1)
            return def;
        return val == true;
    }

    function get_string(key: string, def = ''): string {
        const data = get_data(key);
        if (data == null)
            return def;
        return data.value || '';
    }

    if (use_custom_storage_key)
        apply_custom_key();

    return { set_data, get_data, get, set, get_int, get_bool, get_string };

}