function selectPieceOnMap(map, x, y, active_player_id)
    if map[y][x].player_id == active_player_id then
        return true
    end
    return false
end

function printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, x, y)

    if move_mode and selected_piece_y and selected_piece_x then
        if(map[selected_piece_y][selected_piece_x].piece) then
            love.graphics.print("Selected piece: "..map[selected_piece_y][selected_piece_x].piece.name.." ("..selected_piece_x..", "..selected_piece_y..")", x, y)
        end
    end
end