-- Cube coordinate system for hexagonal grids
-- In cube coordinates: x + y + z = 0
-- This makes many hex operations simpler, especially directional movement

CubeCoords = {}

-- Create a new cube coordinate
function CubeCoords.new(x, y, z)
    assert(x + y + z == 0, "Invalid cube coordinates: x + y + z must equal 0")
    return {x = x, y = y, z = z}
end

-- Convert offset coordinates (col, row with alternating offsets) to cube
-- Uses "odd-q" layout for flat-topped hexagons: odd columns are shifted down
function CubeCoords.from_offset(col, row)
    local x = col
    local z = row - math.floor((col + (col % 2)) / 2)
    local y = -x - z
    return CubeCoords.new(x, y, z)
end

-- Convert cube coordinates back to offset coordinates
-- Uses "odd-q" layout for flat-topped hexagons: odd columns are shifted down
function CubeCoords.to_offset(cube)
    local col = cube.x
    local row = cube.z + math.floor((cube.x + (cube.x % 2)) / 2)
    return col, row
end

-- Get the 6 neighboring directions in cube coordinates
function CubeCoords.directions()
    return {
        {x = 1, y = -1, z = 0},  -- East
        {x = 1, y = 0, z = -1},  -- Southeast
        {x = 0, y = 1, z = -1},  -- Southwest
        {x = -1, y = 1, z = 0},  -- West
        {x = -1, y = 0, z = 1},  -- Northwest
        {x = 0, y = -1, z = 1}   -- Northeast
    }
end

-- Add two cube coordinates
function CubeCoords.add(a, b)
    return CubeCoords.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

-- Subtract two cube coordinates
function CubeCoords.subtract(a, b)
    return CubeCoords.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- Multiply cube coordinate by scalar
function CubeCoords.scale(cube, factor)
    return CubeCoords.new(cube.x * factor, cube.y * factor, cube.z * factor)
end

-- Get neighbor in a specific direction (0-5)
function CubeCoords.neighbor(cube, direction)
    local dirs = CubeCoords.directions()
    return CubeCoords.add(cube, dirs[direction + 1])
end

-- Get all 6 neighbors
function CubeCoords.all_neighbors(cube)
    local neighbors = {}
    local dirs = CubeCoords.directions()
    for _, dir in ipairs(dirs) do
        table.insert(neighbors, CubeCoords.add(cube, dir))
    end
    return neighbors
end

-- Calculate distance between two cube coordinates
function CubeCoords.distance(a, b)
    return (math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)) / 2
end

-- Check if two coordinates are equal
function CubeCoords.equals(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

-- Get direction from a to b (returns direction vector, not normalized to unit)
function CubeCoords.direction(from, to)
    return CubeCoords.subtract(to, from)
end

-- Check if a direction is aligned with hex grid axes (one component is 0)
function CubeCoords.is_aligned(dir)
    return dir.x == 0 or dir.y == 0 or dir.z == 0
end

-- Normalize a direction to a unit direction (one of the 6 directions)
-- Returns nil if not aligned with hex axes
function CubeCoords.normalize_direction(dir)
    if not CubeCoords.is_aligned(dir) then
        return nil
    end
    
    -- Find the greatest common divisor to normalize
    local gcd = math.abs(dir.x)
    if math.abs(dir.y) > 0 then
        if gcd == 0 then
            gcd = math.abs(dir.y)
        else
            local a, b = gcd, math.abs(dir.y)
            while b ~= 0 do
                a, b = b, a % b
            end
            gcd = a
        end
    end
    if math.abs(dir.z) > 0 then
        if gcd == 0 then
            gcd = math.abs(dir.z)
        else
            local a, b = gcd, math.abs(dir.z)
            while b ~= 0 do
                a, b = b, a % b
            end
            gcd = a
        end
    end
    
    if gcd == 0 then return {x = 0, y = 0, z = 0} end
    
    return {
        x = dir.x / gcd,
        y = dir.y / gcd,
        z = dir.z / gcd
    }
end

-- Get all positions in a line from 'from' in direction 'dir'
function CubeCoords.line_from(from, dir, max_distance)
    max_distance = max_distance or 20
    local positions = {}
    local normalized = CubeCoords.normalize_direction(dir)
    
    if not normalized then
        return positions
    end
    
    for i = 1, max_distance do
        local pos = CubeCoords.add(from, CubeCoords.scale(normalized, i))
        table.insert(positions, pos)
    end
    
    return positions
end

-- Convert cube coordinate to a string key for table indexing
function CubeCoords.to_key(cube)
    return cube.x .. "," .. cube.y .. "," .. cube.z
end

-- Convert string key back to cube coordinate
function CubeCoords.from_key(key)
    local x, y, z = key:match("([^,]+),([^,]+),([^,]+)")
    return CubeCoords.new(tonumber(x), tonumber(y), tonumber(z))
end

return CubeCoords
