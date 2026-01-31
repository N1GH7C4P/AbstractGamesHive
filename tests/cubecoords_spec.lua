-- Tests for cubecoords.lua module
local cubecoords = require("cubecoords")

describe("CubeCoords module", function()

  describe("new", function()
    it("creates valid cube coordinates", function()
      local cube = cubecoords.new(1, -2, 1)
      assert.equals(1, cube.x)
      assert.equals(-2, cube.y)
      assert.equals(1, cube.z)
    end)

    it("enforces x + y + z = 0 constraint", function()
      assert.has_error(function()
        cubecoords.new(1, 1, 1)  -- Invalid: sum is 3
      end)
    end)

    it("allows zero coordinates", function()
      local cube = cubecoords.new(0, 0, 0)
      assert.equals(0, cube.x)
      assert.equals(0, cube.y)
      assert.equals(0, cube.z)
    end)
  end)

  describe("add", function()
    it("adds two cube coordinates", function()
      local a = cubecoords.new(1, -1, 0)
      local b = cubecoords.new(0, -1, 1)
      local result = cubecoords.add(a, b)
      assert.equals(1, result.x)
      assert.equals(-2, result.y)
      assert.equals(1, result.z)
    end)
  end)

  describe("subtract", function()
    it("subtracts two cube coordinates", function()
      local a = cubecoords.new(2, -1, -1)
      local b = cubecoords.new(1, -1, 0)
      local result = cubecoords.subtract(a, b)
      assert.equals(1, result.x)
      assert.equals(0, result.y)
      assert.equals(-1, result.z)
    end)
  end)

  describe("scale", function()
    it("multiplies cube coordinate by scalar", function()
      local cube = cubecoords.new(1, -2, 1)
      local result = cubecoords.scale(cube, 3)
      assert.equals(3, result.x)
      assert.equals(-6, result.y)
      assert.equals(3, result.z)
    end)

    it("handles negative scalar", function()
      local cube = cubecoords.new(2, -1, -1)
      local result = cubecoords.scale(cube, -1)
      assert.equals(-2, result.x)
      assert.equals(1, result.y)
      assert.equals(1, result.z)
    end)
  end)

  describe("distance", function()
    it("calculates distance between two coordinates", function()
      local a = cubecoords.new(0, 0, 0)
      local b = cubecoords.new(2, -1, -1)
      assert.equals(2, cubecoords.distance(a, b))
    end)

    it("returns 0 for same coordinate", function()
      local a = cubecoords.new(1, -1, 0)
      assert.equals(0, cubecoords.distance(a, a))
    end)

    it("is symmetric", function()
      local a = cubecoords.new(1, -2, 1)
      local b = cubecoords.new(3, -1, -2)
      assert.equals(cubecoords.distance(a, b), cubecoords.distance(b, a))
    end)
  end)

  describe("equals", function()
    it("returns true for equal coordinates", function()
      local a = cubecoords.new(1, -1, 0)
      local b = cubecoords.new(1, -1, 0)
      assert.is_true(cubecoords.equals(a, b))
    end)

    it("returns false for different coordinates", function()
      local a = cubecoords.new(1, -1, 0)
      local b = cubecoords.new(2, -1, -1)
      assert.is_false(cubecoords.equals(a, b))
    end)
  end)

  describe("directions", function()
    it("returns 6 directions", function()
      local dirs = cubecoords.directions()
      assert.equals(6, #dirs)
    end)

    it("all directions satisfy x + y + z = 0", function()
      local dirs = cubecoords.directions()
      for _, dir in ipairs(dirs) do
        assert.equals(0, dir.x + dir.y + dir.z)
      end
    end)

    it("all directions have distance 1 from origin", function()
      local origin = cubecoords.new(0, 0, 0)
      local dirs = cubecoords.directions()
      for _, dir in ipairs(dirs) do
        local cube = cubecoords.new(dir.x, dir.y, dir.z)
        assert.equals(1, cubecoords.distance(origin, cube))
      end
    end)
  end)

  describe("neighbor", function()
    it("returns neighbor in given direction", function()
      local cube = cubecoords.new(0, 0, 0)
      local neighbor = cubecoords.neighbor(cube, 0)  -- East
      assert.equals(1, neighbor.x)
      assert.equals(-1, neighbor.y)
      assert.equals(0, neighbor.z)
    end)

    it("neighbor is distance 1 from original", function()
      local cube = cubecoords.new(2, -1, -1)
      for dir = 0, 5 do
        local neighbor = cubecoords.neighbor(cube, dir)
        assert.equals(1, cubecoords.distance(cube, neighbor))
      end
    end)
  end)

  describe("all_neighbors", function()
    it("returns 6 neighbors", function()
      local cube = cubecoords.new(0, 0, 0)
      local neighbors = cubecoords.all_neighbors(cube)
      assert.equals(6, #neighbors)
    end)

    it("all neighbors are distance 1 from original", function()
      local cube = cubecoords.new(1, -2, 1)
      local neighbors = cubecoords.all_neighbors(cube)
      for _, neighbor in ipairs(neighbors) do
        assert.equals(1, cubecoords.distance(cube, neighbor))
      end
    end)
  end)

  describe("to_offset and from_offset", function()
    it("round-trip conversion preserves coordinates", function()
      local original = cubecoords.new(2, -3, 1)
      local col, row = cubecoords.to_offset(original)
      local result = cubecoords.from_offset(col, row)
      assert.is_true(cubecoords.equals(original, result))
    end)

    it("converts origin correctly", function()
      local origin = cubecoords.new(0, 0, 0)
      local col, row = cubecoords.to_offset(origin)
      assert.equals(0, col)
      assert.equals(0, row)
    end)

    it("handles multiple coordinates", function()
      local test_coords = {
        cubecoords.new(1, -1, 0),
        cubecoords.new(0, -1, 1),
        cubecoords.new(-1, 0, 1),
        cubecoords.new(2, -1, -1)
      }

      for _, cube in ipairs(test_coords) do
        local col, row = cubecoords.to_offset(cube)
        local result = cubecoords.from_offset(col, row)
        assert.is_true(cubecoords.equals(cube, result))
      end
    end)
  end)

  describe("ring", function()
    it("returns single hex for radius 0", function()
      local center = cubecoords.new(0, 0, 0)
      local ring = cubecoords.ring(center, 0)
      assert.equals(1, #ring)
      assert.is_true(cubecoords.equals(center, ring[1]))
    end)

    it("returns 6 hexes for radius 1", function()
      local center = cubecoords.new(0, 0, 0)
      local ring = cubecoords.ring(center, 1)
      assert.equals(6, #ring)
    end)

    it("all hexes in ring are at correct distance", function()
      local center = cubecoords.new(1, -1, 0)
      local radius = 2
      local ring = cubecoords.ring(center, radius)
      for _, hex in ipairs(ring) do
        assert.equals(radius, cubecoords.distance(center, hex))
      end
    end)

    it("ring size follows formula 6*radius", function()
      local center = cubecoords.new(0, 0, 0)
      for radius = 1, 4 do
        local ring = cubecoords.ring(center, radius)
        assert.equals(6 * radius, #ring)
      end
    end)
  end)

  describe("spiral", function()
    it("includes center for radius 0", function()
      local center = cubecoords.new(0, 0, 0)
      local spiral = cubecoords.spiral(center, 0)
      assert.equals(1, #spiral)
      assert.is_true(cubecoords.equals(center, spiral[1]))
    end)

    it("includes all hexes within radius", function()
      local center = cubecoords.new(0, 0, 0)
      local spiral = cubecoords.spiral(center, 2)
      -- Should have 1 + 6 + 12 = 19 hexes
      assert.equals(19, #spiral)
    end)

    it("all hexes are within max distance", function()
      local center = cubecoords.new(1, -1, 0)
      local radius = 3
      local spiral = cubecoords.spiral(center, radius)
      for _, hex in ipairs(spiral) do
        assert.is_true(cubecoords.distance(center, hex) <= radius)
      end
    end)
  end)

  describe("direction and is_aligned", function()
    it("calculates direction vector", function()
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(2, -1, -1)
      local dir = cubecoords.direction(from, to)
      assert.equals(2, dir.x)
      assert.equals(-1, dir.y)
      assert.equals(-1, dir.z)
    end)

    it("recognizes aligned directions", function()
      assert.is_true(cubecoords.is_aligned({x = 2, y = 0, z = -2}))  -- y=0 aligned
      assert.is_true(cubecoords.is_aligned({x = 0, y = 3, z = -3}))  -- x=0 aligned
      assert.is_true(cubecoords.is_aligned({x = -2, y = 2, z = 0}))  -- z=0 aligned
    end)

    it("recognizes non-aligned directions", function()
      assert.is_false(cubecoords.is_aligned({x = 1, y = 1, z = 1}))
      assert.is_false(cubecoords.is_aligned({x = 2, y = 3, z = -5}))
    end)
  end)

  describe("normalize_direction", function()
    it("normalizes aligned direction", function()
      local dir = {x = 4, y = 0, z = -4}
      local normalized = cubecoords.normalize_direction(dir)
      assert.equals(1, normalized.x)
      assert.equals(0, normalized.y)
      assert.equals(-1, normalized.z)
    end)

    it("returns nil for non-aligned direction", function()
      local dir = {x = 1, y = 1, z = 1}
      local normalized = cubecoords.normalize_direction(dir)
      assert.is_nil(normalized)
    end)

    it("handles negative directions", function()
      local dir = {x = -6, y = 0, z = 6}
      local normalized = cubecoords.normalize_direction(dir)
      assert.equals(-1, normalized.x)
      assert.equals(0, normalized.y)
      assert.equals(1, normalized.z)
    end)
  end)

  describe("to_key and from_key", function()
    it("round-trip conversion preserves coordinates", function()
      local cube = cubecoords.new(2, -3, 1)
      local key = cubecoords.to_key(cube)
      local result = cubecoords.from_key(key)
      assert.is_true(cubecoords.equals(cube, result))
    end)

    it("creates unique keys for different coordinates", function()
      local cube1 = cubecoords.new(1, -1, 0)
      local cube2 = cubecoords.new(0, -1, 1)
      assert.is_not.equals(cubecoords.to_key(cube1), cubecoords.to_key(cube2))
    end)

    it("creates same key for equal coordinates", function()
      local cube1 = cubecoords.new(2, -1, -1)
      local cube2 = cubecoords.new(2, -1, -1)
      assert.equals(cubecoords.to_key(cube1), cubecoords.to_key(cube2))
    end)

    it("handles negative zero correctly", function()
      local cube = cubecoords.new(0, 0, 0)
      local key = cubecoords.to_key(cube)
      assert.equals("0,0,0", key)
    end)
  end)

  describe("round", function()
    it("rounds fractional coordinates correctly", function()
      local rounded = cubecoords.round(1.2, -2.1, 0.9)
      assert.equals(1, rounded.x)
      assert.equals(-2, rounded.y)
      assert.equals(1, rounded.z)
    end)

    it("maintains x + y + z = 0 constraint after rounding", function()
      local rounded = cubecoords.round(0.7, -0.3, -0.4)
      assert.equals(0, rounded.x + rounded.y + rounded.z)
    end)

    it("handles exact integers", function()
      local rounded = cubecoords.round(2, -1, -1)
      assert.equals(2, rounded.x)
      assert.equals(-1, rounded.y)
      assert.equals(-1, rounded.z)
    end)
  end)

  describe("to_pixel and from_pixel", function()
    it("round-trip conversion approximately preserves coordinates", function()
      local original = cubecoords.new(2, -3, 1)
      local hex_size = 30
      local px, py = cubecoords.to_pixel(original, hex_size)
      local result = cubecoords.from_pixel(px, py, hex_size)
      assert.is_true(cubecoords.equals(original, result))
    end)

    it("origin maps to (0, 0)", function()
      local origin = cubecoords.new(0, 0, 0)
      local hex_size = 30
      local px, py = cubecoords.to_pixel(origin, hex_size)
      assert.equals(0, px)
      assert.equals(0, py)
    end)
  end)
end)
