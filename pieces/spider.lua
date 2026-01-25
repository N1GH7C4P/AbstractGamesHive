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

function Spider:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    -- Spider moves exactly 3 spaces around the edge
    clear_all_neighbours(map, w, h)
    map[src_y][src_x].neighbour = true
    flood_neighbours_neighbours_jump(map, dest_x, dest_y, w, h)
    flood_neighbours_neighbours_jump(map, dest_x, dest_y, w, h)
    flood_neighbours_neighbours_jump(map, dest_x, dest_y, w, h)
    if not map[dest_y][dest_x].neighbour then
        return false
    end
    return true
end

function Spider:move_piece(map, src_x, src_y, dest_x, dest_y, active_player_id)
    -- Simple move: transfer piece to destination
    map[dest_y][dest_x].piece = map[src_y][src_x].piece
    map[dest_y][dest_x].player_id = map[src_y][src_x].player_id
    map[src_y][src_x].piece = nil
    map[src_y][src_x].player_id = nil
    return true
end

return Spider
