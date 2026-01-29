cubecoords = require("cubecoords")  -- Global for piece modules

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
    instance.has_moved_last_turn = false  -- Track if piece moved in last turn (for Pillbug restrictions)
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

-- Create a duplicate of this piece with a new owner
function Piece:duplicate(new_owner)
    -- Create new instance of the same class
    local duplicate = getmetatable(self):new(new_owner)
    -- Copy relevant properties (but not owner, cube, or placement state)
    -- These are already set correctly by :new()
    return duplicate
end

-- Get list of legal destination cubes for this piece
-- Subclasses should override this to implement custom movement logic
function Piece:get_legal_moves(map, src_cube)
    -- Returns array of cube coordinates {cube1, cube2, ...}
    -- Default: try adjacent hexes using try_to_move
    local moves = {}
    local neighbors = cubecoords.all_neighbors(src_cube)
    for _, neighbor_cube in ipairs(neighbors) do
        if self:try_to_move(map, src_cube, neighbor_cube) then
            table.insert(moves, neighbor_cube)
        end
    end
    return moves
end

-- Mark legal moves on the map (returns tables of hexes to highlight)
-- Subclasses can override this to implement custom logic
function Piece:mark_legal_moves(map, src_cube)
    -- Returns {normal_moves = {hex1, hex2, ...}, special_targets = {hex3, hex4, ...}}
    -- Default: no moves (subclasses should override)
    return {normal_moves = {}, special_targets = {}}
end

-- Handle a click on a special target when this piece is selected
-- Returns true if the click was handled (and should not continue to other handlers)
function Piece:handle_special_click(map, src_cube, target_cube, mouseX, mouseY)
    -- Default: no special behavior
    return false
end

-- Execute the drop phase of a special ability (for pieces like pillbug)
-- Returns true if successful
function Piece:execute_drop(map, src_cube, target_cube, drop_cube)
    -- Default: no drop phase
    return false
end

return Piece
