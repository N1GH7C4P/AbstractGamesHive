local hexagon = {}

local function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

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

local function toHexagonCoordinatesHorizontal(x, y, grid)
    local piecesize = grid.piecesize
    local shifted = grid.shifted

    local tileX = 0
    local tileY = 0
    local tileThirdWidth = piecesize * math.cos(math.pi / 3)
    local tileWidth = 3 * tileThirdWidth
    local tileHalfHeight = piecesize * math.cos(math.pi / 6)
    local tileHeight = 2 * tileHalfHeight

    -- We use math.ceil because we start the coordinates at 1 and not 0
    tileX = math.ceil(x / tileWidth)

    local offset
    local hexagonA
    local hexagonB
    local hexagonC
    local resultX
    local resultY

    if math.fmod(x, tileWidth) < tileThirdWidth then
        if (not shifted and tileX % 2 == 0) or (shifted and tileX % 2 == 1) then
            tileY = math.ceil(y / tileHeight)
            offset = 0
        else
            tileY = math.ceil((y - tileHalfHeight) / tileHeight)
            offset = tileHalfHeight
        end

        -- Uncertain, so we check which hexagon is the nearest
        local xA = (tileX - 1) * tileWidth + piecesize
        local xB = (tileX - 1) * tileWidth + tileThirdWidth - piecesize
        local xC = xA
        local yA = (tileY - 1) * tileHeight + offset
        local yB = yA + tileHeight / 2
        local yC = yB + tileHeight / 2

        local distanceToA = distanceBetween(x, y, xA, yA)
        local distanceToB = distanceBetween(x, y, xB, yB)
        local distanceToC = distanceBetween(x, y, xC, yC)

        if (not shifted and tileX % 2 == 0) or (shifted and tileX % 2 == 1) then
            hexagonA = {X = tileX, Y = tileY - 1}
            hexagonC = {X = tileX, Y = tileY}
        else
            hexagonA = {X = tileX, Y = tileY}
            hexagonC = {X = tileX, Y = tileY + 1}
        end
        hexagonB = {X = tileX - 1, Y = tileY}

        local possiblepieces = {[distanceToA] = hexagonA, [distanceToB] = hexagonB, [distanceToC] = hexagonC}
        local distances = {}

        for k in pairs(possiblepieces) do
            table.insert(distances, k)
        end
        table.sort(distances)

        local closerHexagon = possiblepieces[distances[1]]
        resultX = closerHexagon.X
        resultY = closerHexagon.Y
    else
        if (not shifted and tileX % 2 == 0) or (shifted and tileX % 2 == 1) then
            tileY = math.ceil((y - tileHalfHeight) / tileHeight)
        else
            tileY = math.ceil(y / tileHeight)
        end

        resultX = tileX
        resultY = tileY
    end

    return resultX, resultY
end

