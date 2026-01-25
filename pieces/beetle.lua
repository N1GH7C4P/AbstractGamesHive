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

function Beetle:try_to_move(map, src_cube, dest_cube)
    -- Beetle can move one space and can climb on top of pieces
    local distance = cubecoords.distance(src_cube, dest_cube)
    if distance ~= 1 then
        return false
    end
    return true
end

function Beetle:move_piece(map, src_cube, dest_cube, active_player_id)
    -- Beetle can move on top of other pieces
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    local tempPiece = nil
    if dest_hex.piece then
        tempPiece = dest_hex.piece
        tempPiece.player_id = dest_hex.player_id
        dest_hex.piece = src_hex.piece
    else
        dest_hex.piece = src_hex.piece
    end
    
    dest_hex.player_id = active_player_id
    
    -- If the source hex has an under_piece, restore it
    if src_hex.piece.under_piece then
        local underpiece = src_hex.piece.under_piece
        src_hex.piece.under_piece = nil
        src_hex.player_id = underpiece.player_id
        src_hex.piece = underpiece
        underpiece = nil
    else
        src_hex.piece = nil
        src_hex.player_id = nil
    end
    
    -- Temp piece becomes the new under_piece
    if tempPiece then
        dest_hex.piece.under_piece = tempPiece
        dest_hex.piece.under_piece.player_id = tempPiece.player_id
        tempPiece = nil
    end
    
    return true
end

return Beetle
