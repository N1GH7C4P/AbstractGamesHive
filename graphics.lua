require "hexagon"
require "map"
cubecoords = require "cubecoords"

function drawAddedPieces(map, canvas, grid, camera_x, camera_y)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    
    love.graphics.setCanvas(canvas)
    
    -- Iterate over all hexes using cube coordinates
    for cube_key, hex in pairs(map.hexes) do
        if hex.piece then
            -- Convert cube coordinates directly to pixel coordinates
            local cube = cubecoords.from_key(cube_key)
            local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
            hx = hx + camera_x
            hy = hy + camera_y
            
            -- Draw hex background based on player
            if hex.player_id == 1 then
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.1, 0.1, 0.1)
            else
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.9, 0.9, 0.9)
            end
            
            -- Draw piece initials
            love.graphics.setColor(hex.piece.color)
            love.graphics.print(hex.piece.initials, hx-8, hy-8)
            
            -- Draw stack height indicator for beetles or stacked pieces
            if hex.piece.under_piece then
                -- Calculate stack height
                local height = 1
                local current = hex.piece.under_piece
                while current do
                    height = height + 1
                    current = current.under_piece
                end
                
                -- Draw height number below piece initials
                love.graphics.setColor(1, 1, 0, 1)  -- Yellow color for visibility
                love.graphics.print(tostring(height), hx-3, hy+5)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    love.graphics.setCanvas()
end

function drawGridHexes(map, canvas, grid, camera_x, camera_y)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    
    love.graphics.setCanvas(canvas)
    
    -- Draw all hexes that exist in the map using cube coordinates directly
    for cube_key, hex in pairs(map.hexes) do
        local cube = cubecoords.from_key(cube_key)
        -- Convert cube coordinates directly to pixel coordinates
        local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
        drawHexagon(hx + camera_x, hy + camera_y, grid.piecesize, grid.pointyTopped)
    end
    
    love.graphics.setCanvas()
end

function drawBackground(canvas, w, h)
    love.graphics.setColor(0.2,0.1,0.4,1)
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(0,1,0,1)
end

function drawSelected(map, x, y, grid, camera_x, camera_y)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    
    -- x, y are offset coordinates
    -- Don't recalculate legal moves here - they should already be marked
    -- when the piece was selected in the mouse handler
    
    -- Draw legal move indicators
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_move then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            drawHexagon(hX + camera_x, hY + camera_y, grid.piecesize, false, true, 1, 0.5, 0.5, 0.3)
        end
    end
    
    -- Draw selection indicator at source hex
    local selected_cube = cubecoords.from_offset(x, y)
    local hX, hY = cubecoords.to_pixel(selected_cube, grid.piecesize)
    drawHexagon(hX + camera_x, hY + camera_y, grid.piecesize - 5, false, false, 0, 1, 0, 1)
end

function printPlayerStock(player, player_id, x, y)
    local pieces = player[player_id].pieces
    love.graphics.print("Player "..player_id.."'s remaining pieces", x, y)
    
    for i = 1, #pieces do
        local piece = pieces[i]
        local pieceName = piece.template and piece.template.name or piece.name
        love.graphics.print(pieceName..": "..tostring(piece.inStock), x, y + 10 + i*20)
        if (i == active_piece_id) then
            love.graphics.print("<==", x+100, y + 10 + i*20)
        end
    end
end