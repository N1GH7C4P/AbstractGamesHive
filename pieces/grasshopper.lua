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
    
    -- Calculate the direction vector
    local dx = dest_x - src_x
    local dy = dest_y - src_y
    
    -- Check if destination is in a straight line (one of 6 hex directions)
    -- For even columns: (0,-1), (1,-1), (-1,0), (1,0), (0,1), (1,1)
    -- For odd columns: (-1,-1), (0,-1), (-1,0), (1,0), (-1,1), (0,1)
    
    -- Normalize direction to check if it's a valid hex line
    local gcd = math.abs(dx) > math.abs(dy) and math.abs(dx) or math.abs(dy)
    if gcd == 0 then return false end
    
    local step_x = dx / gcd
    local step_y = dy / gcd
    
    -- TODO: Implement proper grasshopper jumping logic
    -- For now, return true to allow basic movement
    return true
end

return Grasshopper
