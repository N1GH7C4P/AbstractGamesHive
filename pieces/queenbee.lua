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
    instance.image_path = "img/queen_bee.png"
    return instance
end

function QueenBee:try_to_move(map, src_cube, dest_cube)
    -- Queen can move one space to any adjacent position
    local distance = cubecoords.distance(src_cube, dest_cube)
    if distance ~= 1 then
        return false
    end
    
    -- Check freedom to move rule
    if not self:can_move_through_gap(map, src_cube, dest_cube) then
        return false
    end
    
    return true
end

-- Helper to check if a move through a gap is allowed (freedom to move)
function QueenBee:can_move_through_gap(map, from_cube, to_cube)
    -- Get the two hexes that are common neighbors of both from and to
    local from_neighbors = cubecoords.all_neighbors(from_cube)
    local to_neighbors = cubecoords.all_neighbors(to_cube)
    
    local common_neighbors = {}
    for _, fn in ipairs(from_neighbors) do
        for _, tn in ipairs(to_neighbors) do
            if cubecoords.equals(fn, tn) then
                table.insert(common_neighbors, fn)
            end
        end
    end
    
    -- Need exactly 2 common neighbors (the ones on either side of the gap)
    if #common_neighbors ~= 2 then
        return false
    end
    
    -- Check if both sides are blocked (if so, cannot move through)
    local hex1 = map_get_hex(map, common_neighbors[1])
    local hex2 = map_get_hex(map, common_neighbors[2])
    
    local blocked1 = hex1 and hex1.piece ~= nil
    local blocked2 = hex2 and hex2.piece ~= nil
    
    -- If both sides are blocked, cannot move through
    if blocked1 and blocked2 then
        return false
    end
    
    -- At least one side is open, can move through
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
