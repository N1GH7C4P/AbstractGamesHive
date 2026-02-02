-- Rendering functions for pieces, grid, and UI elements

local hexagon = require "hexagon"
local cubecoords = require "cubecoords"
local animation = require "animation"
local Config = require "config"

-- Draw hex background based on player ID
local function drawHexBackground(hx, hy, piecesize, pointyTopped, player_id)
    local color = player_id == 1 and Config.style.player1Piece or Config.style.player2Piece
    hexagon.draw_hexagon(hx, hy, piecesize, pointyTopped, true, color[1], color[2], color[3], color[4])
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
local function drawStackHeightIndicator(piece, player_id, hx, hy, zoom)
    if piece.under_piece then
        local height = calculateStackHeight(piece)
        local c = player_id == 1 and Config.style.player1StackIndicator or Config.style.player2StackIndicator
        local scale = zoom * (Config.style.stackIndicatorScale or 1)
        love.graphics.setColor(c[1], c[2], c[3], c[4])
        love.graphics.print(tostring(height), hx - 5 * zoom, hy + 3 * zoom, 0, scale, scale)
    end
end

-- Draw border for pieces that moved last turn
local function drawMovementBorder(piece, hx, hy, piecesize, pointyTopped, zoom)
    if piece.has_moved_last_turn then
        local c = Config.style.movedPieceBorder
        love.graphics.setLineWidth(3 * zoom)
        hexagon.draw_hexagon(hx, hy, piecesize, pointyTopped, false, c[1], c[2], c[3], c[4])
        love.graphics.setLineWidth(1)
    end
end

-- Draw a single piece at the given pixel coordinates
local function drawPieceAtPosition(piece, player_id, hx, hy, grid, zoom)
    drawHexBackground(hx, hy, grid.piecesize * zoom, grid.pointyTopped, player_id)
    loadPieceImage(piece)
    drawPieceGraphic(piece, hx, hy, grid.piecesize, zoom)
    drawStackHeightIndicator(piece, player_id, hx, hy, zoom)
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

    local c = Config.style.gridLine
    for cube_key, hex in pairs(map.hexes) do
        local cube = cubecoords.from_key(cube_key)
        local hx, hy = cubecoords.to_pixel(cube, grid.piecesize)
        hexagon.draw_hexagon(hx * zoom + camera_x, hy * zoom + camera_y, grid.piecesize * zoom, grid.pointyTopped, false, c[1], c[2], c[3], c[4])
    end

    love.graphics.setCanvas()
end

function drawBackground(canvas, w, h)
    local c = Config.style.background
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw highlights for legal move locations
local function drawLegalMoveHighlights(map, grid, camera_x, camera_y, zoom)
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_move then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)

            local c = hex.is_beetle_move and Config.style.beetleClimb or Config.style.normalMove
            hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, c[1], c[2], c[3], c[4])
        end
    end
end

-- Draw highlights for pillbug drop locations
local function drawPillbugDropHighlights(map, grid, camera_x, camera_y, zoom)
    local c = Config.style.dropLocation
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_drop then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)
            hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, c[1], c[2], c[3], c[4])
        end
    end
end

-- Draw highlights for special ability targets
local function drawSpecialAbilityHighlights(map, grid, camera_x, camera_y, zoom)
    local beetle = Config.style.beetleClimb
    local special = Config.style.specialAbility
    for cube_key, hex in pairs(map.hexes) do
        if hex.can_special then
            local cube = cubecoords.from_key(cube_key)
            local hX, hY = cubecoords.to_pixel(cube, grid.piecesize)

            if hex.has_dual_option then
                hexagon.draw_split_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false,
                                beetle[1], beetle[2], beetle[3], beetle[4],
                                special[1], special[2], special[3], special[4])
            else
                hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, grid.piecesize * zoom, false, true, special[1], special[2], special[3], special[4])
            end
        end
    end
end

