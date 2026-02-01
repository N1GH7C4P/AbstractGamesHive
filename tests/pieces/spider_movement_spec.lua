-- tests/pieces/spider_movement_spec.lua
-- Integration tests for Spider movement
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
-- SPIDER RULES:
-- - Moves exactly 3 spaces around the hive edge
-- - Cannot backtrack (cannot visit same hex twice in path)
-- - Must stay connected to hive at each step
-- - Subject to freedom of movement rule at each step

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Spider movement", function()

  describe("Basic 3-step movement", function()
    it("moves exactly 3 spaces around a line of pieces", function()
      -- Visual reference (line of ants):
      --       .   .   .   .   .
      --     .  A1  A1  A1  A1  .
      --       .  Sp1  .   .   .
      --
      -- Spider at origin, 4 ants in a line to the N/NE
      -- Spider walks around the edge exactly 3 steps

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "1,-2,1:1:A",      -- Ant NE of N
        "2,-3,1:1:A",      -- Ant NE of that
        "3,-4,1:1:A"       -- Ant NE of that
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider can reach positions exactly 3 steps away
      -- Going NW around: origin -> NW of N -> N of NW ant -> NE of that = 3 steps
      assert.is_true(#moves > 0, "Spider should have legal moves")
    end)

    it("cannot move to adjacent hex (only 1 step)", function()
      -- Spider must move exactly 3 spaces, not 1

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "1,-2,1:1:A",      -- Ant NE of N
        "2,-3,1:1:A"       -- Another ant
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider CANNOT move to adjacent positions (only 1 step)
      assert_no_move(moves, {x=-1, y=0, z=1})   -- NW (1 step)
      assert_no_move(moves, {x=1, y=-1, z=0})   -- NE (1 step)
    end)

    it("cannot move to 2-step position", function()
      -- Spider must move exactly 3 spaces, not 2

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "1,-2,1:1:A",      -- Ant NE of N
        "2,-3,1:1:A"       -- Another ant
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- 2-step positions should not be reachable
      -- (exact positions depend on path, but we can check spider doesn't stop at 2)
      -- NW of NW of origin would be 2 steps if going NW twice
      assert_no_move(moves, {x=-2, y=0, z=2})   -- 2 steps NW
    end)
  end)

  describe("Path constraints", function()
    it("cannot backtrack through same hex", function()
      -- Visual reference (corridor trap):
      --           B1         <- (0,-3,3)
      --        B1    B1      <- (-1,-2,3), (1,-3,2)
      --           .          <- (0,-2,2) empty - step 2
      --        B1    B1      <- (-1,-1,2), (1,-2,1)
      --           .          <- N (0,-1,1) empty - step 1
      --        B1    B1      <- NW (-1,0,1), NE (1,-1,0)
      --           S1         <- origin
      --        B1    B1      <- SW (-1,1,0), SE (1,0,-1)
      --           B1         <- S (0,1,-1)
      --
      -- Spider has only one path: origin -> N -> (0,-2,2)
      -- After step 2, all neighbors of (0,-2,2) are pieces or visited (N)
      -- Spider cannot complete step 3 because it cannot backtrack to N

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        -- Ring around origin (blocks all exits except N)
        "1,-1,0:1:B",      -- NE
        "1,0,-1:1:B",      -- SE
        "0,1,-1:1:B",      -- S
        "-1,1,0:1:B",      -- SW
        "-1,0,1:1:B",      -- NW
        -- Corridor walls (around the 2 empty hexes N and (0,-2,2))
        "1,-2,1:1:B",      -- East wall of corridor
        "-1,-1,2:1:B",     -- West wall of corridor
        -- Top of corridor
        "1,-3,2:1:B",      -- NE of top
        "0,-3,3:1:B",      -- Top cap
        "-1,-2,3:1:B"      -- NW of top
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider's only path: origin -> N -> (0,-2,2)
      -- At (0,-2,2), all neighbors are pieces except N (already visited)
      -- Cannot complete 3 steps because backtracking is forbidden
      assert_move_count(moves, 0)
    end)

    it("must stay connected to hive at each step", function()
      -- Spider must touch at least one piece at each position in path

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N (spider's neighbor)
        "0,-3,3:1:A"       -- Ant far away (gap)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider cannot jump to disconnected positions
      -- Must walk along the hive edge
      assert_no_move(moves, {x=0, y=-3, z=3})
    end)
  end)

  describe("Movement around hive", function()
    it("reaches specific 3-step destinations from arc formation", function()
      -- Visual reference:
      --          A1        <- N
      --       A1    .      <- NW, (NE empty - exit route)
      --         Sp1
      --       A1    .      <- SW (connected to NW)
      --          A1        <- S (connected to SW)
      --
      -- Spider at origin, 4 ants forming connected arc N-NW-SW-S
      -- Spider can exit via NE or SE and walk around

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "-1,0,1:1:A",      -- Ant at NW (adjacent to N)
        "-1,1,0:1:A",      -- Ant at SW (adjacent to NW)
        "0,1,-1:1:A"       -- Ant at S (adjacent to SW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider walks exactly 3 steps around the arc
      -- NE route: origin -> NE (1,-1,0) -> (1,-2,1) -> (0,-2,2) [N of N]
      assert_has_move(moves, {x=0, y=-2, z=2})
      -- SE route: origin -> SE (1,0,-1) -> (1,1,-2) -> (0,2,-2) [S of S]
      assert_has_move(moves, {x=0, y=2, z=-2})
    end)

    it("can reach multiple destinations from same starting point", function()
      -- Visual reference (longer line gives more 3-step destinations):
      --       .   .   .   .   .   .
      --     .  A1  A1  A1  A1  A1  .
      --       .  Sp1  .   .   .   .
      --
      -- Spider at origin, 5 ants in a line extending NE
      -- Spider can walk around either side of the line

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "1,-2,1:1:A",      -- Ant NE of N
        "2,-3,1:1:A",      -- Ant NE of that
        "3,-4,1:1:A",      -- Ant NE of that
        "4,-5,1:1:A"       -- Ant NE of that (5 ants total)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Longer line of ants allows spider to reach multiple 3-step destinations
      -- Can go NW around or NE around
      assert.is_true(#moves >= 2, "Spider should have multiple destinations")
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     A2
      --         Sp1
      --       A1    .
      --          .
      --
      -- Spider is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider (bridge piece)
        "-1,1,0:1:A",      -- Ant at SW
        "1,-1,0:2:A"       -- Enemy ant at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider cannot move - it would split the hive
      assert_move_count(moves, 0)
    end)

    it("can move when hive remains connected", function()
      -- Visual reference:
      --          A1
      --       A1    A1
      --         Sp1
      --       .     .
      --          .
      --
      -- Spider with 3 ants that stay connected

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:A",      -- Ant at N
        "-1,0,1:1:A",      -- Ant at NW (connected to N)
        "1,-1,0:1:A"       -- Ant at NE (connected to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Spider can move - ants stay connected via N
      assert.is_true(#moves > 0, "Spider should be able to move")
    end)
  end)

  describe("Freedom of movement", function()
    it("cannot squeeze through blocked gap during path", function()
      -- Visual reference:
      --          .        <- (0,-2,2) blocked destination
      --       B1    B1    <- (-1,-1,2), (1,-2,1) - form gate with N
      --          B1       <- N (0,-1,1)
      --       B1    .     <- NW (-1,0,1)
      --          S1       <- origin
      --       B1    .     <- SW (-1,1,0)
      --          .
      --
      -- Spider can exit via NE or S, but (0,-2,2) is blocked by gate:
      -- - Path origin -> NE -> (0,-2,2) blocked: common neighbors N + (1,-2,1) both occupied
      -- - No alternative 3-step path exists to (0,-2,2)

      local map = setup_test_map({
        "0,0,0:1:S",       -- Spider at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (connected to N)
        "-1,1,0:1:B",      -- Beetle at SW (connected to NW)
        "-1,-1,2:1:B",     -- Beetle forming west side of gate (connected to N)
        "1,-2,1:1:B"       -- Beetle forming east side of gate (connected to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- (0,-2,2) would be a valid destination (adjacent to N, (-1,-1,2), (1,-2,1))
      -- but freedom of movement blocks all paths to it
      assert_no_move(moves, {x=0, y=-2, z=2})
    end)
  end)
end)
