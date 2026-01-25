local Piece = require("pieces.piece")

-- Spider class
Spider = setmetatable({}, {__index = Piece})
Spider.__index = Spider

function Spider:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Spider"
    instance.initials = "Sp"
    instance.color = {0.5, 0, 0, 1}
    instance.id = 4
    return instance
end

function Spider:try_to_move(map, src_cube, dest_cube)
    -- Spider moves exactly 3 spaces around the edge
    local distance = cubecoords.distance(src_cube, dest_cube)
    if distance ~= 3 then
        return false
    end
    -- TODO: Implement proper spider path validation (must move along edge)
    return true
end

function Spider:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

return Spider
