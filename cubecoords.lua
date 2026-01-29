-- Cube coordinate system for hexagonal grids
-- In cube coordinates: x + y + z = 0
-- This makes many hex operations simpler, especially directional movement

local CubeCoords = {}

-- Create a new cube coordinate
function CubeCoords.new(x, y, z)
    assert(x + y + z == 0, "Invalid cube coordinates: x + y + z must equal 0")
    return {x = x, y = y, z = z}
end

-- Convert cube coordinates back to offset coordinates
-- Uses "odd-q" layout for flat-topped hexagons: odd columns are shifted down
function CubeCoords.to_offset(cube)
    local col = cube.x
    local row = cube.z + math.floor((cube.x + (cube.x % 2)) / 2)
    return col, row
end

-- Convert offset coordinates to cube coordinates
-- Uses "odd-q" layout for flat-topped hexagons: odd columns are shifted down
function CubeCoords.from_offset(col, row)
    local x = col
    local z = row - math.floor((col + (col % 2)) / 2)
    local y = -x - z
    return CubeCoords.new(x, y, z)
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

-- Get all hexes in a ring at distance N from center
function CubeCoords.ring(center, radius)
    if radius == 0 then
        return {center}
    end
    
    local results = {}
    -- Start at a cube that is 'radius' steps away in direction 4 (southwest)
    local cube = CubeCoords.add(center, CubeCoords.scale(CubeCoords.directions()[5], radius))
    
    -- Walk around the ring
    local dirs = CubeCoords.directions()
    for i = 0, 5 do
        for j = 0, radius - 1 do
            table.insert(results, cube)
            cube = CubeCoords.neighbor(cube, i)
        end
    end
    
    return results
end

-- Get all hexes within distance N from center (including center)
function CubeCoords.spiral(center, radius)
    local results = {center}
    for r = 1, radius do
        local ring = CubeCoords.ring(center, r)
        for _, hex in ipairs(ring) do
            table.insert(results, hex)
        end
    end
    return results
end

-- Convert cube coordinates directly to pixel coordinates
-- For flat-topped hexagons (the default in this game)
function CubeCoords.to_pixel(cube, hex_size)
    -- For flat-topped hexagons
    local x = hex_size * (3/2 * cube.x)
    local y = hex_size * (math.sqrt(3)/2 * cube.x + math.sqrt(3) * cube.z)
    return x, y
end

-- Convert pixel coordinates to cube coordinates
-- For flat-topped hexagons
function CubeCoords.from_pixel(px, py, hex_size)
    -- For flat-topped hexagons
    local q = (2/3 * px) / hex_size
    local r = (-1/3 * px + math.sqrt(3)/3 * py) / hex_size
    return CubeCoords.round(q, -q-r, r)
end

-- Round fractional cube coordinates to nearest integer cube coordinates
function CubeCoords.round(x, y, z)
    local rx = math.floor(x + 0.5)
    local ry = math.floor(y + 0.5)
    local rz = math.floor(z + 0.5)
    
    local x_diff = math.abs(rx - x)
    local y_diff = math.abs(ry - y)
    local z_diff = math.abs(rz - z)
    
    if x_diff > y_diff and x_diff > z_diff then
        rx = -ry - rz
    elseif y_diff > z_diff then
        ry = -rx - rz
    else
        rz = -rx - ry
    end
    
    return CubeCoords.new(rx, ry, rz)
end

-- Convert cube coordinates to pixel coordinates for pointy-topped hexagons
function CubeCoords.to_pixel_pointy(cube, hex_size)
    local x = hex_size * (math.sqrt(3) * cube.x + math.sqrt(3)/2 * cube.z)
    local y = hex_size * (3/2 * cube.z)
    return x, y
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
    -- Normalize -0 to 0 to avoid key mismatches
    local x = cube.x == 0 and 0 or cube.x
    local y = cube.y == 0 and 0 or cube.y
    local z = cube.z == 0 and 0 or cube.z
    return x .. "," .. y .. "," .. z
end

-- Convert string key back to cube coordinate
function CubeCoords.from_key(key)
    local x, y, z = key:match("([^,]+),([^,]+),([^,]+)")
    return CubeCoords.new(tonumber(x), tonumber(y), tonumber(z))
end

-- Export module
return {
    new = CubeCoords.new,
    to_offset = CubeCoords.to_offset,
    from_offset = CubeCoords.from_offset,
    directions = CubeCoords.directions,
    add = CubeCoords.add,
    subtract = CubeCoords.subtract,
    scale = CubeCoords.scale,
    neighbor = CubeCoords.neighbor,
    all_neighbors = CubeCoords.all_neighbors,
    distance = CubeCoords.distance,
    equals = CubeCoords.equals,
    ring = CubeCoords.ring,
    spiral = CubeCoords.spiral,
    to_pixel = CubeCoords.to_pixel,
    from_pixel = CubeCoords.from_pixel,
    round = CubeCoords.round,
    to_pixel_pointy = CubeCoords.to_pixel_pointy,
    direction = CubeCoords.direction,
    is_aligned = CubeCoords.is_aligned,
    normalize_direction = CubeCoords.normalize_direction,
    line_from = CubeCoords.line_from,
    to_key = CubeCoords.to_key,
    from_key = CubeCoords.from_key,
}
