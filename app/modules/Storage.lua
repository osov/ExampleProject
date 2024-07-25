local ____exports = {}
local StorageModule, use_custom_storage_key
function StorageModule(file_key)
    if file_key == nil then
        file_key = "sys_save_load"
    end
    local function apply_custom_key()
        file_key = "sys_save_load_" .. sys.get_config("android.package")
    end
    local function set_data(key, tab)
        local filename = sys.get_save_file(file_key, key)
        sys.save(filename, tab)
    end
    local function get_data(key)
        local filename = sys.get_save_file(file_key, key)
        local data = sys.load(filename)
        local nx = next(data)
        if nx == nil then
            return nil
        end
        return data
    end
    local function get(key)
        local data = get_data(key)
        if data == nil then
            return nil
        else
            return data.value
        end
    end
    local function set(key, val)
        set_data(key, {value = val})
    end
    local function get_int(key, def)
        if def == nil then
            def = 0
        end
        local data = get_data(key)
        if data == nil then
            return def
        end
        return data.value
    end
    local function get_bool(key, def)
        if def == nil then
            def = false
        end
        local val = get_int(key, -1)
        if val == -1 then
            return def
        end
        return val == true
    end
    local function get_string(key, def)
        if def == nil then
            def = ""
        end
        local data = get_data(key)
        if data == nil then
            return def
        end
        return data.value or ""
    end
    if use_custom_storage_key then
        apply_custom_key()
    end
    return {
        set_data = set_data,
        get_data = get_data,
        get = get,
        set = set,
        get_int = get_int,
        get_bool = get_bool,
        get_string = get_string
    }
end
use_custom_storage_key = false
function ____exports.register_storage(_use_custom_storage_key)
    use_custom_storage_key = _use_custom_storage_key
    _G.Storage = StorageModule()
end
return ____exports
