-- Tests for camera.lua module
local camera = require("camera")

describe("Camera module", function()
  local G

  -- Set up a fresh G object before each test
  before_each(function()
    G = {
      camera_zoom = 1.0,
      camera_x = 0,
      camera_y = 0,
      is_dragging = false,
      drag_start_x = 0,
      drag_start_y = 0,
      drag_start_camera_x = 0,
      drag_start_camera_y = 0
    }
  end)

  describe("zoom_in", function()
    it("increases zoom level", function()
      local initial_zoom = G.camera_zoom
      camera.zoom_in(G, 400, 300, false)
      assert.is_true(G.camera_zoom > initial_zoom)
    end)

    it("respects maximum zoom limit", function()
      G.camera_zoom = 2.9
      camera.zoom_in(G, 400, 300, false)
      camera.zoom_in(G, 400, 300, false)
      camera.zoom_in(G, 400, 300, false)
      assert.is_true(G.camera_zoom <= 3.0)
    end)

    it("uses keyboard speed when specified", function()
      local zoom1 = camera.zoom_in(G, 400, 300, false)  -- wheel speed
      G.camera_zoom = 1.0  -- reset
      local zoom2 = camera.zoom_in(G, 400, 300, true)   -- keyboard speed
      -- Keyboard speed (0.2) should be larger than wheel speed (0.1)
      assert.is_true(zoom2 > zoom1)
    end)

    it("returns the new zoom level", function()
      local new_zoom = camera.zoom_in(G, 400, 300, false)
      assert.equals(G.camera_zoom, new_zoom)
    end)
  end)

  describe("zoom_out", function()
    it("decreases zoom level", function()
      local initial_zoom = G.camera_zoom
      camera.zoom_out(G, 400, 300, false)
      assert.is_true(G.camera_zoom < initial_zoom)
    end)

    it("respects minimum zoom limit", function()
      G.camera_zoom = 0.4
      camera.zoom_out(G, 400, 300, false)
      camera.zoom_out(G, 400, 300, false)
      camera.zoom_out(G, 400, 300, false)
      assert.is_true(G.camera_zoom >= 0.3)
    end)

    it("returns the new zoom level", function()
      local new_zoom = camera.zoom_out(G, 400, 300, false)
      assert.equals(G.camera_zoom, new_zoom)
    end)
  end)

  describe("reset_zoom", function()
    it("resets zoom to 1.0", function()
      G.camera_zoom = 2.5
      camera.reset_zoom(G)
      assert.equals(1.0, G.camera_zoom)
    end)

    it("returns the new zoom level", function()
      G.camera_zoom = 0.5
      local new_zoom = camera.reset_zoom(G)
      assert.equals(1.0, new_zoom)
    end)
  end)

  describe("start_drag", function()
    it("sets is_dragging to true", function()
      camera.start_drag(G, 100, 200)
      assert.is_true(G.is_dragging)
    end)

    it("stores drag start position", function()
      camera.start_drag(G, 100, 200)
      assert.equals(100, G.drag_start_x)
      assert.equals(200, G.drag_start_y)
    end)

    it("stores camera position at drag start", function()
      G.camera_x = 50
      G.camera_y = 75
      camera.start_drag(G, 100, 200)
      assert.equals(50, G.drag_start_camera_x)
      assert.equals(75, G.drag_start_camera_y)
    end)
  end)

  describe("stop_drag", function()
    it("sets is_dragging to false", function()
      G.is_dragging = true
      camera.stop_drag(G)
      assert.is_false(G.is_dragging)
    end)
  end)

  describe("update_drag", function()
    it("returns false when not dragging", function()
      G.is_dragging = false
      local result = camera.update_drag(G, 150, 250)
      assert.is_false(result)
    end)

    it("returns true when dragging", function()
      camera.start_drag(G, 100, 200)
      local result = camera.update_drag(G, 150, 250)
      assert.is_true(result)
    end)

    it("updates camera position based on drag distance", function()
      G.camera_x = 0
      G.camera_y = 0
      camera.start_drag(G, 100, 200)
      camera.update_drag(G, 150, 250)
      -- Camera should move by the delta (50, 50)
      assert.equals(50, G.camera_x)
      assert.equals(50, G.camera_y)
    end)

    it("does not modify camera position when not dragging", function()
      G.is_dragging = false
      G.camera_x = 10
      G.camera_y = 20
      camera.update_drag(G, 150, 250)
      assert.equals(10, G.camera_x)
      assert.equals(20, G.camera_y)
    end)
  end)

  describe("screen_to_world", function()
    it("converts screen coordinates to world coordinates", function()
      G.camera_x = 100
      G.camera_y = 100
      G.camera_zoom = 1.0
      local world_x, world_y = camera.screen_to_world(G, 200, 200)
      assert.equals(100, world_x)
      assert.equals(100, world_y)
    end)

    it("accounts for zoom level", function()
      G.camera_x = 0
      G.camera_y = 0
      G.camera_zoom = 2.0
      local world_x, world_y = camera.screen_to_world(G, 200, 200)
      assert.equals(100, world_x)
      assert.equals(100, world_y)
    end)

    it("accounts for camera offset", function()
      G.camera_x = 50
      G.camera_y = 50
      G.camera_zoom = 1.0
      local world_x, world_y = camera.screen_to_world(G, 200, 200)
      assert.equals(150, world_x)
      assert.equals(150, world_y)
    end)
  end)

  describe("world_to_screen", function()
    it("converts world coordinates to screen coordinates", function()
      G.camera_x = 100
      G.camera_y = 100
      G.camera_zoom = 1.0
      local screen_x, screen_y = camera.world_to_screen(G, 100, 100)
      assert.equals(200, screen_x)
      assert.equals(200, screen_y)
    end)

    it("accounts for zoom level", function()
      G.camera_x = 0
      G.camera_y = 0
      G.camera_zoom = 2.0
      local screen_x, screen_y = camera.world_to_screen(G, 100, 100)
      assert.equals(200, screen_x)
      assert.equals(200, screen_y)
    end)

    it("is inverse of screen_to_world", function()
      G.camera_x = 50
      G.camera_y = 75
      G.camera_zoom = 1.5
      local world_x, world_y = camera.screen_to_world(G, 300, 450)
      local screen_x, screen_y = camera.world_to_screen(G, world_x, world_y)
      -- Should get back original screen coordinates
      assert.is.near(300, screen_x, 0.001)
      assert.is.near(450, screen_y, 0.001)
    end)
  end)
end)
