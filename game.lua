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