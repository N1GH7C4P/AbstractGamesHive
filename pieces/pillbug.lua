local Piece = require("pieces.piece")

-- Pillbug class
Pillbug = setmetatable({}, {__index = Piece})
Pillbug.__index = Pillbug

function Pillbug:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Pillbug"
    instance.initials = "PB"
    instance.color = {0, 1, 1, 1}  -- Cyan
    instance.id = 8
    instance.image_path = "img/pillbug.png"
    return instance
end

function Pillbug:try_to_move(map, src_cube, dest_cube)
    -- Pillbug moves like a Queen Bee - one space at a time
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

-- Get legal moves including both normal movement and pieces that can be picked up
function Pillbug:get_legal_moves(map, src_cube)
    local moves = {}
    
    -- Add normal movement hexes (empty adjacent hexes)
    local neighbors = cubecoords.all_neighbors(src_cube)
    for _, neighbor_cube in ipairs(neighbors) do
        local hex = map_get_hex(map, neighbor_cube)
        if hex and not hex.piece then
            -- Check if this is a legal normal move
            if self:try_to_move(map, src_cube, neighbor_cube) then
                table.insert(moves, {cube = neighbor_cube, type = "move"})
            end
        end
    end
    
    return moves
end

-- Get pieces that can be picked up by Pillbug special ability
function Pillbug:get_pickable_pieces(map, src_cube)
    local pickable = {}
    
    print("Pillbug at [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "] checking pickable pieces")
    
    -- Check if Pillbug is covered
    local pillbug_hex = map_get_hex(map, src_cube)
    if not pillbug_hex or not pillbug_hex.piece or pillbug_hex.piece.under_piece then
        print("  Pillbug is covered or doesn't exist")
        return pickable
    end
    
    -- Check all adjacent hexes for pieces that can be picked up
    local neighbors = cubecoords.all_neighbors(src_cube)
    for _, neighbor_cube in ipairs(neighbors) do
        local hex = map_get_hex(map, neighbor_cube)
        if hex and hex.piece and not hex.piece.under_piece then
            print("  Checking piece at [" .. neighbor_cube.x .. "," .. neighbor_cube.y .. "," .. neighbor_cube.z .. "]: " .. hex.piece.name)
            
            -- Check if picking up this piece would break the hive
            local tmp_piece = hex.piece
            local tmp_player_id = hex.player_id
            hex.piece = nil
            hex.player_id = nil
            
            clear_all_neighbours(map, map.w, map.h)
            local first_cube = firstPieceCoords(map)
            local can_pick = true
            
            if first_cube then
                flood_neighbours(map, first_cube)
                
                for _, check_hex in pairs(map.hexes) do
                    if check_hex.piece and not check_hex.neighbour then
                        can_pick = false
                        print("    Would break hive - disconnected piece at [" .. check_hex.cube.x .. "," .. check_hex.cube.y .. "," .. check_hex.cube.z .. "]")
                        break
                    end
                end
            end
            
            hex.piece = tmp_piece
            hex.player_id = tmp_player_id
            clear_all_neighbours(map, map.w, map.h)
            
            if can_pick then
                -- Check freedom to move while target is temporarily removed
                hex.piece = nil
                hex.player_id = nil
                local can_move = self:can_move_through_gap(map, neighbor_cube, src_cube)
                hex.piece = tmp_piece
                hex.player_id = tmp_player_id
                
                print("    Can pick: " .. tostring(can_pick) .. ", can_move_through_gap: " .. tostring(can_move))
                if can_move then
                    table.insert(pickable, neighbor_cube)
                    print("    PICKABLE!")
                end
            end
        end
    end
    
    return pickable
end

-- Get valid destinations for a picked up piece
function Pillbug:get_drop_locations(map, pillbug_cube, target_cube)
    local locations = {}
    
    -- Check all hexes adjacent to Pillbug
    local neighbors = cubecoords.all_neighbors(pillbug_cube)
    for _, neighbor_cube in ipairs(neighbors) do
        if not cubecoords.equals(neighbor_cube, target_cube) then
            if self:can_use_special_ability(map, pillbug_cube, target_cube, neighbor_cube) then
                table.insert(locations, neighbor_cube)
            end
        end
    end
    
    return locations
end

