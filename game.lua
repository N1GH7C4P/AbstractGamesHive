function countNearbyPlayer(map, x, y, w, h)
    local enemy_count = 0
    local friendly_count = 0
    
    local cube = cubecoords.from_offset(x, y)
    print("countNearbyPlayer called for [" .. cube.x .. "," .. cube.y .. "," .. cube.z .. "]")

    mark_neighbours_on_map(map, x, y, w, h)
    
    local hex_count = 0
    for _, hex in pairs(map.hexes) do
        hex_count = hex_count + 1
        if hex_count > 500 then
            print("ERROR: Iterating too many hexes in countNearbyPlayer!")
            break
        end
        if hex.neighbour then
            if hex.player_id == active_player_id then
                friendly_count = friendly_count + 1
            elseif hex.player_id then
                enemy_count = enemy_count + 1
            end
        end
    end
    
    print("countNearbyPlayer: checked " .. hex_count .. " hexes, found " .. enemy_count .. " enemies, " .. friendly_count .. " friendlies")
    clear_all_neighbours(map, w, h)
    return enemy_count, friendly_count
end

function checkIfWin(map, w, h)
    local enemy
    local friend

    for _, hex in pairs(map.hexes) do
        if hex.piece and hex.piece.id == 1 then
            local col, row = cubecoords.to_offset(hex.cube)
            enemy, friend = countNearbyPlayer(map, col, row, w, h)
            if enemy + friend == 6 then
                game_over = true
                who_won[hex.player_id] = 1
            end
        end
    end
end

function selectPieceOnMap(map, x, y, active_player_id)
    local cube = cubecoords.from_offset(x, y)
    local hex = map_get_hex(map, cube)
    if hex and hex.player_id == active_player_id then
        return true
    end
    return false
end

function printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, x, y)
    if move_mode == 1 and selected_piece_x > 0 and selected_piece_y > 0 then
        local cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
        local hex = map_get_hex(map, cube)
        if hex and hex.piece then
            love.graphics.print("Selected piece: "..hex.piece.name.." ("..selected_piece_x..", "..selected_piece_y..")", x, y)
        end
    end
end

function pass_turn(active_piece_id)
    if (active_player_id == 1) then
        move_mode = 0
        active_player_id = 2
        turn_number[1] = turn_number[1] + 1
    elseif (active_player_id == 2) then
        move_mode = 0
        active_player_id = 1
        turn_number[2] = turn_number[2] + 1
    end
    checkIfWin(map, w, h)
end
