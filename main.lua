function love.load()
    -- Import the HEXAGÖN library
    hexagon = require("hexagon")
    require "pieces"
    require "player"
    require "game"
    require "graphics"
    require "map"

    move_mode = 0
    window_w = 1024
    window_h = 768
    active_player_id = 1
    active_piece_id = 5
    selected_piece_x = 0
    selected_piece_y = 0

    love.window.setMode(window_w, window_h)
    w = 10;
    h = 10;
    size = 35;

    grid = hexagon.grid(w, h, size, false, false)
    piecesInvetory = init_pieces()
    player = init_players()
    map = init_map(w, h)

    -- Create a canvas on which to draw the grid
    canvas = love.graphics.newCanvas(window_w, window_h)
    overlay = love.graphics.newCanvas(window_w, window_h)
end

function love.keypressed(key)
    if key == "a" and active_piece_id < 5 then
        active_piece_id = active_piece_id + 1
    elseif key == "s" and active_piece_id > 1 then
        active_piece_id = active_piece_id - 1
    end
 end

function love.mousepressed(x, y, button, istouch)
    print("mouse pressed!")
    if button == 1 then
        local mouseX, mouseY = love.mouse.getPosition()
        -- Calculate the coordinates of the mouse cursor in the hexagon grid
        local resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)
        if (resultX > 0 and resultY > 0) then
            if selectPieceOnMap(map, resultX, resultY, active_player_id) then
                print("Piece: "..map[resultY][resultX].piece.name.." ("..resultX..", "..resultY.." selected.")
                mark_neighbours_on_map(map, resultX, resultY, w, h)
                print_neighbours(map, resultX, resultY, w, h)
                selected_piece_x = resultX
                selected_piece_y = resultY
                move_mode = 1
                return
            elseif (not tryAddPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)) then
                return
            end
            if (active_player_id == 1) then
                move_mode = 0
                print("Player2's turn!")
                tryAddPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)
                active_player_id = 2
            elseif (active_player_id == 2) then
                move_mode = 0
                print("Player1's turn!")
                tryAddPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)
                active_player_id = 1
            end
        end
    end
 end

function love.update(dt)
    -- Get the mouse cursor position
    mouseX, mouseY = love.mouse.getPosition()

    -- Calculate the coordinates of the mouse cursor in the hexagon grid
    resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)

    --hexagon.updateNeigbours(resultX, resultY, grid, hexagons)
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas(overlay)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()

    love.graphics.setColor(0,1,0,1)
    drawBackground(canvas, window_w, window_h)
    hexagon.drawGrid(grid, canvas)
    drawAddedPieces(map, overlay, grid)

    love.graphics.draw(canvas)
    love.graphics.draw(overlay)
    highlightNeighbours(map, w, h, grid)
    printPlayerStock(player, active_player_id, 600, 20)
    -- printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, 600, 400)
    print_map_pieces(map, w, h, 600, 200)

    -- Display the coordinates
    if resultX == -1 or resultY == -1 then
        love.graphics.print("Out of grid", 0, window_h - 20)
    else
        love.graphics.print("Hexagon coordinates: "..resultX.." "..resultY, 0, window_h - 20)
    end
end