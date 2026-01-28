-- Input handling for the game
-- Uses global variables managed by globals.lua and modules loaded in main.lua

local Input = {}

function Input.keypressed(key)
    local maxPieceId = #Config.pieceInventory
    
    if key == "a" and active_piece_id < maxPieceId then
        active_piece_id = active_piece_id + 1
    elseif key == "s" and active_piece_id > 1 then
        active_piece_id = active_piece_id - 1
    elseif key == "c" then
        console.toggle()
    elseif key == "x" then
        console.clear()
    elseif key == "d" then
        -- Save game state to file
        gamestate.save("savegame.json")
    elseif key == "l" then
        -- Load game state from file
        gamestate.load("savegame.json")
    elseif key == "h" then
        -- Toggle cube coordinate display
        show_cube_coords = not show_cube_coords
        print("Cube coordinates display: " .. (show_cube_coords and "ON" or "OFF"))
    elseif key == "n" then
        -- Host network game
        if network.mode == "none" then
            network.host(12345)
        else
            print("Already in network game. Press 'q' to quit.")
        end
    elseif key == "m" then
        -- Join network game
        if network.mode == "none" then
            network.join("localhost", 12345)
        else
            print("Already in network game. Press 'q' to quit.")
        end
    elseif key == "q" then
        -- Quit network game
        if network.mode ~= "none" then
            network.disconnect()
        end
    elseif key == "=" or key == "+" then
        -- Zoom in with keyboard
        local zoom_speed = 0.2
        local max_zoom = 3.0
        local mouseX, mouseY = love.mouse.getPosition()
        local world_x_before = (mouseX - camera_x) / camera_zoom
        local world_y_before = (mouseY - camera_y) / camera_zoom
        
        camera_zoom = math.min(camera_zoom + zoom_speed, max_zoom)
        print("Zoom in (keyboard): " .. string.format("%.1f", camera_zoom))
        
        local world_x_after = (mouseX - camera_x) / camera_zoom
        local world_y_after = (mouseY - camera_y) / camera_zoom
        camera_x = camera_x + (world_x_after - world_x_before) * camera_zoom
        camera_y = camera_y + (world_y_after - world_y_before) * camera_zoom
    elseif key == "-" or key == "_" then
        -- Zoom out with keyboard
        local zoom_speed = 0.2
        local min_zoom = 0.3
        local mouseX, mouseY = love.mouse.getPosition()
        local world_x_before = (mouseX - camera_x) / camera_zoom
        local world_y_before = (mouseY - camera_y) / camera_zoom
        
        camera_zoom = math.max(camera_zoom - zoom_speed, min_zoom)
        print("Zoom out (keyboard): " .. string.format("%.1f", camera_zoom))
        
        local world_x_after = (mouseX - camera_x) / camera_zoom
        local world_y_after = (mouseY - camera_y) / camera_zoom
        camera_x = camera_x + (world_x_after - world_x_before) * camera_zoom
        camera_y = camera_y + (world_y_after - world_y_before) * camera_zoom
    elseif key == "0" then
        -- Reset zoom to 1.0
        camera_zoom = 1.0
        print("Zoom reset to 1.0")
    end
end

