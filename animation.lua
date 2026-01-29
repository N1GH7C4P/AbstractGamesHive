-- Animation system for smooth piece movements
local cubecoords = require("cubecoords")

local Animation = {}

-- Start a piece movement animation
function Animation.start_move(piece, from_cube, to_cube, callback)
    G.animating = true
    G.animation_piece = piece
    G.animation_from_cube = from_cube
    G.animation_to_cube = to_cube
    G.animation_progress = 0
    G.animation_callback = callback
end

-- Update animation progress
function Animation.update(dt)
    if not G.animating then
        return
    end
    
    G.animation_progress = G.animation_progress + (dt / G.animation_duration)
    
    if G.animation_progress >= 1.0 then
        -- Animation complete
        G.animation_progress = 1.0
        G.animating = false
        
        -- Call completion callback
        if G.animation_callback then
            G.animation_callback()
            G.animation_callback = nil
        end
        
        -- Clear animation state
        G.animation_piece = nil
        G.animation_from_cube = nil
        G.animation_to_cube = nil
    end
end

-- Ease out cubic function for smooth deceleration
local function ease_out_cubic(t)
    return 1 - math.pow(1 - t, 3)
end

-- Get interpolated position for animated piece
function Animation.get_animated_position(grid_size)
    if not G.animating or not G.animation_from_cube or not G.animation_to_cube then
        return nil
    end
    
    local from_x, from_y = cubecoords.to_pixel(G.animation_from_cube, grid_size)
    local to_x, to_y = cubecoords.to_pixel(G.animation_to_cube, grid_size)
    
    -- Apply easing
    local eased_progress = ease_out_cubic(G.animation_progress)
    
    -- Interpolate position
    local x = from_x + (to_x - from_x) * eased_progress
    local y = from_y + (to_y - from_y) * eased_progress
    
    return x, y, G.animation_piece
end

-- Check if a specific cube is being animated from
function Animation.is_animating_from(cube)
    if not G.animating or not G.animation_from_cube then
        return false
    end
    return cubecoords.equals(G.animation_from_cube, cube)
end

return Animation
