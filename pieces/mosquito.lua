local Piece = require("pieces.piece")
local Pillbug = require("pieces.pillbug")
local PiecesEnum = require("pieces.pieces_enum")

-- Mosquito class - mimics adjacent pieces
Mosquito = setmetatable({}, {__index = Piece})
Mosquito.__index = Mosquito

function Mosquito:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Mosquito"
    instance.initials = "Mo"
    instance.color = {0.5, 0.5, 0.5, 1}  -- Gray
    instance.id = 7
    instance.image_path = "img/mosquito.png"
    return instance
end

function Mosquito:try_to_move(map, src_cube, dest_cube)
    -- Check if mosquito is on top of the hive
    local src_hex = get_hex(map, src_cube)
    if src_hex and src_hex.piece and src_hex.piece.under_piece then
        -- On top of hive - can only move as Beetle
        local beetle = Beetle:new(self.owner)
        return beetle:try_to_move(map, src_cube, dest_cube)
    end
    
    -- Get adjacent piece types (excluding other mosquitos)
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    
    -- Check if destination has a piece (stacking attempt)
    local dest_hex = get_hex(map, dest_cube)
    local is_stacking = dest_hex and dest_hex.piece
    
    -- If trying to stack, must have a Beetle adjacent
    if is_stacking and not adjacent_types[PiecesEnum.BEETLE] then
        return false
    end
    
    -- Try to move using any of the adjacent piece types
    for piece_type, _ in pairs(adjacent_types) do
        local mimicked_piece = self:duplicate_adjacent_piece(map, src_cube, piece_type)
        if mimicked_piece and mimicked_piece.try_to_move then
            if mimicked_piece:try_to_move(map, src_cube, dest_cube) then
                return true
            end
        end
    end
    
    return false
end

-- Get all unique piece types adjacent to the mosquito (excluding other mosquitos)
function Mosquito:get_adjacent_piece_types(map, cube)
    local types = {}
    local neighbors = cubecoords.all_neighbors(cube)
    
    for _, neighbor_cube in ipairs(neighbors) do
        local neighbor_hex = get_hex(map, neighbor_cube)
        if neighbor_hex and neighbor_hex.piece then
            local piece_id = neighbor_hex.piece.id
            -- Ignore other mosquitos
            if piece_id ~= PiecesEnum.MOSQUITO then
                types[piece_id] = true
            end
        end
    end
    
    return types
end

