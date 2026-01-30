local Piece = require("pieces.piece")
local map_module = require("map")
local movement_utils = require("pieces.movement_utils")

-- Grasshopper class
Grasshopper = setmetatable({}, {__index = Piece})
Grasshopper.__index = Grasshopper

function Grasshopper:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Grasshopper"
    instance.initials = "GH"
    instance.color = {0.2, 1, 0.2, 1}
    instance.id = 3
    instance.image_path = "img/grasshopper.png"
    return instance
end

function Grasshopper:try_to_move(map, src_cube, dest_cube)
    -- Grasshopper jumps in a straight line over one or more pieces
    -- Must land in first empty space after jumping
    
    -- Check if they're aligned along a cube axis
    if not cubecoords.is_aligned(cubecoords.subtract(dest_cube, src_cube)) then
        return false
    end
    
    -- Get unit direction from source to destination
    local dir = cubecoords.direction(src_cube, dest_cube)
    local unit_dir = cubecoords.normalize_direction(dir)
    if not unit_dir then
        return false
    end
    
    -- Walk along the direction, must jump over at least one piece
    local current = cubecoords.add(src_cube, unit_dir)
    local jumped_pieces = 0
    
    -- Count pieces we're jumping over
    while true do
        local hex = map_module.get_hex(map, current)
        if not hex then
            return false -- Out of bounds before finding empty space
        end
        
        if hex.piece then
            jumped_pieces = jumped_pieces + 1
            current = cubecoords.add(current, unit_dir)
        else
            -- Found first empty space after jumping
            if jumped_pieces > 0 and cubecoords.equals(current, dest_cube) then
                return true
            else
                return false -- Either no pieces jumped or wrong destination
            end
        end
        
        -- Safety check to prevent infinite loop
        if jumped_pieces > 20 then
            return false
        end
    end
    
    return false
end

-- Helper function to get all legal moves for grasshopper
function Grasshopper:get_legal_moves(map, src_cube)
    local legal_moves = {}
    local directions = cubecoords.directions()
    
    print("Grasshopper get_legal_moves from [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "]")
    
    -- Check each of the 6 directions
    for i, dir in ipairs(directions) do
        print("  Direction " .. i .. ": [" .. dir.x .. "," .. dir.y .. "," .. dir.z .. "]")
        local current = cubecoords.add(src_cube, dir)
        local jumped_pieces = 0
        
        -- Walk in this direction
        while true do
            local hex = map_module.get_hex(map, current)
            if not hex then
                print("    Out of bounds at [" .. current.x .. "," .. current.y .. "," .. current.z .. "]")
                break -- Out of bounds
            end
            
            if hex.piece then
                -- Jumping over a piece
                jumped_pieces = jumped_pieces + 1
                print("    Jumped over piece #" .. jumped_pieces .. " at [" .. current.x .. "," .. current.y .. "," .. current.z .. "]")
                current = cubecoords.add(current, dir)
            else
                -- Found empty space - this is a valid landing spot if we jumped at least 1 piece
                if jumped_pieces > 0 then
                    print("    LEGAL MOVE: [" .. current.x .. "," .. current.y .. "," .. current.z .. "] after jumping " .. jumped_pieces .. " pieces")
                    table.insert(legal_moves, current)
                else
                    print("    Empty space at [" .. current.x .. "," .. current.y .. "," .. current.z .. "] but no pieces jumped")
                end
                break -- Only the first empty space in this direction is valid
            end
            
            -- Safety check
            if jumped_pieces > 20 then
                print("    Safety limit reached!")
                break
            end
        end
    end
    
    print("  Total legal moves found: " .. #legal_moves)
    return legal_moves
end

function Grasshopper:move_piece(map, src_cube, dest_cube, active_player_id)
    -- Use standard movement from movement_utils
    return movement_utils.simple_move_piece(map, src_cube, dest_cube)
end

function Grasshopper:mark_legal_moves(map, src_cube)
    print("Testing Grasshopper moves - checking 6 directions")
    
    local grasshopper_moves = self:get_legal_moves(map, src_cube)
    print("Found " .. #grasshopper_moves .. " potential moves")
    
    local legal_moves = {}
    for _, dest_cube in ipairs(grasshopper_moves) do
        if map_module.pieceCanDetach(map, src_cube) and map_module.try_self_detach(map, src_cube, dest_cube) then
            local hex = map_module.get_hex(map, dest_cube)
            if hex then
                table.insert(legal_moves, hex)
            end
        end
    end
    
    print("Total legal moves: " .. #legal_moves)
    return {normal_moves = legal_moves, special_targets = {}}
end

return Grasshopper