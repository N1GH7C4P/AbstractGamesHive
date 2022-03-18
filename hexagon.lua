local hexagon = {}

local function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

function drawHexagon(x, y, piecesize, pointyTopped, fill)
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
    if fill then
        love.graphics.polygon("fill", vertices)
    else
        love.graphics.polygon("line", vertices)
    end
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

function hexagon.drawGrid(grid, canvas)
    love.graphics.setCanvas(canvas)
    for i = 1, grid.height do
        for j = 1, grid.width do
            local hx, hy = hexagon.toPlanCoordinates(i, j, grid)
                drawHexagon(hx, hy, grid.piecesize, grid.pointyTopped)
        end
    end
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

    -- Out of the grid
    if resultX < 1 or resultX > grid.width or resultY < 1 or resultY > grid.height then
        resultX = -1
        resultY = -1
    end

    return resultX, resultY
end

function hexagon.updateNeigbours(x, y, grid, pieces)
    if x < 0 or y < 0 then
        return
    end
    for i = 0, grid.height do
        for j = 0, grid.width do
            if (i % 2 == 0) then
                -- Neigbours: (X,Y-1),(X+1,Y-1),(X-1,Y),(X+1,Y),(X,Y+1),(X+1,Y+1)
                if (i == y - 1 and j == x) or (i == y - 1 and j == x + 1) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x) or (i == y + 1 and j == x + 1) then
                    print("x: ",j,"y: ", i)
                else

                end
            else
                -- Neighbours: (X-1,Y-1),(X,Y-1),(X-1,Y),(X+1,Y),(X-1,Y+1),(X,Y+1)
                if (i == y - 1 and j == x - 1) or (i == y - 1 and j == x) or (i == y - 1 and j == x) or (i == y and j == x + 1) or (i == y + 1 and j == x - 1) or (i == y + 1 and j == x) then
                    print("x: ",j,"y: ", i)
                else

                end
            end
        end
    end
    print("###############################################")
end

return hexagon
