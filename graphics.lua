require "hexagon"
require "map"

function drawAddedPieces(map, canvas, grid)

    love.graphics.setCanvas(canvas)

    for i = 1, map.h do
        for j = 1, map.w do
            if map[i][j].piece then
                local hx, hy = hexagon.toPlanCoordinates(j, i, grid)
                if (map[i][j].player_id == 1) then
                    love.graphics.setColor(1,1,0,1)
                else
                    love.graphics.setColor(0,1,1,1)
                end
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped, map[i][j].player_id, 1)
                love.graphics.setColor(0,0,0,1)
                love.graphics.print(map[i][j].piece.initials, hx-8, hy-8)
                love.graphics.setColor(0,1,0,1)
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

function printPlayerStock(player, player_id, x, y)

    for i = 1, 5 do
        love.graphics.print("Player "..player_id.."'s remaining pieces", x, y)    
        love.graphics.print(player[player_id].pieces[i].template.name..": "..tostring(player[player_id].pieces[i].inStock), x, y + 10 + i*20)
        if (i == active_piece_id) then
            love.graphics.print("<==", x+100, y + 10 + i*20)
        end
    end
end