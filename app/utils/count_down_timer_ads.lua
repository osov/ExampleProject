local ____exports = {}
function ____exports.CountDownAds(delay_list, fnc)
    local _cur_index = -1
    local _start_time = 0
    local _is_allow = false
    local _last_time = -1
    local id_timer = nil
    local function on_update_tick()
        local wait_time = delay_list[_cur_index + 1]
        local dt = System.now() - _start_time
        local cur_time = wait_time - dt
        if cur_time < 0 then
            cur_time = 0
        end
        _is_allow = cur_time == 0
        if _last_time == cur_time then
            return
        end
        _last_time = cur_time
        fnc(cur_time)
    end
    local function next_tick()
        _cur_index = _cur_index + 1
        if _cur_index > #delay_list - 1 then
            _cur_index = #delay_list - 1
        end
        _start_time = System.now()
        _is_allow = false
    end
    local function is_allow()
        return _is_allow
    end
    local function stop()
        if id_timer then
            timer.cancel(id_timer)
            id_timer = nil
        end
    end
    next_tick()
    id_timer = timer.delay(1, true, on_update_tick)
    return {next_tick = next_tick, is_allow = is_allow, stop = stop}
end
return ____exports
