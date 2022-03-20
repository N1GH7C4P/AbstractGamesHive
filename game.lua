function countNearbyPlayer(map, x, y, w, h)
    local enemy_count = 0
    local friendly_count = 0

    mark_neighbours_on_map(map, x, y, w, h)
    for i = 1, map.h do
        for j = 1, map.w do
            if (map[i][j].neighbour) then
                if (map[i][j].player_id == active_player_id) then
                    friendly_count = friendly_count + 1
                elseif (map[i][j].player_id) then
                    enemy_count = enemy_count + 1
                end
            end
        end
    end
    clear_all_neighbours(map, w, h)
    return enemy_count, friendly_count
end

function checkIfWin(map, w, h)
    local enemy
    local friend

    for i = 1, map.h do
        for j = 1, map.w do
            if map[i][j].piece and map[i][j].piece.id == 1 then
                enemy, friend = countNearbyPlayer(map, j, i, w, h)
                if enemy + friend == 6 then
                    game_over = true
                    who_won[map[i][j].player_id] = 1
                end
            end
        end
    end
end

function selectPieceOnMap(map, x, y, active_player_id)
    if map[y][x].player_id == active_player_id then
        return true
    end
    return false
end

function printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, x, y)
    if move_mode == 1 and selected_piece_x > 0 and selected_piece_y > 0 then
        if map[selected_piece_y][selected_piece_x] then
            love.graphics.print("Selected piece: "..map[selected_piece_y][selected_piece_x].piece.name.." ("..selected_piece_x..", "..selected_piece_y..")", x, y)
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

function try_move_queen(src_x, src_y, x, y, active_player_id)
    mark_neighbours_on_map(map, src_x, src_y, map.w, map.h)
    if not map[y][x].neighbour then
        return false
    end
    return true
end

function try_move_spider(src_x, src_y, x, y, active_player_id)
    clear_all_neighbours(map, map.w, map.h)
    map[src_y][src_x].neighbour = true
    flood_neighbours_neighbours_jump(map, x, y, w, h)
    flood_neighbours_neighbours_jump(map, x, y, w, h)
    flood_neighbours_neighbours_jump(map, x, y, w, h)
    if not map[y][x].neighbour then
        return false
    end
    return true
end

function try_move_soldier_ant(src_x, src_y, x, y, active_player_id)
    return true
end

function try_move_grasshopper(src_x, src_y, x, y, active_player_id)
    return true
end

function try_move_beetle(src_x, src_y, x, y, active_player_id)
    mark_neighbours_on_map(map, src_x, src_y, map.w, map.h)
    if not map[y][x].neighbour then
        return false
    end
    return true
end

function move_beetle(src_x, src_y, x, y, active_player_id)
    -- If there is something, move on top of it ans store it as a tempPiece
    local tempPiece = nil
    if (map[y][x].piece) then
        tempPiece = map[y][x].piece
        tempPiece.player_id = map[y][x].player_id
        map[y][x].piece = map[src_y][src_x].piece
    else
    -- Or just move your piece there if its empty
        map[y][x].piece = map[src_y][src_x].piece
    end
    -- Mark new space with current turn player_id
    map[y][x].player_id = active_player_id
    -- If the source hex has an underpice, store it in "underpiece"
    if (map[src_y][src_x].piece.under_piece) then
        local underpiece = map[src_y][src_x].piece.under_piece
        map[src_y][src_x].piece.under_piece = nil
        map[src_y][src_x].player_id = underpiece.player_id
        map[src_y][src_x].piece = underpiece
        underpiece = nil
    else
        map[src_y][src_x].piece = nil
        map[src_y][src_x].active_piece_id = nil
    end
    --Temp piece becames the new underpiece
    if(tempPiece) then
        map[y][x].piece.under_piece = tempPiece
        map[y][x].piece.under_piece.player_id = tempPiece.player_id
        tempPiece = nil
    end
    return true
end
