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

function Grasshopper:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    -- Grasshopper jumps over pieces in a straight line
    -- It must jump in the direction of one of its faces (6 directions)
    -- and lands in the first empty space after jumping over one or more pieces
    
    -- Get the 6 possible hexagonal directions from source
    local directions = {}
    if src_x % 2 == 0 then
        -- Even column neighbors: (0,-1), (1,-1), (-1,0), (1,0), (0,1), (1,1)
        directions = {
            {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {0, 1}, {1, 1}
        }
    else
        -- Odd column neighbors: (-1,-1), (0,-1), (-1,0), (1,0), (-1,1), (0,1)
        directions = {
            {-1, -1}, {0, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}
        }
    end
    
    -- Check each direction to see if destination is in that straight line
    for _, dir in ipairs(directions) do
        local dx, dy = dir[1], dir[2]
        local current_x, current_y = src_x, src_y
        local jumped_pieces = 0
        
        -- Move in this direction until we reach the destination or run out of bounds
        while true do
            -- Calculate next position in this direction
            -- Need to handle hex grid direction properly
            local next_x = current_x + dx
            local next_y = current_y + dy
            
            -- Adjust for hex grid alternating columns
            if current_x % 2 == 0 then
                -- Coming from even column
                if dx == 1 and dy == -1 then next_x, next_y = current_x + 1, current_y - 1
                elseif dx == 0 and dy == -1 then next_x, next_y = current_x, current_y - 1
                elseif dx == -1 and dy == 0 then next_x, next_y = current_x - 1, current_y
                elseif dx == 1 and dy == 0 then next_x, next_y = current_x + 1, current_y
                elseif dx == 0 and dy == 1 then next_x, next_y = current_x, current_y + 1
                elseif dx == 1 and dy == 1 then next_x, next_y = current_x + 1, current_y + 1
                end
            else
                -- Coming from odd column
                if dx == -1 and dy == -1 then next_x, next_y = current_x - 1, current_y - 1
                elseif dx == 0 and dy == -1 then next_x, next_y = current_x, current_y - 1
                elseif dx == -1 and dy == 0 then next_x, next_y = current_x - 1, current_y
                elseif dx == 1 and dy == 0 then next_x, next_y = current_x + 1, current_y
                elseif dx == -1 and dy == 1 then next_x, next_y = current_x - 1, current_y + 1
                elseif dx == 0 and dy == 1 then next_x, next_y = current_x, current_y + 1
                end
            end
            
            -- Check bounds
            if next_x < 1 or next_x > w or next_y < 1 or next_y > h then
                break
            end
            
            -- If there's a piece here, we're jumping over it
            if map[next_y][next_x].piece then
                jumped_pieces = jumped_pieces + 1
                current_x, current_y = next_x, next_y
                
                -- Update direction based on new column parity
                if next_x % 2 == 0 then
                    if dx == -1 and dy == -1 then dx, dy = 0, -1
                    elseif dx == 1 and dy == -1 then dx, dy = 1, -1
                    elseif dx == -1 and dy == 1 then dx, dy = 0, 1
                    elseif dx == 1 and dy == 1 then dx, dy = 1, 1
                    end
                else
                    if dx == 0 and dy == -1 then dx, dy = -1, -1
                    elseif dx == 1 and dy == -1 then dx, dy = 0, -1
                    elseif dx == 0 and dy == 1 then dx, dy = -1, 1
                    elseif dx == 1 and dy == 1 then dx, dy = 0, 1
                    end
                end
            else
                -- Found empty space - this is where grasshopper must land
                if next_x == dest_x and next_y == dest_y and jumped_pieces > 0 then
                    -- Destination must be adjacent to at least one piece (excluding source)
                    mark_neighbours_on_map(map, dest_x, dest_y, w, h)
                    local has_neighbor = false
                    for i = 1, h do
                        for j = 1, w do
                            if map[i][j].neighbour and map[i][j].piece and not (i == src_y and j == src_x) then
                                has_neighbor = true
                                break
                            end
                        end
                        if has_neighbor then break end
                    end
                    clear_all_neighbours(map, w, h)
                    return has_neighbor
                end
                -- If we hit an empty space but it's not our destination, this direction doesn't work
                break
            end
        end
    end
    
    return false
end

function Grasshopper:move_piece(map, src_x, src_y, dest_x, dest_y, active_player_id)
    -- Simple move: transfer piece to destination
    map[dest_y][dest_x].piece = map[src_y][src_x].piece
    map[dest_y][dest_x].player_id = map[src_y][src_x].player_id
    map[src_y][src_x].piece = nil
    map[src_y][src_x].player_id = nil
    return true
end

return Grasshopper
