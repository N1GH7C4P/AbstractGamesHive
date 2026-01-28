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
    
    -- Mark piece as moved this turn
    src_hex.piece.has_moved_last_turn = true
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

function QueenBee:get_legal_moves(map, src_cube)
    -- Queen moves one space to adjacent empty hexes
    local moves = {}
    local neighbors = cubecoords.all_neighbors(src_cube)
    
    for _, neighbor_cube in ipairs(neighbors) do
        local dest_hex = map_get_hex(map, neighbor_cube)
        if dest_hex and not dest_hex.piece then
            if self:try_to_move(map, src_cube, neighbor_cube) then
                table.insert(moves, neighbor_cube)
            end
        end
    end
    
    return moves
end

function QueenBee:mark_legal_moves(map, src_cube)
    print("Testing Queen moves - checking adjacent hexes only")
    
    mark_neighbours_on_map_cube(map, src_cube)
    local adjacent_positions = {}
    
    for _, hex in pairs(map.hexes) do
        if hex.neighbour and not cubecoords.equals(hex.cube, src_cube) then
            table.insert(adjacent_positions, hex)
        end
    end
    
    -- Clear neighbour flags (not can_move/can_special)
    for _, hex in pairs(map.hexes) do
        hex.neighbour = nil
    end
    
    print("Found " .. #adjacent_positions .. " adjacent hexes")
    local legal_moves = {}
    
    for _, hex in ipairs(adjacent_positions) do
        if not hex.piece then
            if pieceCanDetach(map, src_cube) and try_self_detach(map, src_cube, hex.cube) then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return QueenBee
