-- Base Piece class
Piece = {}
Piece.__index = Piece

function Piece:new(owner)
    local instance = setmetatable({}, self)
    instance.owner = owner
    instance.x = nil
    instance.y = nil
    instance.z = 0  -- z coordinate for stacking (beetles)
    instance.is_placed = false
    instance.under_piece = nil  -- For beetle stacking
    return instance
end

function Piece:try_to_move(map, src_x, src_y, dest_x, dest_y, w, h)
    error("try_to_move must be implemented by subclass")
end

function Piece:place(x, y)
    self.x = x
    self.y = y
    self.is_placed = true
end

function Piece:remove()
    self.is_placed = false
end

return Piece
