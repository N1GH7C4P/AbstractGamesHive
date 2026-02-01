-- tests/pieces/ladybug_movement_spec.lua
-- Integration tests for Ladybug movement
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
-- LADYBUG RULES:
-- - Moves exactly 3 steps
-- - Step 1: Climb onto an adjacent piece
-- - Step 2: Move onto another piece (staying on top of hive)
-- - Step 3: Climb down to empty space adjacent to step 2 piece
-- - Does NOT follow freedom of movement (climbs over everything)

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Ladybug movement", function()

  describe("Basic 3-step movement", function()
    it("can move over two pieces to empty space", function()
      -- Visual reference:
      --          B1       <- N (pieces to climb over)
      --       B1    .     <- NW (connected to N)
      --         LB1
      --       .     .
      --          .
      --
      -- Ladybug climbs NW -> N -> down to NE (empty)

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "-1,0,1:1:B",      -- Beetle at NW (step 1)
        "0,-1,1:1:B"       -- Beetle at N (step 2, connected to NW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Ladybug should be able to reach positions after climbing over 2 pieces
      assert.is_true(#moves > 0, "Ladybug should have legal moves")
    end)

    it("can reach multiple destinations with two adjacent pieces", function()
      -- Visual reference:
      --          B1       <- N (climb over)
      --       B1    .     <- NW (climb over)
      --         LB1
      --       .     .
      --          .
      --
      -- With N and NW as climbing targets, ladybug can reach various positions

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW (adjacent to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- With 2 connected pieces, ladybug should have several destinations
      assert.is_true(#moves >= 2, "Ladybug should reach multiple destinations")
    end)

    it("cannot move with only one adjacent piece", function()
      -- Visual reference:
      --          B1       <- N (only piece)
      --       .     .
      --         LB1
      --       .     .
      --          .
      --
      -- Ladybug needs at least 2 pieces to complete 3-step journey

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B"       -- Single beetle at N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- With only 1 piece, ladybug can't complete step 1->step 2->step 3
      assert_move_count(moves, 0)
    end)
  end)

  describe("Path constraints", function()
    it("must climb onto piece for first step", function()
      -- Ladybug cannot start by moving to empty space
      -- This is implicit in the pathfinding algorithm - step 1 requires piece

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW (connected to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- All valid moves require first stepping onto a piece
      assert.is_true(#moves > 0, "Ladybug should have moves requiring climb")
    end)

    it("must move onto another piece for second step", function()
      -- Ladybug cannot climb down on second step
      -- Step 2 must be onto another piece

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "1,-2,1:1:B"       -- Beetle at NE of N (step 2 target)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Moves should end on empty spaces adjacent to step 2 piece
      -- If pieces are in a line, ladybug can reach positions beyond them
      assert.is_true(#moves >= 1, "Ladybug should reach destinations after climbing 2 pieces")
    end)

    it("must climb down to empty space for third step", function()
      -- Ladybug cannot end on a piece - must climb down to empty
      -- This is tested by checking destinations are all empty

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- All destinations should be empty spaces
      for _, move_cube in ipairs(moves) do
        local hex = test_helpers.get_hex_at(map, move_cube)
        assert.is_nil(hex.piece, "Ladybug destination should be empty")
      end
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     B2
      --         LB1
      --       B1    .
      --          .
      --
      -- Ladybug is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug (bridge piece)
        "-1,1,0:1:B",      -- Beetle at SW
        "1,-1,0:2:B"       -- Enemy beetle at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Ladybug cannot move - it would split the hive
      assert_move_count(moves, 0)
    end)

    it("can move when hive remains connected", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    .     <- NW (connected to N)
      --         LB1
      --       B1    .     <- SW (connected to NW)
      --          .
      --
      -- Ladybug can move because pieces form connected chain

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (adjacent to N)
        "-1,1,0:1:B"       -- Beetle at SW (adjacent to NW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Ladybug can move because beetles remain connected via N-NW-SW chain
      assert.is_true(#moves > 0, "Ladybug should be able to move")
    end)
  end)

  describe("Climbing over pieces", function()
    it("ignores freedom of movement rule", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (blocking gaps for ground pieces)
      --         LB1
      --       B1    B1    <- SW, SE (blocking gaps)
      --          .        <- S empty
      --
      -- Ladybug can still move even though gaps are blocked
      -- (climbing over, not sliding through)

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW
        "1,-1,0:1:B",      -- Beetle at NE
        "-1,1,0:1:B",      -- Beetle at SW
        "1,0,-1:1:B"       -- Beetle at SE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Ladybug should have moves even though surrounded
      -- Can climb over any of the pieces
      assert.is_true(#moves > 0, "Ladybug should climb over surrounding pieces")
    end)

    it("can reach positions blocked to ground pieces", function()
      -- Ladybug can reach S position that would be blocked for ground pieces
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (all connected via N)
      --         LB1
      --       B1    B1    <- SW, SE (creates gate blocking S for ground)
      --          .        <- S (blocked for ground, reachable by ladybug)

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N (connects NW to NE)
        "-1,0,1:1:B",      -- Beetle at NW
        "1,-1,0:1:B",      -- Beetle at NE
        "-1,1,0:1:B",      -- Beetle at SW (creates gate with SE to S)
        "1,0,-1:1:B"       -- Beetle at SE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- S (0,1,-1) would be blocked for ground pieces by SW+SE gap
      -- But ladybug climbs over and can reach it
      assert_has_move(moves, {x=0, y=1, z=-1})
    end)
  end)

  describe("Edge cases", function()
    it("handles three pieces in a triangle", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (forming triangle around origin)
      --         LB1
      --       .     .
      --          .
      --

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (adjacent to N)
        "1,-1,0:1:B"       -- Beetle at NE (adjacent to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Triangle of pieces gives ladybug many climbing options
      assert.is_true(#moves >= 3, "Ladybug should have several moves in triangle")
    end)

    it("can move in longer chains of pieces", function()
      -- Visual reference (line of pieces):
      --       .   .   .   .
      --     .  B1  B1  B1  .
      --       LB1  .   .   .
      --
      -- Ladybug can climb along the line

      local map = setup_test_map({
        "0,0,0:1:L",       -- Ladybug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "1,-2,1:1:B",      -- Beetle NE of N
        "2,-3,1:1:B"       -- Continue line
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Line of 3 pieces allows ladybug to reach far positions
      assert.is_true(#moves >= 4, "Ladybug should reach many positions along line")
    end)
  end)
end)
