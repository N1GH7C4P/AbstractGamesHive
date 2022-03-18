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