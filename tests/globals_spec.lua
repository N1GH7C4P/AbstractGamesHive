-- tests/globals_spec.lua
-- Unit tests for globals module
--
-- Tests cover:
-- - Globals.init: Full initialization of global state
-- - Globals.deselect_piece: Deselect without clearing coordinates

local Globals = require("globals")

describe("Globals module", function()

  describe("init", function()

    it("creates global G table", function()
      Globals.init()

      assert.is_table(G)
    end)

    it("initializes camera state", function()
      Globals.init()

      assert.are.equal(0, G.camera_x)
      assert.are.equal(0, G.camera_y)
      assert.are.equal(0.8, G.camera_zoom)
      assert.is_false(G.is_dragging)
    end)

    it("initializes game state", function()
      Globals.init()

      assert.are.equal(0, G.move_mode)
      assert.are.equal(1, G.active_player_id)
      assert.are.equal(5, G.active_piece_id)
      assert.is_false(G.game_over)
    end)

    it("initializes turn numbers for both players", function()
      Globals.init()

      assert.is_table(G.turn_number)
      assert.are.equal(1, G.turn_number[1])
      assert.are.equal(1, G.turn_number[2])
    end)

    it("initializes who_won for both players", function()
      Globals.init()

      assert.is_table(G.who_won)
      assert.are.equal(0, G.who_won[1])
      assert.are.equal(0, G.who_won[2])
    end)

    it("initializes animation state", function()
      Globals.init()

      assert.is_false(G.animating)
      assert.is_nil(G.animation_piece)
      assert.are.equal(0, G.animation_progress)
      assert.are.equal(0.3, G.animation_duration)
    end)

    it("initializes pillbug mode state", function()
      Globals.init()

      assert.is_false(G.pillbug_special_mode)
      assert.is_nil(G.pillbug_cube)
      assert.is_nil(G.pillbug_target_cube)
    end)

    it("initializes mosquito popup state", function()
      Globals.init()

      assert.is_false(G.mosquito_choice_popup)
      assert.is_table(G.mosquito_choice_options)
      assert.is_nil(G.mosquito_choice_dest)
    end)

    it("initializes mouse state", function()
      Globals.init()

      assert.are.equal(0, G.mouseX)
      assert.are.equal(0, G.mouseY)
    end)

    it("initializes game objects as nil", function()
      Globals.init()

      assert.is_nil(G.grid)
      assert.is_nil(G.player)
      assert.is_nil(G.map)
    end)

    it("resets G when called multiple times", function()
      Globals.init()
      G.camera_x = 500
      G.active_player_id = 2

      Globals.init()

      assert.are.equal(0, G.camera_x)
      assert.are.equal(1, G.active_player_id)
    end)
  end)

  describe("deselect_piece", function()

    it("clears move_mode", function()
      Globals.init()
      G.move_mode = 1

      Globals.deselect_piece()

      assert.are.equal(0, G.move_mode)
    end)

    it("clears highlight", function()
      Globals.init()
      G.highlight = 1

      Globals.deselect_piece()

      assert.are.equal(0, G.highlight)
    end)

    it("preserves selected coordinates", function()
      Globals.init()
      G.selected_piece_x = 5
      G.selected_piece_y = 10
      G.move_mode = 1
      G.highlight = 1

      Globals.deselect_piece()

      assert.are.equal(5, G.selected_piece_x)
      assert.are.equal(10, G.selected_piece_y)
    end)
  end)

  describe("select_piece", function()

    it("sets highlight to 1", function()
      Globals.init()

      Globals.select_piece(3, 4)

      assert.are.equal(1, G.highlight)
    end)

    it("sets selected coordinates", function()
      Globals.init()

      Globals.select_piece(3, 4)

      assert.are.equal(3, G.selected_piece_x)
      assert.are.equal(4, G.selected_piece_y)
    end)

    it("sets move_mode to 1", function()
      Globals.init()

      Globals.select_piece(3, 4)

      assert.are.equal(1, G.move_mode)
    end)
  end)

  describe("clear_selection", function()

    it("clears move_mode and highlight", function()
      Globals.init()
      G.move_mode = 1
      G.highlight = 1

      Globals.clear_selection()

      assert.are.equal(0, G.move_mode)
      assert.are.equal(0, G.highlight)
    end)

    it("clears selected coordinates", function()
      Globals.init()
      G.selected_piece_x = 5
      G.selected_piece_y = 10

      Globals.clear_selection()

      assert.are.equal(0, G.selected_piece_x)
      assert.are.equal(0, G.selected_piece_y)
    end)
  end)

  describe("pillbug mode", function()

    it("enter_pillbug_mode sets state correctly", function()
      Globals.init()
      local pillbug_cube = {x = 0, y = 0, z = 0}
      local target_cube = {x = 1, y = -1, z = 0}

      Globals.enter_pillbug_mode(pillbug_cube, target_cube)

      assert.is_true(G.pillbug_special_mode)
      assert.are.equal(pillbug_cube, G.pillbug_cube)
      assert.are.equal(target_cube, G.pillbug_target_cube)
    end)

    it("clear_pillbug_mode resets state", function()
      Globals.init()
      G.pillbug_special_mode = true
      G.pillbug_cube = {x = 0, y = 0, z = 0}
      G.pillbug_target_cube = {x = 1, y = -1, z = 0}

      Globals.clear_pillbug_mode()

      assert.is_false(G.pillbug_special_mode)
      assert.is_nil(G.pillbug_cube)
      assert.is_nil(G.pillbug_target_cube)
    end)
  end)

  describe("mosquito popup", function()

    it("clear_mosquito_popup resets all popup state", function()
      Globals.init()
      G.mosquito_choice_popup = true
      G.mosquito_choice_options = {{type = "beetle"}}
      G.mosquito_choice_dest = {x = 1, y = -1, z = 0}
      G.mosquito_popup_x = 100
      G.mosquito_popup_y = 200

      Globals.clear_mosquito_popup()

      assert.is_false(G.mosquito_choice_popup)
      assert.are.same({}, G.mosquito_choice_options)
      assert.is_nil(G.mosquito_choice_dest)
      assert.are.equal(0, G.mosquito_popup_x)
      assert.are.equal(0, G.mosquito_popup_y)
    end)
  end)

  describe("reset_ui_state", function()

    it("clears all transient UI state", function()
      Globals.init()
      -- Set up various state
      G.pillbug_special_mode = true
      G.mosquito_choice_popup = true
      G.move_mode = 1
      G.highlight = 1

      Globals.reset_ui_state()

      assert.is_false(G.pillbug_special_mode)
      assert.is_false(G.mosquito_choice_popup)
      assert.are.equal(0, G.move_mode)
      assert.are.equal(0, G.highlight)
    end)
  end)

end)
