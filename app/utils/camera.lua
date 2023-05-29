---@diagnostic disable: param-type-mismatch

local M = {}
local v4_tmp = vmath.vector4()
local MATRIX4 = vmath.matrix4()
local DISPLAY_WIDTH = tonumber(sys.get_config("display.width")) or 540
local DISPLAY_HEIGHT = tonumber(sys.get_config("display.height")) or 960
local GUI_ADJUST = {
  [gui.ADJUST_FIT] = { sx = 1, sy = 1, ox = 0, oy = 0 }, -- Fit
  [gui.ADJUST_ZOOM] = { sx = 1, sy = 1, ox = 0, oy = 0 }, -- Zoom
  [gui.ADJUST_STRETCH] = { sx = 1, sy = 1, ox = 0, oy = 0 }, -- Stretch
}

--- Update the window size
-- @param width Current window width
-- @param height Current window height
function M.update_window_size()
  local width, height = window.get_size()
  if width == 0 or height == 0 then
    return
  end

  local sx = width / DISPLAY_WIDTH
  local sy = height / DISPLAY_HEIGHT

  -- Fit
  local adjust = GUI_ADJUST[gui.ADJUST_FIT]
  local scale = math.min(sx, sy)
  adjust.sx = scale * 1 / sx
  adjust.sy = scale * 1 / sy
  adjust.ox = (width - DISPLAY_WIDTH * scale) * 0.5 / scale
  adjust.oy = (height - DISPLAY_HEIGHT * scale) * 0.5 / scale

  -- Zoom
  adjust = GUI_ADJUST[gui.ADJUST_ZOOM]
  scale = math.max(sx, sy)
  adjust.sx = scale * 1 / sx
  adjust.sy = scale * 1 / sy
  adjust.ox = (width - DISPLAY_WIDTH * scale) * 0.5 / scale
  adjust.oy = (height - DISPLAY_HEIGHT * scale) * 0.5 / scale

  -- Stretch
  adjust = GUI_ADJUST[gui.ADJUST_STRETCH]
  adjust.sx = 1
  adjust.sy = 1
  -- distorts to fit window, offsets always zero
end

local anchor_x = 0
local anchor_y = 0
local function width_projection(near, far)
  local WINDOW_WIDTH, WINDOW_HEIGHT = window.get_size()
  local width = DISPLAY_WIDTH
  local height = DISPLAY_HEIGHT
  local window_width = WINDOW_WIDTH
  local window_height = WINDOW_HEIGHT

  local wr = window_width / width
  local sh = window_height / wr
  local w = width
  local h = sh

  local left = -w / 2
  local right = w / 2
  local bottom = -h / 2
  local top = h / 2

  -- top
  if anchor_y == 1 then
    bottom = -h
    top = 0
  end

  -- bottom
  if anchor_y == -1 then
    bottom = 0
    top = h
  end

  -- left
  if anchor_x == -1 then
    left = 0
    right = w
  end

  -- right
  if anchor_x == 1 then
    left = -w
    right = 0
  end

  return vmath.matrix4_orthographic(left, right, bottom, top, near, far)
end

local cur_projection = width_projection

local function unproject_xyz(inverse_view_projection, x, y, z)
  x = (2 * x / DISPLAY_WIDTH) - 1
  y = (2 * y / DISPLAY_HEIGHT) - 1
  z = (2 * z)
  local inv = inverse_view_projection
  local x1 = x * inv.m00 + y * inv.m01 + z * inv.m02 + inv.m03
  local y1 = x * inv.m10 + y * inv.m11 + z * inv.m12 + inv.m13
  local z1 = x * inv.m20 + y * inv.m21 + z * inv.m22 + inv.m23
  return x1, y1, z1
end

--- Setup width projection align
-- @param pos number align
-- translated to world coordinates
function M.set_align(ax, ay)
  anchor_x = ax
  anchor_y = ay
end

--- Translate screen coordinates to world coordinates given a
-- view and projection matrix
-- @param view View matrix
-- @param projection Projection matrix
-- @param screen Screen coordinates as a vector3
-- @return The mutated screen coordinates (ie the same v3 object)
-- translated to world coordinates
function M.unproject(view, projection, screen)
  assert(view, "You must provide a view")
  assert(projection, "You must provide a projection")
  assert(screen, "You must provide screen coordinates to translate")
  local inv = vmath.inv(projection * view)
  screen.x, screen.y, screen.z = unproject_xyz(inv, screen.x, screen.y, screen.z)
  return screen
end

