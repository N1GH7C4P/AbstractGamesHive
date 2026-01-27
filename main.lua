-- Load modules
hexagon = require("hexagon")
cubecoords = require("cubecoords")
Config = require("config")
globals = require("globals")
require "pieces"
require "player"
require "game"
require "graphics"
require "map"
console = require "console"
gamestate = require "gamestate"
input = require "input"

function love.load()
    -- Initialize global variables
    globals.init()
    
    -- Initialize console to capture print statements
    console.init()

    -- Load configuration into globals
    menu_offset_x = Config.game.menuOffsetX
    window_w = Config.game.windowWidth
    window_h = Config.game.windowHeight
    w = Config.game.mapWidth
    h = Config.game.mapHeight
    size = Config.game.hexSize
    
    love.window.setMode(window_w, window_h)
	love.window.setTitle("hive")

    grid = hexagon.grid(w, h, size, false, false)
    piecesInvetory = init_pieces()
    player = init_players()
    map = init_map()
    
    -- Debug: Check if center hex exists
    local center_cube = cubecoords.new(0, 0, 0)
    local center_hex = map_get_hex(map, center_cube)
    print("Center hex (0,0,0) exists: " .. tostring(center_hex ~= nil))
    if center_hex then
        print("Center hex key: " .. cubecoords.to_key(center_cube))
    end
    
    -- Center camera so (0,0,0) cube coordinate appears in center of screen
    -- Since we now use direct cube-to-pixel conversion, cube (0,0,0) is at pixel (0,0)
    camera_x = window_w / 2
    camera_y = window_h / 2

    canvas = love.graphics.newCanvas(window_w, window_h)
    overlay = love.graphics.newCanvas(window_w, window_h)
end

function love.keypressed(key)
    input.keypressed(key)
end

function love.mousepressed(x, y, button, istouch)
    input.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    input.mousereleased(x, y, button, istouch)
end

function love.update(dt)
    input.update_mouse(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas(overlay)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()

    love.graphics.setColor(0,1,0,1)
    drawBackground(canvas, window_w, window_h)

    drawGridHexes(map, canvas, grid, camera_x, camera_y)
    drawAddedPieces(map, overlay, grid, camera_x, camera_y)
    love.graphics.draw(canvas)
    love.graphics.draw(overlay)
    if (highlight == 1 and move_mode == 1) then
        drawSelected(map, selected_piece_x, selected_piece_y, grid, camera_x, camera_y)
    end
    printPlayerStock(player, active_player_id, menu_offset_x, 20)
    print_map_pieces(map, w, h, menu_offset_x, 200)
    
    -- Draw cube coordinates if enabled
    if show_cube_coords then
        love.graphics.setColor(1, 1, 1, 0.8)
        for _, hex in pairs(map.hexes) do
            local hx, hy = cubecoords.to_pixel(hex.cube, size)
            local coord_text = hex.cube.x .. "," .. hex.cube.y .. "," .. hex.cube.z
            love.graphics.print(coord_text, hx + camera_x - 25, hy + camera_y - 8, 0, 0.8, 0.8)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Display hover coordinates
    local pixel_x = mouseX - camera_x
    local pixel_y = mouseY - camera_y
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, size)
    local hover_hex = map_get_hex(map, hover_cube)
    if not hover_hex then
        love.graphics.print("Out of grid", 0, window_h - 20)
    else
        love.graphics.print("Hexagon coordinates: ["..hover_cube.x..","..hover_cube.y..","..hover_cube.z.."]", 0, window_h - 20)
    end

    if game_over == true then
        love.graphics.setColor(1,0,0,1)
        love.graphics.print("Game Over", window_w / 2, window_h / 2)
        if who_won[1] == 1 and who_won[2] == 1 then
            love.graphics.print("Draw", window_w / 2, window_h / 2 + 20)
        elseif who_won[1] == 1 then
            love.graphics.print("Player 2 Wins", window_w / 2, window_h / 2 + 20)
        elseif who_won[2] == 1 then
            love.graphics.print("Player 1 Wins", window_w / 2, window_h / 2 + 20)
        end
    end
    
    -- Draw console on top of everything
    console.draw(10, 400, 600, 350)
end
