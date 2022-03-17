function love.load()
    -- Import the HEXAGÖN library
    hexagon = require("hexagon/hexagon")
    require "pieces"
    require "player"
    require "game"
    require "graphics"
    require "map"

    active_player_id = 1
    active_piece_id = 1
    love.window.setMode(1200, 800)
    w = 10;
    h = 10;
    size = 40;
    -- Create a 5*5 grid
    grid = hexagon.grid(w, h, size, false, false)
    piecesInvetory = init_pieces()
    player = init_players()
    map = init_map(h, w)

    -- Create a canvas on which to draw the grid
    demoCanvas = love.graphics.newCanvas(1200, 800)
end

function love.mousepressed(x, y, button, istouch)
    print("mouse pressed!")
    if button == 1 then
        mouseX, mouseY = love.mouse.getPosition()
        -- Calculate the coordinates of the mouse cursor in the hexagon grid
        resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)
        addPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)
    end
 end

function love.update(dt)
    -- Get the mouse cursor position
    mouseX, mouseY = love.mouse.getPosition()

    -- Calculate the coordinates of the mouse cursor in the hexagon grid
    resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)

    hexagon.updateNeigbours(resultX, resultY, grid, hexagons)
end

function love.draw()
    -- Draw the demonstration grid on the canvas
    hexagon.drawGrid(grid, demoCanvas)
    
    -- Draw the canvas on screen
    love.graphics.draw(demoCanvas)

    -- Display the coordinates
    if resultX == -1 or resultY == -1 then
        love.graphics.print("Out of grid", 600, 500)
    else
        love.graphics.print("Hexagon coordinates: "..resultX.." "..resultY, 600, 500)
    end
end

