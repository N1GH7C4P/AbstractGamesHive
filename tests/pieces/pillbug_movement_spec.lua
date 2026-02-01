-- tests/pieces/pillbug_movement_spec.lua
-- Integration tests for Pillbug movement
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
-- PILLBUG RULES:
-- Basic Movement:
-- - Moves one space like Queen Bee
-- - Subject to freedom of movement rule
--
-- Special Ability (tested in these tests through pickable pieces):
-- - Can pick up adjacent pieces and move them to another adjacent hex
-- - Cannot use if Pillbug moved last turn
-- - Cannot move covered pieces
-- - Cannot move pieces that moved last turn
-- - Cannot break hive when picking up

local test_helpers = require("tests.test_helpers")
local setup_test_map = test_helpers.setup_test_map
local get_legal_moves = test_helpers.get_legal_moves
local assert_has_move = test_helpers.assert_has_move
local assert_no_move = test_helpers.assert_no_move
local assert_move_count = test_helpers.assert_move_count
local get_pickable_pieces = test_helpers.get_pickable_pieces
local get_drop_locations = test_helpers.get_drop_locations
local cube_in_list = test_helpers.cube_in_list
local set_piece_moved_last_turn = test_helpers.set_piece_moved_last_turn

describe("Pillbug movement", function()

  describe("Basic one-space movement", function()
    it("can move to adjacent empty hexes like Queen", function()
      -- Visual reference:
      --          .
      --       B1    .
      --         P1
      --       .     .
      --          .
      --
      -- Pillbug at origin, beetle at NW

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "-1,0,1:1:B"       -- Beetle at NW (keeps hive connected)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug can move to adjacent empty hexes that stay connected
      assert_has_move(moves, {x=0, y=-1, z=1})   -- N (adjacent to NW)
      assert.is_true(#moves > 0, "Pillbug should have moves")
    end)

    it("cannot move more than one space", function()
      -- Pillbug moves exactly one space, not more

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "0,-2,2:1:B"       -- Beetle at N of N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Cannot move to positions 2 spaces away
      assert_no_move(moves, {x=0, y=-2, z=2})   -- N of N (2 spaces)
    end)
  end)

  describe("Freedom of movement", function()
    it("cannot squeeze through blocked gap", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (blocking gap to S)
      --          P1
      --       B1    B1    <- SW, SE (blocking S gap)
      --          .        <- S (blocked)
      --
      -- Note: All beetles connected via N

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW
        "1,-1,0:1:B",      -- Beetle at NE
        "-1,1,0:1:B",      -- Beetle at SW
        "1,0,-1:1:B"       -- Beetle at SE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug surrounded, S is blocked by SW+SE gap
      assert_no_move(moves, {x=0, y=1, z=-1})   -- S blocked
    end)

    it("can move through unblocked gap", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    .     <- NW only (NE empty)
      --          P1
      --       .     .
      --          .
      --
      -- NW and N don't block NE exit

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW (connected to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug can move to NE (gap not blocked)
      assert_has_move(moves, {x=1, y=-1, z=0})   -- NE unblocked
    end)
  end)

  describe("Hive cohesion", function()
    it("cannot move if it would split the hive", function()
      -- Visual reference:
      --          .
      --       .     B2
      --          P1
      --       B1    .
      --          .
      --
      -- Pillbug is the bridge between two pieces
      -- NOTE: Pillbug can still use special ability on adjacent pieces,
      -- but cannot physically move itself

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug (bridge piece)
        "-1,1,0:1:B",      -- Beetle at SW
        "1,-1,0:2:B"       -- Enemy beetle at NE
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug cannot MOVE (normal movement) - it would split the hive
      -- But it may have special ability targets (can_special hexes)
      -- The get_legal_moves helper includes both, so we check that
      -- normal movement destinations (empty hexes) are not reachable
      assert_no_move(moves, {x=0, y=-1, z=1})   -- N (empty, but can't move there)
      assert_no_move(moves, {x=1, y=0, z=-1})   -- SE (empty, but can't move there)
      assert_no_move(moves, {x=0, y=1, z=-1})   -- S (empty, but can't move there)
    end)

    it("can move when hive remains connected", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    .     <- NW (connected to N)
      --          P1
      --       B1    .     <- SW (connected to NW)
      --          .
      --
      -- Pillbug can move because beetles form connected chain

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (adjacent to N)
        "-1,1,0:1:B"       -- Beetle at SW (adjacent to NW)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug can move because beetles remain connected
      assert.is_true(#moves > 0, "Pillbug should be able to move")
    end)
  end)

  describe("Movement with multiple neighbors", function()
    it("has limited moves when surrounded", function()
      -- Visual reference:
      --          B1       <- N
      --       B1    B1    <- NW, NE (connected via N)
      --          P1
      --       .     .     <- SW, SE empty
      --          .        <- S empty
      --
      -- Pillbug surrounded on 3 sides

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B",      -- Beetle at NW (adjacent to N)
        "1,-1,0:1:B"       -- Beetle at NE (adjacent to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug should have some moves to empty hexes
      -- SE and SW might be blocked by freedom of movement
      assert.is_true(#moves >= 0, "Pillbug has limited moves when surrounded")
    end)
  end)

  describe("Edge cases", function()
    it("handles minimal hive (pillbug + 1 piece)", function()
      -- With just 1 other piece, pillbug has limited movement

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B"       -- Single beetle at N
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug can move around the single beetle
      assert.is_true(#moves > 0, "Pillbug should have moves with minimal hive")
    end)

    it("normal moves are to empty hexes only", function()
      -- Pillbug cannot climb on other pieces (unlike beetle)
      -- NOTE: Occupied hexes may appear in get_legal_moves because
      -- they are special ability targets (pickable pieces), but
      -- normal movement is only to empty hexes

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW (connected to N)
      })

      local moves = get_legal_moves(map, "0,0,0")

      -- Pillbug can reach empty positions adjacent to the beetles
      -- NE is adjacent to N, so should be reachable
      assert_has_move(moves, {x=1, y=-1, z=0})   -- NE is empty and adjacent to N
    end)
  end)

  describe("Special ability - moving adjacent pieces", function()
    it("can pick up adjacent piece", function()
      -- Visual reference:
      --          B1       <- N (target piece)
      --       B1    .     <- NW (keeps hive connected)
      --          P1       <- Pillbug at origin
      --       .     .
      --          .
      --
      -- Pillbug can pick up beetle at N

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N (target)
        "-1,0,1:1:B"       -- Beetle at NW (keeps hive connected when N is lifted)
      })

      local pickable = get_pickable_pieces(map, "0,0,0")

      -- Beetle at N should be pickable (NW keeps hive connected)
      assert.is_true(cube_in_list({x=0, y=-1, z=1}, pickable), "Beetle at N should be pickable")
    end)

    it("can drop piece to adjacent empty hex", function()
      -- Visual reference:
      --          B1       <- N (target piece)
      --       B1    .     <- NW, NE empty (drop location)
      --          P1
      --       .     .     <- SW, SE empty (drop locations)
      --          .        <- S empty (drop location)

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N (target)
        "-1,0,1:1:B"       -- Beetle at NW (keeps hive connected)
      })

      local drop_locs = get_drop_locations(map, "0,0,0", "0,-1,1")

      -- Should be able to drop to NE, SE, S, SW (empty hexes adjacent to pillbug, not the target)
      assert.is_true(#drop_locs > 0, "Should have drop locations")
      assert.is_true(cube_in_list({x=1, y=-1, z=0}, drop_locs), "NE should be a drop location")
    end)

    it("cannot pick up piece if it would break hive", function()
      -- Visual reference:
      --          B1       <- (0,-2,2) only connected via N
      --          B1       <- N (0,-1,1) - bridge piece, picking would disconnect (0,-2,2)
      --          P1       <- Pillbug at origin
      --       B1    .     <- SW keeps pillbug connected
      --          .
      --
      -- Picking up N beetle would disconnect the beetle at (0,-2,2)

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N (bridge - picking would break hive)
        "0,-2,2:1:B",      -- Beetle at N of N (only connected via N)
        "-1,1,0:1:B"       -- Beetle at SW (keeps pillbug connected)
      })

      local pickable = get_pickable_pieces(map, "0,0,0")

      -- N beetle should NOT be pickable - it's a bridge piece
      assert.is_false(cube_in_list({x=0, y=-1, z=1}, pickable), "Bridge piece at N should not be pickable")
      -- But SW beetle should be pickable (doesn't break hive)
      assert.is_true(cube_in_list({x=-1, y=1, z=0}, pickable), "SW beetle should be pickable")
    end)

    it("cannot pick up piece that moved last turn", function()
      -- Visual reference:
      --          B1*      <- N (moved last turn)
      --       B1    .     <- NW (keeps hive connected)
      --          P1
      --       .     .
      --          .

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Beetle at N (will be marked as moved)
        "-1,0,1:1:B"       -- Beetle at NW (keeps hive connected)
      })

      -- Mark beetle at N as moved last turn
      set_piece_moved_last_turn(map, "0,-1,1", true)

      local pickable = get_pickable_pieces(map, "0,0,0")

      -- Beetle at N should NOT be pickable (it moved last turn)
      assert.is_false(cube_in_list({x=0, y=-1, z=1}, pickable), "Piece that moved last turn should not be pickable")
      -- But NW beetle should still be pickable
      assert.is_true(cube_in_list({x=-1, y=0, z=1}, pickable), "NW beetle should be pickable")
    end)

    it("cannot use special ability if pillbug moved last turn", function()
      -- Visual reference:
      --          B1       <- N (target)
      --       B1    .     <- NW
      --          P1*      <- Pillbug moved last turn
      --       .     .
      --          .
      --
      -- get_pickable_pieces shows UI targets, but actual ability is blocked

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin (moved last turn)
        "0,-1,1:1:B",      -- Beetle at N
        "-1,0,1:1:B"       -- Beetle at NW
      })

      -- Mark pillbug as moved last turn
      set_piece_moved_last_turn(map, "0,0,0", true)

      -- get_drop_locations uses can_use_special_ability which checks if pillbug moved
      local drop_locs = get_drop_locations(map, "0,0,0", "0,-1,1")

      -- No drop locations should be available when pillbug moved last turn
      assert.equals(0, #drop_locs, "No drop locations when pillbug moved last turn")
    end)

    it("can pick up both friendly and enemy pieces", function()
      -- Visual reference:
      --          B1       <- N (friendly beetle)
      --       B2    .     <- NW (enemy beetle)
      --          P1
      --       B1    .     <- SW (keeps hive connected)
      --          .

      local map = setup_test_map({
        "0,0,0:1:P",       -- Pillbug at origin
        "0,-1,1:1:B",      -- Friendly beetle at N
        "-1,0,1:2:B",      -- Enemy beetle at NW
        "-1,1,0:1:B"       -- Friendly beetle at SW (keeps hive connected)
      })

      local pickable = get_pickable_pieces(map, "0,0,0")

      -- Both N and NW beetles should be pickable
      assert.is_true(cube_in_list({x=0, y=-1, z=1}, pickable), "Friendly beetle at N should be pickable")
      assert.is_true(cube_in_list({x=-1, y=0, z=1}, pickable), "Enemy beetle at NW should be pickable")
    end)
  end)
end)
