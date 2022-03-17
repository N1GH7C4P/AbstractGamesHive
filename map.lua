require "player"

function addPieceToMap(player_nb, id, map, x, y)
    if getPiecesInStock(player_nb, id > 0) then
        removePieceFromStock(player_nb, id)
        map[y][x].piece = getPieceFromInventoryById(id)
    else
        print("Player ", player_nb, " has no piece nb ", id, " in stock.")
    end
end

function init_map(x, y)

    map = {}

    for i = 1, y do
        map[i] = {}
        for j = 1, x do
            map[i][j] = {}
        end
    end

    return map
end