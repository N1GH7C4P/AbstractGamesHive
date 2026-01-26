function love.load()
    hexagon = require("hexagon")
    cubecoords = require("cubecoords")
    Config = require("config")
    require "pieces"
    require "player"
    require "game"
    require "graphics"
    require "map"
    console = require "console"
    gamestate = require "gamestate"
    
    -- Initialize console to capture print statements
    console.init()

    -- Load configuration
    menu_offset_x = Config.game.menuOffsetX
    window_w = Config.game.windowWidth
    window_h = Config.game.windowHeight
    w = Config.game.mapWidth
    h = Config.game.mapHeight
    size = Config.game.hexSize
    
    -- Game state
    move_mode = 0
    active_player_id = 1
    active_piece_id = 5
    selected_piece_x = 0
    selected_piece_y = 0
    highlight = 0
    game_over = false
    who_won = {0, 0}
    show_cube_coords = false
    turn_number = {1, 1}

    love.window.setMode(window_w, window_h)
	love.window.setTitle("hive")

    grid = hexagon.grid(w, h, size, false, false)
    piecesInvetory = init_pieces()
    player = init_players()
    map = init_map(w, h)

    canvas = love.graphics.newCanvas(window_w, window_h)
    overlay = love.graphics.newCanvas(window_w, window_h)
end

function love.keypressed(key)
    local maxPieceId = #Config.pieceInventory
    
    if key == "a" and active_piece_id < maxPieceId then
        active_piece_id = active_piece_id + 1
    elseif key == "s" and active_piece_id > 1 then
        active_piece_id = active_piece_id - 1
    elseif key == "c" then
        console.toggle()
    elseif key == "x" then
        console.clear()
    elseif key == "d" then
        -- Export game state to file
        gamestate.export_to_file(map, w, h, "gamestate.txt")
    elseif key == "l" then
        -- Load game state from file
        gamestate.load_from_file(map, w, h, "gamestate.txt")
    elseif key == "h" then
        -- Toggle cube coordinate display
        show_cube_coords = not show_cube_coords
        print("Cube coordinates display: " .. (show_cube_coords and "ON" or "OFF"))
    end
 end

function love.mousepressed(x, y, button, istouch)
    if game_over == true then
        return
    end
    if button == 1 then
        local mouseX, mouseY = love.mouse.getPosition()
        local resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)
        if move_mode == 1 then
            local result_cube = cubecoords.from_offset(resultX, resultY)
            local result_hex = map_get_hex(map, result_cube)
            local selected_cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
            local selected_hex = map_get_hex(map, selected_cube)
            
            -- If clicking on a legal move hex (marked with can_move), try to move
            if result_hex and result_hex.can_move then
                local did_move = move_piece_on_map(map, selected_piece_x, selected_piece_y, resultX, resultY)
                clear_all_neighbours(map, w, h)
                move_mode = 0
                if did_move == true then
                    pass_turn(active_player_id)
                end
                return
            else
                -- Clicking elsewhere cancels the selection
                move_mode = 0
                highlight = 0
                clear_all_neighbours(map, w, h)
                return
            end
        end
        if (resultX > 0 and resultY > 0) then
            if selectPieceOnMap(map, resultX, resultY, active_player_id) then
                highlight = 1
                clear_all_neighbours(map, w, h)
                local selected_cube = cubecoords.from_offset(resultX, resultY)
                mark_legal_moves_for_piece(map, selected_cube, w, h)
                selected_piece_x = resultX
                selected_piece_y = resultY
                if player[active_player_id].pieces[1].inStock == 0 then
                    move_mode = 1
                end
                return
            elseif (not tryAddPieceToMap(active_player_id, active_piece_id, map, resultX, resultY)) then
                return
            end
            pass_turn(active_player_id)
        end
    end
 end

function love.update(dt)
    mouseX, mouseY = love.mouse.getPosition()
    resultX, resultY = hexagon.toHexagonCoordinates(mouseX, mouseY, grid)
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
    if (highlight == 1 and move_mode == 1) then
        drawSelected(map, selected_piece_x, selected_piece_y, grid)
    end
    printPlayerStock(player, active_player_id, menu_offset_x, 20)
    print_map_pieces(map, w, h, menu_offset_x, 200)
    
    -- Draw cube coordinates if enabled
    if show_cube_coords then
        love.graphics.setColor(1, 1, 1, 0.8)
        for _, hex in pairs(map.hexes) do
            local col, row = cubecoords.to_offset(hex.cube)
            local hx, hy = hexagon.toPlanCoordinates(col, row, grid)
            local coord_text = hex.cube.x .. "," .. hex.cube.y .. "," .. hex.cube.z
            love.graphics.print(coord_text, hx - 25, hy - 8, 0, 0.8, 0.8)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    if resultX == -1 or resultY == -1 then
        love.graphics.print("Out of grid", 0, window_h - 20)
    else
        local hover_cube = cubecoords.from_offset(resultX, resultY)
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
