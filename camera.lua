-- Camera module for zoom and pan controls
-- Works with the global G object to manage camera state

local Camera = {}

-- Camera constants
local ZOOM_SPEED_WHEEL = 0.1
local ZOOM_SPEED_KEYBOARD = 0.2
local MIN_ZOOM = 0.3
local MAX_ZOOM = 3.0

-- Zoom in towards a specific point (usually mouse position)
-- Modifies G.camera_zoom, G.camera_x, G.camera_y
function Camera.zoom_in(G, mouseX, mouseY, use_keyboard_speed)
    local zoom_speed = use_keyboard_speed and ZOOM_SPEED_KEYBOARD or ZOOM_SPEED_WHEEL

    -- Get world coordinates before zoom
    local world_x_before = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_before = (mouseY - G.camera_y) / G.camera_zoom

    -- Adjust zoom
    G.camera_zoom = math.min(G.camera_zoom + zoom_speed, MAX_ZOOM)

    -- Adjust camera position to zoom towards the point
    local world_x_after = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_after = (mouseY - G.camera_y) / G.camera_zoom
    G.camera_x = G.camera_x + (world_x_after - world_x_before) * G.camera_zoom
    G.camera_y = G.camera_y + (world_y_after - world_y_before) * G.camera_zoom

    return G.camera_zoom
end

-- Zoom out from a specific point (usually mouse position)
-- Modifies G.camera_zoom, G.camera_x, G.camera_y
function Camera.zoom_out(G, mouseX, mouseY, use_keyboard_speed)
    local zoom_speed = use_keyboard_speed and ZOOM_SPEED_KEYBOARD or ZOOM_SPEED_WHEEL

    -- Get world coordinates before zoom
    local world_x_before = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_before = (mouseY - G.camera_y) / G.camera_zoom

    -- Adjust zoom
    G.camera_zoom = math.max(G.camera_zoom - zoom_speed, MIN_ZOOM)

    -- Adjust camera position to zoom from the point
    local world_x_after = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_after = (mouseY - G.camera_y) / G.camera_zoom
    G.camera_x = G.camera_x + (world_x_after - world_x_before) * G.camera_zoom
    G.camera_y = G.camera_y + (world_y_after - world_y_before) * G.camera_zoom

    return G.camera_zoom
end

-- Reset zoom to 1.0
-- Modifies G.camera_zoom
function Camera.reset_zoom(G)
    G.camera_zoom = 1.0
    return G.camera_zoom
end

-- Start camera drag
-- Modifies G.is_dragging, G.drag_start_x, G.drag_start_y, G.drag_start_camera_x, G.drag_start_camera_y
function Camera.start_drag(G, mouseX, mouseY)
    G.is_dragging = true
    G.drag_start_x = mouseX
    G.drag_start_y = mouseY
    G.drag_start_camera_x = G.camera_x
    G.drag_start_camera_y = G.camera_y
end

-- Stop camera drag
-- Modifies G.is_dragging
function Camera.stop_drag(G)
    G.is_dragging = false
end

-- Update camera position during drag
-- Modifies G.camera_x, G.camera_y
-- Returns true if dragging was active, false otherwise
function Camera.update_drag(G, mouseX, mouseY)
    if not G.is_dragging then
        return false
    end

    G.camera_x = G.drag_start_camera_x + (mouseX - G.drag_start_x)
    G.camera_y = G.drag_start_camera_y + (mouseY - G.drag_start_y)
    return true
end

-- Convert screen coordinates to world coordinates
function Camera.screen_to_world(G, screenX, screenY)
    local world_x = (screenX - G.camera_x) / G.camera_zoom
    local world_y = (screenY - G.camera_y) / G.camera_zoom
    return world_x, world_y
end

-- Convert world coordinates to screen coordinates
function Camera.world_to_screen(G, worldX, worldY)
    local screen_x = worldX * G.camera_zoom + G.camera_x
    local screen_y = worldY * G.camera_zoom + G.camera_y
    return screen_x, screen_y
end

return Camera
