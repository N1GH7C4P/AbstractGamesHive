local hexagon = require "hexagon"
local map = require "map"
local cubecoords = require "cubecoords"
local animation = require "animation"

-- Draw hex background based on player ID
local function drawHexBackground(hx, hy, piecesize, pointyTopped, player_id)
    if player_id == 1 then
        hexagon.draw_hexagon(hx, hy, piecesize, pointyTopped, true, 0.1, 0.1, 0.1)
    else
        hexagon.draw_hexagon(hx, hy, piecesize, pointyTopped, true, 0.9, 0.9, 0.9)
    end
end

-- Load piece image if needed
local function loadPieceImage(piece)
    if piece.loadImage then
        piece:loadImage()
    end
end

-- Draw piece image or initials as fallback
local function drawPieceGraphic(piece, hx, hy, piecesize, zoom)
    if piece.image then
        local image = piece.image
        local image_scale = (piecesize * 1.6 * zoom) / image:getWidth()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, hx, hy, 0, image_scale, image_scale, image:getWidth()/2, image:getHeight()/2)
    else
        love.graphics.setColor(piece.color)
        love.graphics.print(piece.initials, hx-8*zoom, hy-8*zoom, 0, zoom, zoom)
    end
end

-- Calculate stack height for stacked pieces
local function calculateStackHeight(piece)
    local height = 1
    local current = piece.under_piece
    while current do
        height = height + 1
        current = current.under_piece
    end
    return height
end

-- Draw stack height indicator
local function drawStackHeightIndicator(piece, hx, hy, zoom)
    if piece.under_piece then
        local height = calculateStackHeight(piece)
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print(tostring(height), hx-3*zoom, hy+5*zoom, 0, zoom, zoom)
    end
end

-- Draw red border for pieces that moved last turn
local function drawMovementBorder(piece, hx, hy, piecesize, pointyTopped, zoom)
    if piece.has_moved_last_turn then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.setLineWidth(3 * zoom)
        hexagon.draw_hexagon(hx, hy, piecesize, pointyTopped, false)
        love.graphics.setLineWidth(1)
    end
end

-- Draw a single piece at the given pixel coordinates
local function drawPieceAtPosition(piece, player_id, hx, hy, grid, zoom)
    drawHexBackground(hx, hy, grid.piecesize * zoom, grid.pointyTopped, player_id)
    loadPieceImage(piece)
    drawPieceGraphic(piece, hx, hy, grid.piecesize, zoom)
    drawStackHeightIndicator(piece, hx, hy, zoom)
    drawMovementBorder(piece, hx, hy, grid.piecesize * zoom, grid.pointyTopped, zoom)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw all static pieces on the board
local function drawStaticPieces(map, grid, camera_x, camera_y, zoom)
    for cube_key, hex in pairs(map.hexes) do
        if hex.piece and not animation.is_animating_from(cubecoords.from_key(cube_key)) then
            local cube = cubecoords.from_key(cube_key)
            local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
            hx = hx * zoom + camera_x
            hy = hy * zoom + camera_y
            
            drawPieceAtPosition(hex.piece, hex.player_id, hx, hy, grid, zoom)
        end
    end
end

-- Draw the currently animating piece if animation is active
local function drawAnimatedPiece(grid, camera_x, camera_y, zoom)
    local anim_x, anim_y, anim_piece = animation.get_animated_position(grid.piecesize)
    
    if anim_x and anim_y and anim_piece then
        local hx = anim_x * zoom + camera_x
        local hy = anim_y * zoom + camera_y
        
        drawPieceAtPosition(anim_piece, anim_piece.owner, hx, hy, grid, zoom)
    end
end

function drawAddedPieces(map, canvas, grid, camera_x, camera_y, zoom)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    zoom = zoom or 1.0
    
    love.graphics.setCanvas(canvas)
    
    drawStaticPieces(map, grid, camera_x, camera_y, zoom)
    drawAnimatedPiece(grid, camera_x, camera_y, zoom)
    
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
        hexagon.draw_hexagon(hx * zoom + camera_x, hy * zoom + camera_y, grid.piecesize * zoom, grid.pointyTopped)
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
            
            -- Check for beetle-specific move (climbing on top)
            if hex.is_beetle_move then
                -- Purple highlight for beetle climbing moves
                hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 0.6, 0.2, 0.8, 0.6)
            else
                -- Orange highlight for normal moves
                hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 1, 0.5, 0, 0.6)
            end
        end
        -- Draw pillbug drop locations in red
        if hex.can_drop then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            -- Red highlight for pillbug drop locations
            hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 1, 0, 0, 0.6)
        end
        -- Draw special ability targets (pickable pieces) in cyan
        if hex.can_special then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            
            -- Check for dual option (can also be climbed with beetle)
            if hex.has_dual_option then
                -- Split hexagon: purple (beetle climb) on left, cyan (pillbug pick) on right
                hexagon.draw_split_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false,
                                0.6, 0.2, 0.8, 0.5,  -- Purple for beetle climb
                                0, 1, 1, 0.5)         -- Cyan for pillbug special
            else
                -- Regular cyan highlight for pillbug-only
                hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, 0, 1, 1, 0.4)
            end
        end
    end
    
    -- Draw selection indicator at source hex
    local selected_cube = cubecoords.from_offset(x, y)
    local hX, hY = cubecoords.to_pixel(selected_cube, grid.piecesize)
    hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, (grid.piecesize - 5) * zoom, false, false, 0, 1, 0, 1)
