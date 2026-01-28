local Piece = require("pieces.piece")
local Pillbug = require("pieces.pillbug")

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
    local src_hex = map_get_hex(map, src_cube)
    if src_hex and src_hex.piece and src_hex.piece.under_piece then
        -- On top of hive - can only move as Beetle
        local beetle = Beetle:new(self.owner)
        return beetle:try_to_move(map, src_cube, dest_cube)
    end
    
    -- Get adjacent piece types (excluding other mosquitos)
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    
    -- Check if destination has a piece (stacking attempt)
    local dest_hex = map_get_hex(map, dest_cube)
    local is_stacking = dest_hex and dest_hex.piece
    
    -- If trying to stack, must have a Beetle adjacent
    if is_stacking and not adjacent_types[2] then
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
        local neighbor_hex = map_get_hex(map, neighbor_cube)
        if neighbor_hex and neighbor_hex.piece then
            local piece_id = neighbor_hex.piece.id
            -- Ignore other mosquitos (id 7)
            if piece_id ~= 7 then
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
        local neighbor_hex = map_get_hex(map, neighbor_cube)
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
    local src_hex = map_get_hex(map, src_cube)
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
    local names = {
        [1] = "Queen Bee",
        [2] = "Beetle",
        [3] = "Grasshopper",
        [4] = "Spider",
        [5] = "Soldier Ant",
        [6] = "Ladybug"
    }
    return names[piece_id] or "Unknown"
end

function Mosquito:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    -- Check if mimicking beetle and moving onto a piece
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    local can_stack = adjacent_types[2]  -- Has beetle adjacent
    
    -- If mosquito is already on top or can act as beetle and destination has piece
    if (src_hex.piece.under_piece or can_stack) and dest_hex.piece then
        -- Use beetle stacking logic
        local tempPiece = dest_hex.piece
        tempPiece.player_id = dest_hex.player_id
        dest_hex.piece = src_hex.piece
        dest_hex.player_id = active_player_id
        
        -- Handle source piece
        if src_hex.piece.under_piece then
            local underpiece = src_hex.piece.under_piece
            src_hex.piece.under_piece = nil
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
        -- Normal move
        dest_hex.piece = src_hex.piece
        dest_hex.player_id = src_hex.player_id
        src_hex.piece = nil
        src_hex.player_id = nil
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
    local pillbug = Pillbug:new(self.owner)
    return pillbug:use_special_ability(map, src_cube, target_cube, dest_cube)
end

function Mosquito:mark_legal_moves(map, src_cube)
    print("Testing Mosquito moves - mimics adjacent pieces")
    
    local src_hex = map_get_hex(map, src_cube)
    
    -- Check which powers are available
    local adjacent_types = self:get_adjacent_piece_types(map, src_cube)
    local has_pillbug = adjacent_types[8] == true  -- Check if Pillbug (id=8) is in the table
    local has_beetle = adjacent_types[2] == true   -- Check if Beetle (id=2) is in the table
    print("Mosquito adjacent piece types: has Pillbug: " .. tostring(has_pillbug) .. ", has Beetle: " .. tostring(has_beetle))
    
    local normal_move_hexes = {}
    local special_target_hexes = {}
    
    -- Check if piece can detach for normal movement (unless it's on top of the hive)
    local can_detach = src_hex.piece.under_piece or pieceCanDetach(map, src_cube)
    
    if can_detach then
        -- Get normal movement options
        local mosquito_moves = self:get_legal_moves(map, src_cube)
        print("Found " .. #mosquito_moves .. " potential normal moves")
        
        for _, dest_cube in ipairs(mosquito_moves) do
            if try_self_detach(map, src_cube, dest_cube) then
                local hex = map_get_hex(map, dest_cube)
                if hex then
                    -- Check if this destination is stacking (beetle power)
                    local dest_hex = map_get_hex(map, dest_cube)
                    if dest_hex.piece and has_beetle then
                        hex.is_beetle_move = true
                    end
                    table.insert(normal_move_hexes, hex)
                end
            end
        end
    else
        print("Mosquito cannot detach - no normal moves available")
    end
    
    -- If adjacent to Pillbug, also show special ability
    if has_pillbug and self.get_pickable_pieces_as_pillbug then
        print("Mosquito can mimic Pillbug special ability")
        local pickable = self:get_pickable_pieces_as_pillbug(map, src_cube)
        print("Found " .. #pickable .. " pickable pieces")
        
        for _, piece_cube in ipairs(pickable) do
            local hex = map_get_hex(map, piece_cube)
            if hex then
                -- Check if this piece can also be climbed with beetle power
                if has_beetle and hex.piece and not hex.piece.under_piece then
                    -- This hex has dual options
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

return Mosquito
