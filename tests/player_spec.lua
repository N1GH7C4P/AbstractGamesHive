-- tests/player_spec.lua
-- Unit tests for player module
--
-- Tests cover:
-- - Player:new: Player creation
-- - Player:getPieceStock: Get stock count for a piece
-- - Player:removePieceFromStock: Remove piece from inventory
-- - Player:addPieceToStock: Add piece to inventory
-- - Player:getPieceInfo: Get piece information
-- - Player:getAllPieces: Get all pieces
-- - Legacy global functions

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map

-- Import pieces module to set up piecesInventory global
local pieces = require("pieces")

-- Import player module (sets up global Player class)
require("player")

-- Helper to initialize pieces inventory if not already done
local function ensure_pieces_inventory()
  if not piecesInventory then
    pieces.init_pieces()
  end
end

describe("Player module", function()

  describe("Player:new", function()

    it("creates a player with correct id", function()
      setup_test_map({})
      ensure_pieces_inventory()

      local player = Player:new(1, Config.pieceInventory)

      assert.are.equal(1, player.id)
    end)

    it("creates a player with pieces from config", function()
      setup_test_map({})
      ensure_pieces_inventory()

      local player = Player:new(1, Config.pieceInventory)

      assert.is_table(player.pieces)
      assert.are.equal(#Config.pieceInventory, #player.pieces)
    end)

    it("initializes piece stock from config counts", function()
      setup_test_map({})
      ensure_pieces_inventory()

      local player = Player:new(1, Config.pieceInventory)

      -- Queen bee should have count 1
      assert.are.equal(1, player.pieces[1].inStock)
      -- Beetles should have count 2
      assert.are.equal(2, player.pieces[2].inStock)
    end)
  end)

  describe("Player:getPieceStock", function()

    it("returns correct stock for valid piece", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local stock = player:getPieceStock(1)  -- Queen

      assert.are.equal(1, stock)
    end)

    it("returns 0 for invalid piece id", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local stock = player:getPieceStock(999)

      assert.are.equal(0, stock)
    end)

    it("returns updated stock after removal", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      player:removePieceFromStock(2)  -- Remove a beetle
      local stock = player:getPieceStock(2)

      assert.are.equal(1, stock)  -- Was 2, now 1
    end)
  end)

  describe("Player:removePieceFromStock", function()

    it("decrements stock and returns true", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)
      local initial_stock = player:getPieceStock(2)

      local result = player:removePieceFromStock(2)

      assert.is_true(result)
      assert.are.equal(initial_stock - 1, player:getPieceStock(2))
    end)

    it("returns false when stock is 0", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      -- Remove all queens (only 1)
      player:removePieceFromStock(1)
      local result = player:removePieceFromStock(1)

      assert.is_false(result)
    end)

    it("returns false for invalid piece id", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local result = player:removePieceFromStock(999)

      assert.is_false(result)
    end)

    it("can remove multiple pieces", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      -- Grasshoppers have count 3
      player:removePieceFromStock(3)
      player:removePieceFromStock(3)
      player:removePieceFromStock(3)

      assert.are.equal(0, player:getPieceStock(3))
    end)
  end)

  describe("Player:addPieceToStock", function()

    it("increments stock and returns true", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)
      local initial_stock = player:getPieceStock(1)

      local result = player:addPieceToStock(1)

      assert.is_true(result)
      assert.are.equal(initial_stock + 1, player:getPieceStock(1))
    end)

    it("returns false for invalid piece id", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local result = player:addPieceToStock(999)

      assert.is_false(result)
    end)

    it("can restore removed pieces", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)
      local initial_stock = player:getPieceStock(2)

      player:removePieceFromStock(2)
      player:addPieceToStock(2)

      assert.are.equal(initial_stock, player:getPieceStock(2))
    end)
  end)

  describe("Player:getPieceInfo", function()

    it("returns piece info for valid id", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local info = player:getPieceInfo(1)

      assert.is_table(info)
      assert.are.equal(1, info.id)
      assert.is_string(info.name)
    end)

    it("returns nil for invalid id", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local info = player:getPieceInfo(999)

      assert.is_nil(info)
    end)

    it("includes template in piece info", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local info = player:getPieceInfo(1)

      assert.is_not_nil(info.template)
    end)
  end)

  describe("Player:getAllPieces", function()

    it("returns all pieces table", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local all_pieces = player:getAllPieces()

      assert.is_table(all_pieces)
      assert.are.equal(#Config.pieceInventory, #all_pieces)
    end)

    it("returns same reference as internal pieces", function()
      setup_test_map({})
      ensure_pieces_inventory()
      local player = Player:new(1, Config.pieceInventory)

      local all_pieces = player:getAllPieces()

      assert.are.equal(player.pieces, all_pieces)
    end)
  end)

  describe("Legacy global functions", function()

    -- Note: These functions require full game initialization with piecesInventory
    -- which is set up by the pieces module. We test them through the test_helpers
    -- setup which initializes the required globals.

    describe("getPiecesInStock", function()

      it("returns 0 for invalid player", function()
        setup_test_map({})
        -- setup_test_map creates minimal G.player without full Player instances
        G.player = {}

        local stock = getPiecesInStock(99, 1)

        assert.are.equal(0, stock)
      end)

      it("returns 0 when player has no getPieceStock method", function()
        setup_test_map({})
        -- G.player from setup_test_map doesn't have proper Player methods

        local stock = getPiecesInStock(1, 1)

        -- Should return 0 because minimal player doesn't have getPieceStock
        assert.are.equal(0, stock)
      end)
    end)

    describe("removePieceFromStock", function()

      it("handles invalid player gracefully", function()
        setup_test_map({})
        G.player = {}

        -- Should not error
        removePieceFromStock(99, 1)

        assert.is_true(true)  -- If we got here, no error occurred
      end)

      it("handles player without removePieceFromStock method gracefully", function()
        setup_test_map({})
        -- G.player from setup_test_map doesn't have proper Player methods

        -- Should not error even with minimal player
        removePieceFromStock(1, 1)

        assert.is_true(true)  -- If we got here, no error occurred
      end)
    end)
  end)

end)
