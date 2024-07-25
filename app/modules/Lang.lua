local ____lualib = require("lualib_bundle")
local __TS__ArrayIncludes = ____lualib.__TS__ArrayIncludes
local __TS__ObjectKeys = ____lualib.__TS__ObjectKeys
local __TS__StringSplit = ____lualib.__TS__StringSplit
local ____exports = {}
local LangModule
local ____langs = require("main.langs")
local lang_data = ____langs.lang_data
function LangModule()
    local get_app_lang, get_system_lang, has_lang, add_lang_data, set_lang, apply, add_lang_list, cur_lang, langs_data
    function get_app_lang()
        local lang = get_system_lang()
        if not has_lang(lang) then
            Log.warn("язык не найден:", lang, "применяем англ")
            lang = "en"
        end
        return lang
    end
    function get_system_lang()
        local info = sys.get_sys_info()
        local code = info.language
        if __TS__ArrayIncludes({
            "ru",
            "be",
            "kk",
            "uk",
            "uz"
        }, code) then
            return "ru"
        else
            return code
        end
    end
    function has_lang(code)
        return langs_data[code] ~= nil
    end
    function add_lang_data(lang, data)
        langs_data[lang] = data
    end
    function set_lang(lang, save_lang, apply_lang)
        if save_lang == nil then
            save_lang = false
        end
        if apply_lang == nil then
            apply_lang = true
        end
        if save_lang then
            Storage.set("lang", lang)
        end
        cur_lang = lang
        if apply_lang then
            apply()
        end
    end
    function apply()
        local data = langs_data[cur_lang]
        if not data then
            return Log.warn("язык не применен:", cur_lang)
        end
        local keys = __TS__ObjectKeys(langs_data[cur_lang])
        do
            local i = 0
            while i < #keys do
                local k = keys[i + 1]
                local val = data[k]
                local ok, node = pcall(gui.get_node, k)
                if ok then
                    gui.set_text(node, val)
                end
                i = i + 1
            end
        end
    end
    function add_lang_list(data)
        local tmp = data
        local langs = {}
        for keys in pairs(tmp) do
            local list = tmp[keys]
            for tl in pairs(list) do
                local tmp = __TS__StringSplit(tl, "-")
                if #tmp == 2 then
                    local l = tmp[2]
                    local val = table.concat(
                        __TS__StringSplit(
                            table.concat(
                                __TS__StringSplit(
                                    table.concat(
                                        __TS__StringSplit(
                                            table.concat(
                                                __TS__StringSplit(list[tl], "\r\n"),
                                                "\n"
                                            ),
                                            "\\n"
                                        ),
                                        "\n"
                                    ),
                                    "\\ n"
                                ),
                                "\n"
                            ),
                            "\\ N"
                        ),
                        "\n"
                    )
                    if langs[l] == nil then
                        langs[l] = {}
                    end
                    local keys_list = __TS__StringSplit(keys, " ")
                    do
                        local id = 0
                        while id < #keys_list do
                            local k = keys_list[id + 1]
                            langs[l][k] = val
                            id = id + 1
                        end
                    end
                end
            end
        end
        local max = 0
        for l in pairs(langs) do
            max = math.max(
                max,
                #__TS__ObjectKeys(langs)
            )
        end
        for l in pairs(langs) do
            local len = #__TS__ObjectKeys(langs)
            if len ~= max then
                Log.error((((("Язык не заполнен целиком:" .. l) .. " = ") .. tostring(max)) .. "/") .. tostring(len))
            end
            add_lang_data(l, langs[l])
        end
    end
    cur_lang = "en"
    langs_data = {}
    local function init()
        add_lang_list(lang_data)
        local save_lang = Storage.get_string("lang", "")
        if save_lang ~= "" then
            set_lang(save_lang, false, false)
        else
            set_lang(
                get_app_lang(),
                false,
                false
            )
        end
    end
    local function get_font()
        return cur_lang == "ar" and "myFont_ar" or "myFont"
    end
    local function get_lang()
        return cur_lang
    end
    local function get_text(code)
        local data = langs_data[cur_lang]
        if not data then
            Log.warn("нет языкового набора:", cur_lang)
            return ""
        end
        if data[code] == nil then
            Log.warn("код не найден:", code)
            return ""
        end
        return data[code]
    end
    local function set_custom_lang(code)
        if not has_lang(code) then
            Log.warn("язык не найден среди переводов:", code)
            code = "en"
        end
        cur_lang = code
        local name = Scene.get_current_name()
        if name ~= "" then
            Manager.send("APPLY_CUSTOM_LANG", {}, (name .. ":/ui#") .. name)
        end
    end
    local function is_gdpr()
        local info = sys.get_sys_info()
        local code = info.language
        return not __TS__ArrayIncludes({
            "ru",
            "az",
            "hy",
            "be",
            "uz",
            "kk",
            "ky",
            "tk",
            "tg",
            "uk"
        }, code)
    end
    init()
    return {
        get_font = get_font,
        get_text = get_text,
        is_gdpr = is_gdpr,
        apply = apply,
        set_custom_lang = set_custom_lang,
        get_lang = get_lang
    }
end
function ____exports.register_lang()
    _G.Lang = LangModule()
end
return ____exports
