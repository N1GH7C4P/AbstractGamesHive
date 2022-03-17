require "hexagon/hexagon"

function drawAddedPieces(pieces)
    for i = 1, pieces do
        drawHexagon(pieces[i].x, pieces[i].y, pieces[i].size, false)
    end
end