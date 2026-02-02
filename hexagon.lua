-- Hexagon grid utilities and rendering

local hexagon = {}

function hexagon.draw_hexagon(x, y, piecesize, pointyTopped, fill, r, g ,b, a)
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1
    local vertices = {}

    if pointyTopped then
        table.insert(vertices, x)
        table.insert(vertices, y + piecesize)
        for i = 1, 5 do
            table.insert(vertices, x + piecesize * math.sin(i * math.pi / 3))
            table.insert(vertices, y + piecesize * math.cos(i * math.pi / 3))
        end
    else
        table.insert(vertices, x + piecesize)
        table.insert(vertices, y)
        for i = 1, 5 do
            table.insert(vertices, x + piecesize * math.cos(i * math.pi / 3))
            table.insert(vertices, y + piecesize * math.sin(i * math.pi / 3))
        end
    end
    love.graphics.setColor(r, g, b, a)
    if fill then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
    love.graphics.setColor(1, 1, 1)
end

-- Draw a hexagon split diagonally with two colors (for showing multiple options)
function hexagon.draw_split_hexagon(x, y, piecesize, pointyTopped, r1, g1, b1, a1, r2, g2, b2, a2)
    a1 = a1 or 1
    a2 = a2 or 1

    -- Generate all vertices
    local vertices = {}
    if pointyTopped then
        table.insert(vertices, {x, y + piecesize})
        for i = 1, 5 do
            table.insert(vertices, {x + piecesize * math.sin(i * math.pi / 3), y + piecesize * math.cos(i * math.pi / 3)})
        end
    else
        table.insert(vertices, {x + piecesize, y})
        for i = 1, 5 do
            table.insert(vertices, {x + piecesize * math.cos(i * math.pi / 3), y + piecesize * math.sin(i * math.pi / 3)})
        end
    end

    -- Draw first half (north-east: includes vertices 6, 1, 2, 3 for full coverage)
    love.graphics.setColor(r1, g1, b1, a1)
    local half1 = {x, y, vertices[6][1], vertices[6][2], vertices[1][1], vertices[1][2], vertices[2][1], vertices[2][2], vertices[3][1], vertices[3][2], x, y}
    love.graphics.polygon("fill", half1)

    -- Draw second half (south-west: includes vertices 3, 4, 5, 6 for full coverage)
    love.graphics.setColor(r2, g2, b2, a2)
    local half2 = {x, y, vertices[3][1], vertices[3][2], vertices[4][1], vertices[4][2], vertices[5][1], vertices[5][2], vertices[6][1], vertices[6][2], x, y}
    love.graphics.polygon("fill", half2)

    love.graphics.setColor(1, 1, 1, 1)
end

return {
    draw_hexagon = hexagon.draw_hexagon,
    draw_split_hexagon = hexagon.draw_split_hexagon,
}
