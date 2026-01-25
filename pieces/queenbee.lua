local Piece = require("pieces.piece")

-- QueenBee class
QueenBee = setmetatable({}, {__index = Piece})
QueenBee.__index = QueenBee

function QueenBee:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Queen bee"
    instance.initials = "QB"
    instance.color = {1, 0.78, 0, 1}
    instance.id = 1
    return instance
end

function QueenBee:try_to_move(map, src_cube, dest_cube)
    -- Queen can move one space to any adjacent position
    local distance = cubecoords.distance(src_cube, dest_cube)
    if distance ~= 1 then
        return false
    end
    return true
end

function QueenBee:move_piece(map, src_cube, dest_cube, active_player_id)
    -- Simple move: transfer piece to destination
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

return QueenBee
