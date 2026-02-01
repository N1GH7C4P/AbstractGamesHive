-- Input handling for the game
-- Uses global variables managed by globals.lua and modules loaded in main.lua

local Input = {}
local cubecoords = require("cubecoords")
local gamestate = require("gamestate")
local console = require("console")
local network = require("network")
local globals = require("globals")
local game = require("game")
local map_module = require("map")
local camera = require("camera")
local actions = require("actions")

-- Key handler functions (Lua doesn't have switch-case, so we use a table-based dispatch)
local keyHandlers = {
    ["a"] = function()
        -- Next piece
        actions.select_next_piece()
    end,

    ["s"] = function()
        -- Previous piece
        actions.select_previous_piece()
    end,
    
    ["c"] = function()
        -- Toggle console
        console.toggle()
    end,
    
    ["x"] = function()
        -- Clear console
        console.clear()
    end,
    
    ["d"] = function()
        -- Save game
        gamestate.save("savegame.json")
    end,

    ["l"] = function()
        -- Load game
        gamestate.load("savegame.json")
    end,
    
    ["h"] = function()
        -- Toggle cube coordinate display
        G.show_cube_coords = not G.show_cube_coords
        print("Cube coordinates display: " .. (G.show_cube_coords and "ON" or "OFF"))
    end,
    
    ["n"] = function()
        -- Host network game
        if network.mode == "none" then
            network.host(12345)
        else
            print("Already in network game. Press 'q' to quit.")
        end
    end,
    
    ["m"] = function()
        -- Join network game
        if network.mode == "none" then
            network.join("localhost", 12345)
        else
            print("Already in network game. Press 'q' to quit.")
        end
    end,
    
    ["q"] = function()
        -- Quit network game
        if network.mode ~= "none" then
            network.disconnect()
        end
    end,
    
    ["="] = function()
        -- Zoom in
        local mouseX, mouseY = love.mouse.getPosition()
        local new_zoom = camera.zoom_in(G, mouseX, mouseY, true)
        print("Zoom in (keyboard): " .. string.format("%.1f", new_zoom))
    end,
    
    ["-"] = function()
        -- Zoom out
        local mouseX, mouseY = love.mouse.getPosition()
        local new_zoom = camera.zoom_out(G, mouseX, mouseY, true)
        print("Zoom out (keyboard): " .. string.format("%.1f", new_zoom))
    end,
    
    ["0"] = function()
        -- Reset zoom
        camera.reset_zoom(G)
        print("Zoom reset to 1.0")
    end,
    
    ["r"] = function()
        -- Restart local game
        print("Restarting game...")
        game.init()
        print("Game restarted")
    end,
    
    ["escape"] = function()
        -- Quit game
        love.event.quit()
    end,
}

-- Support "+" and "_" as aliases
keyHandlers["+"] = keyHandlers["="]
keyHandlers["_"] = keyHandlers["-"]

-- Key descriptions moved to ui.lua for help overlay

function Input.keypressed(key)
    -- Handle spacebar separately to show help
    if key == "space" then
        G.show_help = true
        return
    end
    
    local handler = keyHandlers[key]
    if handler then
        handler()
    end
end

function Input.keyreleased(key)
    -- Hide help when spacebar is released
    if key == "space" then
        G.show_help = false
    end
end

-- Helper: Handle multiple option popup click (e.g., mosquito choosing between beetle/pillbug)
local function handle_multiple_option_click(mouseX, mouseY)
    if not G.mosquito_choice_popup then
        return false
    end
    
    local choice = checkMosquitoChoicePopupClick(mouseX, mouseY, G.mosquito_popup_x, G.mosquito_popup_y)
    local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)

    if choice == "beetle" then
        -- Execute beetle move (climbing on top)
        print("Mosquito using Beetle power to climb")
        actions.execute_mosquito_beetle_choice(selected_cube, G.mosquito_choice_dest)
        map_module.clear_all_neighbours(G.map, G.w, G.h)
        globals.deselect_piece()
        globals.clear_mosquito_popup()
        return true
    elseif choice == "pillbug" then
        -- Switch to pillbug special ability mode
        print("Mosquito using Pillbug power")
        globals.clear_mosquito_popup()
        local drop_locations = actions.execute_mosquito_pillbug_choice(selected_cube, G.mosquito_choice_dest)
        print("Found " .. #drop_locations .. " drop locations")
        return true
    else
        -- Click outside popup cancels
        globals.clear_mosquito_popup()
        globals.deselect_piece()
        map_module.clear_all_neighbours(G.map, G.w, G.h)
        return true
    end
end

-- Helper: Handle piece selector click
local function handle_piece_selector_click(mouseX, mouseY)
    local display_player_id = (network and network.mode ~= "none" and network.local_player_id) or G.active_player_id
    local piece_count = #G.player[display_player_id].pieces
    local piece_size = 30
    local piece_spacing = piece_size * 2.5
    local total_width = (piece_count - 1) * piece_spacing
    local center_x = (G.window_w - total_width) / 2
    local selected_piece = clickPieceSelector(G.player, display_player_id, mouseX, mouseY, center_x, 20, piece_size)
    
    if selected_piece then
        actions.select_piece_by_id(selected_piece)
        print("Selected piece: " .. G.player[display_player_id].pieces[selected_piece].template.name)
        return true
    end
    
    return false
end

-- Helper: Handle drop click (phase 2 of special ability)
local function handle_drop_click(result_cube, result_hex)
    if not G.pillbug_special_mode or not G.pillbug_target_cube then
        return false
    end

    local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)

    if result_hex and result_hex.can_drop then
        actions.execute_drop(selected_cube, G.pillbug_target_cube, result_cube)
    end

    -- Reset state (whether successful or cancelled)
    globals.clear_pillbug_mode()
    globals.deselect_piece()
    map_module.clear_all_neighbours(G.map, G.w, G.h)
    return true
