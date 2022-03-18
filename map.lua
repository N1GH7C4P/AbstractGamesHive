require "player"

function checkAddPiece(player_nb, id, map, x, y)
    if (map[y][x].piece) then
        print("int")
        return false
    end
    print("out")
    return true
    -- first check if empty
    -- then check if atlest one next to
end

function addPieceToMap(player_nb, id, map, x, y)
    if getPiecesInStock(player_nb, id) == 0 then
        print("Player ", player_nb, " has no piece nb ", id, " in stock.")
        return false
    end
    if (not checkAddPiece(player_nb, id, map, x, y)) then
        print("Piece cant be placed there")
        return false
    end
    removePieceFromStock(player_nb, id)
    print("Removed one "..getPieceFromInventoryById(id).name.." from player"..player_nb.."'s stock.")
    map[y][x].player_id = player_nb
    map[y][x].piece = getPieceFromInventoryById(id)
    return true
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

function print_map_pieces(map, w, h, x, y)
    count = 0
    for i = 1, h do
        for j = 1, w do
            if (map[i][j].piece) then
                love.graphics.print( map[i][j].piece.name.." ("..j..", "..i..") - placed by: player"..map[i][j].player_id, x, y + count*20)
                count = count + 1
            end
        end
    end
end