-- Input handling for the game
-- Uses global variables managed by globals.lua and modules loaded in main.lua

local Input = {}
local PiecesEnum = require("pieces.pieces_enum")
local cubecoords = require("cubecoords")
local gamestate = require("gamestate")
local console = require("console")
local network = require("network")
local globals = require("globals")
local game = require("game")
local map_module = require("map")

-- Key handler functions (Lua doesn't have switch-case, so we use a table-based dispatch)
local keyHandlers = {
    ["a"] = function()
        -- Next piece
        local maxPieceId = #Config.pieceInventory
        if G.active_piece_id < maxPieceId then
            G.active_piece_id = G.active_piece_id + 1
        end
    end,
    
    ["s"] = function()
        -- Previous piece
        if G.active_piece_id > 1 then
            G.active_piece_id = G.active_piece_id - 1
        end
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
        gamestate.save("output/savegame.json")
    end,
    
    ["l"] = function()
        -- Load game
        gamestate.load("output/savegame.json")
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
        local zoom_speed = 0.2
        local max_zoom = 3.0
        local mouseX, mouseY = love.mouse.getPosition()
        local world_x_before = (mouseX - G.camera_x) / G.camera_zoom
        local world_y_before = (mouseY - G.camera_y) / G.camera_zoom
        
        G.camera_zoom = math.min(G.camera_zoom + zoom_speed, max_zoom)
        print("Zoom in (keyboard): " .. string.format("%.1f", G.camera_zoom))
        
        local world_x_after = (mouseX - G.camera_x) / G.camera_zoom
        local world_y_after = (mouseY - G.camera_y) / G.camera_zoom
        G.camera_x = G.camera_x + (world_x_after - world_x_before) * G.camera_zoom
        G.camera_y = G.camera_y + (world_y_after - world_y_before) * G.camera_zoom
    end,
    
    ["-"] = function()
        -- Zoom out
        local zoom_speed = 0.2
        local min_zoom = 0.3
        local mouseX, mouseY = love.mouse.getPosition()
        local world_x_before = (mouseX - G.camera_x) / G.camera_zoom
        local world_y_before = (mouseY - G.camera_y) / G.camera_zoom
        
        G.camera_zoom = math.max(G.camera_zoom - zoom_speed, min_zoom)
        print("Zoom out (keyboard): " .. string.format("%.1f", G.camera_zoom))
        
        local world_x_after = (mouseX - G.camera_x) / G.camera_zoom
        local world_y_after = (mouseY - G.camera_y) / G.camera_zoom
        G.camera_x = G.camera_x + (world_x_after - world_x_before) * G.camera_zoom
        G.camera_y = G.camera_y + (world_y_after - world_y_before) * G.camera_zoom
    end,
    
    ["0"] = function()
        -- Reset zoom
        G.camera_zoom = 1.0
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

-- Help descriptions for each key
local keyDescriptions = {
    ["Left Click"] = "Select/move pieces, place pieces from inventory",
    ["Right Click"] = "Deselect piece, cancel action",
    ["Mouse Wheel"] = "Zoom in/out",
    ["Drag"] = "Pan camera around the board",
    ["Space"] = "Show this help screen",
    ["r"] = "Restart game (local only)",
    ["h"] = "Toggle cube coordinate display",
    ["c"] = "Toggle debug console",
    ["x"] = "Clear console output",
    ["d"] = "Save game to file",
    ["l"] = "Load game from file",
    ["n"] = "Host network game (port 12345)",
    ["m"] = "Join network game (localhost:12345)",
    ["q"] = "Quit/disconnect network game",
    ["+/="] = "Zoom in",
    ["-/_"] = "Zoom out",
    ["0"] = "Reset zoom to 1.0x",
    ["Escape"] = "Quit game",
}

function Input.draw_help_overlay()
    if not G.show_help then return end
    
    -- Semi-transparent dark background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, G.window_w, G.window_h)
    
    -- Title
    love.graphics.setColor(1, 1, 0.5, 1)
    local title = "KEYBOARD & MOUSE CONTROLS"
    local font = love.graphics.getFont()
    local title_width = font:getWidth(title)
    love.graphics.print(title, (G.window_w - title_width) / 2, 50)
    
    -- Controls list
    love.graphics.setColor(1, 1, 1, 1)
    local y = 100
    local line_height = 25
    local key_x = G.window_w / 2 - 250
    local desc_x = G.window_w / 2 - 100
    
    -- Sort keys for consistent display
    local sorted_keys = {}
    for key, _ in pairs(keyDescriptions) do
        table.insert(sorted_keys, key)
    end
    table.sort(sorted_keys)
    
    for _, key in ipairs(sorted_keys) do
        local desc = keyDescriptions[key]
        -- Draw key in yellow
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.print(key, key_x, y)
        -- Draw description in white
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(desc, desc_x, y)
        y = y + line_height
    end
    
    -- Footer
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local footer = "Release SPACE to close"
    local footer_width = font:getWidth(footer)
    love.graphics.print(footer, (G.window_w - footer_width) / 2, G.window_h - 50)
    
    love.graphics.setColor(1, 1, 1, 1)
end

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
    if choice == "beetle" then
        -- Execute beetle move (climbing on top)
        print("Mosquito using Beetle power to climb")
        local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)
        local did_move = map_module.move_piece_on_map(G.map, selected_cube, G.mosquito_choice_dest, function()
            game.checkIfWin(G.map, G.w, G.h)
        end)
        map_module.clear_all_neighbours(G.map, G.w, G.h)
        G.move_mode = 0
        G.mosquito_choice_popup = false
        G.mosquito_choice_dest = nil
        if did_move == true then
            game.pass_turn(G.active_player_id)
        end
        return true
    elseif choice == "pillbug" then
        -- Switch to pillbug special ability mode
        print("Mosquito using Pillbug power")
        local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)
        local selected_hex = map_module.get_hex(G.map, selected_cube)
        
        G.pillbug_special_mode = true
        G.pillbug_cube = selected_cube
        G.pillbug_target_cube = G.mosquito_choice_dest
        G.mosquito_choice_popup = false
        G.mosquito_choice_dest = nil
        
        -- Clear current highlights and show drop locations
        map_module.clear_all_neighbours(G.map, G.w, G.h)
        
        -- Get and mark valid drop locations
        local drop_locations = selected_hex.piece:get_drop_locations_as_pillbug(G.map, G.pillbug_cube, G.pillbug_target_cube)
        print("Found " .. #drop_locations .. " drop locations")
        for _, dest_cube in ipairs(drop_locations) do
            local hex = map_module.get_hex(G.map, dest_cube)
            if hex then
                hex.can_drop = true
                print("  DROP LOCATION: [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
            end
        end
        return true
    else
        -- Click outside popup cancels
        G.mosquito_choice_popup = false
        G.mosquito_choice_dest = nil
        G.move_mode = 0
        G.highlight = 0
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
        G.active_piece_id = selected_piece
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
    local selected_hex = map_module.get_hex(G.map, selected_cube)
    
    if result_hex and result_hex.can_drop then
        -- Let the piece execute its own drop logic
        local success = selected_hex.piece:execute_drop(G.map, G.pillbug_cube, G.pillbug_target_cube, result_cube)
        if success then
            game.pass_turn(G.active_player_id)
        end
    end
    
    -- Reset state (whether successful or cancelled)
    G.pillbug_special_mode = false
    G.pillbug_cube = nil
    G.pillbug_target_cube = nil
    G.move_mode = 0
    G.highlight = 0
    map_module.clear_all_neighbours(G.map, G.w, G.h)
    return true
end

-- Helper: Handle normal movement click
local function handle_normal_movement_click(result_cube, result_hex)
    if not result_hex or not result_hex.can_move or result_hex.can_special then
        return false
    end
    
    local selected_cube = cubecoords.from_offset(G.selected_piece_x, G.selected_piece_y)
    local did_move = map_module.move_piece_on_map(G.map, selected_cube, result_cube, function()
        game.checkIfWin(G.map, G.w, G.h)
    end)
    map_module.clear_all_neighbours(G.map, G.w, G.h)
    G.move_mode = 0
    if did_move == true then
        game.pass_turn(G.active_player_id)
    end
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
local function handle_piece_placement_click(result_cube, result_hex, resultX, resultY)
    if not result_hex then
        return false
    end
    
    if game.selectPieceOnMap(G.map, result_cube, G.active_player_id) then
        -- Select existing piece on map
        G.highlight = 1
        map_module.clear_all_neighbours(G.map, G.w, G.h)
        map_module.mark_legal_moves_for_piece(G.map, result_cube, G.w, G.h)
        G.selected_piece_x = resultX
        G.selected_piece_y = resultY
        if G.player[G.active_player_id].pieces[1].inStock == 0 then
            G.move_mode = 1
        end
        return true
    else
        -- Place new piece from inventory
        local piece_info = G.player[G.active_player_id]:getPieceInfo(G.active_piece_id)
        if piece_info and piece_info.template then
            if not map_module.tryAddPieceToMap(G.active_player_id, piece_info.template, G.map, result_cube) then
                return true
            end
            game.checkIfWin(G.map, G.w, G.h)
            game.pass_turn(G.active_player_id)
            return true
        end
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
        G.is_dragging = true
        G.drag_start_x = x
        G.drag_start_y = y
        G.drag_start_camera_x = G.camera_x
        G.drag_start_camera_y = G.camera_y
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
        local pixel_x = (mouseX - G.camera_x) / G.camera_zoom
        local pixel_y = (mouseY - G.camera_y) / G.camera_zoom
        local result_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
        local result_hex = map_module.get_hex(G.map, result_cube)
         
        -- Convert cube to offset for compatibility
        local resultX, resultY = cubecoords.to_offset(result_cube)
        
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
            G.move_mode = 0
            G.highlight = 0
            map_module.clear_all_neighbours(G.map, G.w, G.h)
            return
        else
            -- No piece selected - handle selection or placement
            handle_piece_placement_click(result_cube, result_hex, resultX, resultY)
        end
    end
end

function Input.mousereleased(x, y, button, istouch)
    -- Stop dragging on right-click or middle-click release
    if button == 2 or button == 3 then
        is_dragging = false
    end
end

function Input.wheelmoved(x, y)
    print("Wheelmoved: x=" .. x .. ", y=" .. y)  -- Debug logging
    
    -- Zoom in/out with mousewheel
    local zoom_speed = 0.1
    local min_zoom = 0.3
    local max_zoom = 3.0
    
    -- Get mouse position before zoom
    local mouseX, mouseY = love.mouse.getPosition()
    local world_x_before = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_before = (mouseY - G.camera_y) / G.camera_zoom
    
    -- Adjust zoom
    if y > 0 then
        G.camera_zoom = math.min(G.camera_zoom + zoom_speed, max_zoom)
        print("Zooming in: " .. G.camera_zoom)
    elseif y < 0 then
        G.camera_zoom = math.max(G.camera_zoom - zoom_speed, min_zoom)
        print("Zooming out: " .. G.camera_zoom)
    end
    
    -- Adjust camera position to zoom towards mouse cursor
    local world_x_after = (mouseX - G.camera_x) / G.camera_zoom
    local world_y_after = (mouseY - G.camera_y) / G.camera_zoom
    
    G.camera_x = G.camera_x + (world_x_after - world_x_before) * G.camera_zoom
    G.camera_y = G.camera_y + (world_y_after - world_y_before) * G.camera_zoom
end

function Input.update_mouse(dt)
    G.mouseX, G.mouseY = love.mouse.getPosition()
    -- Convert mouse to cube coordinates for display (accounting for zoom)
    local pixel_x = (G.mouseX - G.camera_x) / G.camera_zoom
    local pixel_y = (G.mouseY - G.camera_y) / G.camera_zoom
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
    G.resultX, G.resultY = cubecoords.to_offset(hover_cube)
    
    -- Handle camera dragging
    if G.is_dragging then
        G.camera_x = G.drag_start_camera_x + (G.mouseX - G.drag_start_x)
        G.camera_y = G.drag_start_camera_y + (G.mouseY - G.drag_start_y)
    end
end

-- Export module
return {
    mousepressed = Input.mousepressed,
    mousereleased = Input.mousereleased,
    wheelmoved = Input.wheelmoved,
    update_mouse = Input.update_mouse,
    keypressed = Input.keypressed,
    keyreleased = Input.keyreleased,
    draw_help_overlay = Input.draw_help_overlay,
}
