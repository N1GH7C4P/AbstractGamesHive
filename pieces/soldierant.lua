local Piece = require("pieces.piece")

-- SoldierAnt class
SoldierAnt = setmetatable({}, {__index = Piece})
SoldierAnt.__index = SoldierAnt

function SoldierAnt:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Soldier ant"
    instance.initials = "SA"
    instance.color = {0.5, 0.5, 0.5, 1}
    instance.id = 5
    return instance
end

function SoldierAnt:try_to_move(map, src_cube, dest_cube)
    -- Soldier ant can move any number of spaces around the edge of the hive
    -- Must stay adjacent to at least one piece at all times
    -- Cannot move through tight spaces (Freedom to Move rule)
    -- TODO: Implement proper path-finding
    return true
end

function SoldierAnt:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

return SoldierAnt
