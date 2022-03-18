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
            enemy, firend = countNearbyPlayer(map, j, i, w, h)
            if enemy == 6 then
                return true
            end
        end
    end
    return false
end

function selectPieceOnMap(map, x, y, active_player_id)
    if map[y][x].player_id == active_player_id then
        print("Clicked map tile matches belongs to active player.")
        return true
    end
    print("Clicked tile does not belong to active player.")
    return false
end

function printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, x, y)
    --print(tostring(selected_piece_x)..", "..tostring(selected_piece_y))
    if move_mode == 1 and selected_piece_x > 0 and selected_piece_y > 0 then
        if map[selected_piece_y][selected_piece_x] then
            love.graphics.print("Selected piece: "..map[selected_piece_y][selected_piece_x].piece.name.." ("..selected_piece_x..", "..selected_piece_y..")", x, y)
        end
    end
end

function pass_turn(active_piece_id)
    if (active_player_id == 1) then
        move_mode = 0
        print("Player2's turn!")
        active_player_id = 2
        turn_number[1] = turn_number[1] + 1
    elseif (active_player_id == 2) then
        move_mode = 0
        print("Player1's turn!")
        active_player_id = 1
        turn_number[2] = turn_number[2] + 1
    end
<<<<<<< HEAD
end

function highlight_queenbee_movement()
    for i = 1, h do
        for j = 1, w do
            if map[i][j].neighbour and not map[i][j].piece then
                higlightHex(j, i)
            end
        end
    end
end

function highlight_beetle_movement(map, x, y, active_player_id)
    highlightNeighbours()
end

function highlight_grasshopper_movement(map, x, y, active_player_id)

end

function highlight_spider_movement(map, x, y, active_player_id)

end

function highlight_soldier_ant_movement(map, x, y, active_player_id)

end

function move_beetle(src_x, src_y, x, y, active_player_id)
    if (map[y][x].piece) then
        tempPiece = map[y][x].piece
        map[y][x].piece = piecesInventory.beetle
        map[y][x].piece.under_piece = tempPiece
        map[y][x].piece.under_piece.player_id = map[y][x].player_id
        tempPiece = nil
    else
        map[y][x].piece = piecesInventory.beetle
    end
    map[y][x].player_id = active_player_id
    if (map[src_y][src_x].piece.under_piece) then
        map[src_y][src_x].player_id = map[src_y][src_x].piece.under_piece.player_id
        map[src_y][src_x].piece = map[src_y][src_x].piece.under_piece
    else
        map[src_y][src_x].piece = nil
    end
end
=======
    if checkIfWin(map, w, h) then
        print("win")
    end
end
>>>>>>> bd04f1fa2bf32046e33109713c23d0826241256f
