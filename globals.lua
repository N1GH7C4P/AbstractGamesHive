-- Global game state and configuration
-- This file contains all global variables used across the codebase
-- All globals are namespaced under 'G' to distinguish them from local variables

local Globals = {}

function Globals.init()
    -- Initialize global state table
    G = {}
    
    -- Configuration
    G.menu_offset_x = 0
    G.window_w = 0
    G.window_h = 0
    G.w = 0  -- Legacy map width (for backward compatibility)
    G.h = 0  -- Legacy map height (for backward compatibility)
    G.size = 0  -- Hex size
    
    -- Camera/viewport state for panning
    G.camera_x = 0
    G.camera_y = 0
    G.camera_zoom = 0.8  -- Camera zoom level (0.8 = default, >1 = zoomed in, <1 = zoomed out)
    G.is_dragging = false
    G.drag_start_x = 0
    G.drag_start_y = 0
    G.drag_start_camera_x = 0
    G.drag_start_camera_y = 0
    
    -- Game state
    G.move_mode = 0
    G.active_player_id = 1
    G.active_piece_id = 5
    G.selected_piece_x = 0
    G.selected_piece_y = 0
    G.highlight = 0
    G.game_over = false
    G.who_won = {0, 0}
    G.show_cube_coords = false
    G.turn_number = {1, 1}
    
    -- Pillbug special move state
    G.pillbug_special_mode = false
    G.pillbug_cube = nil
    G.pillbug_target_cube = nil
    
    -- Mosquito power choice popup state
    G.mosquito_choice_popup = false
    G.mosquito_choice_options = {}  -- List of {type="beetle"|"pillbug", dest_cube=...}
    G.mosquito_choice_dest = nil
    G.mosquito_popup_x = 0
    G.mosquito_popup_y = 0
    
    -- Mouse state
    G.mouseX = 0
    G.mouseY = 0
    G.resultX = 0
    G.resultY = 0
    
    -- Game objects (initialized later)
    G.grid = nil
    G.piecesInvetory = nil
    G.player = nil
    G.map = nil
    G.canvas = nil
    G.overlay = nil
end

-- Reset transient UI state (used when loading games or resetting interaction)
function Globals.reset_ui_state()
    G.pillbug_special_mode = false
    G.pillbug_cube = nil
    G.pillbug_target_cube = nil
    G.mosquito_choice_popup = false
    G.mosquito_choice_options = {}
    G.mosquito_choice_dest = nil
    G.mosquito_popup_x = 0
    G.mosquito_popup_y = 0
    G.selected_piece_x = 0
    G.selected_piece_y = 0
    G.move_mode = 0
    G.highlight = 0
end

return Globals
