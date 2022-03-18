require "player"

function addPieceToMap(player_nb, id, map, x, y)
    if getPiecesInStock(player_nb, id) > 0 then
        removePieceFromStock(player_nb, id)
        print("Removed one "..getPieceFromInventoryById(id).name.." from player"..player_nb.."'s stock.")
        map[y][x].piece = getPieceFromInventoryById(id)
    else
        print("Player ", player_nb, " has no piece nb ", id, " in stock.")
    end
end

function init_map(w, h)

    map = {}
    map.w = w
    map.h = h

    for i = 1, h do
        map[i] = {}
        for j = 1, w do
            map[i][j] = {}
        end
    end

    return map
end