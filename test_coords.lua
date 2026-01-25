-- Test coordinate conversion
function CubeCoords_new(x, y, z)
    return {x = x, y = y, z = z}
end

function from_offset(col, row)
    local x = col - math.floor((row + (row % 2)) / 2)
    local z = row
    local y = -x - z
    return CubeCoords_new(x, y, z)
end

function to_offset(cube)
    local col = cube.x + math.floor((cube.z + (cube.z % 2)) / 2)
    local row = cube.z
    return col, row
end

function to_key(cube)
    return cube.x .. "," .. cube.y .. "," .. cube.z
end

-- Test QB2 at (8, 5)
print("QB2 at offset (8, 5):")
local qb2_cube = from_offset(8, 5)
print("  Cube: " .. to_key(qb2_cube))
local col, row = to_offset(qb2_cube)
print("  Back to offset: (" .. col .. ", " .. row .. ")")

-- Test neighbors
local dirs = {
    {1, -1, 0}, {1, 0, -1}, {0, 1, -1},
    {-1, 1, 0}, {-1, 0, 1}, {0, -1, 1}
}

print("\nNeighbors of QB2 at (8,5):")
for i, dir in ipairs(dirs) do
    local neighbor = CubeCoords_new(
        qb2_cube.x + dir[1],
        qb2_cube.y + dir[2],
        qb2_cube.z + dir[3]
    )
    local ncol, nrow = to_offset(neighbor)
    print("  Direction " .. i .. ": cube=" .. to_key(neighbor) .. " offset=(" .. ncol .. ", " .. nrow .. ")")
end
