local Piece = require("pieces.piece")

-- Grasshopper class
Grasshopper = setmetatable({}, {__index = Piece})
Grasshopper.__index = Grasshopper

function Grasshopper:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Grasshopper"
    instance.initials = "GH"
    instance.color = {0.2, 1, 0.2, 1}
    instance.id = 3
    return instance
end

function Grasshopper:try_to_move(map, src_cube, dest_cube)
    -- Grasshopper jumps in a straight line over one or more pieces
    -- Must land in first empty space after jumping
    
    -- Get direction from source to destination
    local dir = cubecoords.direction(src_cube, dest_cube)
    
    -- Check if direction is aligned with hex grid axes
    if not cubecoords.is_aligned(dir) then
        return false
    end
    
    -- Normalize the direction
    local unit_dir = cubecoords.normalize_direction(dir)
    if not unit_dir then
        return false
    end
    
    -- Walk along the direction, counting pieces jumped
    local current = src_cube
    local jumped_count = 0
    local found_empty = false
    
    for i = 1, 20 do  -- Max distance check
        current = cubecoords.add(current, unit_dir)
        local hex = map_get_hex(map, current)
        
        if not hex then
            -- Out of bounds
            break
        end
        
        if hex.piece then
            -- Jumping over a piece
            jumped_count = jumped_count + 1
        else
            -- Found empty space - this is where grasshopper must land
            if cubecoords.equals(current, dest_cube) and jumped_count > 0 then
                -- Destination must be adjacent to at least one piece (to maintain hive)
                local neighbors = cubecoords.all_neighbors(dest_cube)
                for _, ncube in ipairs(neighbors) do
                    local nhex = map_get_hex(map, ncube)
                    if nhex and nhex.piece and not cubecoords.equals(ncube, src_cube) then
                        return true
                    end
                end
                return false
            else
                -- Hit empty space but it's not our destination
                return false
            end
        end
    end
    
    return false
end

function Grasshopper:move_piece(map, src_cube, dest_cube, active_player_id)
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id
    src_hex.piece = nil
    src_hex.player_id = nil
    return true
end

return Grasshopper
