-- tests/hexagon_spec.lua
-- Unit tests for hexagon module

-- Mock love.graphics before loading module
_G.love = _G.love or {}
_G.love.graphics = {
    setColor = function() end,
    polygon = function() end,
    setCanvas = function() end,
}

local hexagon = require("hexagon")

describe("Hexagon module", function()

  describe("draw_hexagon", function()
    local polygon_calls
    local color_calls

    before_each(function()
      polygon_calls = {}
      color_calls = {}

      _G.love.graphics.polygon = function(mode, vertices)
        table.insert(polygon_calls, {mode = mode, vertices = vertices})
      end

      _G.love.graphics.setColor = function(r, g, b, a)
        table.insert(color_calls, {r = r, g = g, b = b, a = a})
      end
    end)

    it("draws filled hexagon", function()
      hexagon.draw_hexagon(100, 100, 32, false, true, 1, 0, 0, 1)

      assert.are.equal(1, #polygon_calls)
      assert.are.equal("fill", polygon_calls[1].mode)
    end)

    it("draws line hexagon", function()
      hexagon.draw_hexagon(100, 100, 32, false, false, 0, 1, 0, 1)

      assert.are.equal(1, #polygon_calls)
      assert.are.equal("line", polygon_calls[1].mode)
    end)

    it("generates 12 vertex values (6 points x 2 coords)", function()
      hexagon.draw_hexagon(100, 100, 32, false, true)

      assert.are.equal(12, #polygon_calls[1].vertices)
    end)

    it("uses default color values when not provided", function()
      hexagon.draw_hexagon(100, 100, 32, false, true)

      -- First color call should be the hexagon color
      assert.are.equal(1, color_calls[1].r)
      assert.are.equal(1, color_calls[1].g)
      assert.are.equal(1, color_calls[1].b)
      assert.are.equal(1, color_calls[1].a)
    end)

    it("uses provided color values", function()
      hexagon.draw_hexagon(100, 100, 32, false, true, 0.5, 0.6, 0.7, 0.8)

      assert.are.equal(0.5, color_calls[1].r)
      assert.are.equal(0.6, color_calls[1].g)
      assert.are.equal(0.7, color_calls[1].b)
      assert.are.equal(0.8, color_calls[1].a)
    end)

    it("resets color to white after drawing", function()
      hexagon.draw_hexagon(100, 100, 32, false, true, 1, 0, 0, 1)

      -- Last color call should reset to white
      local last_color = color_calls[#color_calls]
      assert.are.equal(1, last_color.r)
      assert.are.equal(1, last_color.g)
      assert.are.equal(1, last_color.b)
    end)

    it("draws pointy-topped hexagon", function()
      hexagon.draw_hexagon(100, 100, 32, true, true)

      assert.are.equal(1, #polygon_calls)
      assert.are.equal(12, #polygon_calls[1].vertices)
    end)
  end)

  describe("draw_split_hexagon", function()
    local polygon_calls
    local color_calls

    before_each(function()
      polygon_calls = {}
      color_calls = {}

      _G.love.graphics.polygon = function(mode, vertices)
        table.insert(polygon_calls, {mode = mode, vertices = vertices})
      end

      _G.love.graphics.setColor = function(r, g, b, a)
        table.insert(color_calls, {r = r, g = g, b = b, a = a})
      end
    end)

    it("draws two polygon halves", function()
      hexagon.draw_split_hexagon(100, 100, 32, false, 1, 0, 0, 1, 0, 0, 1, 1)

      assert.are.equal(2, #polygon_calls)
      assert.are.equal("fill", polygon_calls[1].mode)
      assert.are.equal("fill", polygon_calls[2].mode)
    end)

    it("uses different colors for each half", function()
      hexagon.draw_split_hexagon(100, 100, 32, false, 1, 0, 0, 1, 0, 0, 1, 1)

      -- First half should be red
      assert.are.equal(1, color_calls[1].r)
      assert.are.equal(0, color_calls[1].g)
      assert.are.equal(0, color_calls[1].b)

      -- Second half should be blue
      assert.are.equal(0, color_calls[2].r)
      assert.are.equal(0, color_calls[2].g)
      assert.are.equal(1, color_calls[2].b)
    end)

    it("resets color to white after drawing", function()
      hexagon.draw_split_hexagon(100, 100, 32, false, 1, 0, 0, 1, 0, 1, 0, 1)

      local last_color = color_calls[#color_calls]
      assert.are.equal(1, last_color.r)
      assert.are.equal(1, last_color.g)
      assert.are.equal(1, last_color.b)
      assert.are.equal(1, last_color.a)
    end)

    it("draws pointy-topped split hexagon", function()
      hexagon.draw_split_hexagon(100, 100, 32, true, 1, 0, 0, 1, 0, 0, 1, 1)

      assert.are.equal(2, #polygon_calls)
    end)

    it("uses default alpha when not provided", function()
      -- Alpha values should default to 1
      hexagon.draw_split_hexagon(100, 100, 32, false, 1, 0, 0, nil, 0, 0, 1, nil)

      assert.are.equal(1, color_calls[1].a)
      assert.are.equal(1, color_calls[2].a)
    end)
  end)
end)