-- Draw selection indicator at source hex
local function drawSelectionIndicator(x, y, grid, camera_x, camera_y, zoom)
    local c = Config.style.selection
    local selected_cube = cubecoords.from_offset(x, y)
    local hX, hY = cubecoords.to_pixel(selected_cube, grid.piecesize)
    hexagon.draw_hexagon(hX * zoom + camera_x, hY * zoom + camera_y, (grid.piecesize - 5) * zoom, false, false, c[1], c[2], c[3], c[4])
end

function drawSelected(map, x, y, grid, camera_x, camera_y, zoom)
    camera_x = camera_x or 0
    camera_y = camera_y or 0
    zoom = zoom or 1.0
    
    drawLegalMoveHighlights(map, grid, camera_x, camera_y, zoom)
    drawPillbugDropHighlights(map, grid, camera_x, camera_y, zoom)
    drawSpecialAbilityHighlights(map, grid, camera_x, camera_y, zoom)
    drawSelectionIndicator(x, y, grid, camera_x, camera_y, zoom)
end

-- Draw selection highlight for active piece
local function drawSelectionHighlight(px, py, size)
    local c = Config.style.selectionHighlight
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    hexagon.draw_hexagon(px, py, size + 5, false, true, c[1], c[2], c[3], 1)
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
    local c = player_id == 1 and Config.style.player1Selector or Config.style.player2Selector
    local t = player_id == 1 and Config.style.player1SelectorText or Config.style.player2SelectorText
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    hexagon.draw_hexagon(px, py, size, false, true, c[1], c[2], c[3], c[4])

    local template = piece.template
    loadPieceTemplateImage(template)
    drawPieceImageOrInitials(template, px, py, size)

    love.graphics.setColor(t[1], t[2], t[3], t[4])
    love.graphics.print("x" .. piece.inStock, px - 10, py + 10)
end

-- Draw unavailable (out of stock) piece button
local function drawUnavailablePieceButton(piece, px, py, size)
    local c = Config.style.selectorDisabled
    local t = Config.style.selectorDisabledText
    love.graphics.setColor(c[1], c[2], c[3], c[4])
    hexagon.draw_hexagon(px, py, size, false, true, c[1], c[2], c[3], c[4])
    love.graphics.setColor(t[1], t[2], t[3], t[4])
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
    local popup_x = mouseX + 20
    local popup_y = mouseY - 40
    local popup_width = 150
    local popup_height = 80

    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", popup_x, popup_y, popup_width, popup_height, 5, 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", popup_x, popup_y, popup_width, popup_height, 5, 5)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Choose Power:", popup_x + 10, popup_y + 10)

    local option_y = popup_y + 35
    local beetle = Config.style.beetleClimb
    love.graphics.setColor(beetle[1], beetle[2], beetle[3], 1)
    love.graphics.rectangle("fill", popup_x + 10, option_y, 15, 15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Beetle (climb)", popup_x + 30, option_y)

    option_y = option_y + 25
    local special = Config.style.specialAbility
    love.graphics.setColor(special[1], special[2], special[3], 1)
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

function setupCanvases()
    love.graphics.setCanvas(G.canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas(G.overlay)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()
end

function drawGameBoard()
    drawBackground(G.canvas, G.window_w, G.window_h)
    drawGridHexes(G.map, G.canvas, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    drawAddedPieces(G.map, G.overlay, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    love.graphics.draw(G.canvas)
    love.graphics.draw(G.overlay)
    if (G.highlight == 1 and G.move_mode == 1) then
        drawSelected(G.map, G.selected_piece_x, G.selected_piece_y, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    end
end

return {
    drawAddedPieces = drawAddedPieces,
    drawGridHexes = drawGridHexes,
    drawBackground = drawBackground,
    drawSelected = drawSelected,
    drawPieceSelector = drawPieceSelector,
    getPieceSelectorHover = getPieceSelectorHover,
    clickPieceSelector = clickPieceSelector,
    drawMosquitoChoicePopup = drawMosquitoChoicePopup,
    checkMosquitoChoicePopupClick = checkMosquitoChoicePopupClick,
    printPlayerStock = printPlayerStock,
    setupCanvases = setupCanvases,
    drawGameBoard = drawGameBoard,
}