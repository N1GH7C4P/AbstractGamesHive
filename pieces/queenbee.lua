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

function QueenBee:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    -- Queen can move one space to any adjacent position
    local map_module = require("map")
    map_module.mark_neighbours_on_map(map, src_x, src_y, w, h)
    if not map[dest_y][dest_x].neighbour then
        return false
    end
    return true
end

return QueenBee
