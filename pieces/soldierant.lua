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

function SoldierAnt:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    -- Soldier ant can move any number of spaces around the edge of the hive
    -- Must stay adjacent to at least one piece at all times
    -- Cannot move through tight spaces (Freedom to Move rule)
    
    -- TODO: Implement proper soldier ant path-finding logic
    -- For now, return true to allow basic movement
    return true
end

function SoldierAnt:move_piece(map, src_x, src_y, dest_x, dest_y, active_player_id)
    -- Simple move: transfer piece to destination
    map[dest_y][dest_x].piece = map[src_y][src_x].piece
    map[dest_y][dest_x].player_id = map[src_y][src_x].player_id
    map[src_y][src_x].piece = nil
    map[src_y][src_x].player_id = nil
    return true
end

return SoldierAnt