-- Duplicate an adjacent piece for mimicking (with mosquito's owner)
function Mosquito:duplicate_adjacent_piece(map, cube, piece_id)
    -- Find an adjacent piece with this ID
    local neighbors = cubecoords.all_neighbors(cube)
    for _, neighbor_cube in ipairs(neighbors) do
        local neighbor_hex = get_hex(map, neighbor_cube)
        if neighbor_hex and neighbor_hex.piece and neighbor_hex.piece.id == piece_id then
            -- Duplicate the piece with mosquito's owner
            return neighbor_hex.piece:duplicate(self.owner)
        end
    end
    return nil
end

-- Get all legal moves by combining moves from all adjacent piece types
function Mosquito:get_legal_moves(map, src_cube)
    print("Mosquito:get_legal_moves starting from [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "]")
    
    -- Check if on top of the hive
    local src_hex = get_hex(map, src_cube)
    if src_hex and src_hex.piece and src_hex.piece.under_piece then
        print("  Mosquito is on top of hive - using Beetle movement only")
        local beetle = Beetle:new(self.owner)
        return beetle:get_legal_moves(map, src_cube)
    end
    
    local all_moves = {}
    local move_set = {}  -- To avoid duplicates
    
    -- Get adjacent piece types
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    
    print("  Adjacent piece types: ")
    for piece_id, _ in pairs(adjacent_types) do
        local piece_name = self:get_piece_name(piece_id)
        print("    - " .. piece_name .. " (id: " .. piece_id .. ")")
    end
    
    -- Collect moves from each adjacent piece type
    for piece_id, _ in pairs(adjacent_types) do
        local mimicked_piece = self:duplicate_adjacent_piece(map, src_cube, piece_id)
        if mimicked_piece then
            print("  Checking moves as " .. mimicked_piece.name)
            local moves = mimicked_piece:get_legal_moves(map, src_cube)
            
            for _, move_cube in ipairs(moves) do
                local key = cubecoords.to_key(move_cube)
                if not move_set[key] then
                    move_set[key] = true
                    table.insert(all_moves, move_cube)
                end
            end
        end
    end
    
    print("Total unique destinations found: " .. #all_moves)
    return all_moves
end

-- Helper to get piece name by ID
function Mosquito:get_piece_name(piece_id)
    return PiecesEnum.ID_TO_NAME[piece_id] or "Unknown"
end

function Mosquito:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = get_hex(map, src_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    -- Mark piece as moved this turn
    src_hex.piece.has_moved_last_turn = true
    
    -- Check if mimicking beetle and moving onto a piece
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    local can_stack = adjacent_types[PiecesEnum.BEETLE]  -- Has beetle adjacent
    
    -- If mosquito is already on top or can act as beetle and destination has piece
    if (src_hex.piece.under_piece or can_stack) and dest_hex.piece then
        -- Use beetle stacking logic
        local tempPiece = dest_hex.piece
        tempPiece.player_id = dest_hex.player_id
        dest_hex.piece = src_hex.piece
        dest_hex.player_id = src_hex.piece.owner
        
        -- Handle source piece - restore under_piece to source if it exists
        if src_hex.piece.under_piece then
            local underpiece = src_hex.piece.under_piece
            src_hex.piece.under_piece = nil  -- Clear the link before moving
            src_hex.player_id = underpiece.player_id
            src_hex.piece = underpiece
        else
            src_hex.piece = nil
            src_hex.player_id = nil
        end
        
        -- Stack on destination
        dest_hex.piece.under_piece = tempPiece
        dest_hex.piece.under_piece.player_id = tempPiece.player_id
        
        return true
    else
        -- Normal move - move mosquito without its under_piece
        dest_hex.piece = src_hex.piece
        dest_hex.player_id = src_hex.piece.owner
        
        -- Handle source hex
        if src_hex.piece.under_piece then
            -- Mosquito was on top - restore the under_piece and clear the link
            local underpiece = src_hex.piece.under_piece
            dest_hex.piece.under_piece = nil  -- Clear mosquito's under_piece link
            src_hex.piece = underpiece
            src_hex.player_id = underpiece.player_id
        else
            -- Mosquito was on ground
            src_hex.piece = nil
            src_hex.player_id = nil
        end
        
        return true
    end
end

-- Mosquito can use Pillbug's special ability if adjacent to a Pillbug
function Mosquito:get_pickable_pieces_as_pillbug(map, src_cube)
    local pillbug = Pillbug:new(self.owner)
    return pillbug:get_pickable_pieces(map, src_cube)
end

function Mosquito:get_drop_locations_as_pillbug(map, src_cube, target_cube)
    local pillbug = Pillbug:new(self.owner)
    return pillbug:get_drop_locations(map, src_cube, target_cube)
end

function Mosquito:use_special_ability_as_pillbug(map, src_cube, target_cube, dest_cube)
    -- Check if mosquito moved last turn (same restriction as pillbug)
    local mosquito_hex = get_hex(map, src_cube)
    if mosquito_hex and mosquito_hex.piece and mosquito_hex.piece.has_moved_last_turn then
        return false
    end
    
    local pillbug = Pillbug:new(self.owner)
    -- Pillbug's use_special_ability will mark the target piece as moved
    -- The mosquito itself doesn't physically move, so don't mark it
    return pillbug:use_special_ability(map, src_cube, target_cube, dest_cube)
end

function Mosquito:mark_legal_moves(map, src_cube)
    print("Testing Mosquito moves - mimics adjacent pieces")
    
    local src_hex = get_hex(map, src_cube)
    
    -- Check which powers are available
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    local has_pillbug = adjacent_types[PiecesEnum.PILLBUG] == true
    local has_beetle = adjacent_types[PiecesEnum.BEETLE] == true
    print("Mosquito adjacent piece types: has Pillbug: " .. tostring(has_pillbug) .. ", has Beetle: " .. tostring(has_beetle))
    
    local normal_move_hexes = {}
    local special_target_hexes = {}
    local beetle_climb_hexes = {}  -- Track beetle climbs
    
    -- Check if piece can detach for normal movement (unless it's on top of the hive)
    local can_detach = src_hex.piece.under_piece or pieceCanDetach(map, src_cube)
    
    if can_detach then
        -- Get normal movement options
        local mosquito_moves = self:get_legal_moves(map, src_cube)
        print("Found " .. #mosquito_moves .. " potential normal moves")
        
        for _, dest_cube in ipairs(mosquito_moves) do
            if try_self_detach(map, src_cube, dest_cube) then
                local hex = get_hex(map, dest_cube)
                if hex then
                    table.insert(normal_move_hexes, hex)
                    -- Track if this destination is stacking (beetle power)
                    local dest_hex = get_hex(map, dest_cube)
                    if dest_hex.piece and has_beetle then
                        table.insert(beetle_climb_hexes, hex)
                    end
                end
            end
        end
    else
        print("Mosquito cannot detach - no normal moves available")
    end
    
    -- Mark beetle climb moves AFTER validation loop
    for _, hex in ipairs(beetle_climb_hexes) do
        hex.is_beetle_move = true
    end
    
    -- If adjacent to Pillbug, also show special ability
    if has_pillbug and self.get_pickable_pieces_as_pillbug then
        print("Mosquito can mimic Pillbug special ability")
        local pickable = self:get_pickable_pieces_as_pillbug(map, src_cube)
        print("Found " .. #pickable .. " pickable pieces")
        
        for _, piece_cube in ipairs(pickable) do
            local hex = get_hex(map, piece_cube)
            if hex then
                -- Check if this piece can also be climbed with beetle power
                -- Must verify it's actually in the beetle climb list (legal move)
                local is_beetle_climbable = false
                if has_beetle and hex.piece and not hex.piece.under_piece then
                    -- Check if this hex is in the beetle climb hexes list
                    for _, climb_hex in ipairs(beetle_climb_hexes) do
                        if climb_hex == hex then
                            is_beetle_climbable = true
                            break
                        end
                    end
                end
                
                if is_beetle_climbable then
                    hex.has_dual_option = true
                    print("  Hex at [" .. piece_cube.x .. "," .. piece_cube.y .. "," .. piece_cube.z .. "] has dual options")
                end
                table.insert(special_target_hexes, hex)
            end
        end
    end
    
    print("Marked " .. #normal_move_hexes .. " normal moves and " .. #special_target_hexes .. " special targets")
    return {normal_moves = normal_move_hexes, special_targets = special_target_hexes}
end

-- Handle special ability click (mimicking pillbug)
function Mosquito:handle_special_click(map, src_cube, target_cube, mouseX, mouseY)
    local target_hex = get_hex(map, target_cube)
    
    -- Check if we have dual options (beetle climb AND pillbug special)
    if target_hex and target_hex.has_dual_option then
        print("Mosquito has dual options - showing popup")
        G.mosquito_choice_popup = true
        G.mosquito_choice_dest = target_cube
        G.mosquito_popup_x = mouseX
        G.mosquito_popup_y = mouseY
        return true
    end
    
    -- Otherwise handle like pillbug
    print("Mosquito using Pillbug power: Selected target piece at [" .. target_cube.x .. "," .. target_cube.y .. "," .. target_cube.z .. "]")
    
    G.pillbug_special_mode = true
    G.pillbug_cube = src_cube
    G.pillbug_target_cube = target_cube
    
    -- Clear current highlights and show drop locations
    clear_all_neighbours(G.map, G.w, G.h)
    
    local drop_locations = self:get_drop_locations_as_pillbug(map, src_cube, target_cube)
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

-- Execute drop phase of special ability (mimicking pillbug)
function Mosquito:execute_drop(map, src_cube, target_cube, drop_cube)
    return self:use_special_ability_as_pillbug(map, src_cube, target_cube, drop_cube)
end

return Mosquito
