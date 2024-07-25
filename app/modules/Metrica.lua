local ____exports = {}
local MetricaModule
function MetricaModule()
    local function init(id_metrica_android)
        if System.platform == "HTML5" then
            if yametrica ~= nil then
                yametrica.not_bounce()
            end
        elseif System.platform == "Android" then
            if appmetrica ~= nil and id_metrica_android ~= "" then
                appmetrica.set_callback(function() return log("app metrica init ok") end)
                appmetrica.initialize(id_metrica_android)
            end
        end
    end
    local function report(event, json_data)
        if json_data == nil then
            json_data = ""
        end
        if appmetrica ~= nil then
            appmetrica.report_event(
                event,
                json_data == "" and "" or json.encode(json_data)
            )
        end
        if yametrica ~= nil then
            yametrica.hit(event, json_data == "" and ({}) or json_data)
        end
    end
    return {init = init, report = report}
end
function ____exports.register_metrica()
    _G.Metrica = MetricaModule()
end
return ____exports
