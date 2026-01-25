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
