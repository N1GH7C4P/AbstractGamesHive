-- tests/map_spec.lua
-- Unit tests for map module
--
-- Tests cover:
-- - init_map: Map initialization
-- - get_hex: Hex retrieval by cube coordinates
-- - expand_map: Map expansion by adding rings
-- - mark_neighbours_on_map_cube: Neighbor marking
-- - clear_all_neighbours: Clearing neighbor flags
-- - pieceCanDetach: Hive cohesion check
-- - firstPieceCoords: Finding first piece
-- - try_move_piece_on_map: Move validation

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_hex_at = test_helpers.get_hex_at

local map_module = require("map")
local cubecoords = require("cubecoords")

describe("Map module", function()

  describe("init_map", function()

    it("creates a map with hexes table", function()
      local map = map_module.init_map()

      assert.is_table(map, "Map should be a table")
      assert.is_table(map.hexes, "Map should have hexes table")
    end)

    it("creates center hex at origin", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      local hex = map_module.get_hex(map, center)

      assert.is_not_nil(hex, "Center hex should exist")
      assert.are.equal(0, hex.cube.x)
      assert.are.equal(0, hex.cube.y)
      assert.are.equal(0, hex.cube.z)
    end)

    it("creates hexes with nil piece by default", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      local hex = map_module.get_hex(map, center)

      assert.is_nil(hex.piece, "Hex should have no piece initially")
      assert.is_nil(hex.player_id, "Hex should have no player_id initially")
    end)

    it("initializes current_radius from config", function()
      local map = map_module.init_map()

      assert.is_number(map.current_radius, "Map should have current_radius")
      assert.is_true(map.current_radius > 0, "Radius should be positive")
    end)

    it("creates all hexes within initial radius", function()
      local map = map_module.init_map()

      -- Check that hexes exist at distance = radius
      local radius = map.current_radius
      local test_cube = cubecoords.new(radius, -radius, 0)
      local hex = map_module.get_hex(map, test_cube)

      assert.is_not_nil(hex, "Hex at edge of radius should exist")
    end)
  end)

  describe("get_hex", function()

    it("returns hex for valid coordinates", function()
      local map = map_module.init_map()
      local cube = cubecoords.new(1, -1, 0)

      local hex = map_module.get_hex(map, cube)

      assert.is_not_nil(hex, "Should return hex for valid coords")
      assert.are.equal(1, hex.cube.x)
      assert.are.equal(-1, hex.cube.y)
      assert.are.equal(0, hex.cube.z)
    end)

    it("returns nil for coordinates outside map", function()
      local map = map_module.init_map()
      local far_cube = cubecoords.new(100, -100, 0)

      local hex = map_module.get_hex(map, far_cube)

      assert.is_nil(hex, "Should return nil for coords outside map")
    end)

    it("returns same hex for same coordinates", function()
      local map = map_module.init_map()
      local cube = cubecoords.new(2, -1, -1)

      local hex1 = map_module.get_hex(map, cube)
      local hex2 = map_module.get_hex(map, cube)

      assert.are.equal(hex1, hex2, "Should return same hex object")
    end)
  end)

  describe("expand_map", function()

    it("increases current_radius by 1", function()
      local map = map_module.init_map()
      local original_radius = map.current_radius

      map_module.expand_map(map)

      assert.are.equal(original_radius + 1, map.current_radius)
    end)

    it("adds new hexes at expanded radius", function()
      local map = map_module.init_map()
      local new_radius = map.current_radius + 1
      local test_cube = cubecoords.new(new_radius, -new_radius, 0)

      -- Before expansion, hex shouldn't exist
      local hex_before = map_module.get_hex(map, test_cube)
      assert.is_nil(hex_before, "Hex outside radius shouldn't exist yet")

      map_module.expand_map(map)

      -- After expansion, hex should exist
      local hex_after = map_module.get_hex(map, test_cube)
      assert.is_not_nil(hex_after, "Hex should exist after expansion")
    end)

    it("preserves existing hexes after expansion", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      -- Get center hex before expansion
      local hex_before = map_module.get_hex(map, center)

      map_module.expand_map(map)

      -- Center hex should still be the same
      local hex_after = map_module.get_hex(map, center)
      assert.are.equal(hex_before, hex_after, "Existing hexes should be preserved")
    end)
  end)

  describe("mark_neighbours_on_map_cube", function()

    it("marks all 6 neighbors of a hex", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      map_module.mark_neighbours_on_map_cube(map, center)

      -- Check all 6 neighbors are marked
      local neighbors = cubecoords.all_neighbors(center)
      local marked_count = 0
      for _, ncube in ipairs(neighbors) do
        local hex = map_module.get_hex(map, ncube)
        if hex and hex.neighbour then
          marked_count = marked_count + 1
        end
      end

      assert.are.equal(6, marked_count, "All 6 neighbors should be marked")
    end)

    it("does not mark the center hex itself", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      map_module.mark_neighbours_on_map_cube(map, center)

      local center_hex = map_module.get_hex(map, center)
      assert.is_nil(center_hex.neighbour, "Center hex should not be marked as neighbour")
    end)
  end)

  describe("clear_all_neighbours", function()

    it("clears neighbour flags from all hexes", function()
      local map = map_module.init_map()
      local center = cubecoords.new(0, 0, 0)

      -- First mark some neighbors
      map_module.mark_neighbours_on_map_cube(map, center)

      -- Then clear
      map_module.clear_all_neighbours(map)

      -- Check that no hexes have neighbour flag
      for _, hex in pairs(map.hexes) do
        assert.is_nil(hex.neighbour, "No hex should have neighbour flag after clear")
      end
    end)

    it("clears can_move flags", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })

      -- Manually set some flags
      local hex = map_module.get_hex(map, cubecoords.new(0, 0, 0))
      hex.can_move = true
      hex.can_special = true
      hex.is_beetle_move = true

      map_module.clear_all_neighbours(map)

      assert.is_nil(hex.can_move, "can_move should be cleared")
      assert.is_nil(hex.can_special, "can_special should be cleared")
      assert.is_nil(hex.is_beetle_move, "is_beetle_move should be cleared")
    end)
  end)

  describe("firstPieceCoords", function()

    it("returns nil for empty map", function()
      local map = map_module.init_map()

      local coords = map_module.firstPieceCoords(map)

      assert.is_nil(coords, "Should return nil for empty map")
    end)

    it("returns coordinates of a piece on the map", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })

      local coords = map_module.firstPieceCoords(map)

      assert.is_not_nil(coords, "Should return coordinates")
      assert.are.equal(0, coords.x)
      assert.are.equal(0, coords.y)
      assert.are.equal(0, coords.z)
    end)

    it("returns a piece coordinate when multiple pieces exist", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB",
        "-1,0,1:1:B"
      })

      local coords = map_module.firstPieceCoords(map)

      assert.is_not_nil(coords, "Should return coordinates")
      -- Should return one of the pieces (order not guaranteed)
      local hex = map_module.get_hex(map, coords)
      assert.is_not_nil(hex.piece, "Returned coords should have a piece")
    end)
  end)

  describe("pieceCanDetach", function()

    it("returns true for single piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })

      local cube = cubecoords.new(0, 0, 0)
      local can_detach = map_module.pieceCanDetach(map, cube)

      assert.is_true(can_detach, "Single piece can always detach")
    end)

    it("returns false when removal would break hive", function()
      -- Linear arrangement: QB - B - QB
      -- Removing the middle beetle would disconnect the queens
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:1:B",
        "2,-2,0:2:QB"
      })

      local middle_cube = cubecoords.new(1, -1, 0)
      local can_detach = map_module.pieceCanDetach(map, middle_cube)

      assert.is_false(can_detach, "Middle piece in line cannot detach")
    end)

    it("returns true when piece is on edge of connected hive", function()
      -- Triangle arrangement - any piece can be removed
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB",
        "0,-1,1:1:B"
      })

      -- The beetle at 0,-1,1 is on the edge
      local edge_cube = cubecoords.new(0, -1, 1)
      local can_detach = map_module.pieceCanDetach(map, edge_cube)

      assert.is_true(can_detach, "Edge piece in triangle can detach")
    end)

    it("returns false for non-existent hex", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })

      local far_cube = cubecoords.new(100, -100, 0)
      local can_detach = map_module.pieceCanDetach(map, far_cube)

      assert.is_false(can_detach, "Non-existent hex returns false")
    end)

    it("returns true for beetle on top of stack", function()
      -- Beetle stacked on queen - can always detach since queen remains
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })

      -- Manually create beetle stack
      local Beetle = require("pieces.beetle")
      local queen_hex = map_module.get_hex(map, cubecoords.new(0, 0, 0))
      local beetle = Beetle:new(2)
      beetle.under_piece = queen_hex.piece
      queen_hex.piece = beetle
      queen_hex.player_id = 2

      local cube = cubecoords.new(0, 0, 0)
      local can_detach = map_module.pieceCanDetach(map, cube)

      assert.is_true(can_detach, "Beetle on stack can always detach")
    end)
  end)

  describe("try_move_piece_on_map", function()

    it("returns false when piece cannot detach", function()
      -- Linear: QB - B - QB, middle piece can't move
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:1:B",
        "2,-2,0:2:QB"
      })
      G.map = map

      local src = cubecoords.new(1, -1, 0)
      local dest = cubecoords.new(1, 0, -1)

      local result = map_module.try_move_piece_on_map(map, src, dest)

      assert.is_false(result, "Move should fail when piece can't detach")
    end)

    it("returns false when destination would disconnect from hive", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      -- Try to move queen to isolated position
      local src = cubecoords.new(0, 0, 0)
      local dest = cubecoords.new(-5, 5, 0)

      local result = map_module.try_move_piece_on_map(map, src, dest)

      assert.is_false(result, "Move to disconnected position should fail")
    end)

    it("returns false for non-beetle climbing on piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB",
        "0,1,-1:1:S"  -- Spider
      })
      G.map = map

      -- Spider trying to climb on queen
      local src = cubecoords.new(0, 1, -1)
      local dest = cubecoords.new(0, 0, 0)

      local result = map_module.try_move_piece_on_map(map, src, dest)

      assert.is_false(result, "Non-beetle cannot climb on other pieces")
    end)
  end)

  describe("flood_neighbours", function()

    it("marks all connected pieces", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB",
        "2,-2,0:1:B"
      })

      -- Clear any existing marks
      map_module.clear_all_neighbours(map)

      -- Flood from center
      local center = cubecoords.new(0, 0, 0)
      map_module.flood_neighbours(map, center)

      -- Check all pieces are marked as neighbours
      local p2_hex = map_module.get_hex(map, cubecoords.new(1, -1, 0))
      local p3_hex = map_module.get_hex(map, cubecoords.new(2, -2, 0))

      assert.is_true(p2_hex.neighbour, "Second piece should be marked")
      assert.is_true(p3_hex.neighbour, "Third piece should be marked")
    end)

    it("does not mark empty hexes", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })

      map_module.clear_all_neighbours(map)

      local center = cubecoords.new(0, 0, 0)
      map_module.flood_neighbours(map, center)

      -- Check empty hex is not marked
      local empty_hex = map_module.get_hex(map, cubecoords.new(-1, 0, 1))
      assert.is_falsy(empty_hex.neighbour, "Empty hex should not be marked")
    end)
  end)

  describe("try_self_detach", function()

    it("returns true when destination stays connected to hive", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB",
        "0,1,-1:1:B"
      })
      G.map = map

      -- Beetle can move to adjacent position that stays connected
      local src = cubecoords.new(0, 1, -1)
      local dest = cubecoords.new(1, 0, -1)

      local result = map_module.try_self_detach(map, src, dest)

      assert.is_true(result, "Move to connected position should succeed")
    end)

    it("returns false when destination has no neighbors", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      local src = cubecoords.new(0, 0, 0)
      local dest = cubecoords.new(-5, 5, 0)

      local result = map_module.try_self_detach(map, src, dest)

      assert.is_false(result, "Move to isolated position should fail")
    end)
  end)

end)
