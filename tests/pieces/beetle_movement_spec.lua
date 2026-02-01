-- tests/pieces/beetle_movement_spec.lua
-- Integration tests for Beetle movement
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
-- BEETLE SPECIAL RULES:
-- - Moves one space like Queen
-- - Can climb on top of other pieces (stacking)
-- - Freedom of movement accounts for stack heights
-- - Piece underneath beetle cannot move

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count

describe("Beetle movement", function()

  describe("Basic one-space movement", function()
    it("can move to adjacent empty hexes like Queen", function()
      -- Visual reference:
      --          .
      --       .     A1
      --         B1
      --       .     A1
      --          .
      --
      -- Beetle at origin, ants at NE and SE

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "1,-1,0:1:A",      -- Ant at NE
        "1,0,-1:1:A"       -- Ant at SE (adjacent to NE)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CAN move to empty adjacent hexes
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N is free
      assert_has_move(moves, {x=0, y=1, z=-1})   -- S is free

      -- Beetle CAN also climb on occupied hexes (unlike Queen)
      assert_has_move(moves, {x=1, y=-1, z=0})   -- NE - can climb
      assert_has_move(moves, {x=1, y=0, z=-1})   -- SE - can climb
    end)

    it("cannot move when it would break the hive", function()
      -- Visual reference:
      --          .
      --       .     A2
      --         B1
      --       A1    .
      --          .
      --
      -- Beetle is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle (bridge piece)
        "-1,1,0:1:A",      -- Ant on one side (SW)
        "1,-1,0:2:A"       -- Enemy ant on other side (NE)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle is the bridge - moving would split the hive
      assert_move_count(moves, 0)
    end)
  end)

  describe("Climbing on pieces", function()
    it("can climb on top of adjacent piece", function()
      -- Visual reference:
      --          A1
      --       A1    A1
      --         B1
      --       .     .
      --          .
      --
      -- Beetle can climb onto NW or NE ant
      -- Ants connected via N so beetle can detach

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "-1,0,1:1:A",      -- Ant at NW
        "1,-1,0:1:A",      -- Ant at NE
        "0,-1,1:1:A"       -- Ant at N (connects NW and NE)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CAN climb on all three ants
      assert_has_move(moves, {x=-1, y=0, z=1})  -- NW - climb on ant
      assert_has_move(moves, {x=1, y=-1, z=0})  -- NE - climb on ant
      assert_has_move(moves, {x=0, y=-1, z=1})  -- N - climb on ant
    end)

    it("can climb on enemy pieces", function()
      -- Visual reference:
      --          A1
      --       A2    A1
      --         B1
      --       .     .
      --          .
      --
      -- Beetle can climb onto enemy ant at NW
      -- Ants connected via N so beetle can detach

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "-1,0,1:2:A",      -- Enemy ant at NW
        "1,-1,0:1:A",      -- Friendly ant at NE
        "0,-1,1:1:A"       -- Ant at N (connects NW and NE)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CAN climb on enemy piece
      assert_has_move(moves, {x=-1, y=0, z=1})  -- NW - climb on enemy ant
    end)
  end)

  describe("Movement while on top of stack", function()
    it("can move when on top of another piece", function()
      -- Visual reference:
      --          .
      --       A1   [B1]
      --         A1
      --       .     .
      --          .
      --
      -- Beetle is on top of ant at NE, can move to adjacent hexes

      local map = setup_test_map({
        "0,0,0:1:A",       -- Ant at origin (base of hive)
        "1,-1,0:1:A",      -- Ant at NE (beetle will be on top)
        "-1,0,1:1:A"       -- Ant at NW (connected)
      })

      -- Manually place beetle on top of NE ant
      local map_module = require("map")
      local Beetle = require("pieces.beetle")
      local ne_hex = map_module.get_hex(map, {x=1, y=-1, z=0})
      local beetle = Beetle:new(1)
      beetle.under_piece = ne_hex.piece
      beetle.under_piece.player_id = ne_hex.player_id
      ne_hex.piece = beetle
      ne_hex.player_id = 1

      local moves = get_legal_moves(map, "1,-1,0")

      -- Beetle on top can move to various adjacent positions
      -- It should have moves available (exact count depends on implementation)
      assert.is_true(#moves > 0, "Beetle on stack should be able to move")
    end)

    it("beetle on stack does not break hive when moving", function()
      -- Visual reference:
      --          .
      --      [B1]    .
      --         A1
      --       .     .
      --          .
      --
      -- Beetle on top of ant at NW, ant at origin
      -- The ant underneath maintains hive connection

      local map = setup_test_map({
        "0,0,0:1:A",       -- Ant at origin
        "-1,0,1:1:A"       -- Ant at NW (beetle will be on top)
      })

      -- Manually place beetle on top of NW ant
      local map_module = require("map")
      local Beetle = require("pieces.beetle")
      local nw_hex = map_module.get_hex(map, {x=-1, y=0, z=1})
      local beetle = Beetle:new(1)
      beetle.under_piece = nw_hex.piece
      beetle.under_piece.player_id = nw_hex.player_id
      nw_hex.piece = beetle
      nw_hex.player_id = 1

      local moves = get_legal_moves(map, "-1,0,1")

      -- Beetle on stack can move because piece underneath maintains cohesion
      assert.is_true(#moves > 0, "Beetle on stack should be able to move without breaking hive")
    end)
  end)

  describe("Freedom of movement rules", function()
    it("cannot squeeze through narrow gap on ground level", function()
      -- Visual reference:
      --          .
      --       A1    .
      --         B1
      --       .     .
      --          A1
      --
      -- NW and S are occupied, blocking movement to SW
      -- Connected via chain bypassing beetle

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "-1,0,1:1:A",      -- Ant at NW (blocks SW gap)
        "0,1,-1:1:A",      -- Ant at S (blocks SW gap)
        "-2,1,1:1:A",      -- Chain connecting NW to S
        "-2,2,0:1:A",
        "-1,2,-1:1:A"
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CANNOT move to SW (gap blocked by NW and S)
      assert_no_move(moves, {x=-1, y=1, z=0})  -- SW blocked

      -- But beetle CAN climb on the blocking pieces
      assert_has_move(moves, {x=-1, y=0, z=1})  -- NW - climb
      assert_has_move(moves, {x=0, y=1, z=-1})  -- S - climb
    end)

    it("can move through gap when climbing over", function()
      -- When beetle climbs on top of a piece, it bypasses ground-level gaps
      -- This is tested by the "can climb on top of adjacent piece" test
      -- The beetle can always climb regardless of ground-level freedom of movement

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "-1,0,1:1:A",      -- Ant at NW
        "0,1,-1:1:A",      -- Ant at S
        "-1,1,0:1:A"       -- Ant at SW (the "blocked" position now has a piece)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CAN climb onto SW even though gap would block ground movement
      assert_has_move(moves, {x=-1, y=1, z=0})  -- SW - climb on piece
    end)

    it("cannot pass through gate formed by higher stacks", function()
      -- Visual reference (side view showing heights):
      --
      --   Height 2:        [B2]  [B2]     <- gate (beetles on ants)
      --   Height 1:   [B1]  A1    A1   .  <- beetle on ant, empty destination
      --
      -- Top-down view:
      --          .
      --      [B2]   [B2]      <- NW and NE have height-2 stacks (gate)
      --        [B1]           <- Beetle at origin on height-1 stack
      --          A1    .      <- S has ant, SE is empty destination
      --             .
      --
      -- Beetle at origin (on top of ant = height 1) wants to move to N (empty)
      -- But NW and NE both have height-2 stacks forming a gate
      -- Beetle cannot pass through because both sides are higher

      local map = setup_test_map({
        "0,0,0:1:A",       -- Ant at origin (beetle will be on top)
        "-1,0,1:1:A",      -- Ant at NW (base of gate)
        "1,-1,0:1:A",      -- Ant at NE (base of gate)
        "0,1,-1:1:A"       -- Ant at S (keeps hive connected)
      })

      -- Place beetle on top of origin ant (height 1)
      local map_module = require("map")
      local Beetle = require("pieces.beetle")

      local origin_hex = map_module.get_hex(map, {x=0, y=0, z=0})
      local beetle_origin = Beetle:new(1)
      beetle_origin.under_piece = origin_hex.piece
      beetle_origin.under_piece.player_id = origin_hex.player_id
      origin_hex.piece = beetle_origin
      origin_hex.player_id = 1

      -- Place beetles on top of NW and NE ants (creating height-2 gate)
      local nw_hex = map_module.get_hex(map, {x=-1, y=0, z=1})
      local beetle_nw = Beetle:new(2)
      beetle_nw.under_piece = nw_hex.piece
      beetle_nw.under_piece.player_id = nw_hex.player_id
      nw_hex.piece = beetle_nw
      nw_hex.player_id = 2

      local ne_hex = map_module.get_hex(map, {x=1, y=-1, z=0})
      local beetle_ne = Beetle:new(2)
      beetle_ne.under_piece = ne_hex.piece
      beetle_ne.under_piece.player_id = ne_hex.player_id
      ne_hex.piece = beetle_ne
      ne_hex.player_id = 2

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle CANNOT move to N (empty) - blocked by gate (NW and NE both height 2)
      assert_no_move(moves, {x=0, y=-1, z=1})  -- N blocked by gate

      -- Beetle CAN move to empty hexes SE and SW (not blocked by gate)
      assert_has_move(moves, {x=1, y=0, z=-1})  -- SE - empty, can slide there
      assert_has_move(moves, {x=-1, y=1, z=0})  -- SW - empty, can slide there

      -- Beetle CAN climb onto the gate stacks (under_piece maintains connectivity)
      assert_has_move(moves, {x=-1, y=0, z=1})  -- NW - climb onto gate
      assert_has_move(moves, {x=1, y=-1, z=0})  -- NE - climb onto gate

      -- Beetle CAN climb onto S (the ant)
      assert_has_move(moves, {x=0, y=1, z=-1})  -- S - climb onto ant

      assert_move_count(moves, 5)
    end)
  end)

  describe("Beetle with multiple pieces", function()
    it("has many move options in crowded area", function()
      -- Visual reference:
      --          A1
      --       A1    A1
      --         B1
      --       A1    .
      --          .
      --
      -- Beetle surrounded by 4 pieces, can climb on all of them

      local map = setup_test_map({
        "0,0,0:1:B",       -- Beetle at origin
        "0,-1,1:1:A",      -- Ant at N
        "-1,0,1:1:A",      -- Ant at NW
        "1,-1,0:1:A",      -- Ant at NE
        "-1,1,0:1:A"       -- Ant at SW
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Beetle can climb on all 4 surrounding pieces
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N - climb
      assert_has_move(moves, {x=-1, y=0, z=1})   -- NW - climb
      assert_has_move(moves, {x=1, y=-1, z=0})   -- NE - climb
      assert_has_move(moves, {x=-1, y=1, z=0})   -- SW - climb

      -- And can move to open positions (SE and S)
      assert_has_move(moves, {x=1, y=0, z=-1})   -- SE - empty, adjacent to NE
      assert_has_move(moves, {x=0, y=1, z=-1})   -- S - empty, adjacent to SW
    end)
  end)
end)
