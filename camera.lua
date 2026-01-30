-- Camera module for zoom and pan controls
-- Manages camera position, zoom level, and drag state

local Camera = {}

-- Camera state
local zoom = 1.0
local x = 0
local y = 0

-- Drag state
local is_dragging = false
local drag_start_x = 0
local drag_start_y = 0
local drag_start_camera_x = 0
local drag_start_camera_y = 0

-- Camera constants
local ZOOM_SPEED_WHEEL = 0.1
local ZOOM_SPEED_KEYBOARD = 0.2
local MIN_ZOOM = 0.3
local MAX_ZOOM = 3.0

-- Initialize camera (optionally with starting values)
function Camera.init(initial_zoom, initial_x, initial_y)
    zoom = initial_zoom or 1.0
    x = initial_x or 0
    y = initial_y or 0
    is_dragging = false
end

-- Zoom in towards a specific point (usually mouse position)
function Camera.zoom_in(mouseX, mouseY, use_keyboard_speed)
    local zoom_speed = use_keyboard_speed and ZOOM_SPEED_KEYBOARD or ZOOM_SPEED_WHEEL

    -- Get world coordinates before zoom
    local world_x_before = (mouseX - x) / zoom
    local world_y_before = (mouseY - y) / zoom

    -- Adjust zoom
    zoom = math.min(zoom + zoom_speed, MAX_ZOOM)

    -- Adjust camera position to zoom towards the point
    local world_x_after = (mouseX - x) / zoom
    local world_y_after = (mouseY - y) / zoom
    x = x + (world_x_after - world_x_before) * zoom
    y = y + (world_y_after - world_y_before) * zoom

    return zoom
end

-- Zoom out from a specific point (usually mouse position)
function Camera.zoom_out(mouseX, mouseY, use_keyboard_speed)
    local zoom_speed = use_keyboard_speed and ZOOM_SPEED_KEYBOARD or ZOOM_SPEED_WHEEL

    -- Get world coordinates before zoom
    local world_x_before = (mouseX - x) / zoom
    local world_y_before = (mouseY - y) / zoom

    -- Adjust zoom
    zoom = math.max(zoom - zoom_speed, MIN_ZOOM)

    -- Adjust camera position to zoom from the point
    local world_x_after = (mouseX - x) / zoom
    local world_y_after = (mouseY - y) / zoom
    x = x + (world_x_after - world_x_before) * zoom
    y = y + (world_y_after - world_y_before) * zoom

    return zoom
end

-- Reset zoom to 1.0
function Camera.reset_zoom()
    zoom = 1.0
    return zoom
end

-- Start camera drag
function Camera.start_drag(mouseX, mouseY)
    is_dragging = true
    drag_start_x = mouseX
    drag_start_y = mouseY
    drag_start_camera_x = x
    drag_start_camera_y = y
end

-- Stop camera drag
function Camera.stop_drag()
    is_dragging = false
end

-- Update camera position during drag
function Camera.update_drag(mouseX, mouseY)
    if not is_dragging then
        return false
    end

    x = drag_start_camera_x + (mouseX - drag_start_x)
    y = drag_start_camera_y + (mouseY - drag_start_y)
    return true
end

-- Check if currently dragging
function Camera.is_dragging()
    return is_dragging
end

-- Get current zoom level
function Camera.get_zoom()
    return zoom
end

-- Get current camera position
function Camera.get_position()
    return x, y
end

-- Set camera position (useful for initialization or loading saved state)
function Camera.set_position(new_x, new_y)
    x = new_x
    y = new_y
end

-- Set zoom level (useful for initialization or loading saved state)
function Camera.set_zoom(new_zoom)
    zoom = math.max(MIN_ZOOM, math.min(new_zoom, MAX_ZOOM))
end

-- Convert screen coordinates to world coordinates
function Camera.screen_to_world(screenX, screenY)
    local world_x = (screenX - x) / zoom
    local world_y = (screenY - y) / zoom
    return world_x, world_y
end

-- Convert world coordinates to screen coordinates
function Camera.world_to_screen(worldX, worldY)
    local screen_x = worldX * zoom + x
    local screen_y = worldY * zoom + y
    return screen_x, screen_y
end

return Camera