local function toHexagonCoordinatesVertical(x, y, grid)
    local piecesize = grid.piecesize
    local shifted = grid.shifted

    local tileX = 0
    local tileY = 0
    local tileThirdHeight = piecesize * math.cos(math.pi / 3)
    local tileHeight = 3 * tileThirdHeight
    local tileHalfWidth = piecesize * math.cos(math.pi / 6)
    local tileWidth = 2 * tileHalfWidth

    -- We use math.ceil because we start the coordinates at 1 and not 0
    tileY = math.ceil(y / tileHeight)

    local offset
    local hexagonA
    local hexagonB
    local hexagonC
    local resultX
    local resultY

    if math.fmod(y, tileHeight) < tileThirdHeight then
        if (not shifted and tileY % 2 == 0) or (shifted and tileY % 2 == 1) then
            tileX = math.ceil(x / tileWidth)
            offset = 0
        else
            tileX = math.ceil((x - tileHalfWidth) / tileWidth)
            offset = tileHalfWidth
        end

        -- Uncertain, so we check which hexagon is the nearest
        local yA = (tileY - 1) * tileHeight + piecesize
        local yB = (tileY - 1) * tileHeight + tileThirdHeight - piecesize
        local yC = yA
        local xA = (tileX - 1) * tileWidth + offset
        local xB = xA + tileWidth / 2
        local xC = xB + tileWidth / 2

        local distanceToA = distanceBetween(x, y, xA, yA)
        local distanceToB = distanceBetween(x, y, xB, yB)
        local distanceToC = distanceBetween(x, y, xC, yC)

        if (not shifted and tileY % 2 == 0) or (shifted and tileY % 2 == 1) then
            hexagonA = {Y = tileY, X = tileX - 1}
            hexagonC = {Y = tileY, X = tileX}
        else
            hexagonA = {Y = tileY, X = tileX}
            hexagonC = {Y = tileY, X = tileX + 1}
        end
        hexagonB = {Y = tileY - 1, X = tileX}

        local possiblepieces = {[distanceToA] = hexagonA, [distanceToB] = hexagonB, [distanceToC] = hexagonC}
        local distances = {}

        for k in pairs(possiblepieces) do
            table.insert(distances, k)
        end
        table.sort(distances)

        local closerHexagon = possiblepieces[distances[1]]
        resultX = closerHexagon.X
        resultY = closerHexagon.Y
    else
        if (not shifted and tileY % 2 == 0) or (shifted and tileY % 2 == 1) then
            tileX = math.ceil((x - tileHalfWidth) / tileWidth)
        else
            tileX = math.ceil(x / tileWidth)
        end

        resultX = tileX
        resultY = tileY
    end

    return resultX, resultY
end

function hexagon.grid(width, height, piecesize, pointyTopped, shifted)
        local grid = {}
        assert(type(width) == "number", "width expects a number")
        grid.width = width
        assert(type(height) == "number", "height expects a number")
        grid.height = height
        assert(type(piecesize) == "number", "piecesize expects a number")
        grid.piecesize = piecesize
        assert(type(pointyTopped) == "boolean", "pointyTopped expects a boolean")
        grid.pointyTopped = pointyTopped
        assert(type(shifted) == "boolean", "shifted expects a boolean")
        grid.shifted = shifted

        return grid
end

function hexagon.drawGrid(grid, canvas, camera_x, camera_y)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    
    love.graphics.setCanvas(canvas)
    -- Note: This function now expects the map to be passed via a global or param
    -- For now, we'll draw based on grid dimensions, but the actual rendering
    -- should be done by iterating through map.hexes
    -- This is a compatibility stub - actual grid drawing happens in graphics.lua
    love.graphics.setCanvas()
end

-- Given the coordinates of an hexagon in the grid, return the coordinates of its center in the plan
function hexagon.toPlanCoordinates(x, y, grid)
    local piecesize = grid.piecesize
    local shifted = grid.shifted

    local hx
    local hy

    if grid.pointyTopped then
        hx = x * 2 * piecesize * (math.sin(math.pi / 3))
        hy = piecesize + (y - 1) * piecesize * (math.cos(math.pi / 3) + 1)

        if (shifted and y % 2 == 0) or (not shifted and y % 2 == 1) then
            hx = hx - piecesize * (math.sin(math.pi / 3))
        end
    else
        hx = piecesize + (x - 1) * piecesize * (math.cos(math.pi / 3) + 1)
        hy = y * 2 * piecesize * (math.sin(math.pi / 3))

        if (shifted and x % 2 == 0) or (not shifted and x % 2 == 1) then
            hy = hy - piecesize * (math.sin(math.pi / 3))
        end
    end

    return hx , hy
end

-- Given the coordinates of a point in the plan, return the coordinates of the hexagon under that point in the grid
function hexagon.toHexagonCoordinates(x, y, grid)
    local resultX = 0
    local resultY = 0

    if grid.pointyTopped then
        resultX, resultY = toHexagonCoordinatesVertical(x, y, grid)
    else
        resultX, resultY = toHexagonCoordinatesHorizontal(x, y, grid)
    end

    -- Don't check bounds - let the map determine if hex exists
    -- The calling code should check if map_get_hex returns nil
    return resultX, resultY
end

return hexagon
