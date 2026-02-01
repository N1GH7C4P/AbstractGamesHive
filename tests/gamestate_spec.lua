-- tests/gamestate_spec.lua
-- Unit tests for gamestate save/load functionality
--
-- Tests use a mock love.filesystem to test serialization/deserialization

-- Clear any cached gamestate module first
package.loaded["gamestate"] = nil

-- Storage for mock filesystem (must use _G for busted compatibility)
_G.mock_files = {}

-- Set up love mock BEFORE any requires (must use _G for busted compatibility)
_G.love = {
  filesystem = {
    write = function(filename, content)
      _G.mock_files[filename] = content
      return true
    end,
    read = function(filename)
      if _G.mock_files[filename] then
        return _G.mock_files[filename], nil
      else
        return nil, "File not found: " .. filename
      end
    end,
    getSaveDirectory = function()
      return "/mock/save/directory"
    end
  }
}

-- Set up G before any requires (must use _G for busted compatibility)
_G.G = {
  active_player_id = 1,
  active_piece_id = 1,
  turn_number = {1, 1},
  move_mode = 0,
  game_over = false,
  who_won = {0, 0},
  selected_piece_x = 0,
  selected_piece_y = 0,
  highlight = 0,
  camera_x = 400,
  camera_y = 300,
  camera_zoom = 1.0,
  w = 50,
  h = 50,
  animating = false,
  network = {mode = "none", connected = false},
  pillbug_special_mode = false,
  pillbug_cube = nil,
  pillbug_target_cube = nil,
  mosquito_choice_popup = false,
  mosquito_choice_options = {},
  mosquito_choice_dest = nil,
  mosquito_popup_x = 0,
  mosquito_popup_y = 0
}

-- Now require modules
local json = require("json")
local map_module = require("map")
local PlayerClass = require("player")
local Config = require("config")
local pieces_module = require("pieces")
local Globals = require("globals")
local GameState = require("gamestate")

-- Helper to reset game state for testing (preserves mock_files by default)
local function reset_game_state(clear_files)
  -- Only clear mock filesystem if explicitly requested
  if clear_files then
    _G.mock_files = {}
  end

  -- Reset game state values (use _G.G for busted compatibility)
  _G.G.active_player_id = 1
  _G.G.active_piece_id = 1
  _G.G.turn_number = {1, 1}
  _G.G.move_mode = 0
  _G.G.game_over = false
  _G.G.who_won = {0, 0}
  _G.G.selected_piece_x = 0
  _G.G.selected_piece_y = 0
  _G.G.highlight = 0
  _G.G.camera_x = 400
  _G.G.camera_y = 300
  _G.G.camera_zoom = 1.0
  _G.G.pillbug_special_mode = false
  _G.G.pillbug_cube = nil
  _G.G.pillbug_target_cube = nil
  _G.G.mosquito_choice_popup = false
  _G.G.mosquito_choice_options = {}
  _G.G.mosquito_choice_dest = nil
  _G.G.mosquito_popup_x = 0
  _G.G.mosquito_popup_y = 0

  -- Initialize pieces inventory (sets global piecesInventory)
  pieces_module.init_pieces()

  -- Initialize players
  _G.G.player = {}
  for i = 1, 2 do
    _G.G.player[i] = PlayerClass:new(i, Config.pieceInventory)
  end

  -- Initialize map
  _G.G.map = map_module.init_map()
end

