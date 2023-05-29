local ____exports = {}
function ____exports.EventTimer(event_name, wait_time, on_update)
    local get_time_to_take, take
    function get_time_to_take()
        local last_time = Storage.get_int("et-" .. event_name, 0)
        local now = System.now()
        local dt = now - last_time
        local elapsed = wait_time - dt
        if elapsed < 0 then
            elapsed = 0
        end
        return elapsed
    end
    function take()
        Storage.set(
            "et-" .. event_name,
            System.now()
        )
    end
    local id_timer = nil
    local function is_allow(auto_take)
        if auto_take == nil then
            auto_take = false
        end
        local is_allow = get_time_to_take() < 1
        if auto_take then
            take()
        end
        return is_allow
    end
    local function stop()
        if id_timer then
            timer.cancel(id_timer)
            id_timer = nil
        end
    end
    local function do_tick()
        if on_update then
            on_update(get_time_to_take())
        end
    end
    local function run_timer()
        timer.delay(0, false, do_tick)
        id_timer = timer.delay(1, true, do_tick)
    end
    if on_update then
        run_timer()
    end
    return {is_allow = is_allow, get_time_to_take = get_time_to_take, take = take, stop = stop}
end
return ____exports
