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
    instance.image_path = "img/soldier_ant.png"
    return instance
end

function SoldierAnt:try_to_move(map, src_cube, dest_cube)
    -- Soldier ant can move any number of spaces around the edge of the hive
    -- Must stay adjacent to at least one piece at all times
    -- Cannot move through tight spaces (Freedom to Move rule)
    
    -- Use BFS to find if destination is reachable
    local visited = {}
    local queue = {src_cube}
    visited[cubecoords.to_key(src_cube)] = true
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        if cubecoords.equals(current, dest_cube) then
            return true
        end
        
        -- Try each neighbor
        local neighbors = cubecoords.all_neighbors(current)
        for _, next_cube in ipairs(neighbors) do
            local next_hex = map_get_hex(map, next_cube)
            local next_key = cubecoords.to_key(next_cube)
            
            if next_hex and not next_hex.piece and not visited[next_key] then
                -- Check if has adjacent pieces (stays connected)
                local has_adjacent_piece = false
                local next_neighbors = cubecoords.all_neighbors(next_cube)
                for _, nn in ipairs(next_neighbors) do
                    local nn_hex = map_get_hex(map, nn)
                    if nn_hex and nn_hex.piece then
                        has_adjacent_piece = true
                        break
                    end
                end
                
                if has_adjacent_piece and self:can_move_through_gap(map, current, next_cube) then
                    visited[next_key] = true
                    table.insert(queue, next_cube)
                end
            end
        end
    end
    
    return false
end

-- Helper to check if a move through a gap is allowed (freedom to move)
function SoldierAnt:can_move_through_gap(map, from_cube, to_cube)
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

-- Helper function to get all legal moves for soldier ant
function SoldierAnt:get_legal_moves(map, src_cube)
    local legal_moves = {}
    local visited = {}
    local queue = {src_cube}
    visited[cubecoords.to_key(src_cube)] = true
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        -- Try each neighbor
        local neighbors = cubecoords.all_neighbors(current)
        for _, next_cube in ipairs(neighbors) do
            local next_hex = map_get_hex(map, next_cube)
            local next_key = cubecoords.to_key(next_cube)
            
            if next_hex and not next_hex.piece and not visited[next_key] then
                -- Check if has adjacent pieces
                local has_adjacent_piece = false
                local next_neighbors = cubecoords.all_neighbors(next_cube)
                for _, nn in ipairs(next_neighbors) do
                    local nn_hex = map_get_hex(map, nn)
                    if nn_hex and nn_hex.piece then
                        has_adjacent_piece = true
                        break
                    end
                end
                
                if has_adjacent_piece and self:can_move_through_gap(map, current, next_cube) then
                    visited[next_key] = true
                    table.insert(queue, next_cube)
                    -- Add to legal moves (excluding starting position)
                    if not cubecoords.equals(next_cube, src_cube) then
                        table.insert(legal_moves, next_cube)
                    end
                end
            end
        end
    end
    
    return legal_moves
end

function SoldierAnt:move_piece(map, src_cube, dest_cube, active_player_id)
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

function SoldierAnt:mark_legal_moves(map, src_cube)
    print("Testing Soldier Ant moves - unlimited movement with BFS")
    
    if not pieceCanDetach(map, src_cube) then
        print("Soldier Ant cannot detach - would break hive")
        return {normal_moves = {}, special_targets = {}}
    end
    
    local ant_moves = self:get_legal_moves(map, src_cube)
    print("Found " .. #ant_moves .. " potential moves")
    
    local legal_moves = {}
    for _, dest_cube in ipairs(ant_moves) do
        if try_self_detach(map, src_cube, dest_cube) then
            local hex = map_get_hex(map, dest_cube)
            if hex then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return SoldierAnt
