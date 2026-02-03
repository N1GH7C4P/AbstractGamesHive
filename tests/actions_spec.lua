-- tests/actions_spec.lua
-- Unit tests for actions module
--
-- Tests cover:
-- - select_piece_on_map: Piece selection for movement
-- - move_piece: Piece movement execution
-- - select_next_piece / select_previous_piece: Inventory navigation
-- - select_piece_by_id: Direct inventory selection
-- - enter_pillbug_mode: Pillbug special ability setup
-- - execute_drop: Pillbug drop execution
-- - execute_mosquito_pillbug_choice: Mosquito pillbug mimicry
--
-- Note: place_piece tests are omitted as they require full game initialization

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_hex_at = test_helpers.get_hex_at

-- Import actions module after test_helpers initializes globals
local Actions = require("actions")
local cubecoords = require("cubecoords")
local map_module = require("map")

describe("Actions module", function()

  describe("select_piece_on_map", function()

    it("selects own piece successfully", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      local cube = cubecoords.new(0, 0, 0)
      local result = Actions.select_piece_on_map(cube, 1)

      assert.is_true(result, "Selection should succeed")
    end)

    it("returns false when selecting opponent piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      local cube = cubecoords.new(1, -1, 0)  -- Player 2's queen
      local result = Actions.select_piece_on_map(cube, 1)

      assert.is_false(result, "Selection of opponent piece should fail")
    end)

    it("returns false for empty hex", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })
      G.map = map

      local cube = cubecoords.new(1, -1, 0)  -- Empty hex
      local result = Actions.select_piece_on_map(cube, 1)

      assert.is_false(result, "Selection of empty hex should fail")
    end)

    it("enables move mode when queen is placed", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map
      G.move_mode = 0

      local cube = cubecoords.new(0, 0, 0)
      Actions.select_piece_on_map(cube, 1)

      assert.are.equal(1, G.move_mode, "Move mode should be enabled when queen is placed")
    end)
  end)

  describe("move_piece", function()

    it("returns false for move that breaks hive", function()
      -- Queen alone cannot move (would break hive)
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      local src = cubecoords.new(0, 0, 0)
      local dest = cubecoords.new(-1, 0, 1)

      local result = Actions.move_piece(src, dest)

      assert.is_false(result, "Move that breaks hive should fail")
    end)

    it("returns false for invalid destination", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      -- Try to move queen to non-adjacent position
      local src = cubecoords.new(0, 0, 0)
      local dest = cubecoords.new(5, -5, 0)

      local result = Actions.move_piece(src, dest)

      assert.is_false(result, "Invalid move should fail")
    end)
  end)

  describe("select_next_piece", function()

    it("increments active_piece_id", function()
      -- Setup minimal globals for inventory navigation
      setup_test_map({})  -- Initializes G
      G.active_piece_id = 1

      local result = Actions.select_next_piece()

      assert.is_true(result, "Should return true when changed")
      assert.are.equal(2, G.active_piece_id)
    end)

    it("increments through multiple pieces", function()
      setup_test_map({})
      G.active_piece_id = 1

      Actions.select_next_piece()
      Actions.select_next_piece()
      Actions.select_next_piece()

      assert.are.equal(4, G.active_piece_id)
    end)

    it("returns false at max piece", function()
      setup_test_map({})
      G.active_piece_id = #Config.pieceInventory

      local result = Actions.select_next_piece()

      assert.is_false(result, "Should return false at max")
      assert.are.equal(#Config.pieceInventory, G.active_piece_id, "Should not exceed max")
    end)
  end)

  describe("select_previous_piece", function()

    it("decrements active_piece_id", function()
      setup_test_map({})
      G.active_piece_id = 3

      local result = Actions.select_previous_piece()

      assert.is_true(result, "Should return true when changed")
      assert.are.equal(2, G.active_piece_id)
    end)

    it("decrements through multiple pieces", function()
      setup_test_map({})
      G.active_piece_id = 5

      Actions.select_previous_piece()
      Actions.select_previous_piece()
      Actions.select_previous_piece()

      assert.are.equal(2, G.active_piece_id)
    end)

    it("returns false at first piece", function()
      setup_test_map({})
      G.active_piece_id = 1

      local result = Actions.select_previous_piece()

      assert.is_false(result, "Should return false at minimum")
      assert.are.equal(1, G.active_piece_id, "Should not go below 1")
    end)
  end)

  describe("select_piece_by_id", function()

    it("sets active_piece_id directly", function()
      setup_test_map({})
      G.active_piece_id = 1

      Actions.select_piece_by_id(5)

      assert.are.equal(5, G.active_piece_id)
    end)

    it("allows setting to any value", function()
      setup_test_map({})
      G.active_piece_id = 3

      Actions.select_piece_by_id(1)

      assert.are.equal(1, G.active_piece_id)
    end)
  end)

  describe("enter_pillbug_mode", function()

    it("returns drop locations for valid pillbug setup", function()
      -- Pillbug at center with adjacent piece to pick up
      local map = setup_test_map({
        "0,0,0:1:P",      -- Pillbug
        "1,-1,0:2:B",     -- Target beetle (NE)
        "-1,1,0:1:QB"     -- Queen to keep hive connected
      })
      G.map = map

      local src_cube = cubecoords.new(0, 0, 0)
      local target_cube = cubecoords.new(1, -1, 0)

      local drop_locations = Actions.enter_pillbug_mode(src_cube, target_cube)

      assert.is_table(drop_locations, "Should return drop locations table")
    end)

    it("returns empty table when source hex has no piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })
      G.map = map

      local src_cube = cubecoords.new(1, -1, 0)  -- Empty hex
      local target_cube = cubecoords.new(0, 0, 0)

      local drop_locations = Actions.enter_pillbug_mode(src_cube, target_cube)

      assert.are.equal(0, #drop_locations, "Should return empty table")
    end)

    it("marks drop locations on the map", function()
      local map = setup_test_map({
        "0,0,0:1:P",      -- Pillbug
        "1,-1,0:2:B",     -- Target beetle
        "-1,1,0:1:QB"     -- Queen for connectivity
      })
      G.map = map

      local src_cube = cubecoords.new(0, 0, 0)
      local target_cube = cubecoords.new(1, -1, 0)

      local drop_locations = Actions.enter_pillbug_mode(src_cube, target_cube)

      -- Check that at least some hexes are marked with can_drop
      local marked_count = 0
      for _, dest_cube in ipairs(drop_locations) do
        local hex = map_module.get_hex(map, dest_cube)
        if hex and hex.can_drop then
          marked_count = marked_count + 1
        end
      end

      assert.are.equal(#drop_locations, marked_count, "All drop locations should be marked")
    end)
  end)

  describe("execute_drop", function()

    it("returns false when source has no piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })
      G.map = map

      local src_cube = cubecoords.new(1, -1, 0)  -- Empty
      local target_cube = cubecoords.new(0, 0, 0)
      local drop_cube = cubecoords.new(-1, 0, 1)

      local result = Actions.execute_drop(src_cube, target_cube, drop_cube)

      assert.is_false(result, "Drop should fail with no source piece")
    end)

    it("returns false when source piece has no execute_drop method", function()
      -- Queen doesn't have execute_drop
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:B"
      })
      G.map = map

      local src_cube = cubecoords.new(0, 0, 0)
      local target_cube = cubecoords.new(1, -1, 0)
      local drop_cube = cubecoords.new(-1, 0, 1)

      local result = Actions.execute_drop(src_cube, target_cube, drop_cube)

      assert.is_false(result, "Drop should fail for piece without execute_drop")
    end)
  end)

  describe("execute_mosquito_pillbug_choice", function()

    it("returns drop locations when mosquito is adjacent to pillbug", function()
      -- Mosquito adjacent to pillbug with pickable piece
      local map = setup_test_map({
        "0,0,0:1:M",      -- Mosquito
        "1,-1,0:1:P",     -- Pillbug to copy ability from
        "-1,0,1:2:B",     -- Potential target to pick up
        "-1,1,0:1:QB"     -- Queen for connectivity
      })
      G.map = map

      local src_cube = cubecoords.new(0, 0, 0)
      local target_cube = cubecoords.new(-1, 0, 1)

      local drop_locations = Actions.execute_mosquito_pillbug_choice(src_cube, target_cube)

      assert.is_table(drop_locations, "Should return drop locations table")
    end)

    it("returns empty table when source has no piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })
      G.map = map

      local src_cube = cubecoords.new(1, -1, 0)  -- Empty hex
      local target_cube = cubecoords.new(0, 0, 0)

      local drop_locations = Actions.execute_mosquito_pillbug_choice(src_cube, target_cube)

      assert.are.equal(0, #drop_locations, "Should return empty table")
    end)
  end)

  describe("execute_mosquito_beetle_choice", function()

    it("returns boolean result", function()
      -- Mosquito adjacent to beetle
      local map = setup_test_map({
        "0,0,0:1:M",      -- Mosquito
        "1,-1,0:1:B",     -- Beetle to copy
        "-1,0,1:2:QB",    -- Opponent queen
        "-1,1,0:1:QB"     -- Own queen for connectivity
      })
      G.map = map

      local src = cubecoords.new(0, 0, 0)
      local dest = cubecoords.new(1, -1, 0)  -- Climb onto beetle

      local result = Actions.execute_mosquito_beetle_choice(src, dest)

      assert.is_boolean(result, "Should return a boolean")
    end)
  end)

end)
