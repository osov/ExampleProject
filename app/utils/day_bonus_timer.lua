local ____exports = {}
function ____exports.DayBonus()
    local t = os.date("*t")
    local current_dm = (tostring(t.day) .. ".") .. tostring(t.month)
    local function is_allow()
        local last_dm = Storage.get_string("day_bonus_last_dm", "")
        return current_dm ~= last_dm
    end
    local function take()
        local last_recv = Storage.get_int("day_bonus_last_time", 0)
        if last_recv == 0 then
            last_recv = System.now()
        end
        if System.now() - last_recv > 2 * 24 * 60 * 60 then
            Storage.set("day_bonus_seq", 0)
        end
        Storage.set(
            "day_bonus_seq",
            Storage.get_int("day_bonus_seq", 0) + 1
        )
        Storage.set(
            "day_bonus_all",
            Storage.get_int("day_bonus_all", 0) + 1
        )
        Storage.set("day_bonus_last_dm", current_dm)
        Storage.set(
            "day_bonus_last_time",
            System.now()
        )
    end
    local function get_num_days_seq()
        return Storage.get_int("day_bonus_seq", 1)
    end
    return {is_allow = is_allow, take = take, get_num_days_seq = get_num_days_seq}
end
return ____exports