function Input.mousepressed(x, y, button, istouch)
    if game_over == true then
        return
    end
    
    -- Block input if in network game and not local player's turn
    if network and network.mode ~= "none" and not network.is_local_turn then
        print("Waiting for opponent's move...")
        return
    end
    
    -- Right-click or middle-click to start dragging
    if button == 2 or button == 3 then
        is_dragging = true
        drag_start_x = x
        drag_start_y = y
        drag_start_camera_x = camera_x
        drag_start_camera_y = camera_y
        return
    end
    
    if button == 1 then
        local mouseX, mouseY = love.mouse.getPosition()
        
        -- Check if mosquito choice popup is active
        if mosquito_choice_popup then
            local choice = checkMosquitoChoicePopupClick(mouseX, mouseY, mosquito_popup_x, mosquito_popup_y)
            if choice == "beetle" then
                -- Execute beetle move (climbing on top)
                print("Mosquito using Beetle power to climb")
                local selected_cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
                local did_move = move_piece_on_map(map, selected_cube, mosquito_choice_dest)
                clear_all_neighbours(map, w, h)
                move_mode = 0
                mosquito_choice_popup = false
                mosquito_choice_dest = nil
                if did_move == true then
                    pass_turn(active_player_id)
                end
                return
            elseif choice == "pillbug" then
                -- Switch to pillbug special ability mode
                print("Mosquito using Pillbug power")
                local selected_cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
                local selected_hex = map_get_hex(map, selected_cube)
                
                pillbug_special_mode = true
                pillbug_cube = selected_cube
                pillbug_target_cube = mosquito_choice_dest
                mosquito_choice_popup = false
                mosquito_choice_dest = nil
                
                -- Clear current highlights and show drop locations
                clear_all_neighbours(map, w, h)
                
                -- Get and mark valid drop locations
                local drop_locations = selected_hex.piece:get_drop_locations_as_pillbug(map, pillbug_cube, pillbug_target_cube)
                print("Found " .. #drop_locations .. " drop locations")
                for _, dest_cube in ipairs(drop_locations) do
                    local hex = map_get_hex(map, dest_cube)
                    if hex then
                        hex.can_move = true
                        print("  DROP LOCATION: [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
                    end
                end
                return
            else
                -- Click outside popup cancels
                mosquito_choice_popup = false
                mosquito_choice_dest = nil
                move_mode = 0
                highlight = 0
                clear_all_neighbours(map, w, h)
                return
            end
        end
        
        -- Check if clicking on piece selector first (use centered position)
        local piece_count = #player[active_player_id].pieces
        local piece_size = 30
        local piece_spacing = piece_size * 2.5
        local total_width = (piece_count - 1) * piece_spacing
        local center_x = (window_w - total_width) / 2
        local selected_piece = clickPieceSelector(player, active_player_id, mouseX, mouseY, center_x, 20, piece_size)
        if selected_piece then
            active_piece_id = selected_piece
            print("Selected piece: " .. player[active_player_id].pieces[selected_piece].template.name)
            return
        end
        
        -- Convert mouse position to cube coordinates directly (accounting for zoom)
        local pixel_x = (mouseX - camera_x) / camera_zoom
        local pixel_y = (mouseY - camera_y) / camera_zoom
        local result_cube = cubecoords.from_pixel(pixel_x, pixel_y, size)
        local result_hex = map_get_hex(map, result_cube)
        
        if result_cube.x == 0 and result_cube.y == 0 and result_cube.z == 0 then
            print("CLICKED CENTER (0,0,0): pixel=(" .. pixel_x .. "," .. pixel_y .. "), hex_exists=" .. tostring(result_hex ~= nil))
        end
        
        print("CLICK: mouse=(" .. mouseX .. "," .. mouseY .. "), camera=(" .. camera_x .. "," .. camera_y .. "), pixel=(" .. pixel_x .. "," .. pixel_y .. "), cube=[" .. result_cube.x .. "," .. result_cube.y .. "," .. result_cube.z .. "], hex_exists=" .. tostring(result_hex ~= nil))
        
        -- Convert cube to offset for compatibility with existing code
        local resultX, resultY = cubecoords.to_offset(result_cube)
        
        if move_mode == 1 then
            local selected_cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
            local selected_hex = map_get_hex(map, selected_cube)
            
            -- Check if we're in Pillbug special move mode (phase 2: selecting destination)
            if pillbug_special_mode and pillbug_target_cube then
                if result_hex and result_hex.can_move then
                    -- Execute Pillbug or Mosquito special ability
                    local success = false
                    if selected_hex.piece.name == "Pillbug" and selected_hex.piece.use_special_ability then
                        success = selected_hex.piece:use_special_ability(map, pillbug_cube, pillbug_target_cube, result_cube)
                    elseif selected_hex.piece.name == "Mosquito" and selected_hex.piece.use_special_ability_as_pillbug then
                        success = selected_hex.piece:use_special_ability_as_pillbug(map, pillbug_cube, pillbug_target_cube, result_cube)
                    end
                    if success then
                        pass_turn(active_player_id)
                    end
                    -- Reset state
                    pillbug_special_mode = false
                    pillbug_cube = nil
                    pillbug_target_cube = nil
                    move_mode = 0
                    highlight = 0
                    clear_all_neighbours(map, w, h)
                    return
                else
                    -- Cancel special move
                    pillbug_special_mode = false
                    pillbug_cube = nil
                    pillbug_target_cube = nil
                    move_mode = 0
                    highlight = 0
                    clear_all_neighbours(map, w, h)
                    return
                end
            end
            
            -- Check if clicking on a legal move hex (for normal movement) FIRST
            -- This allows normal movement to work alongside special abilities
            if result_hex and result_hex.can_move and not result_hex.can_special then
                local did_move = move_piece_on_map(map, selected_cube, result_cube)
                clear_all_neighbours(map, w, h)
                move_mode = 0
                if did_move == true then
                    pass_turn(active_player_id)
                end
                return
            end
            
            -- Check if clicking on a pickable piece (Pillbug or Mosquito mimicking Pillbug special ability phase 1)
            if result_hex and result_hex.can_special and selected_hex.piece and (selected_hex.piece.name == "Pillbug" or selected_hex.piece.name == "Mosquito") then
                -- Check if mosquito has dual options (can also climb with beetle power)
                if selected_hex.piece.name == "Mosquito" and result_hex.piece and not result_hex.piece.under_piece then
                    -- Check if mosquito is adjacent to beetle
                    local adjacent_types = selected_hex.piece:get_adjacent_piece_types(map, selected_cube)
                    if adjacent_types[2] then  -- Has beetle adjacent
                        print("Mosquito has dual options - showing popup")
                        mosquito_choice_popup = true
                        mosquito_choice_dest = result_cube
                        mosquito_popup_x = mouseX
                        mosquito_popup_y = mouseY
                        return
                    end
                end
                
                local piece_name = selected_hex.piece.name
                print(piece_name .. " special: Selected target piece at [" .. result_cube.x .. "," .. result_cube.y .. "," .. result_cube.z .. "]")
                pillbug_special_mode = true
                pillbug_cube = selected_cube
                pillbug_target_cube = result_cube
                
                -- Clear current highlights and show drop locations
                clear_all_neighbours(map, w, h)
                
                -- Get and mark valid drop locations
                local drop_locations
                if selected_hex.piece.name == "Pillbug" then
                    drop_locations = selected_hex.piece:get_drop_locations(map, pillbug_cube, pillbug_target_cube)
                else
                    -- Mosquito using Pillbug ability
                    drop_locations = selected_hex.piece:get_drop_locations_as_pillbug(map, pillbug_cube, pillbug_target_cube)
                end
                print("Found " .. #drop_locations .. " drop locations")
                for _, dest_cube in ipairs(drop_locations) do
                    local hex = map_get_hex(map, dest_cube)
                    if hex then
                        hex.can_move = true  -- Use same highlighting for simplicity
                        print("  DROP LOCATION: [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
                    end
                end
                
                return
            end
            
            -- Clicking elsewhere cancels the selection
            move_mode = 0
            highlight = 0
            clear_all_neighbours(map, w, h)
            return
        end
        -- Check if hex exists in map
        local result_cube = cubecoords.from_offset(resultX, resultY)
        local result_hex = map_get_hex(map, result_cube)
        if result_hex then
            if selectPieceOnMap(map, resultX, resultY, active_player_id) then
                highlight = 1
                clear_all_neighbours(map, w, h)
                local selected_cube = cubecoords.from_offset(resultX, resultY)
                mark_legal_moves_for_piece(map, selected_cube, w, h)
                selected_piece_x = resultX
                selected_piece_y = resultY
                if player[active_player_id].pieces[1].inStock == 0 then
                    move_mode = 1
                end
                return
            else
                -- Get the piece template from player inventory
                local piece_info = player[active_player_id]:getPieceInfo(active_piece_id)
                if piece_info and piece_info.template then
                    if not tryAddPieceToMap(active_player_id, piece_info.template, map, result_cube) then
                        return
                    end
                    pass_turn(active_player_id)
                else
                    return
                end
            end
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
    local world_x_before = (mouseX - camera_x) / camera_zoom
    local world_y_before = (mouseY - camera_y) / camera_zoom
    
    -- Adjust zoom
    if y > 0 then
        camera_zoom = math.min(camera_zoom + zoom_speed, max_zoom)
        print("Zooming in: " .. camera_zoom)
    elseif y < 0 then
        camera_zoom = math.max(camera_zoom - zoom_speed, min_zoom)
        print("Zooming out: " .. camera_zoom)
    end
    
    -- Adjust camera position to zoom towards mouse cursor
    local world_x_after = (mouseX - camera_x) / camera_zoom
    local world_y_after = (mouseY - camera_y) / camera_zoom
    
    camera_x = camera_x + (world_x_after - world_x_before) * camera_zoom
    camera_y = camera_y + (world_y_after - world_y_before) * camera_zoom
end

function Input.update_mouse(dt)
    mouseX, mouseY = love.mouse.getPosition()
    -- Convert mouse to cube coordinates for display (accounting for zoom)
    local pixel_x = (mouseX - camera_x) / camera_zoom
    local pixel_y = (mouseY - camera_y) / camera_zoom
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, size)
    resultX, resultY = cubecoords.to_offset(hover_cube)
    
    -- Handle camera dragging
    if is_dragging then
        camera_x = drag_start_camera_x + (mouseX - drag_start_x)
        camera_y = drag_start_camera_y + (mouseY - drag_start_y)
    end
end

return Input