-- Check if a move through a gap is allowed (freedom to move)
function Pillbug:can_move_through_gap(map, from_cube, to_cube)
    print("  can_move_through_gap: from [" .. from_cube.x .. "," .. from_cube.y .. "," .. from_cube.z .. "] to [" .. to_cube.x .. "," .. to_cube.y .. "," .. to_cube.z .. "]")
    
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
    
    print("    Found " .. #common_neighbors .. " common neighbors")
    
    -- For adjacent hexes, there should be exactly 2 common neighbors
    if #common_neighbors ~= 2 then
        print("    FAIL: Should have exactly 2 common neighbors, has " .. #common_neighbors)
        return false
    end
    
    -- Check if both common neighbors are occupied (gate blocking)
    local cn1_hex = map_get_hex(map, common_neighbors[1])
    local cn2_hex = map_get_hex(map, common_neighbors[2])
    
    if not cn1_hex or not cn2_hex then
        print("    FAIL: Common neighbor hex doesn't exist")
        return false
    end
    
    local cn1_occupied = cn1_hex.piece ~= nil
    local cn2_occupied = cn2_hex.piece ~= nil
    print("    Common neighbor 1 [" .. common_neighbors[1].x .. "," .. common_neighbors[1].y .. "," .. common_neighbors[1].z .. "]: " .. (cn1_occupied and "OCCUPIED" or "empty"))
    print("    Common neighbor 2 [" .. common_neighbors[2].x .. "," .. common_neighbors[2].y .. "," .. common_neighbors[2].z .. "]: " .. (cn2_occupied and "OCCUPIED" or "empty"))
    
    -- If both neighbors are occupied, the gap is blocked (gate blocking)
    if cn1_hex.piece and cn2_hex.piece then
        print("    FAIL: Both neighbors occupied (gate blocking)")
        return false
    end
    
    -- If at least one neighbor is empty, the piece can move through
    print("    SUCCESS: At least one neighbor empty, can move through gap")
    return true
end

function Pillbug:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then
        return false
    end
    
    -- Move the piece
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    
    return true
end

-- Special ability: Move an adjacent piece to another hex adjacent to the Pillbug
function Pillbug:can_use_special_ability(map, pillbug_cube, target_cube, dest_cube)
    -- Check if Pillbug is not covered
    local pillbug_hex = map_get_hex(map, pillbug_cube)
    if not pillbug_hex or not pillbug_hex.piece then
        return false
    end
    
    if pillbug_hex.piece.under_piece then
        return false  -- Pillbug is covered
    end
    
    -- Check if target is adjacent to Pillbug
    local distance_to_target = cubecoords.distance(pillbug_cube, target_cube)
    if distance_to_target ~= 1 then
        return false  -- Target not adjacent
    end
    
    -- Check if destination is adjacent to Pillbug
    local distance_to_dest = cubecoords.distance(pillbug_cube, dest_cube)
    if distance_to_dest ~= 1 then
        return false  -- Destination not adjacent to Pillbug
    end
    
    -- Check if target hex has a piece
    local target_hex = map_get_hex(map, target_cube)
    if not target_hex or not target_hex.piece then
        return false  -- No piece to move
    end
    
    -- Check if target piece is covered (stacked with 2+ pieces)
    if target_hex.piece.under_piece then
        return false  -- Target is covered, cannot move it
    end
    
    -- Check if destination is empty
    local dest_hex = map_get_hex(map, dest_cube)
    if not dest_hex or dest_hex.piece then
        return false  -- Destination not empty
    end
    
    -- Check if moving the target would break the hive (step 1: lifting)
    local tmp_piece = target_hex.piece
    local tmp_player_id = target_hex.player_id
    target_hex.piece = nil
    target_hex.player_id = nil
    
    -- Check hive connectivity after removing target
    clear_all_neighbours(map, map.w, map.h)
    local first_cube = firstPieceCoords(map)
    
    if not first_cube then
        -- If no pieces left, restore and allow
        target_hex.piece = tmp_piece
        target_hex.player_id = tmp_player_id
        return true
    end
    
    flood_neighbours(map, first_cube)
    
    -- Check if any piece is disconnected
    local hive_connected = true
    for _, check_hex in pairs(map.hexes) do
        if check_hex.piece and not check_hex.neighbour then
            hive_connected = false
            break
        end
    end
    
    -- Restore the piece
    target_hex.piece = tmp_piece
    target_hex.player_id = tmp_player_id
    clear_all_neighbours(map, map.w, map.h)
    
    if not hive_connected then
        return false  -- Would break hive in step 1
    end
    
    -- Check freedom to move for picking up (between target and Pillbug)
    -- Temporarily remove target to check the gap properly
    target_hex.piece = nil
    target_hex.player_id = nil
    if not self:can_move_through_gap(map, target_cube, pillbug_cube) then
        target_hex.piece = tmp_piece
        target_hex.player_id = tmp_player_id
        return false  -- Cannot pick up through narrow gap
    end
    
    -- Check freedom to move for placing down (between Pillbug and destination)
    if not self:can_move_through_gap(map, pillbug_cube, dest_cube) then
        target_hex.piece = tmp_piece
        target_hex.player_id = tmp_player_id
        return false  -- Cannot place through narrow gap
    end
    
    -- Restore the piece
    target_hex.piece = tmp_piece
    target_hex.player_id = tmp_player_id
    
    return true
end

-- Execute the special ability
function Pillbug:use_special_ability(map, pillbug_cube, target_cube, dest_cube)
    if not self:can_use_special_ability(map, pillbug_cube, target_cube, dest_cube) then
        return false
    end
    
    local target_hex = map_get_hex(map, target_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    -- Move the piece
    dest_hex.piece = target_hex.piece
    dest_hex.player_id = target_hex.player_id
    target_hex.piece = nil
    target_hex.player_id = nil
    
    print("Pillbug moved piece from [" .. target_cube.x .. "," .. target_cube.y .. "," .. target_cube.z .. "] to [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
    
    return true
end

return Pillbug
