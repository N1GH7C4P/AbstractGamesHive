-- Map utilities for working with cube coordinates
-- Provides bridge between old offset coordinates and new cube coordinates

MapCoords = {}

-- Create a map that uses cube coordinates internally
-- but maintains backward compatibility with offset coordinates
function MapCoords.init_cube_map(w, h)
    local cube_map = {}
    cube_map.offset_to_cube = {}  -- Lookup table: [row][col] = cube_key
    cube_map.cube_to_offset = {}  -- Lookup table: cube_key = {col, row}
    cube_map.hexes = {}            -- Actual hex data: cube_key = hex_data
    cube_map.w = w
    cube_map.h = h
    
    -- Build coordinate mappings
    for row = 1, h do
        cube_map.offset_to_cube[row] = {}
        for col = 1, w do
            local cube = cubecoords.from_offset(col, row)
            local key = cubecoords.to_key(cube)
            
            cube_map.offset_to_cube[row][col] = key
            cube_map.cube_to_offset[key] = {col = col, row = row, cube = cube}
            cube_map.hexes[key] = {
                cube = cube,
                col = col,
                row = row,
                piece = nil,
                player_id = nil,
                neighbour = nil
            }
        end
    end
    
    return cube_map
end

-- Get hex by offset coordinates (maintains old API)
function MapCoords.get_by_offset(cube_map, col, row)
    if not cube_map.offset_to_cube[row] then return nil end
    local key = cube_map.offset_to_cube[row][col]
    if not key then return nil end
    return cube_map.hexes[key]
end

-- Get hex by cube coordinates
function MapCoords.get_by_cube(cube_map, cube)
    local key = cubecoords.to_key(cube)
    return cube_map.hexes[key]
end

-- Set hex data by offset coordinates
function MapCoords.set_by_offset(cube_map, col, row, data)
    if not cube_map.offset_to_cube[row] then return false end
    local key = cube_map.offset_to_cube[row][col]
    if not key then return false end
    
    for k, v in pairs(data) do
        cube_map.hexes[key][k] = v
    end
    return true
end

-- Set hex data by cube coordinates
function MapCoords.set_by_cube(cube_map, cube, data)
    local key = cubecoords.to_key(cube)
    if not cube_map.hexes[key] then return false end
    
    for k, v in pairs(data) do
        cube_map.hexes[key][k] = v
    end
    return true
end

-- Get all neighbors of a hex
function MapCoords.get_neighbors(cube_map, cube)
    local neighbors = {}
    local neighbor_cubes = cubecoords.all_neighbors(cube)
    
    for _, ncube in ipairs(neighbor_cubes) do
        local hex = MapCoords.get_by_cube(cube_map, ncube)
        if hex then
            table.insert(neighbors, hex)
        end
    end
    
    return neighbors
end

-- Iterate over all hexes
function MapCoords.iter_all(cube_map)
    local hexes = {}
    for _, hex in pairs(cube_map.hexes) do
        table.insert(hexes, hex)
    end
    return hexes
end

return MapCoords
