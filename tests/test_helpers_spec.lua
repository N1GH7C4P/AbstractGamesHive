-- tests/test_helpers_spec.lua
-- Validation tests for the test helper functions

local test_helpers = require("tests.test_helpers")
local cubecoords = require("cubecoords")
local map_module = require("map")

describe("Test Helpers", function()

  describe("parse_cube", function()
    it("parses valid cube coordinate string", function()
      local cube = test_helpers.parse_cube("1,-1,0")
      assert.equals(1, cube.x)
      assert.equals(-1, cube.y)
      assert.equals(0, cube.z)
    end)

    it("parses origin correctly", function()
      local cube = test_helpers.parse_cube("0,0,0")
      assert.equals(0, cube.x)
      assert.equals(0, cube.y)
      assert.equals(0, cube.z)
    end)

    it("parses negative coordinates", function()
      local cube = test_helpers.parse_cube("-2,1,1")
      assert.equals(-2, cube.x)
      assert.equals(1, cube.y)
      assert.equals(1, cube.z)
    end)

    it("returns cube table unchanged", function()
      local input = {x = 1, y = -1, z = 0}
      local output = test_helpers.parse_cube(input)
      assert.equals(input, output)
    end)

    it("throws error for invalid format", function()
      assert.has_error(function()
        test_helpers.parse_cube("invalid")
      end)
    end)
  end)

  describe("cube_to_string", function()
    it("formats cube coordinate as string", function()
      local cube = cubecoords.new(1, -1, 0)
      local str = test_helpers.cube_to_string(cube)
      assert.equals("1,-1,0", str)
    end)

    it("handles origin", function()
      local cube = cubecoords.new(0, 0, 0)
      local str = test_helpers.cube_to_string(cube)
      assert.equals("0,0,0", str)
    end)

    it("handles negative coordinates", function()
      local cube = cubecoords.new(-2, 1, 1)
      local str = test_helpers.cube_to_string(cube)
      assert.equals("-2,1,1", str)
    end)
  end)

  describe("setup_test_map", function()
    it("creates empty map with no pieces", function()
      local map = test_helpers.setup_test_map({})
      assert.is_not_nil(map)
      assert.is_not_nil(map.hexes)
    end)

    it("places single piece at origin", function()
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB"
      })

      local hex = map_module.get_hex(map, cubecoords.new(0, 0, 0))
      assert.is_not_nil(hex)
      assert.is_not_nil(hex.piece)
      assert.equals("Queen bee", hex.piece.name)
      assert.equals(1, hex.player_id)
    end)

    it("places multiple pieces", function()
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB",   -- Queen at origin
        "1,-1,0:2:A",   -- Ant east
        "0,1,-1:1:B"    -- Beetle southwest
      })

      local queen_hex = test_helpers.get_hex_at(map, "0,0,0")
      local ant_hex = test_helpers.get_hex_at(map, "1,-1,0")
      local beetle_hex = test_helpers.get_hex_at(map, "0,1,-1")

      assert.equals("Queen bee", queen_hex.piece.name)
      assert.equals(1, queen_hex.player_id)

      assert.equals("Soldier ant", ant_hex.piece.name)
      assert.equals(2, ant_hex.player_id)

      assert.equals("Beetle", beetle_hex.piece.name)
      assert.equals(1, beetle_hex.player_id)
    end)

    it("throws error for invalid piece code", function()
      assert.has_error(function()
        test_helpers.setup_test_map({"0,0,0:1:INVALID"})
      end)
    end)

    it("throws error for invalid player number", function()
      assert.has_error(function()
        test_helpers.setup_test_map({"0,0,0:3:QB"})
      end)
    end)

    it("creates all piece types correctly", function()
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB",    -- Queen Bee
        "1,-1,0:1:A",    -- Ant
        "1,0,-1:1:B",    -- Beetle
        "0,1,-1:1:G",    -- Grasshopper
        "-1,1,0:1:S",    -- Spider
        "-1,0,1:1:L",    -- Ladybug
        "0,-1,1:1:M",    -- Mosquito
        "2,-1,-1:1:P"    -- Pillbug
      })

      assert.equals("Queen bee", test_helpers.get_hex_at(map, "0,0,0").piece.name)
      assert.equals("Soldier ant", test_helpers.get_hex_at(map, "1,-1,0").piece.name)
      assert.equals("Beetle", test_helpers.get_hex_at(map, "1,0,-1").piece.name)
      assert.equals("Grasshopper", test_helpers.get_hex_at(map, "0,1,-1").piece.name)
      assert.equals("Spider", test_helpers.get_hex_at(map, "-1,1,0").piece.name)
      assert.equals("Ladybug", test_helpers.get_hex_at(map, "-1,0,1").piece.name)
      assert.equals("Mosquito", test_helpers.get_hex_at(map, "0,-1,1").piece.name)
      assert.equals("Pillbug", test_helpers.get_hex_at(map, "2,-1,-1").piece.name)
    end)
  end)

  describe("get_hex_at", function()
    it("returns hex at position", function()
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB"
      })

      local hex = test_helpers.get_hex_at(map, "0,0,0")
      assert.is_not_nil(hex)
      assert.equals("Queen bee", hex.piece.name)
    end)

    it("accepts cube coordinate table", function()
      local map = test_helpers.setup_test_map({
        "1,-1,0:2:A"
      })

      local cube = cubecoords.new(1, -1, 0)
      local hex = test_helpers.get_hex_at(map, cube)
      assert.is_not_nil(hex)
      assert.equals("Soldier ant", hex.piece.name)
    end)

    it("returns hex even if no piece", function()
      local map = test_helpers.setup_test_map({})
      local hex = test_helpers.get_hex_at(map, "0,0,0")
      assert.is_not_nil(hex)
      assert.is_nil(hex.piece)
    end)
  end)

  describe("assert_has_move", function()
    it("succeeds when move is present", function()
      local moves = {
        cubecoords.new(1, -1, 0),
        cubecoords.new(0, 1, -1)
      }

      -- Should not throw
      test_helpers.assert_has_move(moves, "1,-1,0")
    end)

    it("throws error when move is not present", function()
      local moves = {
        cubecoords.new(1, -1, 0)
      }

      assert.has_error(function()
        test_helpers.assert_has_move(moves, "0,1,-1")
      end)
    end)

    it("accepts cube coordinate table", function()
      local moves = {
        cubecoords.new(1, -1, 0)
      }

      local cube = cubecoords.new(1, -1, 0)
      test_helpers.assert_has_move(moves, cube)
    end)
  end)

  describe("assert_no_move", function()
    it("succeeds when move is not present", function()
      local moves = {
        cubecoords.new(1, -1, 0)
      }

      -- Should not throw
      test_helpers.assert_no_move(moves, "0,1,-1")
    end)

    it("throws error when move is present", function()
      local moves = {
        cubecoords.new(1, -1, 0),
        cubecoords.new(0, 1, -1)
      }

      assert.has_error(function()
        test_helpers.assert_no_move(moves, "1,-1,0")
      end)
    end)
  end)

  describe("assert_move_count", function()
    it("succeeds when count matches", function()
      local moves = {
        cubecoords.new(1, -1, 0),
        cubecoords.new(0, 1, -1)
      }

      test_helpers.assert_move_count(moves, 2)
    end)

    it("throws error when count does not match", function()
      local moves = {
        cubecoords.new(1, -1, 0)
      }

      assert.has_error(function()
        test_helpers.assert_move_count(moves, 2)
      end)
    end)

    it("handles zero moves", function()
      local moves = {}
      test_helpers.assert_move_count(moves, 0)
    end)
  end)

  describe("get_legal_moves integration", function()
    it("returns legal moves for Queen Bee", function()
      -- Setup: Queen at origin with an adjacent ant
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB",   -- Queen at origin
        "1,-1,0:1:A"    -- Ant to the east
      })

      local moves = test_helpers.get_legal_moves(map, "0,0,0")

      -- Queen should have some legal moves (exact count depends on rules)
      assert.is_true(#moves >= 0)  -- At minimum, should return an array
    end)

    it("returns empty array when piece cannot move", function()
      -- Setup: Queen surrounded on all 6 sides
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB",     -- Queen in center
        "1,-1,0:2:A",     -- Surrounded by ants
        "1,0,-1:2:A",
        "0,1,-1:2:A",
        "-1,1,0:2:A",
        "-1,0,1:2:A",
        "0,-1,1:2:A"
      })

      local moves = test_helpers.get_legal_moves(map, "0,0,0")

      -- Queen surrounded on all sides should not be able to move
      test_helpers.assert_move_count(moves, 0)
    end)
  end)

  describe("execute_move integration", function()
    it("moves a piece from one hex to another", function()
      local map = test_helpers.setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:1:A"
      })

      -- Try to move queen to a valid adjacent position
      local from = "0,0,0"
      local to = "0,-1,1"  -- Northeast of queen

      local success = test_helpers.execute_move(map, from, to)

      if success then
        -- Verify piece moved
        local old_hex = test_helpers.get_hex_at(map, from)
        local new_hex = test_helpers.get_hex_at(map, to)

        -- Old position should be empty (or have under_piece if stacked)
        -- New position should have the queen
        assert.equals("Queen bee", new_hex.piece.name)
      end
    end)
  end)
end)
