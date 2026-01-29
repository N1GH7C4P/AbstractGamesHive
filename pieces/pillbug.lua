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
        local hex = get_hex(map, neighbor_cube)
        if hex and not hex.piece then
            -- Check if this is a legal normal move
            if self:try_to_move(map, src_cube, neighbor_cube) then
                table.insert(moves, neighbor_cube)
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
    local pillbug_hex = get_hex(map, src_cube)
    if not pillbug_hex or not pillbug_hex.piece or pillbug_hex.piece.under_piece then
        print("  Pillbug is covered or doesn't exist")
        return pickable
    end
    
    -- Check all adjacent hexes for pieces that can be picked up
    local neighbors = cubecoords.all_neighbors(src_cube)
    for _, neighbor_cube in ipairs(neighbors) do
        local hex = get_hex(map, neighbor_cube)
        if hex and hex.piece and not hex.piece.under_piece then
            print("  Checking piece at [" .. neighbor_cube.x .. "," .. neighbor_cube.y .. "," .. neighbor_cube.z .. "]: " .. hex.piece.name)
            
            -- Check if the piece moved last turn - cannot be moved by Pillbug
            if hex.piece.has_moved_last_turn then
                print("    SKIPPED: Piece moved last turn, cannot be picked")
            else
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
                    -- Use height-based gate rule since piece will be at height 1
                    hex.piece = nil
                    hex.player_id = nil
                    local can_move = self:can_move_through_gap_at_height_1(map, neighbor_cube, src_cube)
                    hex.piece = tmp_piece
                    hex.player_id = tmp_player_id
                    
                    print("    Can pick: " .. tostring(can_pick) .. ", can_move_through_gap_at_height_1: " .. tostring(can_move))
                    if can_move then
                        table.insert(pickable, neighbor_cube)
                        print("    PICKABLE!")
                    end
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
    local cn1_hex = get_hex(map, common_neighbors[1])
    local cn2_hex = get_hex(map, common_neighbors[2])
    
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

-- Check if piece can move through gap when at height 1 (Pillbug special ability)
-- Uses beetle gate rule: both neighbors must be height 2+ to block
function Pillbug:can_move_through_gap_at_height_1(map, from_cube, to_cube)
    print("  can_move_through_gap_at_height_1: from [" .. from_cube.x .. "," .. from_cube.y .. "," .. from_cube.z .. "] to [" .. to_cube.x .. "," .. to_cube.y .. "," .. to_cube.z .. "]")
    
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
    
    -- Get stack heights of the common neighbors
    local cn1_hex = get_hex(map, common_neighbors[1])
    local cn2_hex = get_hex(map, common_neighbors[2])
    
    if not cn1_hex or not cn2_hex then
        print("    FAIL: Common neighbor hex doesn't exist")
        return false
    end
    
    -- Calculate stack heights (similar to beetle gate rule)
    local function get_stack_height(hex)
        if not hex.piece then return 0 end
        local height = 1
        local current = hex.piece.under_piece
        while current do
            height = height + 1
            current = current.under_piece
        end
        return height
    end
    
    local height1 = get_stack_height(cn1_hex)
    local height2 = get_stack_height(cn2_hex)
    
    print("    Common neighbor 1 height: " .. height1)
    print("    Common neighbor 2 height: " .. height2)
    
    -- Piece is at height 1 (conceptually on top of Pillbug)
    -- Both neighbors must be height 2+ to block (beetle gate rule)
    if height1 >= 2 and height2 >= 2 then
        print("    FAIL: Both neighbors are height 2+, blocking movement (beetle gate)")
        return false
    end
    
    print("    SUCCESS: At least one neighbor is height < 2, can move through")
    return true
end

