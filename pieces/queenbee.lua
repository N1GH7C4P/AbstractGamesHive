local Piece = require("pieces.piece")
local map_module = require("map")
local movement_utils = require("pieces.movement_utils")

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
    if not movement_utils.can_move_through_gap(map, src_cube, dest_cube) then
        return false
    end

    return true
end

function QueenBee:move_piece(map, src_cube, dest_cube, active_player_id)
    -- Use standard movement from movement_utils
    return movement_utils.simple_move_piece(map, src_cube, dest_cube)
end

function QueenBee:get_legal_moves(map, src_cube)
    -- Queen moves one space to adjacent empty hexes
    local moves = {}
    local neighbors = cubecoords.all_neighbors(src_cube)
    
    for _, neighbor_cube in ipairs(neighbors) do
        local dest_hex = map_module.get_hex(map, neighbor_cube)
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
    
    map_module.mark_neighbours_on_map_cube(map, src_cube)
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
            if movement_utils.can_move_through_gap(map, src_cube, hex.cube)
                and map_module.pieceCanDetach(map, src_cube)
                and map_module.try_self_detach(map, src_cube, hex.cube) then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return QueenBee
