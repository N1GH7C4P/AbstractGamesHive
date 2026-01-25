require "hexagon"
require "map"
cubecoords = require "cubecoords"

function drawAddedPieces(map, canvas, grid)
    love.graphics.setCanvas(canvas)
    
    -- Iterate over all hexes using cube coordinates
    for cube_key, hex in pairs(map.hexes) do
        if hex.piece then
            -- Convert cube coordinates to offset for rendering
            local cube = cubecoords.from_key(cube_key)
            local col, row = cubecoords.to_offset(cube)
            
            local hx, hy = hexagon.toPlanCoordinates(col, row, grid)
            
            -- Draw hex background based on player
            if hex.player_id == 1 then
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.1, 0.1, 0.1)
            else
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.9, 0.9, 0.9)
            end
            
            -- Draw piece initials
            love.graphics.setColor(hex.piece.color)
            love.graphics.print(hex.piece.initials, hx-8, hy-8)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    love.graphics.setCanvas()
end

function drawBackground(canvas, w, h)
    love.graphics.setColor(0.2,0.1,0.4,1)
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(0,1,0,1)
end

function drawSelected(map, x, y, grid)
    -- x, y are offset coordinates
    -- Don't recalculate legal moves here - they should already be marked
    -- when the piece was selected in the mouse handler
    
    -- Draw legal move indicators
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_move then
            local cube = cubecoords.from_key(cube_key)
            local col, row = cubecoords.to_offset(cube)
            local hX, hY = hexagon.toPlanCoordinates(col, row, grid)
            drawHexagon(hX, hY, grid.piecesize, false, true, 1, 0.5, 0.5, 0.3)
        end
    end
    
    -- Draw selection indicator at source hex
    local hX, hY = hexagon.toPlanCoordinates(x, y, grid)
    drawHexagon(hX, hY, grid.piecesize - 5, false, false, 0, 1, 0, 1)
end

function printPlayerStock(player, player_id, x, y)
    for i = 1, 5 do
        love.graphics.print("Player "..player_id.."'s remaining pieces", x, y)    
        love.graphics.print(player[player_id].pieces[i].template.name..": "..tostring(player[player_id].pieces[i].inStock), x, y + 10 + i*20)
        if (i == active_piece_id) then
            love.graphics.print("<==", x+100, y + 10 + i*20)
        end
    end
end