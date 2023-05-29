local ____exports = {}
function ____exports.CountDownTimer(max_time, fnc_tick, fnc_end)
    local stop, tick_timer, id_timer, start_time
    function stop()
        if id_timer ~= nil then
            timer.cancel(id_timer)
            id_timer = nil
        end
    end
    function tick_timer()
        local delta = max_time - (System.now() - start_time)
        if delta < 1 then
            delta = 0
        end
        fnc_tick(math.floor(delta))
        if delta == 0 then
            stop()
            fnc_end()
        end
    end
    id_timer = nil
    start_time = 0
    local function start(_max_time)
        if _max_time == nil then
            _max_time = 0
        end
        if _max_time > 0 then
            max_time = _max_time
        end
        stop()
        start_time = System.now()
        id_timer = timer.delay(1, true, tick_timer)
        tick_timer()
    end
    return {start = start, stop = stop}
end
return ____exports
