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
    instance.image_path = nil  -- Path to piece image
    instance.image = nil  -- Loaded image (lazy loaded)
    instance.image_load_attempted = false  -- Track if we already tried loading
    return instance
end

-- Load the piece image if not already loaded
function Piece:loadImage()
    if self.image_path and not self.image and not self.image_load_attempted then
        self.image_load_attempted = true
        local success, image = pcall(love.graphics.newImage, self.image_path)
        if success then
            self.image = image
        end
        -- Don't print warnings - it's okay if images don't exist
    end
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