function Pillbug:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = get_hex(map, src_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then
        return false
    end
    
    -- Mark piece as moved this turn
    src_hex.piece.has_moved_last_turn = true
    
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
    local pillbug_hex = get_hex(map, pillbug_cube)
    if not pillbug_hex or not pillbug_hex.piece then
        return false
    end
    
    if pillbug_hex.piece.under_piece then
        return false  -- Pillbug is covered
    end
    
    -- Check if Pillbug moved in its last turn
    if pillbug_hex.piece.has_moved_last_turn then
        return false  -- Pillbug cannot use special ability if it moved last turn
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
    local target_hex = get_hex(map, target_cube)
    if not target_hex or not target_hex.piece then
        return false  -- No piece to move
    end
    
    -- Check if target piece is covered (stacked with 2+ pieces)
    if target_hex.piece.under_piece then
        return false  -- Target is covered, cannot move it
    end
    
    -- Check if target piece moved in the last turn
    if target_hex.piece.has_moved_last_turn then
        return false  -- Cannot move a piece that moved last turn
    end
    
    -- Check if destination is empty
    local dest_hex = get_hex(map, dest_cube)
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
    -- Piece is conceptually lifted to height 1, so use beetle gate rule
    target_hex.piece = nil
    target_hex.player_id = nil
    if not self:can_move_through_gap_at_height_1(map, target_cube, pillbug_cube) then
        target_hex.piece = tmp_piece
        target_hex.player_id = tmp_player_id
        return false  -- Cannot pick up through narrow gap
    end
    
    -- Check freedom to move for placing down (between Pillbug and destination)
    -- Piece is at height 1 on Pillbug, moving to destination
    if not self:can_move_through_gap_at_height_1(map, pillbug_cube, dest_cube) then
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
    
    local target_hex = get_hex(map, target_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    -- Mark target piece as moved (it physically moved to a new hex)
    target_hex.piece.has_moved_last_turn = true
    
    -- Move the piece
    dest_hex.piece = target_hex.piece
    dest_hex.player_id = target_hex.player_id
    target_hex.piece = nil
    target_hex.player_id = nil
    
    print("Pillbug moved piece from [" .. target_cube.x .. "," .. target_cube.y .. "," .. target_cube.z .. "] to [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
    
    return true
end

function Pillbug:mark_legal_moves(map, src_cube)
    print("Testing Pillbug moves - normal movement and special ability")
    
    local normal_move_hexes = {}
    local special_target_hexes = {}
    
    -- Get normal movement options (only if can detach)
    if pieceCanDetach(map, src_cube) then
        local pillbug_moves = self:get_legal_moves(map, src_cube)
        print("Found " .. #pillbug_moves .. " normal moves")
        
        for _, move_cube in ipairs(pillbug_moves) do
            local hex = get_hex(map, move_cube)
            if hex and try_self_detach(map, src_cube, move_cube) then
                table.insert(normal_move_hexes, hex)
            end
        end
    else
        print("Pillbug cannot detach - no normal moves available")
    end
    
    -- Get pickable pieces for special ability (always available)
    local pickable = self:get_pickable_pieces(map, src_cube)
    print("Found " .. #pickable .. " pickable pieces")
    
    for _, piece_cube in ipairs(pickable) do
        local hex = get_hex(map, piece_cube)
        if hex then
            table.insert(special_target_hexes, hex)
        end
    end
    
    print("Marked " .. #normal_move_hexes .. " normal moves and " .. #special_target_hexes .. " special targets")
    return {normal_moves = normal_move_hexes, special_targets = special_target_hexes}
end

-- Handle special ability click (phase 1: pick up target piece)
function Pillbug:handle_special_click(map, src_cube, target_cube, mouseX, mouseY)
    print("Pillbug special: Selected target piece at [" .. target_cube.x .. "," .. target_cube.y .. "," .. target_cube.z .. "]")
    
    -- Set global state for drop phase
    G.pillbug_special_mode = true
    G.pillbug_cube = src_cube
    G.pillbug_target_cube = target_cube
    
    -- Clear current highlights and show drop locations
    clear_all_neighbours(G.map, G.w, G.h)
    
    local drop_locations = self:get_drop_locations(map, src_cube, target_cube)
    print("Found " .. #drop_locations .. " drop locations")
    
    for _, dest_cube in ipairs(drop_locations) do
        local hex = get_hex(map, dest_cube)
        if hex then
            hex.can_drop = true
            print("  DROP LOCATION: [" .. dest_cube.x .. "," .. dest_cube.y .. "," .. dest_cube.z .. "]")
        end
    end
    
    return true
end

-- Execute drop phase of special ability
function Pillbug:execute_drop(map, src_cube, target_cube, drop_cube)
    return self:use_special_ability(map, src_cube, target_cube, drop_cube)
end

return Pillbug
