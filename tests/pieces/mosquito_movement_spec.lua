-- tests/pieces/mosquito_movement_spec.lua
-- Integration tests for Mosquito movement
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
-- MOSQUITO RULES:
-- - Mimics movement abilities of adjacent pieces
-- - When adjacent to multiple piece types, can use ANY of their abilities
-- - If on top of the hive, can only move as Beetle
-- - If adjacent to Pillbug, can use Pillbug's special ability
-- - Cannot mimic other Mosquitos

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count
local get_dual_option_hexes = test_helpers.get_dual_option_hexes
local cube_in_list = test_helpers.cube_in_list
local simulate_special_click = test_helpers.simulate_special_click
local is_mosquito_popup_active = test_helpers.is_mosquito_popup_active
local clear_mosquito_popup_state = test_helpers.clear_mosquito_popup_state

describe("Mosquito movement", function()

  describe("Mimicking Queen Bee", function()
    it("can move one space like Queen when adjacent to Queen", function()
      -- Visual reference:
      --          .
      --       QB1   .
      --         M1
      --       .     .
      --          .
      --
      -- Mosquito adjacent to Queen, moves one space

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "-1,0,1:1:QB"      -- Queen at NW
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito mimics Queen - can move to adjacent empty hexes
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N (adjacent to QB)
      assert.is_true(#moves > 0, "Mosquito should have Queen-like moves")
    end)
  end)

  describe("Mimicking Beetle", function()
    it("can climb onto pieces like Beetle when adjacent to Beetle", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    .     <- NW (beetle to mimic)
      --         M1
      --       .     .
      --          .
      --
      -- Mosquito can climb onto beetles

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "-1,0,1:1:B",      -- Beetle at NW
        "0,-1,1:1:B"       -- Beetle at N (connected to NW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito mimics Beetle - can climb onto pieces
      assert_has_move(moves, {x=-1, y=0, z=1})   -- NW - climb onto beetle
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N - climb onto beetle
    end)
  end)

  describe("Mimicking Spider", function()
    it("can move exactly 3 steps like Spider when adjacent to Spider", function()
      -- Visual reference:
      --       .   .   .   .
      --     .  S1  B1  B1  .     <- Spider at N, beetles extending line
      --       .  M1   .   .
      --
      -- Mosquito adjacent to Spider can move 3 steps

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:S",      -- Spider at N (to mimic)
        "1,-2,1:1:B",      -- Beetle NE of spider
        "2,-3,1:1:B"       -- Beetle NE of that
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito mimics Spider - moves exactly 3 steps
      -- Should have some moves but not adjacent positions (spider doesn't move to adjacent)
      assert.is_true(#moves > 0, "Mosquito should have Spider-like moves")
    end)
  end)

  describe("Mimicking Grasshopper", function()
    it("can jump like Grasshopper when adjacent to Grasshopper", function()
      -- Visual reference:
      --          .        <- landing spot
      --          G1       <- Grasshopper to jump over
      --         M1
      --       B1    .     <- beetle to keep hive connected
      --          .
      --
      -- Mosquito adjacent to Grasshopper can jump

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:G",      -- Grasshopper at N (to mimic and jump over)
        "-1,0,1:1:B"       -- Beetle at NW (keeps hive connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito mimics Grasshopper - can jump over pieces
      assert_has_move(moves, {x=0, y=-2, z=2})   -- Jump N over grasshopper
    end)
  end)

  describe("Mimicking Soldier Ant", function()
    it("can move unlimited spaces like Ant when adjacent to Ant", function()
      -- Visual reference:
      --       .   .   .   .
      --     .  A1  B1  B1  .     <- Ant at N, beetles extending line
      --       .  M1   .   .
      --
      -- Mosquito adjacent to Ant can move many spaces

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:A",      -- Soldier Ant at N (to mimic)
        "1,-2,1:1:B",      -- Beetle NE of ant
        "2,-3,1:1:B"       -- Beetle NE of that
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito mimics Ant - unlimited movement around hive
      assert.is_true(#moves >= 5, "Mosquito should have many Ant-like moves")
    end)
  end)

  describe("Multiple mimicking options", function()
    it("can use any adjacent piece's movement", function()
      -- Visual reference:
      --          G1       <- Grasshopper at N
      --       QB1   B1    <- Queen at NW, Beetle at NE
      --         M1
      --       .     .
      --          .
      --
      -- Mosquito has 3 different movement options

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:G",      -- Grasshopper at N
        "-1,0,1:1:QB",     -- Queen at NW
        "1,-1,0:1:B"       -- Beetle at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Should combine moves from all three: Queen, Beetle, Grasshopper
      -- Can jump over grasshopper (Grasshopper power)
      assert_has_move(moves, {x=0, y=-2, z=2})
      -- Can climb on beetle (Beetle power)
      assert_has_move(moves, {x=1, y=-1, z=0})
    end)
  end)

  describe("Cannot mimic other Mosquitos", function()
    it("ignores adjacent Mosquitos when determining moves", function()
      -- Visual reference:
      --          B1       <- N (connects NW to NE)
      --       M2    QB1   <- Enemy mosquito at NW, Queen at NE (both connected via N)
      --         M1
      --       .     .
      --          .
      --
      -- Mosquito should only mimic Queen, not the other Mosquito

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:B",      -- Beetle at N (connects NW to NE)
        "-1,0,1:2:M",      -- Enemy mosquito at NW (should be ignored)
        "1,-1,0:1:QB"      -- Queen at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Should have Queen-like movement (one space) plus Beetle-like (can climb)
      -- The mosquito ignores the other mosquito and mimics Queen and Beetle
      assert.is_true(#moves > 0, "Mosquito should have moves from Queen and Beetle")
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     B2
      --         M1
      --       B1    .
      --          .
      --
      -- Mosquito is the bridge between two pieces

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito (bridge piece)
        "-1,1,0:1:B",      -- Beetle at SW
        "1,-1,0:2:B"       -- Enemy beetle at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito cannot move - it would split the hive
      assert_move_count(moves, 0)
    end)
  end)

  describe("Edge cases", function()
    it("has no moves when only adjacent to another Mosquito", function()
      -- Visual reference:
      --          .
      --       M2    .
      --         M1
      --       .     .
      --          .
      --
      -- Mosquito only adjacent to another Mosquito - cannot mimic

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "-1,0,1:2:M"       -- Enemy mosquito at NW
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Mosquito cannot mimic another Mosquito - no movement options
      assert_move_count(moves, 0)
    end)
  end)

  describe("Dual power scenarios", function()
    it("recognizes hex with both Beetle climb and Pillbug pick options", function()
      -- Visual reference:
      --          B1       <- N (target - can climb onto OR pick up)
      --       P1    B1    <- NW Pillbug, NE Beetle (both powers for mosquito)
      --          M1       <- Mosquito at origin
      --       B1    .     <- SW keeps hive connected
      --          .
      --
      -- Mosquito adjacent to Pillbug (NW) and Beetle (NE)
      -- The beetle at N can be:
      -- - Climbed onto (Beetle power from NE)
      -- - Picked up (Pillbug power from NW)
      -- This should mark N as having dual options

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:B",      -- Beetle at N (target for dual options)
        "-1,0,1:1:P",      -- Pillbug at NW (gives Pillbug power)
        "1,-1,0:1:B",      -- Beetle at NE (gives Beetle power)
        "-1,1,0:1:B"       -- Beetle at SW (keeps hive connected when N is lifted)
      })

      local dual_hexes = get_dual_option_hexes(map, "0,0,0")

      -- N should be marked as dual option (can climb OR pick)
      assert.is_true(cube_in_list({x=0, y=-1, z=1}, dual_hexes),
        "Beetle at N should have dual options (climb or pick)")
    end)

    it("does not mark hex as dual when only one power applies", function()
      -- Visual reference:
      --          B1       <- (0,-2,2) only connected via N
      --          B1       <- N (bridge - picking would disconnect (0,-2,2))
      --       P1    B1    <- NW Pillbug, NE Beetle (both give powers)
      --          M1
      --       B1    .     <- SW keeps NW connected when N lifted
      --          .
      --
      -- N is a bridge piece - picking it would disconnect (0,-2,2)
      -- So N should only have Beetle climb option, not Pillbug pick

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:B",      -- Beetle at N (bridge piece - can't be picked)
        "0,-2,2:1:B",      -- Beetle at N of N (only connected via N)
        "-1,0,1:1:P",      -- Pillbug at NW (gives Pillbug power)
        "1,-1,0:1:B",      -- Beetle at NE (gives Beetle power)
        "-1,1,0:1:B"       -- Beetle at SW (keeps NW connected)
      })

      local dual_hexes = get_dual_option_hexes(map, "0,0,0")

      -- N should NOT be dual option (picking would break hive)
      assert.is_false(cube_in_list({x=0, y=-1, z=1}, dual_hexes),
        "Bridge piece at N should not have dual options")
    end)

    it("triggers choice popup when clicking on hex with dual options", function()
      -- Visual reference:
      --          B1       <- N (target - can climb onto OR pick up)
      --       P1    B1    <- NW Pillbug, NE Beetle (both powers for mosquito)
      --          M1       <- Mosquito at origin
      --       B1    .     <- SW keeps hive connected
      --          .
      --
      -- When clicking on the beetle at N, mosquito should show a popup
      -- to choose between climbing onto it (beetle power) or picking it up (pillbug power)

      clear_mosquito_popup_state()

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:B",      -- Beetle at N (target for dual options)
        "-1,0,1:1:P",      -- Pillbug at NW (gives Pillbug power)
        "1,-1,0:1:B",      -- Beetle at NE (gives Beetle power)
        "-1,1,0:1:B"       -- Beetle at SW (keeps hive connected)
      })

      -- First verify this hex has dual options
      local dual_hexes = get_dual_option_hexes(map, "0,0,0")
      assert.is_true(cube_in_list({x=0, y=-1, z=1}, dual_hexes),
        "Beetle at N should have dual options before click test")

      -- Simulate clicking on the dual-option hex
      local result = simulate_special_click(map, "0,0,0", "0,-1,1", 100, 200)

      -- Should return true (handled the click)
      assert.is_true(result, "handle_special_click should return true")

      -- Should have triggered the popup
      assert.is_true(is_mosquito_popup_active(),
        "Mosquito choice popup should be active after clicking dual-option hex")

      -- Verify popup destination was set correctly
      assert.are.equal(0, G.mosquito_choice_dest.x)
      assert.are.equal(-1, G.mosquito_choice_dest.y)
      assert.are.equal(1, G.mosquito_choice_dest.z)

      -- Verify popup coordinates were captured
      assert.are.equal(100, G.mosquito_popup_x)
      assert.are.equal(200, G.mosquito_popup_y)

      clear_mosquito_popup_state()
    end)

    it("does not trigger popup when clicking hex with only one option", function()
      -- Visual reference:
      --          B1       <- N (can only be picked, not climbed - pillbug only)
      --       P1    .     <- NW Pillbug (no beetle adjacent to mosquito)
      --          M1       <- Mosquito at origin
      --       .     .
      --          QB1      <- S keeps hive connected (not adjacent to mosquito via beetle)
      --
      -- Mosquito only has pillbug power (via P at NW), not beetle power
      -- Clicking on N should NOT show popup, just enter pillbug special mode

      clear_mosquito_popup_state()

      local map = setup_test_map({
        "0,0,0:1:M",       -- Mosquito at origin
        "0,-1,1:1:B",      -- Beetle at N (can be picked - but mosquito can't climb as no beetle adjacent)
        "-1,0,1:1:P",      -- Pillbug at NW (gives Pillbug power only)
        "0,1,-1:1:QB"      -- Queen at S (keeps hive connected, not a beetle so no climb power)
      })

      -- Verify this hex does NOT have dual options
      local dual_hexes = get_dual_option_hexes(map, "0,0,0")
      assert.is_false(cube_in_list({x=0, y=-1, z=1}, dual_hexes),
        "Beetle at N should not have dual options (no adjacent beetle for climb)")

      -- Simulate clicking on the target
      local result = simulate_special_click(map, "0,0,0", "0,-1,1", 100, 200)

      -- Should still handle the click (enter pillbug mode)
      assert.is_true(result, "handle_special_click should return true")

      -- Should NOT have triggered the popup
      assert.is_false(is_mosquito_popup_active(),
        "Mosquito choice popup should NOT be active when only one option exists")

      -- Should be in pillbug special mode instead
      assert.is_true(G.pillbug_special_mode,
        "Should enter pillbug special mode directly")

      clear_mosquito_popup_state()
    end)
  end)
end)
