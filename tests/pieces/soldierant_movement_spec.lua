-- tests/pieces/soldierant_movement_spec.lua
-- Integration tests for Soldier Ant movement
--
-- DIRECTION REFERENCE (flat-topped hexagons):
--        N (0,-1,1)
--       / \
--  NW  /   \  NE
-- (-1,0,1) (1,-1,0)
--     |     |
--  SW |     | SE
-- (-1,1,0) (1,0,-1)
--       \ /
--     S (0,1,-1)
--
-- SOLDIER ANT RULES:
-- - Moves any number of spaces around the hive edge (unlimited movement)
-- - Must stay adjacent to at least one piece at all times
-- - Cannot move through tight gaps (Freedom of Movement rule)
-- - Uses BFS to find all reachable empty hexes
--
-- NOTE: Piece code "A" = Soldier Ant. Other pieces use QB, B, G, S, etc.

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Soldier Ant movement", function()

  describe("Unlimited movement", function()
    it("can move to adjacent empty hex", function()
      -- Visual reference:
      --          .
      --       QB1   .
      --         A1
      --       .     .
      --          .
      --
      -- Soldier ant at origin, queen at NW

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "-1,0,1:1:QB"      -- Queen at NW (keeps hive connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant can move to N (adjacent to NW queen)
      assert_has_move(moves, {x=0, y=-1, z=1})
      -- Can also move around the hive edge
      assert.is_true(#moves > 0, "Soldier ant should have moves")
    end)

    it("can move many spaces around hive", function()
      -- Visual reference (line of beetles):
      --       .   .   .   .   .   .
      --     .  B1  B1  B1  B1  B1  .
      --       .  A1   .   .   .   .
      --
      -- Soldier ant can walk around the entire line

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:B",      -- Beetle at N
        "1,-2,1:1:B",      -- Beetle NE of N
        "2,-3,1:1:B",      -- Continue line
        "3,-4,1:1:B",      -- Continue line
        "4,-5,1:1:B"       -- End of line
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant can reach positions all around the line
      assert.is_true(#moves >= 10, "Soldier ant should have many moves around a line")
    end)

    it("can reach far positions in single move", function()
      -- Visual reference (long line):
      --       .   .   .   .   .   .   .   .
      --     .  B1  B1  B1  B1  B1  B1  B1  .
      --       A1   .   .   .   .   .   .   .
      --
      -- Soldier ant at one end, can reach the other end

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:B",      -- Beetle at N
        "1,-2,1:1:B",      -- Continue line NE
        "2,-3,1:1:B",
        "3,-4,1:1:B",
        "4,-5,1:1:B",
        "5,-6,1:1:B",
        "6,-7,1:1:B"       -- Far end
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Should be able to reach position at the far end
      assert_has_move(moves, {x=7, y=-7, z=0})   -- Beyond the far end
    end)
  end)

  describe("Movement constraints", function()
    it("must stay adjacent to hive at all times", function()
      -- Soldier ant cannot move to positions not adjacent to any piece

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:QB"      -- Single queen at N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant can only move to positions adjacent to the queen
      -- Cannot move to far positions not adjacent to any piece
      assert_no_move(moves, {x=0, y=2, z=-2})   -- Far S (not adjacent to anything)
    end)

    it("cannot squeeze through blocked gap", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (blocking gap to origin's S)
      --          A1
      --       B1    B1    <- SW, SE (blocking gap)
      --          .        <- S (blocked by SW+SE gap)
      --
      -- Note: All beetles must be connected for hive cohesion

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW
        "1,-1,0:1:B",      -- Beetle at NE
        "-1,1,0:1:B",      -- Beetle at SW
        "1,0,-1:1:B"       -- Beetle at SE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant surrounded, gaps blocked
      -- S is blocked by SW+SE gap
      assert_no_move(moves, {x=0, y=1, z=-1})
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     B2
      --          A1
      --       B1    .
      --          .
      --
      -- Soldier ant is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant (bridge piece)
        "-1,1,0:1:B",      -- Beetle at SW
        "1,-1,0:2:B"       -- Enemy beetle at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant cannot move - it would split the hive
      assert_move_count(moves, 0)
    end)

    it("can move when hive remains connected", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    .     <- NW (connected to N)
      --          A1
      --       B1    .     <- SW (connected to NW)
      --          B1       <- S (connected to SW)
      --
      -- Soldier ant can move because beetles form connected chain

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (adjacent to N)
        "-1,1,0:1:B",      -- Beetle at SW (adjacent to NW)
        "0,1,-1:1:B"       -- Beetle at S (adjacent to SW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant can move because beetles remain connected
      assert.is_true(#moves > 0, "Soldier ant should be able to move")
    end)
  end)

  describe("Movement around obstacles", function()
    it("can navigate around a line of pieces", function()
      -- Visual reference (beetles form a line, not surrounding):
      --          .
      --       B1    .      <- NW only (not blocking NE exit)
      --          A1
      --       B1    .      <- SW only (not blocking SE exit)
      --          B1        <- S (connecting NW-SW-S)
      --
      -- Soldier ant can exit via NE or SE (not blocked)

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "-1,0,1:1:B",      -- Beetle at NW
        "-1,1,0:1:B",      -- Beetle at SW (connected to NW)
        "0,1,-1:1:B"       -- Beetle at S (connected to SW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant should have moves around the line
      assert.is_true(#moves >= 5, "Soldier ant should navigate around line")
    end)
  end)

  describe("Edge cases", function()
    it("handles minimal hive (ant + 1 piece)", function()
      -- With just 1 other piece, ant has limited movement

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:QB"      -- Single queen at N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant can move around the single queen
      -- Should be able to reach positions adjacent to the queen
      assert.is_true(#moves > 0, "Soldier ant should have moves with minimal hive")
    end)

    it("can reach all edge positions in complex hive", function()
      -- Visual reference (L-shaped hive - not surrounding ant):
      --          B1       <- N
      --       B1    .     <- NW (connected to N), NE empty (exit route)
      --          A1
      --       B1    .     <- SW (connected to NW)
      --          B1       <- S (connected to SW)
      --          B1       <- S of S
      --
      -- Soldier ant should reach all edge positions

      local map = setup_test_map({
        "0,0,0:1:A",       -- Soldier Ant at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (connected to N)
        "-1,1,0:1:B",      -- Beetle at SW (connected to NW)
        "0,1,-1:1:B",      -- Beetle at S (connected to SW)
        "0,2,-2:1:B"       -- Beetle at S of S
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Soldier ant should have many edge positions available
      assert.is_true(#moves >= 8, "Soldier ant should reach many positions in L-shaped hive")
    end)
  end)
end)