end

-- Draw selection highlight for active piece
local function drawSelectionHighlight(px, py, size)
    love.graphics.setColor(1, 1, 0, 0.5)
    hexagon.draw_hexagon(px, py, size + 5, false, true, 1, 1, 0)
end

-- Load template image if not already loaded
local function loadPieceTemplateImage(template)
    if template.image_path and not template.image then
        local success, image = pcall(love.graphics.newImage, template.image_path)
        if success then
            template.image = image
        end
    end
end

-- Draw piece image or initials as fallback
local function drawPieceImageOrInitials(template, px, py, size)
    if template.image then
        local image = template.image
        local image_scale = (size * 1.6) / image:getWidth()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, px, py, 0, image_scale, image_scale, image:getWidth()/2, image:getHeight()/2)
    else
        love.graphics.setColor(template.color)
        love.graphics.print(template.initials, px - 8, py - 8)
    end
end

-- Draw available piece button with image and stock count
local function drawAvailablePieceButton(piece, player_id, px, py, size)
    if player_id == 1 then
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
    else
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
    end
    hexagon.draw_hexagon(px, py, size, false, true, player_id == 1 and 0.2 or 0.9, player_id == 1 and 0.2 or 0.9, player_id == 1 and 0.2 or 0.9)
    
    local template = piece.template
    loadPieceTemplateImage(template)
    drawPieceImageOrInitials(template, px, py, size)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("x" .. piece.inStock, px - 10, py + 10)
end

-- Draw unavailable (out of stock) piece button
local function drawUnavailablePieceButton(piece, px, py, size)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
    hexagon.draw_hexagon(px, py, size, false, true, 0.3, 0.3, 0.3)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.print(piece.template.initials, px - 8, py - 8)
end

function drawPieceSelector(player, player_id, x, y, size)
    size = size or 30
    local spacing = size * 2.5

    local pieces = player[player_id].pieces
    for i = 1, #pieces do
        local piece = pieces[i]
        local px = x + (i - 1) * spacing
        local py = y + 40
        
        if i == G.active_piece_id then
            drawSelectionHighlight(px, py, size)
        end
        
        if piece.inStock > 0 then
            drawAvailablePieceButton(piece, player_id, px, py, size)
        else
            drawUnavailablePieceButton(piece, px, py, size)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Get hover info for piece selector (returns piece index, piece id, name and stock if hovering)
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
            return i, pieces[i].template.id, pieces[i].template.name, pieces[i].inStock
        end
    end
    
    return nil, nil, nil, nil
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

-- Draw mosquito power choice popup
function drawMosquitoChoicePopup(mouseX, mouseY)
    -- Draw popup background
    local popup_x = mouseX + 20
    local popup_y = mouseY - 40
    local popup_width = 150
    local popup_height = 80
    
    -- Draw background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", popup_x, popup_y, popup_width, popup_height, 5, 5)
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup_x, popup_y, popup_width, popup_height, 5, 5)
    love.graphics.setLineWidth(1)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Choose Power:", popup_x + 10, popup_y + 10)
    
    -- Draw options
    local option_y = popup_y + 35
    
    -- Beetle option (purple)
    love.graphics.setColor(0.6, 0.2, 0.8, 1)
    love.graphics.rectangle("fill", popup_x + 10, option_y, 15, 15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Beetle (climb)", popup_x + 30, option_y)
    
    -- Pillbug option (cyan)
    option_y = option_y + 25
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.rectangle("fill", popup_x + 10, option_y, 15, 15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Pillbug (move)", popup_x + 30, option_y)
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Check which option is clicked in the popup (returns "beetle", "pillbug", or nil)
function checkMosquitoChoicePopupClick(mouseX, mouseY, popup_mouse_x, popup_mouse_y)
    local popup_x = popup_mouse_x + 20
    local popup_y = popup_mouse_y - 40
    local popup_width = 150
    local popup_height = 80
    
    -- Check if click is within popup bounds
    if mouseX < popup_x or mouseX > popup_x + popup_width or
       mouseY < popup_y or mouseY > popup_y + popup_height then
        return nil  -- Click outside popup
    end
    
    -- Check beetle option
    local beetle_y = popup_y + 35
    if mouseY >= beetle_y and mouseY <= beetle_y + 15 then
        return "beetle"
    end
    
    -- Check pillbug option
    local pillbug_y = popup_y + 60
    if mouseY >= pillbug_y and mouseY <= pillbug_y + 15 then
        return "pillbug"
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
        if (i == G.active_piece_id) then
            love.graphics.print("<==", x+100, y + 10 + i*20)
        end
    end
end