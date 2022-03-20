require "hexagon"
require "map"

function drawAddedPieces(map, canvas, grid)

    love.graphics.setCanvas(canvas)

    for i = 1, map.h do
        for j = 1, map.w do
            if map[i][j].piece then
                local hx, hy = hexagon.toPlanCoordinates(j, i, grid)
                if (map[i][j].player_id == 1) then
                    drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.1, 0.1, 0.1)
                else
                    drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, true, 0.9, 0.9, 0.9)
                end
                love.graphics.setColor(map[i][j].piece.color)
                love.graphics.print(map[i][j].piece.initials, hx-8, hy-8)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end
    love.graphics.setCanvas()
end

function drawBackground(canvas, w, h)
    love.graphics.setColor(0.2,0.1,0.4,1)
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(0,1,0,1)
end

function drawSelected(x, y)
    for i = 1, h do
        for j = 1, w do
            if try_move_piece_on_map(map, x, y, j, i) then
                local hX, hY = hexagon.toPlanCoordinates(j, i, grid)
                drawHexagon(hX, hY, grid.piecesize, false, true, 1, 0.5, 0.5, 0.3)
            end
        end
    end
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