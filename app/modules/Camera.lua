local ____exports = {}
local CameraModule
local camera = require("utils.camera")
function CameraModule()
    local is_gui_projection = false
    local function set_gui_projection(value)
        is_gui_projection = value
        msg.post("@render:", "use_only_projection", {value = value})
    end
    local function screen_to_world(screen_x, screen_y)
        return camera.screen_to_world(screen_x, screen_y)
    end
    local function transform_input_action(action)
        if is_gui_projection and action.x ~= nil then
            local tp = camera.screen_to_world(action.x, action.y)
            local window_x, window_y = window.get_size()
            local stretch_x = window_x / gui.get_width()
            local stretch_y = window_y / gui.get_height()
            action.x = tp.x / stretch_x
            action.y = tp.y / stretch_y
        end
    end
    local function set_go_prjection(anchor_x, anchor_y)
        msg.post("@render:", "use_width_projection", {anchor_x = anchor_x, anchor_y = anchor_y, near = -1, far = 1})
        camera.set_align(anchor_x, anchor_y)
        camera.update_window_size()
    end
    local function get_ltrb()
        return camera.screen_to_world_bounds()
    end
    return {
        set_gui_projection = set_gui_projection,
        transform_input_action = transform_input_action,
        set_go_prjection = set_go_prjection,
        get_ltrb = get_ltrb,
        screen_to_world = screen_to_world
    }
end
function ____exports.register_camera()
    _G.Camera = CameraModule()
end
return ____exports
