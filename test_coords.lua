cubecoords = require("cubecoords")

-- Test what offset coords (0,0,0) maps to
local cube = cubecoords.new(0, 0, 0)
local col, row = cubecoords.to_offset(cube)
print("Cube (0,0,0) -> Offset (" .. col .. ", " .. row .. ")")

-- Test reverse
local cube2 = cubecoords.from_offset(col, row)
print("Offset (" .. col .. ", " .. row .. ") -> Cube (" .. cube2.x .. ", " .. cube2.y .. ", " .. cube2.z .. ")")
