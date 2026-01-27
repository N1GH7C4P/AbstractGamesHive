-- Global game state and configuration
-- This file contains all global variables used across the codebase

local Globals = {}

function Globals.init()
    -- Configuration
    menu_offset_x = 0
    window_w = 0
    window_h = 0
    w = 0  -- Legacy map width (for backward compatibility)
    h = 0  -- Legacy map height (for backward compatibility)
    size = 0  -- Hex size
    
    -- Camera/viewport state for panning
    camera_x = 0
    camera_y = 0
    is_dragging = false
    drag_start_x = 0
    drag_start_y = 0
    drag_start_camera_x = 0
    drag_start_camera_y = 0
    
    -- Game state
    move_mode = 0
    active_player_id = 1
    active_piece_id = 5
    selected_piece_x = 0
    selected_piece_y = 0
    highlight = 0
    game_over = false
    who_won = {0, 0}
    show_cube_coords = false
    turn_number = {1, 1}
    
    -- Mouse state
    mouseX = 0
    mouseY = 0
    resultX = 0
    resultY = 0
    
    -- Game objects (initialized later)
    grid = nil
    piecesInvetory = nil
    player = nil
    map = nil
    canvas = nil
    overlay = nil
end

return Globals
