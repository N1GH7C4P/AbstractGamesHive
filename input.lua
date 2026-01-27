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
        -- Export game state to file
        gamestate.export_to_file(map, "gamestate.txt")
    elseif key == "l" then
        -- Load game state from file
        gamestate.load_from_file(map, "gamestate.txt")
    elseif key == "h" then
        -- Toggle cube coordinate display
        show_cube_coords = not show_cube_coords
        print("Cube coordinates display: " .. (show_cube_coords and "ON" or "OFF"))
    end
end

function Input.mousepressed(x, y, button, istouch)
    if game_over == true then
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
        -- Convert mouse position to cube coordinates directly
        local pixel_x = mouseX - camera_x
        local pixel_y = mouseY - camera_y
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
            
            -- If clicking on a legal move hex (marked with can_move), try to move
            if result_hex and result_hex.can_move then
                local did_move = move_piece_on_map(map, selected_piece_x, selected_piece_y, resultX, resultY)
                clear_all_neighbours(map, w, h)
                move_mode = 0
                if did_move == true then
                    pass_turn(active_player_id)
                end
                return
            else
                -- Clicking elsewhere cancels the selection
                move_mode = 0
                highlight = 0
                clear_all_neighbours(map, w, h)
                return
            end
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
            elseif (not tryAddPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)) then
                return
            end
            pass_turn(active_player_id)
        end
    end
end

function Input.mousereleased(x, y, button, istouch)
    -- Stop dragging on right-click or middle-click release
    if button == 2 or button == 3 then
        is_dragging = false
    end
end

function Input.update_mouse(dt)
    mouseX, mouseY = love.mouse.getPosition()
    -- Convert mouse to cube coordinates for display
    local pixel_x = mouseX - camera_x
    local pixel_y = mouseY - camera_y
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, size)
    resultX, resultY = cubecoords.to_offset(hover_cube)
    
    -- Handle camera dragging
    if is_dragging then
        camera_x = drag_start_camera_x + (mouseX - drag_start_x)
        camera_y = drag_start_camera_y + (mouseY - drag_start_y)
    end
end

return Input
