-- tests/game_spec.lua
-- Unit tests for game module
--
-- Tests cover:
-- - checkIfWin: Queen surrounded detection and win/tie conditions
-- - selectPieceOnMap: Piece selection validation
-- - pass_turn: Turn switching and movement flag clearing

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_hex_at = test_helpers.get_hex_at

-- Import game module after test_helpers initializes globals
local Game = require("game")

describe("Game module", function()

  describe("checkIfWin", function()

    it("detects when player 1 queen is surrounded", function()
      -- Visual reference (queen at center surrounded by 6 pieces):
      --          B2       <- N
      --       B2    B2    <- NW, NE
      --         QB1       <- Queen at origin
      --       B2    B2    <- SW, SE
      --          B2       <- S

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Player 1 Queen at origin
        "0,-1,1:2:B",      -- N
        "-1,0,1:2:B",      -- NW
        "1,-1,0:2:B",      -- NE
        "-1,1,0:2:B",      -- SW
        "1,0,-1:2:B",      -- SE
        "0,1,-1:2:B"       -- S
      })

      -- Reset win state
      G.game_over = false
      G.who_won = {0, 0}

      Game.checkIfWin(map, G.w, G.h)

      assert.is_true(G.game_over, "Game should be over when queen is surrounded")
      assert.are.equal(1, G.who_won[1], "Player 1 should have lost (their queen surrounded)")
      assert.are.equal(0, G.who_won[2], "Player 2 should not have lost")
    end)

    it("detects when player 2 queen is surrounded", function()
      -- Player 2 queen surrounded by player 1 pieces
      local map = setup_test_map({
        "0,0,0:2:QB",      -- Player 2 Queen at origin
        "0,-1,1:1:B",      -- N
        "-1,0,1:1:B",      -- NW
        "1,-1,0:1:B",      -- NE
        "-1,1,0:1:B",      -- SW
        "1,0,-1:1:B",      -- SE
        "0,1,-1:1:B"       -- S
      })

      G.game_over = false
      G.who_won = {0, 0}

      Game.checkIfWin(map, G.w, G.h)

      assert.is_true(G.game_over, "Game should be over when queen is surrounded")
      assert.are.equal(0, G.who_won[1], "Player 1 should not have lost")
      assert.are.equal(1, G.who_won[2], "Player 2 should have lost (their queen surrounded)")
    end)

    it("detects a tie when both queens are surrounded", function()
      -- Both queens surrounded (can happen in edge cases)
      -- Queen 1 at origin, Queen 2 nearby, both surrounded
      local map = setup_test_map({
        -- Player 1 Queen surrounded
        "0,0,0:1:QB",
        "0,-1,1:2:B",
        "-1,0,1:2:B",
        "1,-1,0:2:B",
        "-1,1,0:2:B",
        "1,0,-1:2:B",
        "0,1,-1:2:B",
        -- Player 2 Queen surrounded (adjacent to the cluster)
        "2,-1,-1:2:QB",
        "2,-2,0:1:B",
        "3,-2,-1:1:B",
        "3,-1,-2:1:B",
        "2,0,-2:1:B",
        "1,0,-1:1:B",  -- This overlaps, so let's adjust
      })

      -- Actually let's create a simpler tie scenario
      -- with two separate surrounded queens
      local map2 = setup_test_map({
        -- Player 1 Queen at origin, surrounded
        "0,0,0:1:QB",
        "0,-1,1:2:B",
        "-1,0,1:2:B",
        "1,-1,0:2:B",
        "-1,1,0:2:B",
        "1,0,-1:2:B",
        "0,1,-1:2:B",
        -- Player 2 Queen far away, also surrounded
        "10,0,-10:2:QB",
        "10,-1,-9:1:B",
        "9,0,-9:1:B",
        "11,-1,-10:1:B",
        "9,1,-10:1:B",
        "11,0,-11:1:B",
        "10,1,-11:1:B"
      })

      G.game_over = false
      G.who_won = {0, 0}

      Game.checkIfWin(map2, G.w, G.h)

      assert.is_true(G.game_over, "Game should be over when both queens surrounded")
      assert.are.equal(1, G.who_won[1], "Player 1 should have lost (tie)")
      assert.are.equal(1, G.who_won[2], "Player 2 should have lost (tie)")
    end)

    it("does not end game when queen has open neighbors", function()
      -- Queen with only 5 neighbors (not surrounded)
      local map = setup_test_map({
        "0,0,0:1:QB",      -- Player 1 Queen at origin
        "0,-1,1:2:B",      -- N
        "-1,0,1:2:B",      -- NW
        "1,-1,0:2:B",      -- NE
        "-1,1,0:2:B",      -- SW
        "1,0,-1:2:B"       -- SE (missing S)
      })

      G.game_over = false
      G.who_won = {0, 0}

      Game.checkIfWin(map, G.w, G.h)

      assert.is_false(G.game_over, "Game should NOT be over with only 5 neighbors")
      assert.are.equal(0, G.who_won[1])
      assert.are.equal(0, G.who_won[2])
    end)

    it("detects queen under a beetle stack as surrounded", function()
      -- Queen at origin with beetle on top, and all neighbors occupied
      -- First set up the map
      local map = setup_test_map({
        "0,0,0:1:QB",      -- Player 1 Queen at origin (will have beetle on top)
        "0,-1,1:2:B",      -- N
        "-1,0,1:2:B",      -- NW
        "1,-1,0:2:B",      -- NE
        "-1,1,0:2:B",      -- SW
        "1,0,-1:2:B",      -- SE
        "0,1,-1:2:B"       -- S
      })

      -- Now stack a beetle on top of the queen
      local queen_hex = get_hex_at(map, "0,0,0")
      local Beetle = require("pieces.beetle")
      local beetle_on_top = Beetle:new(2)
      beetle_on_top.under_piece = queen_hex.piece
      queen_hex.piece = beetle_on_top
      queen_hex.player_id = 2

      G.game_over = false
      G.who_won = {0, 0}

      Game.checkIfWin(map, G.w, G.h)

      -- The queen is still surrounded (beetle on top counts as part of surrounding)
      assert.is_true(G.game_over, "Game should be over - queen under beetle is surrounded")
      assert.are.equal(1, G.who_won[1], "Player 1 should have lost")
    end)

    it("handles empty board without error", function()
      local map = setup_test_map({})

      G.game_over = false
      G.who_won = {0, 0}

      -- Should not error on empty board
      Game.checkIfWin(map, G.w, G.h)

      assert.is_false(G.game_over)
      assert.are.equal(0, G.who_won[1])
      assert.are.equal(0, G.who_won[2])
    end)
  end)

  describe("selectPieceOnMap", function()

    it("returns true when selecting own piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })

      G.active_player_id = 1
      local cube = {x=0, y=0, z=0}

      local result = Game.selectPieceOnMap(map, cube, G.active_player_id)

      assert.is_true(result, "Should be able to select own piece")
    end)

    it("returns false when selecting opponent piece", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })

      G.active_player_id = 1
      local cube = {x=1, y=-1, z=0}  -- Player 2's queen

      local result = Game.selectPieceOnMap(map, cube, G.active_player_id)

      assert.is_false(result, "Should NOT be able to select opponent's piece")
    end)

    it("returns false when selecting empty hex", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })

      G.active_player_id = 1
      local cube = {x=1, y=-1, z=0}  -- Empty hex

      local result = Game.selectPieceOnMap(map, cube, G.active_player_id)

      assert.is_false(result, "Should NOT be able to select empty hex")
    end)

    it("returns false for non-existent hex", function()
      local map = setup_test_map({
        "0,0,0:1:QB"
      })

      G.active_player_id = 1
      local cube = {x=100, y=-100, z=0}  -- Way outside map

      local result = Game.selectPieceOnMap(map, cube, G.active_player_id)

      assert.is_false(result, "Should return false for non-existent hex")
    end)
  end)

  describe("pass_turn", function()

    it("switches from player 1 to player 2", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      G.active_player_id = 1
      G.move_mode = 1
      G.turn_number = {1, 1}

      Game.pass_turn()

      assert.are.equal(2, G.active_player_id, "Should switch to player 2")
      assert.are.equal(0, G.move_mode, "Move mode should reset to 0")
      assert.are.equal(2, G.turn_number[1], "Player 1 turn count should increment")
      assert.are.equal(1, G.turn_number[2], "Player 2 turn count should stay same")
    end)

    it("switches from player 2 to player 1", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:2:QB"
      })
      G.map = map

      G.active_player_id = 2
      G.move_mode = 1
      G.turn_number = {2, 1}

      Game.pass_turn()

      assert.are.equal(1, G.active_player_id, "Should switch to player 1")
      assert.are.equal(0, G.move_mode, "Move mode should reset to 0")
      assert.are.equal(2, G.turn_number[1], "Player 1 turn count should stay same")
      assert.are.equal(2, G.turn_number[2], "Player 2 turn count should increment")
    end)

    it("clears has_moved_last_turn flags for new active player", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:1:B",
        "2,-1,-1:2:QB",
        "3,-1,-2:2:B"
      })
      G.map = map

      -- Set moved flags on player 2's pieces (simulating they moved last turn)
      local p2_queen = get_hex_at(map, "2,-1,-1")
      local p2_beetle = get_hex_at(map, "3,-1,-2")
      p2_queen.piece.has_moved_last_turn = true
      p2_beetle.piece.has_moved_last_turn = true

      -- Player 1 passes, player 2's turn starts
      G.active_player_id = 1
      G.turn_number = {1, 1}

      Game.pass_turn()

      -- Player 2's flags should be cleared (their new turn is starting)
      assert.is_falsy(p2_queen.piece.has_moved_last_turn,
        "Player 2 queen's moved flag should be cleared")
      assert.is_falsy(p2_beetle.piece.has_moved_last_turn,
        "Player 2 beetle's moved flag should be cleared")
    end)

    it("does not clear opponent's has_moved_last_turn flags", function()
      local map = setup_test_map({
        "0,0,0:1:QB",
        "1,-1,0:1:B",
        "2,-1,-1:2:QB"
      })
      G.map = map

      -- Set moved flag on player 1's beetle
      local p1_beetle = get_hex_at(map, "1,-1,0")
      p1_beetle.piece.has_moved_last_turn = true

      -- Player 1 passes, player 2's turn starts
      G.active_player_id = 1
      G.turn_number = {1, 1}

      Game.pass_turn()

      -- Player 1's flags should NOT be cleared yet (they moved this turn)
      assert.is_true(p1_beetle.piece.has_moved_last_turn,
        "Player 1's moved flag should remain until their next turn")
    end)
  end)
end)
