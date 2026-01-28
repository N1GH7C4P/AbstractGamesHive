require "hexagon"
require "map"
cubecoords = require "cubecoords"

function drawAddedPieces(map, canvas, grid, camera_x, camera_y, zoom)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    zoom = zoom or 1.0
    
    love.graphics.setCanvas(canvas)
    
    -- Iterate over all hexes using cube coordinates
    for cube_key, hex in pairs(map.hexes) do
        if hex.piece then
            -- Convert cube coordinates directly to pixel coordinates
            local cube = cubecoords.from_key(cube_key)
            local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
            hx = hx * zoom + camera_x
            hy = hy * zoom + camera_y
            
            -- Draw hex background based on player
            if hex.player_id == 1 then
                drawHexagon(hx, hy, grid.piecesize * zoom, grid.pointyTopped, true, 0.1, 0.1, 0.1)
            else
                drawHexagon(hx, hy, grid.piecesize * zoom, grid.pointyTopped, true, 0.9, 0.9, 0.9)
            end
            
            -- Load piece image if needed
            if hex.piece.loadImage then
                hex.piece:loadImage()
            end
            
            -- Draw piece image if available, otherwise draw initials
            if hex.piece.image then
                local image = hex.piece.image
                local image_scale = (grid.piecesize * 1.6 * zoom) / image:getWidth()
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, hx, hy, 0, image_scale, image_scale, image:getWidth()/2, image:getHeight()/2)
            else
                -- Draw piece initials (fallback)
                love.graphics.setColor(hex.piece.color)
                love.graphics.print(hex.piece.initials, hx-8*zoom, hy-8*zoom, 0, zoom, zoom)
            end
            
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
                love.graphics.print(tostring(height), hx-3*zoom, hy+5*zoom, 0, zoom, zoom)
            end
            
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
    
    love.graphics.setCanvas()
end

function drawGridHexes(map, canvas, grid, camera_x, camera_y, zoom)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    zoom = zoom or 1.0
    
    love.graphics.setCanvas(canvas)
    
    -- Draw all hexes that exist in the map using cube coordinates directly
    for cube_key, hex in pairs(map.hexes) do
        local cube = cubecoords.from_key(cube_key)
        -- Convert cube coordinates directly to pixel coordinates
        local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
        drawHexagon(hx * zoom + camera_x, hy * zoom + camera_y, grid.piecesize * zoom, grid.pointyTopped)
    end
    
    love.graphics.setCanvas()
end

function drawBackground(canvas, w, h)
    love.graphics.setColor(0.2,0.1,0.4,1)
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(0,1,0,1)
end

function drawSelected(map, x, y, grid, camera_x, camera_y, zoom)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    zoom = zoom or 1.0
    
    -- x, y are offset coordinates
    -- Don't recalculate legal moves here - they should already be marked
    -- when the piece was selected in the mouse handler
    
    -- Draw legal move indicators
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_move then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            -- Orange highlight for normal moves - make it bright and opaque
            drawHexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 1, 0.5, 0, 0.6)
        end
        -- Draw special ability targets (pickable pieces) in cyan
        if hex.can_special then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            drawHexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 0, 1, 1, 0.4)
        end
    end
    
    -- Draw selection indicator at source hex
    local selected_cube = cubecoords.from_offset(x, y)
    local hX, hY = cubecoords.to_pixel(selected_cube, grid.piecesize)
    drawHexagon(hX * zoom + camera_x, hY * zoom + camera_y, (grid.piecesize - 5) * zoom, false, false, 0, 1, 0, 1)
end

function drawPieceSelector(player, player_id, x, y, size)
    size = size or 30
    local spacing = size * 2.5

    local pieces = player[player_id].pieces
    for i = 1, #pieces do
        local piece = pieces[i]
        local px = x + (i - 1) * spacing
        local py = y + 40
        
        -- Draw button background
        if i == active_piece_id then
            -- Highlighted selection
            love.graphics.setColor(1, 1, 0, 0.5)
            drawHexagon(px, py, size + 5, false, true, 1, 1, 0)
        end
        
        -- Draw piece button
        if piece.inStock > 0 then
            -- Available piece
            if player_id == 1 then
                love.graphics.setColor(0.2, 0.2, 0.2, 1)
            else
                love.graphics.setColor(0.9, 0.9, 0.9, 1)
            end
            drawHexagon(px, py, size, false, true, player_id == 1 and 0.2 or 0.9, player_id == 1 and 0.2 or 0.9, player_id == 1 and 0.2 or 0.9)
            
            -- Load template image if needed (template might not have loadImage method)
            local template = piece.template
            if template.image_path and not template.image then
                local success, image = pcall(love.graphics.newImage, template.image_path)
                if success then
                    template.image = image
                end
            end
            
            -- Draw piece image or initials
            if template.image then
                local image = template.image
                local image_scale = (size * 1.6) / image:getWidth()
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, px, py, 0, image_scale, image_scale, image:getWidth()/2, image:getHeight()/2)
            else
                -- Draw piece initials (fallback)
                love.graphics.setColor(template.color)
                love.graphics.print(template.initials, px - 8, py - 8)
            end
            
            -- Draw stock count
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("x" .. piece.inStock, px - 10, py + 10)
        else
            -- Out of stock - greyed out
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            drawHexagon(px, py, size, false, true, 0.3, 0.3, 0.3)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.print(piece.template.initials, px - 8, py - 8)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Get hover info for piece selector (returns piece index and name if hovering)
function getPieceSelectorHover(player, player_id, mouseX, mouseY, x, y, size)
    size = size or 30
    local spacing = size * 2.5
    local py = y + 40
    
    local pieces = player[player_id].pieces
    for i = 1, #pieces do
        local px = x + (i - 1) * spacing
        local dx = mouseX - px
        local dy = mouseY - py
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist < size then
            return i, pieces[i].template.name, pieces[i].inStock
        end
    end
    
    return nil, nil, nil
end

-- Check if mouse click is on piece selector and return selected piece
function clickPieceSelector(player, player_id, mouseX, mouseY, x, y, size)
    size = size or 30
    local spacing = size * 2.5
    local py = y + 40
    
    local pieces = player[player_id].pieces
    for i = 1, #pieces do
        if pieces[i].inStock > 0 then
            local px = x + (i - 1) * spacing
            local dx = mouseX - px
            local dy = mouseY - py
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist < size then
                return i
            end
        end
    end
    
    return nil
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