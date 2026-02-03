-- tests/animation_spec.lua
-- Unit tests for animation module
--
-- Tests cover:
-- - Animation.start_move: Starting an animation
-- - Animation.update: Updating animation progress
-- - Animation.get_animated_position: Getting interpolated position
-- - Animation.is_animating_from: Checking animation source

local Globals = require("globals")
local Animation = require("animation")
local cubecoords = require("cubecoords")

describe("Animation module", function()

  before_each(function()
    Globals.init()
  end)

  describe("start_move", function()

    it("sets animating to true", function()
      local piece = {name = "test"}
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(1, -1, 0)

      Animation.start_move(piece, from, to, nil)

      assert.is_true(G.animating)
    end)

    it("stores piece reference", function()
      local piece = {name = "test"}
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(1, -1, 0)

      Animation.start_move(piece, from, to, nil)

      assert.are.equal(piece, G.animation_piece)
    end)

    it("stores from and to cubes", function()
      local piece = {name = "test"}
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(1, -1, 0)

      Animation.start_move(piece, from, to, nil)

      assert.are.equal(from, G.animation_from_cube)
      assert.are.equal(to, G.animation_to_cube)
    end)

    it("resets progress to 0", function()
      local piece = {name = "test"}
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(1, -1, 0)
      G.animation_progress = 0.5

      Animation.start_move(piece, from, to, nil)

      assert.are.equal(0, G.animation_progress)
    end)

    it("stores callback function", function()
      local piece = {name = "test"}
      local from = cubecoords.new(0, 0, 0)
      local to = cubecoords.new(1, -1, 0)
      local callback = function() end

      Animation.start_move(piece, from, to, callback)

      assert.are.equal(callback, G.animation_callback)
    end)
  end)

  describe("update", function()

    it("does nothing when not animating", function()
      G.animating = false
      G.animation_progress = 0

      Animation.update(0.1)

      assert.are.equal(0, G.animation_progress)
    end)

    it("increments progress based on dt and duration", function()
      G.animating = true
      G.animation_progress = 0
      G.animation_duration = 0.3

      Animation.update(0.1)  -- 0.1 / 0.3 = ~0.333

      assert.is_true(G.animation_progress > 0)
      assert.is_true(G.animation_progress < 1)
    end)

    it("caps progress at 1.0", function()
      G.animating = true
      G.animation_progress = 0.9
      G.animation_duration = 0.3

      Animation.update(0.5)  -- Would exceed 1.0

      assert.are.equal(1.0, G.animation_progress)
    end)

    it("sets animating to false when complete", function()
      G.animating = true
      G.animation_progress = 0.9
      G.animation_duration = 0.3

      Animation.update(0.5)

      assert.is_false(G.animating)
    end)

    it("calls callback when animation completes", function()
      local callback_called = false
      G.animating = true
      G.animation_progress = 0.9
      G.animation_duration = 0.3
      G.animation_callback = function()
        callback_called = true
      end

      Animation.update(0.5)

      assert.is_true(callback_called)
    end)

    it("clears callback after calling it", function()
      G.animating = true
      G.animation_progress = 0.9
      G.animation_duration = 0.3
      G.animation_callback = function() end

      Animation.update(0.5)

      assert.is_nil(G.animation_callback)
    end)

    it("clears animation state when complete", function()
      G.animating = true
      G.animation_progress = 0.9
      G.animation_duration = 0.3
      G.animation_piece = {name = "test"}
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = cubecoords.new(1, -1, 0)

      Animation.update(0.5)

      assert.is_nil(G.animation_piece)
      assert.is_nil(G.animation_from_cube)
      assert.is_nil(G.animation_to_cube)
    end)
  end)

  describe("get_animated_position", function()

    it("returns nil when not animating", function()
      G.animating = false

      local result = Animation.get_animated_position(35)

      assert.is_nil(result)
    end)

    it("returns nil when from_cube is nil", function()
      G.animating = true
      G.animation_from_cube = nil

      local result = Animation.get_animated_position(35)

      assert.is_nil(result)
    end)

    it("returns nil when to_cube is nil", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = nil

      local result = Animation.get_animated_position(35)

      assert.is_nil(result)
    end)

    it("returns position when animating", function()
      local piece = {name = "test"}
      G.animating = true
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = cubecoords.new(1, -1, 0)
      G.animation_progress = 0.5
      G.animation_piece = piece

      local x, y, returned_piece = Animation.get_animated_position(35)

      assert.is_number(x)
      assert.is_number(y)
      assert.are.equal(piece, returned_piece)
    end)

    it("returns start position at progress 0", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = cubecoords.new(2, -2, 0)
      G.animation_progress = 0
      G.animation_piece = {}

      local x, y = Animation.get_animated_position(35)
      local from_x, from_y = cubecoords.to_pixel(G.animation_from_cube, 35)

      assert.are.equal(from_x, x)
      assert.are.equal(from_y, y)
    end)

    it("returns end position at progress 1", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = cubecoords.new(2, -2, 0)
      G.animation_progress = 1
      G.animation_piece = {}

      local x, y = Animation.get_animated_position(35)
      local to_x, to_y = cubecoords.to_pixel(G.animation_to_cube, 35)

      assert.are.equal(to_x, x)
      assert.are.equal(to_y, y)
    end)

    it("returns interpolated position at progress 0.5", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(0, 0, 0)
      G.animation_to_cube = cubecoords.new(2, -2, 0)
      G.animation_progress = 0.5
      G.animation_piece = {}

      local x, y = Animation.get_animated_position(35)
      local from_x, from_y = cubecoords.to_pixel(G.animation_from_cube, 35)
      local to_x, to_y = cubecoords.to_pixel(G.animation_to_cube, 35)

      -- Should be somewhere between start and end (eased)
      assert.is_true(x > from_x or x == from_x)
      assert.is_true(x < to_x or x == to_x)
    end)
  end)

  describe("is_animating_from", function()

    it("returns false when not animating", function()
      G.animating = false
      local cube = cubecoords.new(0, 0, 0)

      local result = Animation.is_animating_from(cube)

      assert.is_false(result)
    end)

    it("returns false when from_cube is nil", function()
      G.animating = true
      G.animation_from_cube = nil
      local cube = cubecoords.new(0, 0, 0)

      local result = Animation.is_animating_from(cube)

      assert.is_false(result)
    end)

    it("returns true when cube matches from_cube", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(1, -1, 0)
      local cube = cubecoords.new(1, -1, 0)

      local result = Animation.is_animating_from(cube)

      assert.is_true(result)
    end)

    it("returns false when cube does not match from_cube", function()
      G.animating = true
      G.animation_from_cube = cubecoords.new(1, -1, 0)
      local cube = cubecoords.new(0, 0, 0)

      local result = Animation.is_animating_from(cube)

      assert.is_false(result)
    end)
  end)

end)
