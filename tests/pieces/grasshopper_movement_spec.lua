-- tests/pieces/grasshopper_movement_spec.lua
-- Integration tests for Grasshopper movement
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
-- GRASSHOPPER RULES:
-- - Jumps in a straight line over one or more pieces
-- - Lands on the first empty space after jumping
-- - Must jump over at least one piece (cannot move to empty adjacent hex)
-- - Cannot jump over empty spaces

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Grasshopper movement", function()

  describe("Basic jumping", function()
    it("can jump over one piece and land on first empty space", function()
      -- Visual reference (N-S line):
      --          .      <- landing spot (0,-2,2)
      --          A1     <- piece to jump over
      --          GH1    <- grasshopper at origin
      --          .
      --          .

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A"       -- Ant at N (to jump over)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper can jump over the ant and land at (0,-2,2)
      assert_has_move(moves, {x=0, y=-2, z=2})  -- Landing N of the ant

      -- Should have exactly 1 legal move
      assert_move_count(moves, 1)
    end)

    it("can jump over multiple pieces in a line", function()
      -- Visual reference (N-S line):
      --          .      <- landing spot (0,-3,3)
      --          A1     <- piece 2
      --          A1     <- piece 1
      --          GH1    <- grasshopper at origin
      --          .

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A",      -- Ant at N
        "0,-2,2:1:A"       -- Ant at N of N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper jumps over both ants and lands at (0,-3,3)
      assert_has_move(moves, {x=0, y=-3, z=3})

      -- Should have exactly 1 legal move
      assert_move_count(moves, 1)
    end)

    it("cannot move to adjacent empty space without jumping", function()
      -- Visual reference:
      --          .
      --       A1    .
      --         GH1
      --       .     .
      --          .
      --
      -- Grasshopper has an ant at NW, but cannot move to empty N

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "-1,0,1:1:A"       -- Ant at NW (keeps hive connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper CANNOT move to adjacent empty spaces
      assert_no_move(moves, {x=0, y=-1, z=1})   -- N is adjacent, not a jump
      assert_no_move(moves, {x=1, y=-1, z=0})   -- NE is adjacent
      assert_no_move(moves, {x=1, y=0, z=-1})   -- SE is adjacent
      assert_no_move(moves, {x=0, y=1, z=-1})   -- S is adjacent
      assert_no_move(moves, {x=-1, y=1, z=0})   -- SW is adjacent

      -- Can only jump over NW ant
      assert_has_move(moves, {x=-2, y=0, z=2})  -- Landing after NW ant
      assert_move_count(moves, 1)
    end)
  end)

  describe("Multiple directions", function()
    it("can jump in multiple directions", function()
      -- Visual reference:
      --          A1     <- can jump N
      --       A1    A1  <- can jump NW, can jump NE
      --         GH1
      --       .     .
      --          .

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A",      -- Ant at N
        "-1,0,1:1:A",      -- Ant at NW
        "1,-1,0:1:A"       -- Ant at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper can jump in 3 directions
      assert_has_move(moves, {x=0, y=-2, z=2})   -- Jump N over ant
      assert_has_move(moves, {x=-2, y=0, z=2})   -- Jump NW over ant
      assert_has_move(moves, {x=2, y=-2, z=0})   -- Jump NE over ant

      assert_move_count(moves, 3)
    end)

    it("can jump over pieces in all 6 directions", function()
      -- Grasshopper surrounded by 6 pieces, can jump over each
      --          A1
      --       A1    A1
      --         GH1
      --       A1    A1
      --          A1

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A",      -- N
        "1,-1,0:1:A",      -- NE
        "1,0,-1:1:A",      -- SE
        "0,1,-1:1:A",      -- S
        "-1,1,0:1:A",      -- SW
        "-1,0,1:1:A"       -- NW
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper can jump in all 6 directions
      assert_has_move(moves, {x=0, y=-2, z=2})   -- Jump N
      assert_has_move(moves, {x=2, y=-2, z=0})   -- Jump NE
      assert_has_move(moves, {x=2, y=0, z=-2})   -- Jump SE
      assert_has_move(moves, {x=0, y=2, z=-2})   -- Jump S
      assert_has_move(moves, {x=-2, y=2, z=0})   -- Jump SW
      assert_has_move(moves, {x=-2, y=0, z=2})   -- Jump NW

      assert_move_count(moves, 6)
    end)
  end)

  describe("Jump over enemy pieces", function()
    it("can jump over enemy pieces", function()
      -- Visual reference:
      --          .      <- landing spot (N jump)
      --          A2     <- enemy ant to jump over
      --         GH1
      --       A1    A1  <- connected pieces (keep hive together)
      --          A1     <- jump over this too

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:2:A",      -- Enemy ant at N (jump over)
        "-1,0,1:1:A",      -- Ant at NW (connected to enemy via origin area)
        "-1,1,0:1:A",      -- Ant at SW (connects NW to S)
        "0,1,-1:1:A"       -- Ant at S (jump over)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Can jump over enemy
      assert_has_move(moves, {x=0, y=-2, z=2})   -- Jump N over enemy ant

      -- Can also jump over friendly
      assert_has_move(moves, {x=0, y=2, z=-2})   -- Jump S over friendly ant
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     A2
      --         GH1
      --       A1    .
      --          .
      --
      -- Grasshopper is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper (bridge piece)
        "-1,1,0:1:A",      -- Ant at SW
        "1,-1,0:2:A"       -- Enemy ant at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper cannot move - it would split the hive
      assert_move_count(moves, 0)
    end)

    it("can jump when hive remains connected", function()
      -- Visual reference:
      --          .      <- landing
      --          A1     <- jump over this
      --         GH1
      --       A1    .   <- NW connects N to SW
      --          A1     <- SW connects to S

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A",      -- Ant at N (jump target)
        "-1,0,1:1:A",      -- Ant at NW (connects N to SW)
        "-1,1,0:1:A"       -- Ant at SW (keeps hive connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Grasshopper can move because ants stay connected (N-NW-SW chain)
      assert.is_true(#moves > 0, "Grasshopper should be able to jump")
    end)
  end)

  describe("Edge cases", function()
    it("lands on first empty space only", function()
      -- Visual reference (jumping N):
      --          .      <- NOT a valid landing (too far)
      --          .      <- valid landing (first empty after piece)
      --          A1     <- piece to jump over
      --          GH1    <- grasshopper
      --       A1    A1  <- connected pieces (keep hive connected without grasshopper)
      --          A1

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,-1,1:1:A",      -- Ant at N (jump over)
        "-1,0,1:1:A",      -- Ant at NW (connected to N)
        "0,1,-1:1:A",      -- Ant at S
        "-1,1,0:1:A"       -- Ant at SW (connects NW to S)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Can land at first empty space after N ant
      assert_has_move(moves, {x=0, y=-2, z=2})

      -- Cannot land further (second empty space)
      assert_no_move(moves, {x=0, y=-3, z=3})
    end)

    it("cannot jump in direction with no pieces", function()
      -- Visual reference:
      --          .      <- empty, cannot jump here
      --          .      <- empty, nothing to jump over
      --         GH1
      --          A1     <- piece to jump over
      --          A1     <- keeps hive connected after grasshopper jumps

      local map = setup_test_map({
        "0,0,0:1:G",       -- Grasshopper at origin
        "0,1,-1:1:A",      -- Ant at S (jump over)
        "0,2,-2:1:A"       -- Ant at S of S (stays connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Cannot jump N (no pieces to jump over)
      assert_no_move(moves, {x=0, y=-1, z=1})
      assert_no_move(moves, {x=0, y=-2, z=2})

      -- Can only jump S over the ant, landing at (0,3,-3)
      assert_has_move(moves, {x=0, y=3, z=-3})
      assert_move_count(moves, 1)
    end)
  end)
end)
