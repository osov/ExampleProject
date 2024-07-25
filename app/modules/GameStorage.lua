local ____lualib = require("lualib_bundle")
local __TS__TypeOf = ____lualib.__TS__TypeOf
local ____exports = {}
local GameStorageModule
local ____game_config = require("main.game_config")
local _GAME_CONFIG = ____game_config._GAME_CONFIG
local _STORAGE_CONFIG = ____game_config._STORAGE_CONFIG
function GameStorageModule()
    local default_list = _STORAGE_CONFIG
    local function get_key(key, _type)
        if _type == nil then
            _type = ""
        end
        local data = Storage.get_data("settings-" .. key)
        if data == nil then
            if default_list[key] == nil then
                Log.error("Ключ не зарегистрирован:", key)
                return nil
            end
            local val = default_list[key]
            if _type ~= "" and __TS__TypeOf(val) ~= _type then
                Log.error(
                    "Ключ имеет неправильный тип. Ключ:" .. key,
                    "ожидаемый тип:" .. _type,
                    "фактический тип:" .. __TS__TypeOf(val)
                )
            end
            return val
        end
        return data.value
    end
    local function set(key, val)
        Storage.set("settings-" .. key, val)
    end
    local function get(key)
        return get_key(key)
    end
    return {set = set, get = get}
end
function ____exports.register_game_storage()
    _G.GameStorage = GameStorageModule()
    _G.GAME_CONFIG = _GAME_CONFIG
end
return ____exports
