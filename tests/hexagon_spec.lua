-- tests/hexagon_spec.lua
-- Unit tests for hexagon module
--
-- Tests cover:
-- - grid: Grid configuration creation and validation
-- - toPlanCoordinates: Hex grid to pixel coordinate conversion
-- - toHexagonCoordinates: Pixel to hex grid coordinate conversion
-- - draw_hexagon: Hexagon drawing (with mocked love.graphics)
-- - draw_split_hexagon: Split hexagon drawing (with mocked love.graphics)

-- Mock love.graphics before loading module
_G.love = _G.love or {}
_G.love.graphics = {
    setColor = function() end,
    polygon = function() end,
    setCanvas = function() end,
}

local hexagon = require("hexagon")

describe("Hexagon module", function()

  describe("grid", function()

    it("creates a grid with correct properties", function()
      local grid = hexagon.grid(10, 8, 32, true, false)

      assert.are.equal(10, grid.width)
      assert.are.equal(8, grid.height)
      assert.are.equal(32, grid.piecesize)
      assert.is_true(grid.pointyTopped)
      assert.is_false(grid.shifted)
    end)

    it("creates flat-topped non-shifted grid", function()
      local grid = hexagon.grid(20, 15, 48, false, false)

      assert.are.equal(20, grid.width)
      assert.are.equal(15, grid.height)
      assert.are.equal(48, grid.piecesize)
      assert.is_false(grid.pointyTopped)
      assert.is_false(grid.shifted)
    end)

    it("creates shifted grid", function()
      local grid = hexagon.grid(5, 5, 24, true, true)

      assert.is_true(grid.shifted)
    end)

    it("validates width is a number", function()
      assert.has_error(function()
        hexagon.grid("invalid", 10, 32, true, false)
      end, "width expects a number")
    end)

    it("validates height is a number", function()
      assert.has_error(function()
        hexagon.grid(10, "invalid", 32, true, false)
      end, "height expects a number")
    end)

    it("validates piecesize is a number", function()
      assert.has_error(function()
        hexagon.grid(10, 10, "invalid", true, false)
      end, "piecesize expects a number")
    end)

    it("validates pointyTopped is a boolean", function()
      assert.has_error(function()
        hexagon.grid(10, 10, 32, "invalid", false)
      end, "pointyTopped expects a boolean")
    end)

    it("validates shifted is a boolean", function()
      assert.has_error(function()
        hexagon.grid(10, 10, 32, true, "invalid")
      end, "shifted expects a boolean")
    end)
  end)

  describe("toPlanCoordinates", function()

    describe("flat-topped hexagons", function()
      local grid

      before_each(function()
        grid = hexagon.grid(10, 10, 32, false, false)
      end)

      it("returns coordinates for hex at (1,1)", function()
        local hx, hy = hexagon.toPlanCoordinates(1, 1, grid)

        -- For flat-topped: hx = piecesize + (x-1) * piecesize * 1.5
        -- With x=1: hx = 32 + 0 = 32
        assert.are.equal(32, hx)
        -- hy involves sin(pi/3) factor
        assert.is_true(hy > 0)
      end)

      it("returns different coordinates for adjacent hexes", function()
        local hx1, hy1 = hexagon.toPlanCoordinates(1, 1, grid)
        local hx2, hy2 = hexagon.toPlanCoordinates(2, 1, grid)

        assert.are_not.equal(hx1, hx2)
      end)

      it("handles odd and even columns differently when not shifted", function()
        local hx1, hy1 = hexagon.toPlanCoordinates(1, 1, grid)
        local hx2, hy2 = hexagon.toPlanCoordinates(2, 1, grid)

        -- Odd columns (1) should have different y offset than even (2)
        assert.are_not.equal(hy1, hy2)
      end)

      it("returns positive coordinates for positive grid positions", function()
        local hx, hy = hexagon.toPlanCoordinates(5, 5, grid)

        assert.is_true(hx > 0)
        assert.is_true(hy > 0)
      end)
    end)

    describe("pointy-topped hexagons", function()
      local grid

      before_each(function()
        grid = hexagon.grid(10, 10, 32, true, false)
      end)

      it("returns coordinates for hex at (1,1)", function()
        local hx, hy = hexagon.toPlanCoordinates(1, 1, grid)

        -- For pointy-topped at y=1 (odd), x is adjusted
        assert.is_true(hx > 0)
        -- hy = piecesize for y=1
        assert.are.equal(32, hy)
      end)

      it("handles shifted grid differently", function()
        local grid_shifted = hexagon.grid(10, 10, 32, true, true)

        local hx1, hy1 = hexagon.toPlanCoordinates(1, 1, grid)
        local hx2, hy2 = hexagon.toPlanCoordinates(1, 1, grid_shifted)

        -- Shifted grids offset even vs odd rows differently
        assert.are_not.equal(hx1, hx2)
      end)
    end)
  end)

  describe("toHexagonCoordinates", function()

    describe("flat-topped hexagons", function()
      local grid

      before_each(function()
        grid = hexagon.grid(10, 10, 32, false, false)
      end)

      it("returns hex coordinates for a point", function()
        -- Get the center of hex (1,1)
        local px, py = hexagon.toPlanCoordinates(1, 1, grid)

        -- Convert back to hex coordinates
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(1, hx)
        assert.are.equal(1, hy)
      end)

      it("round-trips coordinates for hex (3,4)", function()
        local px, py = hexagon.toPlanCoordinates(3, 4, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(3, hx)
        assert.are.equal(4, hy)
      end)

      it("round-trips coordinates for hex (5,2)", function()
        local px, py = hexagon.toPlanCoordinates(5, 2, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(5, hx)
        assert.are.equal(2, hy)
      end)

      it("handles points near hex boundaries", function()
        -- Get center of (2,2) and offset slightly
        local px, py = hexagon.toPlanCoordinates(2, 2, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px + 1, py + 1, grid)

        -- Small offset should still resolve to same hex
        assert.are.equal(2, hx)
        assert.are.equal(2, hy)
      end)
    end)

    describe("pointy-topped hexagons", function()
      local grid

      before_each(function()
        grid = hexagon.grid(10, 10, 32, true, false)
      end)

      it("round-trips coordinates for hex (1,1)", function()
        local px, py = hexagon.toPlanCoordinates(1, 1, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(1, hx)
        assert.are.equal(1, hy)
      end)

      it("round-trips coordinates for hex (4,3)", function()
        local px, py = hexagon.toPlanCoordinates(4, 3, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(4, hx)
        assert.are.equal(3, hy)
      end)

      it("round-trips coordinates for odd row", function()
        local px, py = hexagon.toPlanCoordinates(2, 3, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(2, hx)
        assert.are.equal(3, hy)
      end)

      it("round-trips coordinates for even row", function()
        local px, py = hexagon.toPlanCoordinates(2, 4, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(2, hx)
        assert.are.equal(4, hy)
      end)
    end)

    describe("shifted grids", function()

      it("round-trips flat-topped shifted grid", function()
        local grid = hexagon.grid(10, 10, 32, false, true)
        local px, py = hexagon.toPlanCoordinates(3, 3, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(3, hx)
        assert.are.equal(3, hy)
      end)

      it("round-trips pointy-topped shifted grid", function()
        local grid = hexagon.grid(10, 10, 32, true, true)
        local px, py = hexagon.toPlanCoordinates(3, 3, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(3, hx)
        assert.are.equal(3, hy)
      end)
    end)

    describe("different piece sizes", function()

      it("works with small piece size", function()
        local grid = hexagon.grid(10, 10, 16, false, false)
        local px, py = hexagon.toPlanCoordinates(2, 2, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(2, hx)
        assert.are.equal(2, hy)
      end)

      it("works with large piece size", function()
        local grid = hexagon.grid(10, 10, 64, false, false)
        local px, py = hexagon.toPlanCoordinates(2, 2, grid)
        local hx, hy = hexagon.toHexagonCoordinates(px, py, grid)

        assert.are.equal(2, hx)
        assert.are.equal(2, hy)
      end)
    end)
  end)

  describe("draw_hexagon", function()
    local grid
    local polygon_calls
    local color_calls

    before_each(function()
      grid = hexagon.grid(10, 10, 32, false, false)
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

  describe("drawGrid", function()

    it("executes without error", function()
      local grid = hexagon.grid(10, 10, 32, false, false)
      local mock_canvas = {}

      assert.has_no.errors(function()
        hexagon.drawGrid(grid, mock_canvas, 0, 0)
      end)
    end)

    it("accepts optional camera offsets", function()
      local grid = hexagon.grid(10, 10, 32, false, false)

      assert.has_no.errors(function()
        hexagon.drawGrid(grid, {}, 100, 200)
      end)
    end)

    it("uses default camera offsets when not provided", function()
      local grid = hexagon.grid(10, 10, 32, false, false)

      assert.has_no.errors(function()
        hexagon.drawGrid(grid, {})
      end)
    end)
  end)
end)