end

-- Helper: Handle normal movement click
local function handle_normal_movement_click(result_cube, result_hex)
    if not result_hex or not result_hex.can_move or result_hex.can_special then
        return false
    end

    local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)
    actions.move_piece(selected_cube, result_cube)

    -- Clean up UI state after move
    map_module.clear_all_neighbours(G.map, G.w, G.h)
    globals.deselect_piece()
    return true
end

-- Helper: Handle special ability click (phase 1 of special ability)
local function handle_special_ability_click(result_cube, result_hex, mouseX, mouseY)
    if not result_hex or not result_hex.can_special then
        return false
    end
    
    local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)
    local selected_hex = map_module.get_hex(G.map, selected_cube)
    
    if not selected_hex or not selected_hex.piece then
        return false
    end
    
    -- Let the piece handle its own special click logic
    return selected_hex.piece:handle_special_click(G.map, selected_cube, result_cube, mouseX, mouseY)
end

-- Helper: Handle piece selection and placement from inventory
local function handle_piece_placement_click(result_cube, result_hex)
    if not result_hex then
        return false
    end

    -- Try to select existing piece on map
    if actions.select_piece_on_map(result_cube, G.active_player_id) then
        return true
    end

    -- Place new piece from inventory
    local piece_info = G.player[G.active_player_id]:getPieceInfo(G.active_piece_id)
    if piece_info and piece_info.template then
        actions.place_piece(G.active_player_id, piece_info.template, result_cube)
        return true
    end

    return false
end

function Input.mousepressed(x, y, button, istouch)
    if G.game_over == true then
        return
    end
    
    -- Block input if help overlay is shown
    if G.show_help then
        return
    end
    
    -- Block input if in network game and not local player's turn
    if network and network.mode ~= "none" and not network.is_local_turn then
        print("Waiting for opponent's move...")
        return
    end
    
    -- Right-click or middle-click to start dragging
    if button == 2 or button == 3 then
        camera.start_drag(G, x, y)
        return
    end
    
    if button == 1 then
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- Handle multiple option popup if active
        if handle_multiple_option_click(mouseX, mouseY) then
            return
        end
        
        -- Handle piece selector click
        if handle_piece_selector_click(mouseX, mouseY) then
            return
        end

        -- Convert mouse position to cube coordinates
        local pixel_x, pixel_y = camera.screen_to_world(G, mouseX, mouseY)
        local result_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
        local result_hex = map_module.get_hex(G.map, result_cube)
        
        if G.move_mode == 1 then
            -- Piece is selected - handle movement or special actions
            
            -- Handle drop (phase 2)
            if handle_drop_click(result_cube, result_hex) then
                return
            end
            
            -- Handle normal movement
            if handle_normal_movement_click(result_cube, result_hex) then
                return
            end
            
            -- Handle special ability (phase 1)
            if handle_special_ability_click(result_cube, result_hex, mouseX, mouseY) then
                return
            end
            
            -- Clicking elsewhere cancels the selection
            globals.deselect_piece()
            map_module.clear_all_neighbours(G.map, G.w, G.h)
            return
        else
            -- No piece selected - handle selection or placement
            handle_piece_placement_click(result_cube, result_hex)
        end
    end
end

function Input.mousereleased(x, y, button, istouch)
    -- Stop dragging on right-click or middle-click release
    if button == 2 or button == 3 then
        camera.stop_drag(G)
    end
end

function Input.wheelmoved(x, y)
    print("Wheelmoved: x=" .. x .. ", y=" .. y)  -- Debug logging

    -- Zoom in/out with mousewheel
    local mouseX, mouseY = love.mouse.getPosition()

    if y > 0 then
        local new_zoom = camera.zoom_in(G, mouseX, mouseY, false)
        print("Zooming in: " .. new_zoom)
    elseif y < 0 then
        local new_zoom = camera.zoom_out(G, mouseX, mouseY, false)
        print("Zooming out: " .. new_zoom)
    end
end

function Input.update_mouse(dt)
    G.mouseX, G.mouseY = love.mouse.getPosition()
    -- Convert mouse to cube coordinates for display (accounting for zoom)
    local pixel_x, pixel_y = camera.screen_to_world(G, G.mouseX, G.mouseY)
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
    G.resultX, G.resultY = cubecoords.to_offset(hover_cube)

    -- Handle camera dragging
    camera.update_drag(G, G.mouseX, G.mouseY)
end

return {
    mousepressed = Input.mousepressed,
    mousereleased = Input.mousereleased,
    wheelmoved = Input.wheelmoved,
    update_mouse = Input.update_mouse,
    keypressed = Input.keypressed,
    keyreleased = Input.keyreleased,
}
