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
    instance.image_path = "img/spider.png"
    return instance
end

function Spider:try_to_move(map, src_cube, dest_cube)
    -- Spider moves exactly 3 spaces around the edge
    -- Must find a valid 3-step path following "freedom to move" rules
    
    -- Check if there's a valid 3-step path
    local visited = {}
    visited[cubecoords.to_key(src_cube)] = true
    
    return self:find_path(map, src_cube, dest_cube, 0, visited)
end

-- Helper to check if a move through a gap is allowed (freedom to move)
function Spider:can_move_through_gap(map, from_cube, to_cube)
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
    local hex1 = get_hex(map, common_neighbors[1])
    local hex2 = get_hex(map, common_neighbors[2])
    
    local blocked1 = hex1 and hex1.piece ~= nil
    local blocked2 = hex2 and hex2.piece ~= nil
    
    -- If both sides are blocked, cannot move through
    if blocked1 and blocked2 then
        return false
    end
    
    -- At least one side is open, can move through
    return true
end

-- Recursive pathfinding for exactly 3 steps
function Spider:find_path(map, current_cube, dest_cube, steps, visited)
    -- If we've taken 3 steps, check if we're at destination
    if steps == 3 then
        return cubecoords.equals(current_cube, dest_cube)
    end
    
    -- If we're at destination but haven't taken 3 steps, this path fails
    if cubecoords.equals(current_cube, dest_cube) then
        return false
    end
    
    -- Try moving to each neighbor
    local neighbors = cubecoords.all_neighbors(current_cube)
    for _, next_cube in ipairs(neighbors) do
        local next_hex = get_hex(map, next_cube)
        local next_key = cubecoords.to_key(next_cube)
        
        -- Check if this hex is valid:
        -- 1. Exists in map
        -- 2. Is empty (no piece)
        -- 3. Not already visited in this path
        -- 4. Has at least one neighbor with a piece (stays connected to hive)
        -- 5. Can move through the gap (freedom to move)
        if next_hex and not next_hex.piece and not visited[next_key] then
            -- Check if destination has adjacent pieces (stays connected)
            local has_adjacent_piece = false
            local next_neighbors = cubecoords.all_neighbors(next_cube)
            for _, nn in ipairs(next_neighbors) do
                local nn_hex = get_hex(map, nn)
                if nn_hex and nn_hex.piece then
                    has_adjacent_piece = true
                    break
                end
            end
            
            if has_adjacent_piece and self:can_move_through_gap(map, current_cube, next_cube) then
                -- Mark as visited and recurse
                visited[next_key] = true
                if self:find_path(map, next_cube, dest_cube, steps + 1, visited) then
                    return true
                end
                -- Backtrack
                visited[next_key] = nil
            end
        end
    end
    
    return false
end

-- Helper function to get all legal moves for spider
function Spider:get_legal_moves(map, src_cube)
    local legal_moves = {}
    local initial_visited = {}
    initial_visited[cubecoords.to_key(src_cube)] = true
    
    print("Spider:get_legal_moves starting from [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "]")
    
    -- Find all positions reachable in exactly 3 steps
    -- Pass src_cube so we can ignore it when checking for adjacent pieces
    self:find_all_paths(map, src_cube, 0, initial_visited, legal_moves, {}, src_cube)
    
    print("Total destinations found: " .. #legal_moves)
    return legal_moves
end

-- Collect all destinations reachable in exactly 3 steps
-- path parameter tracks the sequence of positions visited
-- src_cube is the starting position to ignore when checking for adjacent pieces
function Spider:find_all_paths(map, current_cube, steps, visited, destinations, path, src_cube)
    -- Add current position to path
    local current_path = {}
    for i, cube in ipairs(path) do
        current_path[i] = cube
    end
    table.insert(current_path, {x = current_cube.x, y = current_cube.y, z = current_cube.z})
    
    -- If we've taken 3 steps, this is a valid destination
    if steps == 3 then
        -- Log the complete path
        local path_str = "Path: "
        for i, cube in ipairs(current_path) do
            local col, row = cubecoords.to_offset(cube)
            path_str = path_str .. "[" .. cube.x .. "," .. cube.y .. "," .. cube.z .. "]"
            path_str = path_str .. "=(" .. col .. "," .. row .. ")"
            if i < #current_path then
                path_str = path_str .. " -> "
            end
        end
        print("  " .. path_str)
        
        table.insert(destinations, current_cube)
        return
    end
    
    -- Try moving to each neighbor
    local neighbors = cubecoords.all_neighbors(current_cube)
    for _, next_cube in ipairs(neighbors) do
        local next_hex = get_hex(map, next_cube)
        local next_key = cubecoords.to_key(next_cube)
        
        if next_hex and not next_hex.piece and not visited[next_key] then
            -- Check if has adjacent pieces (excluding the spider's starting position)
            local has_adjacent_piece = false
            local next_neighbors = cubecoords.all_neighbors(next_cube)
            for _, nn in ipairs(next_neighbors) do
                -- Skip the starting position when checking for adjacent pieces
                if not cubecoords.equals(nn, src_cube) then
                    local nn_hex = get_hex(map, nn)
                    if nn_hex and nn_hex.piece then
                        has_adjacent_piece = true
                        break
                    end
                end
            end
            
            if has_adjacent_piece and self:can_move_through_gap(map, current_cube, next_cube) then
                visited[next_key] = true
                self:find_all_paths(map, next_cube, steps + 1, visited, destinations, current_path, src_cube)
                visited[next_key] = nil
            end
        end
    end
end

function Spider:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = get_hex(map, src_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    -- Mark piece as moved this turn
    src_hex.piece.has_moved_last_turn = true
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

function Spider:mark_legal_moves(map, src_cube)
    print("Testing Spider moves - finding paths of exactly 3 steps")
    
    if not pieceCanDetach(map, src_cube) then
        print("Spider cannot detach - would break hive")
        return {normal_moves = {}, special_targets = {}}
    end
    
    local spider_moves = self:get_legal_moves(map, src_cube)
    print("Found " .. #spider_moves .. " potential moves")
    
    local legal_moves = {}
    for _, dest_cube in ipairs(spider_moves) do
        if try_self_detach(map, src_cube, dest_cube) then
            local hex = get_hex(map, dest_cube)
            if hex then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return Spider
