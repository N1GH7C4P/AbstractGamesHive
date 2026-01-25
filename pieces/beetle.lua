local Piece = require("pieces.piece")

-- Beetle class
Beetle = setmetatable({}, {__index = Piece})
Beetle.__index = Beetle

function Beetle:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Beetle"
    instance.initials = "Be"
    instance.color = {0.5, 0.2, 0, 1}
    instance.id = 2
    return instance
end

function Beetle:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    -- Beetle can move one space and can climb on top of pieces
    mark_neighbours_on_map(map, src_x, src_y, w, h)
    if not map[dest_y][dest_x].neighbour then
        return false
    end
    return true
end

function Beetle:move_piece(map, src_x, src_y, dest_x, dest_y, active_player_id)
    -- If there is something, move on top of it and store it as under_piece
    local tempPiece = nil
    if map[dest_y][dest_x].piece then
        tempPiece = map[dest_y][dest_x].piece
        tempPiece.player_id = map[dest_y][dest_x].player_id
        map[dest_y][dest_x].piece = map[src_y][src_x].piece
    else
        -- Or just move your piece there if its empty
        map[dest_y][dest_x].piece = map[src_y][src_x].piece
    end
    -- Mark new space with current turn player_id
    map[dest_y][dest_x].player_id = active_player_id
    -- If the source hex has an under_piece, restore it
    if map[src_y][src_x].piece.under_piece then
        local underpiece = map[src_y][src_x].piece.under_piece
        map[src_y][src_x].piece.under_piece = nil
        map[src_y][src_x].player_id = underpiece.player_id
        map[src_y][src_x].piece = underpiece
        underpiece = nil
    else
        map[src_y][src_x].piece = nil
        map[src_y][src_x].player_id = nil
    end
    -- Temp piece becomes the new under_piece
    if tempPiece then
        map[dest_y][dest_x].piece.under_piece = tempPiece
        map[dest_y][dest_x].piece.under_piece.player_id = tempPiece.player_id
        tempPiece = nil
    end
    return true
end

return Beetle