describe("GameState module", function()

  before_each(function()
    reset_game_state(true)  -- Clear mock files at start of each test
  end)

  describe("save", function()

    it("saves game state to file", function()
      _G.G.active_player_id = 2
      _G.G.turn_number = {3, 2}
      _G.G.move_mode = 1

      local result = GameState.save("test_save.json")

      assert.is_true(result, "Save should succeed")
      assert.is_not_nil(_G.mock_files["test_save.json"], "File should be written")
    end)

    it("saves correct game state data", function()
      _G.G.active_player_id = 2
      _G.G.turn_number = {5, 4}
      _G.G.game_over = true
      _G.G.who_won = {1, 0}

      GameState.save("test_save.json")

      local saved_data = json.decode(_G.mock_files["test_save.json"])
      assert.are.equal(2, saved_data.game_state.active_player_id)
      assert.are.equal(5, saved_data.game_state.turn_number[1])
      assert.are.equal(4, saved_data.game_state.turn_number[2])
      assert.is_true(saved_data.game_state.game_over)
      assert.are.equal(1, saved_data.game_state.who_won[1])
      assert.are.equal(0, saved_data.game_state.who_won[2])
    end)

    it("saves camera state", function()
      _G.G.camera_x = 500
      _G.G.camera_y = 400
      _G.G.camera_zoom = 1.5

      GameState.save("test_save.json")

      local saved_data = json.decode(_G.mock_files["test_save.json"])
      assert.are.equal(500, saved_data.camera.x)
      assert.are.equal(400, saved_data.camera.y)
      assert.are.equal(1.5, saved_data.camera.zoom)
    end)

    it("saves player inventory data", function()
      -- Reduce some piece counts to simulate pieces played
      _G.G.player[1].pieces[1].inStock = 0  -- Queen played
      _G.G.player[1].pieces[2].inStock = 1  -- One ant left

      GameState.save("test_save.json")

      local saved_data = json.decode(_G.mock_files["test_save.json"])
      assert.are.equal(0, saved_data.players[1].pieces[1].inStock)
      assert.are.equal(1, saved_data.players[1].pieces[2].inStock)
    end)

    it("saves pieces on board", function()
      -- Place some pieces on the board
      local QueenBee = require("pieces.queenbee")
      local Beetle = require("pieces.beetle")

      local cube1 = cubecoords.new(0, 0, 0)
      local hex1 = map_module.get_hex(_G.G.map, cube1)
      hex1.piece = QueenBee:new(1)
      hex1.player_id = 1

      local cube2 = cubecoords.new(1, -1, 0)
      local hex2 = map_module.get_hex(_G.G.map, cube2)
      hex2.piece = Beetle:new(2)
      hex2.player_id = 2

      GameState.save("test_save.json")

      local saved_data = json.decode(_G.mock_files["test_save.json"])
      assert.are.equal(2, #saved_data.board, "Should have 2 pieces saved")

      -- Find the queen in saved data
      local queen_saved = nil
      for _, piece_data in ipairs(saved_data.board) do
        if piece_data.piece_id == 1 then -- Queen ID
          queen_saved = piece_data
          break
        end
      end

      assert.is_not_nil(queen_saved, "Queen should be in saved data")
      assert.are.equal(0, queen_saved.cube.x)
      assert.are.equal(0, queen_saved.cube.y)
      assert.are.equal(0, queen_saved.cube.z)
      assert.are.equal(1, queen_saved.player_id)
    end)

    it("saves stacked pieces with under_piece info", function()
      local QueenBee = require("pieces.queenbee")
      local Beetle = require("pieces.beetle")

      -- Create a beetle on top of a queen
      local cube = cubecoords.new(0, 0, 0)
      local hex = map_module.get_hex(_G.G.map, cube)

      local queen = QueenBee:new(1)
      local beetle = Beetle:new(2)
      beetle.under_piece = queen

      hex.piece = beetle
      hex.player_id = 2

      GameState.save("test_save.json")

      local saved_data = json.decode(_G.mock_files["test_save.json"])
      assert.are.equal(1, #saved_data.board)

      local piece_data = saved_data.board[1]
      assert.is_true(piece_data.has_under_piece)
      assert.is_not_nil(piece_data.under_piece)
      assert.are.equal(1, piece_data.under_piece.id)  -- Queen ID
      assert.are.equal(1, piece_data.under_piece.player_id)
    end)

    it("uses default filename when none provided", function()
      GameState.save()

      assert.is_not_nil(_G.mock_files["savegame.json"], "Should use default filename")
    end)
  end)

  describe("load", function()

    it("restores game state from file", function()
      -- First save a game state
      _G.G.active_player_id = 2
      _G.G.turn_number = {7, 6}
      _G.G.game_over = true
      _G.G.who_won = {0, 1}

      GameState.save("test_load.json")

      -- Reset state
      reset_game_state()
      assert.are.equal(1, _G.G.active_player_id)

      -- Load saved state
      local result = GameState.load("test_load.json")

      assert.is_true(result, "Load should succeed")
      assert.are.equal(2, _G.G.active_player_id)
      assert.are.equal(7, _G.G.turn_number[1])
      assert.are.equal(6, _G.G.turn_number[2])
      assert.is_true(_G.G.game_over)
      assert.are.equal(0, _G.G.who_won[1])
      assert.are.equal(1, _G.G.who_won[2])
    end)

    it("restores camera state", function()
      _G.G.camera_x = 600
      _G.G.camera_y = 500
      _G.G.camera_zoom = 2.0

      GameState.save("test_load.json")

      -- Reset
      _G.G.camera_x = 0
      _G.G.camera_y = 0
      _G.G.camera_zoom = 0.8

      GameState.load("test_load.json")

      assert.are.equal(600, _G.G.camera_x)
      assert.are.equal(500, _G.G.camera_y)
      assert.are.equal(2.0, _G.G.camera_zoom)
    end)

    it("restores player inventory", function()
      _G.G.player[1].pieces[1].inStock = 0
      _G.G.player[2].pieces[1].inStock = 0

      GameState.save("test_load.json")

      -- Reset inventory
      reset_game_state()

      GameState.load("test_load.json")

      assert.are.equal(0, _G.G.player[1].pieces[1].inStock)
      assert.are.equal(0, _G.G.player[2].pieces[1].inStock)
    end)

    it("restores pieces on board", function()
      local QueenBee = require("pieces.queenbee")
      local Beetle = require("pieces.beetle")

      -- Place pieces
      local cube1 = cubecoords.new(0, 0, 0)
      local hex1 = map_module.get_hex(_G.G.map, cube1)
      hex1.piece = QueenBee:new(1)
      hex1.player_id = 1

      local cube2 = cubecoords.new(1, -1, 0)
      local hex2 = map_module.get_hex(_G.G.map, cube2)
      hex2.piece = Beetle:new(2)
      hex2.player_id = 2

      GameState.save("test_load.json")

      -- Clear and reinit
      reset_game_state()

      -- Verify board is empty after reinit
      local check_hex = map_module.get_hex(_G.G.map, cubecoords.new(0, 0, 0))
      assert.is_nil(check_hex.piece, "Board should be empty before load")

      GameState.load("test_load.json")

      -- Verify pieces restored
      local restored_hex1 = map_module.get_hex(_G.G.map, cubecoords.new(0, 0, 0))
      assert.is_not_nil(restored_hex1.piece)
      assert.are.equal("Queen bee", restored_hex1.piece.name)
      assert.are.equal(1, restored_hex1.player_id)

      local restored_hex2 = map_module.get_hex(_G.G.map, cubecoords.new(1, -1, 0))
      assert.is_not_nil(restored_hex2.piece)
      assert.are.equal("Beetle", restored_hex2.piece.name)
      assert.are.equal(2, restored_hex2.player_id)
    end)

    it("restores stacked pieces correctly", function()
      local QueenBee = require("pieces.queenbee")
      local Beetle = require("pieces.beetle")

      -- Create a beetle on queen
      local cube = cubecoords.new(0, 0, 0)
      local hex = map_module.get_hex(_G.G.map, cube)

      local queen = QueenBee:new(1)
      local beetle = Beetle:new(2)
      beetle.under_piece = queen

      hex.piece = beetle
      hex.player_id = 2

      GameState.save("test_load.json")

      -- Clear and reinit
      reset_game_state()

      GameState.load("test_load.json")

      -- Verify stack restored
      local restored_hex = map_module.get_hex(_G.G.map, cubecoords.new(0, 0, 0))
      assert.is_not_nil(restored_hex.piece)
      assert.are.equal("Beetle", restored_hex.piece.name)
      assert.are.equal(2, restored_hex.player_id)

      assert.is_not_nil(restored_hex.piece.under_piece)
      assert.are.equal("Queen bee", restored_hex.piece.under_piece.name)
      assert.are.equal(1, restored_hex.piece.under_piece.player_id)
    end)

    it("returns false for non-existent file", function()
      local result = GameState.load("nonexistent.json")

      assert.is_false(result, "Load should fail for missing file")
    end)

    it("resets UI state after loading", function()
      GameState.save("test_load.json")

      -- Set some UI state that should be reset
      _G.G.pillbug_special_mode = true
      _G.G.pillbug_cube = {x=1, y=0, z=-1}
      _G.G.mosquito_choice_popup = true
      _G.G.move_mode = 2

      GameState.load("test_load.json")

      -- UI state should be reset by Globals.reset_ui_state
      assert.is_false(_G.G.pillbug_special_mode)
      assert.is_nil(_G.G.pillbug_cube)
      assert.is_false(_G.G.mosquito_choice_popup)
      assert.are.equal(0, _G.G.move_mode)
    end)

    it("uses default filename when none provided", function()
      GameState.save()  -- Saves to savegame.json

      reset_game_state()

      local result = GameState.load()  -- Loads from savegame.json

      assert.is_true(result)
    end)
  end)

  describe("round-trip integrity", function()

    it("preserves complete game state through save/load cycle", function()
      local QueenBee = require("pieces.queenbee")
      local Beetle = require("pieces.beetle")
      local Spider = require("pieces.spider")

      -- Set up complex game state
      _G.G.active_player_id = 2
      _G.G.turn_number = {10, 9}
      _G.G.camera_x = 750
      _G.G.camera_y = 550
      _G.G.camera_zoom = 1.25

      -- Place several pieces
      local placements = {
        {cube = {0, 0, 0}, piece = QueenBee, player = 1},
        {cube = {1, -1, 0}, piece = Beetle, player = 1},
        {cube = {-1, 1, 0}, piece = Spider, player = 2},
        {cube = {0, 1, -1}, piece = QueenBee, player = 2},
      }

      for _, p in ipairs(placements) do
        local cube = cubecoords.new(p.cube[1], p.cube[2], p.cube[3])
        local hex = map_module.get_hex(_G.G.map, cube)
        hex.piece = p.piece:new(p.player)
        hex.player_id = p.player
      end

      -- Reduce inventory
      _G.G.player[1].pieces[1].inStock = 0  -- Queen played
      _G.G.player[2].pieces[1].inStock = 0  -- Queen played

      GameState.save("roundtrip.json")

      -- Completely reinitialize
      reset_game_state()

      GameState.load("roundtrip.json")

      -- Verify everything
      assert.are.equal(2, _G.G.active_player_id)
      assert.are.equal(10, _G.G.turn_number[1])
      assert.are.equal(9, _G.G.turn_number[2])
      assert.are.equal(750, _G.G.camera_x)
      assert.are.equal(550, _G.G.camera_y)
      assert.are.equal(1.25, _G.G.camera_zoom)
      assert.are.equal(0, _G.G.player[1].pieces[1].inStock)
      assert.are.equal(0, _G.G.player[2].pieces[1].inStock)

      -- Verify pieces
      local hex1 = map_module.get_hex(_G.G.map, cubecoords.new(0, 0, 0))
      assert.are.equal("Queen bee", hex1.piece.name)
      assert.are.equal(1, hex1.player_id)

      local hex2 = map_module.get_hex(_G.G.map, cubecoords.new(1, -1, 0))
      assert.are.equal("Beetle", hex2.piece.name)

      local hex3 = map_module.get_hex(_G.G.map, cubecoords.new(-1, 1, 0))
      assert.are.equal("Spider", hex3.piece.name)

      local hex4 = map_module.get_hex(_G.G.map, cubecoords.new(0, 1, -1))
      assert.are.equal("Queen bee", hex4.piece.name)
      assert.are.equal(2, hex4.player_id)
    end)
  end)
end)
