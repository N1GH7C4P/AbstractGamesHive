local Piece = require("pieces.piece")
local map_module = require("map")
local movement_utils = require("pieces.movement_utils")

-- Ladybug class
Ladybug = setmetatable({}, {__index = Piece})
Ladybug.__index = Ladybug

function Ladybug:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Ladybug"
    instance.initials = "LB"
    instance.color = {1, 0, 0, 1}  -- Red
    instance.id = 6
    instance.image_path = "img/ladybug.png"
    return instance
end

function Ladybug:try_to_move(map, src_cube, dest_cube)
    -- Ladybug moves exactly 3 spaces:
    -- Step 1: Climb onto an adjacent piece
    -- Step 2: Move onto another piece
    -- Step 3: Climb down to empty space adjacent to step 2 piece
    
    -- Find if there's a valid 3-step path
    local visited = {}
    visited[cubecoords.to_key(src_cube)] = true
    
    return self:find_path(map, src_cube, dest_cube, 0, visited)
end

-- Recursive pathfinding for exactly 3 steps with specific rules
function Ladybug:find_path(map, current_cube, dest_cube, steps, visited)
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
        local next_hex = map_module.get_hex(map, next_cube)
        local next_key = cubecoords.to_key(next_cube)
        
        if next_hex and not visited[next_key] then
            local valid = false
            
            if steps == 0 then
                -- Step 1: Must climb onto a piece
                valid = next_hex.piece ~= nil
            elseif steps == 1 then
                -- Step 2: Must move onto another piece
                valid = next_hex.piece ~= nil
            elseif steps == 2 then
                -- Step 3: Must climb down to empty space
                valid = not next_hex.piece
            end
            
            if valid then
                visited[next_key] = true
                if self:find_path(map, next_cube, dest_cube, steps + 1, visited) then
                    return true
                end
                visited[next_key] = nil
            end
        end
    end
    
    return false
end

-- Helper function to get all legal moves for ladybug
function Ladybug:get_legal_moves(map, src_cube)
    local legal_moves = {}
    local initial_visited = {}
    initial_visited[cubecoords.to_key(src_cube)] = true
    
    print("Ladybug:get_legal_moves starting from [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "]")
    
    -- Find all positions reachable in exactly 3 steps
    self:find_all_paths(map, src_cube, 0, initial_visited, legal_moves, {})
    
    print("Total destinations found: " .. #legal_moves)
    return legal_moves
end

-- Collect all destinations reachable in exactly 3 steps following ladybug rules
function Ladybug:find_all_paths(map, current_cube, steps, visited, destinations, path)
    -- Add current position to path
    local current_path = {}
    for i, cube in ipairs(path) do
        current_path[i] = cube
    end
    table.insert(current_path, {x = current_cube.x, y = current_cube.y, z = current_cube.z})
    
    -- If we've taken 3 steps, this is a valid destination
    if steps == 3 then
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
        local next_hex = map_module.get_hex(map, next_cube)
        local next_key = cubecoords.to_key(next_cube)
        
        if next_hex and not visited[next_key] then
            local valid = false
            
            if steps == 0 then
                -- Step 1: Must climb onto a piece
                valid = next_hex.piece ~= nil
            elseif steps == 1 then
                -- Step 2: Must move onto another piece
                valid = next_hex.piece ~= nil
            elseif steps == 2 then
                -- Step 3: Must climb down to empty space
                valid = not next_hex.piece
            end
            
            if valid then
                visited[next_key] = true
                self:find_all_paths(map, next_cube, steps + 1, visited, destinations, current_path)
                visited[next_key] = nil
            end
        end
    end
end

function Ladybug:mark_legal_moves(map, src_cube)
    print("Testing Ladybug moves - exactly 3 steps (2 on top, 1 down)")
    
    if not map_module.pieceCanDetach(map, src_cube) then
        print("Ladybug cannot detach - would break hive")
        return {normal_moves = {}, special_targets = {}}
    end
    
    local ladybug_moves = self:get_legal_moves(map, src_cube)
    print("Found " .. #ladybug_moves .. " potential moves")
    
    local legal_moves = {}
    for _, dest_cube in ipairs(ladybug_moves) do
        if map_module.try_self_detach(map, src_cube, dest_cube) then
            local hex = map_module.get_hex(map, dest_cube)
            if hex then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return Ladybug
