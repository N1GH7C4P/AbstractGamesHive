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
network = require "network"

function love.load()
    -- Initialize global variables
    globals.init()
    
    -- Initialize console to capture print statements
    console.init()
    console.visible = false  -- Start with console hidden
    
    -- Initialize network module
    network.init()

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

function love.wheelmoved(x, y)
    input.wheelmoved(x, y)
end

function love.update(dt)
    input.update_mouse(dt)
    network.update(dt)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas(overlay)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()

    love.graphics.setColor(0,1,0,1)
    drawBackground(canvas, window_w, window_h)

    drawGridHexes(map, canvas, grid, camera_x, camera_y, camera_zoom)
    drawAddedPieces(map, overlay, grid, camera_x, camera_y, camera_zoom)
    love.graphics.draw(canvas)
    love.graphics.draw(overlay)
    if (highlight == 1 and move_mode == 1) then
        drawSelected(map, selected_piece_x, selected_piece_y, grid, camera_x, camera_y, camera_zoom)
    end
    
    -- Draw piece selector with visual buttons (centered at top)
    local piece_count = #player[active_player_id].pieces
    local piece_size = 30
    local piece_spacing = piece_size * 2.5
    local total_width = (piece_count - 1) * piece_spacing
    local center_x = (window_w - total_width) / 2
    drawPieceSelector(player, active_player_id, center_x, 20, piece_size)
    
    -- Show hover tooltip for piece selector
    local hover_piece_id, hover_piece_name, hover_stock = getPieceSelectorHover(player, active_player_id, mouseX, mouseY, center_x, 20, piece_size)
    if hover_piece_id then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", mouseX + 10, mouseY - 30, 150, 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(hover_piece_name, mouseX + 15, mouseY - 25)
        love.graphics.print("In stock: " .. hover_stock, mouseX + 15, mouseY - 10)
    end
    
    -- Draw cube coordinates if enabled
    if show_cube_coords then
        love.graphics.setColor(1, 1, 1, 0.8)
        for _, hex in pairs(map.hexes) do
            local hx, hy = cubecoords.to_pixel(hex.cube, size)
            hx = hx * camera_zoom + camera_x
            hy = hy * camera_zoom + camera_y
            local coord_text = hex.cube.x .. "," .. hex.cube.y .. "," .. hex.cube.z
            love.graphics.print(coord_text, hx - 25*camera_zoom, hy - 8*camera_zoom, 0, 0.8*camera_zoom, 0.8*camera_zoom)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Display hover coordinates
    local pixel_x = (mouseX - camera_x) / camera_zoom
    local pixel_y = (mouseY - camera_y) / camera_zoom
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, size)
    local hover_hex = map_get_hex(map, hover_cube)
    if not hover_hex then
        love.graphics.print("Out of grid", 0, window_h - 20)
    else
        love.graphics.print("Hexagon coordinates: ["..hover_cube.x..","..hover_cube.y..","..hover_cube.z.."]", 0, window_h - 20)
    end
    
    -- Display zoom level
    love.graphics.print("Zoom: " .. string.format("%.1f", camera_zoom) .. "x", 0, window_h - 40)
    
    -- Display network status
    if network.mode ~= "none" then
        love.graphics.setColor(0, 1, 0, 1)
        local status_y = window_h - 60
        if network.mode == "server" then
            local status = network.connected and "Hosting (Connected)" or "Hosting (Waiting...)"
            love.graphics.print(status, 0, status_y)
        elseif network.mode == "client" then
            local status = network.connected and "Connected to Server" or "Connecting..."
            love.graphics.print(status, 0, status_y)
        end
        
        if network.connected then
            local turn_text = network.is_local_turn and "YOUR TURN" or "Opponent's turn"
            love.graphics.print(turn_text, 0, status_y - 20)
        end
        love.graphics.setColor(1, 1, 1, 1)
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
