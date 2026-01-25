-- Base Piece class
Piece = {}
Piece.__index = Piece

function Piece:new(owner)
    local instance = setmetatable({}, self)
    instance.owner = owner
    instance.cube = nil  -- Cube coordinates {x, y, z}
    instance.z_height = 0  -- z height for stacking (beetles on top of hive)
    instance.is_placed = false
    instance.under_piece = nil  -- For beetle stacking
    return instance
end

function Piece:try_to_move(map, src_cube, dest_cube)
    error("try_to_move must be implemented by subclass")
end

function Piece:place(cube)
    self.cube = cube
    self.is_placed = true
end

function Piece:remove()
    self.is_placed = false
    self.cube = nil
end

return Piece
