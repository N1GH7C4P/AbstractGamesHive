-- tests/pieces/queenbee_movement_spec.lua
-- Integration tests for Queen Bee movement
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

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Queen Bee movement", function()

  describe("Basic one-space movement", function()
    it("can move to adjacent empty hexes", function()
      -- Visual reference:
      --          .
      --       .    A1
      --         QB1
      --       .    A1
      --          .
      --
      -- Ants at NE and SE (adjacent to each other)

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen at origin
        "1,-1,0:1:A",      -- Ant at NE
        "1,0,-1:1:A"       -- Ant at SE (adjacent to NE ant)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen CAN move to N and S (open positions)
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N is free
      assert_has_move(moves, {x=0, y=1, z=-1})   -- S is free

      -- Queen CANNOT move to occupied positions
      assert_no_move(moves, {x=1, y=-1, z=0})    -- NE is occupied
      assert_no_move(moves, {x=1, y=0, z=-1})    -- SE is occupied

      -- Should have exactly 2 legal moves
      assert_move_count(moves, 2)
    end)

    it("cannot move when completely surrounded", function()
      -- Visual reference:
      --          A2
      --       A2    A2
      --         QB1
      --       A2    A2
      --          A2

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen in center
        "1,-1,0:2:A",      -- Surrounded by ants
        "1,0,-1:2:A",
        "0,1,-1:2:A",
        "-1,1,0:2:A",
        "-1,0,1:2:A",
        "0,-1,1:2:A"
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen surrounded on all 6 sides cannot move
      assert_move_count(moves, 0)
    end)
  end)

  describe("Freedom of movement rules", function()
    it("cannot squeeze through gap when both sides are blocked", function()
      -- Visual reference:
      --          .
      --       A1    .
      --         QB1
      --       .     .
      --          A1
      --
      -- Queen at origin, pieces at NW and S block the SW gap
      -- NW and S are connected via a chain that bypasses the Queen:
      --   NW -> (-2,1,1) -> (-2,2,0) -> (-1,2,-1) -> S
      -- This allows Queen to detach while keeping hive connected
      --
      -- Queen tries to move to SW but cannot - gap is too narrow
      -- (both common neighbors NW and S are occupied)

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen at origin
        "-1,0,1:1:A",      -- Ant at Northwest (blocks SW gap)
        "0,1,-1:1:A",      -- Ant at South (blocks SW gap)
        "-2,1,1:1:A",      -- Chain connecting NW to S
        "-2,2,0:1:A",      -- (bypassing Queen)
        "-1,2,-1:1:A"      -- (so Queen can detach)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen CANNOT move to Southwest because both sides of gap are blocked
      assert_no_move(moves, {x=-1, y=1, z=0})  -- SW is blocked (gap too narrow)

      -- Queen CANNOT move to NE - would be disconnected from hive
      assert_no_move(moves, {x=1, y=-1, z=0})  -- NE has no adjacent pieces except Queen

      -- Queen CAN move to N (adjacent to NW) and SE (adjacent to S)
      assert_has_move(moves, {x=0, y=-1, z=1})  -- N is valid (touches NW)
      assert_has_move(moves, {x=1, y=0, z=-1})  -- SE is valid (touches S)

      -- Should have exactly 2 legal moves (N and SE)
      assert_move_count(moves, 2)
    end)

    it("can move through gap when one side is open", function()
      -- Visual reference:
      --          A1
      --       .     A1
      --         QB1
      --       .     .
      --          .
      --
      -- Ants at N and NE, gap between them has one side open

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen at origin
        "0,-1,1:1:A",      -- Ant at North
        "1,-1,0:1:A"       -- Ant at NE (adjacent to N ant)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen CAN move to NW - gap between N and NE is open on NW side
      assert_has_move(moves, {x=-1, y=0, z=1})  -- NW is accessible

      -- Queen CAN move to SE - no obstruction
      assert_has_move(moves, {x=1, y=0, z=-1})  -- SE is accessible

      -- Should have exactly 2 legal moves
      assert_move_count(moves, 2)
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     A2
      --         QB1
      --       A1    .
      --          .
      --
      -- If Queen is the only piece connecting two groups,
      -- it cannot move

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen (bridge piece)
        "-1,1,0:1:A",      -- Ant on one side
        "1,-1,0:2:A"       -- Enemy ant on other side
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen is the bridge - moving it would split the hive
      assert_move_count(moves, 0)
    end)

    it("can move when hive remains connected", function()
      -- Visual reference:
      --          A1
      --       A1    A1
      --         QB1
      --       .     .
      --          .

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen at origin
        "1,-1,0:1:A",      -- Ant to the east
        "0,-1,1:1:A",      -- Ant to the northeast
        "-1,0,1:1:A"       -- Ant to the northwest
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen can move because the three ants remain connected when queen moves
      assert.is_true(#moves > 0, "Queen should be able to move without breaking hive")
    end)
  end)

  describe("Queen with multiple pieces", function()
    it("has limited moves in crowded area", function()
      -- Visual reference:
      --          A1
      --       A1    A1
      --         QB1
      --       A1    .
      --          .
      --
      -- Queen surrounded on 4 sides (N, NW, NE, SW)
      -- All ants connected to each other, so Queen can detach
      -- But most directions are blocked by pieces or freedom-of-movement

      local map = setup_test_map({
        "0,0,0:1:QB",      -- Queen at origin
        "0,-1,1:1:A",      -- Ant at N
        "-1,0,1:1:A",      -- Ant at NW (adjacent to N)
        "1,-1,0:1:A",      -- Ant at NE (adjacent to N)
        "-1,1,0:1:A"       -- Ant at SW (adjacent to NW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Queen has limited moves - only SE and S are potentially open
      -- S requires touching SW, SE requires touching NE
      assert_has_move(moves, {x=1, y=0, z=-1})   -- SE (touches NE)
      assert_has_move(moves, {x=0, y=1, z=-1})   -- S (touches SW)
      assert_move_count(moves, 2)
    end)
  end)
end)