--- Convert screen coordinates to world coordinates based
-- on a specific camera's view and projection
-- Screen coordinates are the scaled coordinates provided by action.x and action.y
-- in on_input()
-- @param camera_id or nil for the first camera
-- @param screen Screen coordinates as x,y
-- @return World coordinates
-- http://webglfactory.blogspot.se/2011/05/how-to-convert-world-to-screen.html
function M.screen_to_world(x, y, calc_is_inv)
  local view = MATRIX4
  local projection = cur_projection(-1, 1)
  local width, height = window.get_size()
  local is_inv = (width > height) and calc_is_inv
  local viewport_width = 0
  local viewport_height = 0
  if is_inv then
    viewport_width = DISPLAY_HEIGHT
    viewport_height = DISPLAY_WIDTH
  else
    viewport_width = DISPLAY_WIDTH
    viewport_height = DISPLAY_HEIGHT
  end
  local viewport_left = 0
  local viewport_bottom = 0

  local s = vmath.vector3(x, y, 0)
  s.x = (s.x - viewport_left) * (DISPLAY_WIDTH / viewport_width)
  s.y = (s.y - viewport_bottom) * (DISPLAY_HEIGHT / viewport_height)
  return M.unproject(view, projection, s)
end

--- Convert window coordinates to world coordinates based
-- on a specific camera's view and projection
-- Window coordinates are the non-scaled coordinates provided by action.screen_x
-- and action.screen_y in on_input()
-- @param camera_id or nil for the first camera
-- @param window Window coordinates as screen_x, screen_y
-- @return World coordinates
function M.window_to_world(screen_x, screen_y)
  local WINDOW_WIDTH, WINDOW_HEIGHT = window.get_size()
  local dpi_ratio = 1
  local view = MATRIX4
  local projection = cur_projection(-1, 1)
  local viewport_width = DISPLAY_WIDTH
  local viewport_height = DISPLAY_HEIGHT
  local viewport_left = 0
  local viewport_bottom = 0
  local scale_x = screen_x * dpi_ratio * DISPLAY_WIDTH / WINDOW_WIDTH
  local scale_y = screen_y * dpi_ratio * DISPLAY_HEIGHT / WINDOW_HEIGHT

  local screen = vmath.vector3(scale_x, scale_y, 0)
  screen.x = (screen.x - viewport_left) * (DISPLAY_WIDTH / viewport_width)
  screen.y = (screen.y - viewport_bottom) * (DISPLAY_HEIGHT / viewport_height)
  return M.unproject(view, projection, screen)
end

--- Convert world coordinates to screen coordinates based
-- on a specific camera's view and projection.
-- @param camera_id or nil for the first camera
-- @param world World coordinates as a vector3
-- @return Screen coordinates
-- http://webglfactory.blogspot.se/2011/05/how-to-convert-world-to-screen.html
function M.world_to_screen(world, adjust_mode)
  local view = MATRIX4
  local projection = cur_projection(-1, 1)
  local viewport_width = DISPLAY_WIDTH
  local viewport_height = DISPLAY_HEIGHT
  local viewport_left = 0
  local viewport_bottom = 0

  local screen = M.project(view, projection, vmath.vector3(world))
  screen.x = viewport_left + screen.x * (viewport_width / DISPLAY_WIDTH)
  screen.y = viewport_bottom + screen.y * (viewport_height / DISPLAY_HEIGHT)
  if adjust_mode then
    screen.x = (screen.x / GUI_ADJUST[adjust_mode].sx) - GUI_ADJUST[adjust_mode].ox
    screen.y = (screen.y / GUI_ADJUST[adjust_mode].sy) - GUI_ADJUST[adjust_mode].oy
  end
  return vmath.vector3(screen.x, screen.y, screen.z)
end

--- Translate world coordinates to screen coordinates given a
-- view and projection matrix
-- @param view View matrix
-- @param projection Projection matrix
-- @param world World coordinates as a vector3
-- @return The mutated world coordinates (ie the same v3 object)
-- translated to screen coordinates
function M.project(view, projection, world)
  assert(view, "You must provide a view")
  assert(projection, "You must provide a projection")
  assert(world, "You must provide world coordinates to translate")
  v4_tmp.x, v4_tmp.y, v4_tmp.z, v4_tmp.w = world.x, world.y, world.z, 1
  local v4 = projection * view * v4_tmp
  world.x = ((v4.x + 1) / 2) * DISPLAY_WIDTH
  world.y = ((v4.y + 1) / 2) * DISPLAY_HEIGHT
  world.z = ((v4.z + 0) / 2)
  return world
end

--- Get the screen bounds as world coordinates, ie where in world space the
-- screen corners are
-- @param camera_id or nil for the first camera
-- @return bounds Vector4 where x is left, y is top, z is right and w is bottom
function M.screen_to_world_bounds()
  local WINDOW_WIDTH, WINDOW_HEIGHT = window.get_size()
  local view = MATRIX4
  local projection = cur_projection(-1, 1)
  local inv = vmath.inv(projection * view)
  local bl_x, bl_y = unproject_xyz(inv, 0, 0, 0)
  local br_x, br_y = unproject_xyz(inv, WINDOW_WIDTH, 0, 0)
  local tl_x, tl_y = unproject_xyz(inv, 0, WINDOW_HEIGHT, 0)
  return vmath.vector4(bl_x, tl_y, br_x, bl_y)
end

return M
