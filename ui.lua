-- UI module - handles all user interface elements
local cubecoords = require("cubecoords")
local map_module = require("map")

local UI = {}
local keyDescriptions = {
    ["Left Click"] = "Select/move pieces, place pieces from inventory",
    ["Right Click"] = "Deselect piece, cancel action",
    ["Mouse Wheel"] = "Zoom in/out",
    ["Drag"] = "Pan camera around the board",
    ["Space"] = "Show this help screen",
    ["r"] = "Restart game (local only)",
    ["h"] = "Toggle cube coordinate display",
    ["c"] = "Toggle debug console",
    ["x"] = "Clear console output",
    ["d"] = "Save game to file",
    ["l"] = "Load game from file",
    ["n"] = "Host network game (port 12345)",
    ["m"] = "Join network game (localhost:12345)",
    ["q"] = "Quit/disconnect network game",
    ["+/="] = "Zoom in",
    ["-/_"] = "Zoom out",
    ["0"] = "Reset zoom to 1.0x",
    ["Escape"] = "Quit game",
}

function UI.drawHelpOverlay()
    if not G.show_help then return end
    -- Semi-transparent dark background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, G.window_w, G.window_h)
    -- Title
    love.graphics.setColor(1, 1, 0.5, 1)
    local title = "KEYBOARD & MOUSE CONTROLS"
    local font = love.graphics.getFont()
    local title_width = font:getWidth(title)
    love.graphics.print(title, (G.window_w - title_width) / 2, 50)
    -- Controls list
    love.graphics.setColor(1, 1, 1, 1)
    local y = 100
    local line_height = 25
    local key_x = G.window_w / 2 - 250
    local desc_x = G.window_w / 2 - 100
    -- Sort keys for consistent display
    local sorted_keys = {}
    for key, _ in pairs(keyDescriptions) do
        table.insert(sorted_keys, key)
    end
    table.sort(sorted_keys)
    for _, key in ipairs(sorted_keys) do
        local desc = keyDescriptions[key]
        love.graphics.setColor(1, 1, 0.5, 1)
        love.graphics.print(key, key_x, y)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(desc, desc_x, y)
        y = y + line_height
    end
    -- Footer
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local footer = "Release SPACE to close"
    local footer_width = font:getWidth(footer)
    love.graphics.print(footer, (G.window_w - footer_width) / 2, G.window_h - 50)
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawPieceSelectorUI(graphics)
    local network = require("network")
    local display_player_id = (network and network.mode ~= "none" and network.local_player_id) or G.active_player_id
    local piece_count = #G.player[display_player_id].pieces
    local piece_size = 30
    local piece_spacing = piece_size * 2.5
    local total_width = (piece_count - 1) * piece_spacing
    local center_x = (G.window_w - total_width) / 2
    graphics.drawPieceSelector(G.player, display_player_id, center_x, 20, piece_size)
    return center_x, piece_size, display_player_id, piece_count
end

function UI.drawPieceSelectorTooltip(graphics, center_x, piece_size, display_player_id, piece_count)
    local PiecesEnum = require("pieces/pieces_enum")
    local hover_piece_idx, hover_piece_id, hover_piece_name, hover_stock = graphics.getPieceSelectorHover(G.player, display_player_id, G.mouseX, G.mouseY, center_x, 20, piece_size)
    if not hover_piece_id then return end
    
    local rules_text = PiecesEnum.RULES[hover_piece_id] or "No rules available."
    local max_width = 400
    local font = love.graphics.getFont()
    local _, wrapped_lines = font:getWrap(rules_text, max_width - 20)
    local text_height = #wrapped_lines * font:getHeight() * font:getLineHeight()
    
    local is_rightmost = hover_piece_idx > (piece_count - 3)
    local tooltip_x = is_rightmost and (G.mouseX - max_width - 10) or (G.mouseX + 10)
    local tooltip_height = text_height + 60
    
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", tooltip_x, G.mouseY - 30, max_width, tooltip_height)
    
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.print(hover_piece_name, tooltip_x + 10, G.mouseY - 25)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("In stock: " .. hover_stock, tooltip_x + 10, G.mouseY - 10)
    
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.line(tooltip_x + 10, G.mouseY + 10, tooltip_x + max_width - 10, G.mouseY + 10)
    
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.printf(rules_text, tooltip_x + 10, G.mouseY + 15, max_width - 20, "left")
    
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawCubeCoordinatesOverlay()
    if not G.show_cube_coords then return end
    
    love.graphics.setColor(1, 1, 1, 0.8)
    for _, hex in pairs(G.map.hexes) do
        local hx, hy = cubecoords.to_pixel(hex.cube, G.size)
        hx = hx * G.camera_zoom + G.camera_x
        hy = hy * G.camera_zoom + G.camera_y
        local coord_text = hex.cube.x .. "," .. hex.cube.y .. "," .. hex.cube.z
        love.graphics.print(coord_text, hx - 25*G.camera_zoom, hy - 8*G.camera_zoom, 0, 0.8*G.camera_zoom, 0.8*G.camera_zoom)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawHoverCoordinates()
    local pixel_x = (G.mouseX - G.camera_x) / G.camera_zoom
    local pixel_y = (G.mouseY - G.camera_y) / G.camera_zoom
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
    local hover_hex = map_module.get_hex(G.map, hover_cube)
    
    if not hover_hex then
        love.graphics.print("Out of grid", 0, G.window_h - 20)
    else
        love.graphics.print("Hexagon coordinates: ["..hover_cube.x..","..hover_cube.y..","..hover_cube.z.."]", 0, G.window_h - 20)
    end
    
    return hover_hex
end

function UI.drawStackTooltip(hover_hex)
    if not (hover_hex and hover_hex.piece and hover_hex.piece.under_piece) then return end
    
    local stack_pieces = {}
    local current = hover_hex.piece
    
    while current do
        table.insert(stack_pieces, current)
        current = current.under_piece
    end
    
    local tooltip_width = 200
    local line_height = 20
    local tooltip_height = #stack_pieces * line_height + 30
    local tooltip_x = G.mouseX + 15
    local tooltip_y = G.mouseY + 15
    
    if tooltip_x + tooltip_width > G.window_w then
        tooltip_x = G.mouseX - tooltip_width - 15
    end
    if tooltip_y + tooltip_height > G.window_h - 100 then
        tooltip_y = G.mouseY - tooltip_height - 15
    end
    
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", tooltip_x, tooltip_y, tooltip_width, tooltip_height)
    
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.print("Stack (top to bottom):", tooltip_x + 5, tooltip_y + 5)
    
    local y_offset = 25
    for i, piece in ipairs(stack_pieces) do
        local player_color = piece.owner == 1 and "P1: " or "P2: "
        local piece_name = piece.name or "Unknown"
        
        if piece.owner == 1 then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 1)
        end
        
        love.graphics.print(i .. ". " .. player_color .. piece_name, tooltip_x + 10, tooltip_y + y_offset)
        y_offset = y_offset + line_height
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawStatus()
    love.graphics.print("Zoom: " .. string.format("%.1f", G.camera_zoom) .. "x", 0, G.window_h - 40)
    
    local network = require("network")
    if network.mode == "none" then return end
    
    love.graphics.setColor(0, 1, 0, 1)
    local status_y = G.window_h - 60
    if network.mode == "server" then
        local status = network.connected and "Hosting (Connected)" or "Hosting (Waiting...)"
        love.graphics.print(status, 0, status_y)
    elseif network.mode == "client" then
        local status = network.connected and "Connected to Server" or "Connecting..."
        love.graphics.print(status, 0, status_y)
    end
    
    if network.connected then
        local turn_text = network.is_local_turn and "YOUR TURN" or "Opponent's turn"
        love.graphics.print(turn_text, 0, status_y - 20)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawGameOverScreen()
    if not G.game_over then return end
    
    -- Semi-transparent dark overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, G.window_w, G.window_h)
    
    -- Panel dimensions
    local panel_width = 500
    local panel_height = 300
    local panel_x = (G.window_w - panel_width) / 2
    local panel_y = (G.window_h - panel_height) / 2
    
    -- Draw panel background
    love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
    love.graphics.rectangle("fill", panel_x, panel_y, panel_width, panel_height, 10, 10)
    
    -- Draw panel border
    love.graphics.setColor(0.8, 0.6, 0.2, 1)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", panel_x, panel_y, panel_width, panel_height, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- Title
    local font = love.graphics.getFont()
    local title = "GAME OVER"
    local title_scale = 2.5
    local title_width = font:getWidth(title) * title_scale
    
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.print(title, (G.window_w - title_width) / 2, panel_y + 40, 0, title_scale, title_scale)
    
    -- Winner text
    local winner_text
    local winner_color
    if G.who_won[1] == 1 and G.who_won[2] == 1 then
        winner_text = "IT'S A DRAW!"
        winner_color = {0.9, 0.9, 0.2, 1}
    elseif G.who_won[1] == 1 then
        winner_text = "PLAYER 2 WINS!"
        winner_color = {0.9, 0.9, 0.9, 1}  -- White for player 2
    elseif G.who_won[2] == 1 then
        winner_text = "PLAYER 1 WINS!"
        winner_color = {0.3, 0.3, 0.3, 1}  -- Dark for player 1
    end
    
    local winner_scale = 2.0
    local winner_width = font:getWidth(winner_text) * winner_scale
    love.graphics.setColor(winner_color)
    love.graphics.print(winner_text, (G.window_w - winner_width) / 2, panel_y + 120, 0, winner_scale, winner_scale)
    
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    local inst0 = "Press 'R' to restart game"
    local inst1 = "Press 'L' to load saved game"
    local inst2 = "Press 'N' to host new network game"
    local inst3 = "Press 'M' to join network game"
    local inst4 = "Press 'ESC' to quit"
    
    local inst_y = panel_y + 190
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.print(inst0, (G.window_w - font:getWidth(inst0)) / 2, inst_y)
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.print(inst1, (G.window_w - font:getWidth(inst1)) / 2, inst_y + 20)
    love.graphics.print(inst2, (G.window_w - font:getWidth(inst2)) / 2, inst_y + 40)
    love.graphics.print(inst3, (G.window_w - font:getWidth(inst3)) / 2, inst_y + 60)
    love.graphics.print(inst4, (G.window_w - font:getWidth(inst4)) / 2, inst_y + 80)
    
    love.graphics.setColor(1, 1, 1, 1)
end

function UI.drawMosquitoPopup(graphics)
    if not G.mosquito_choice_popup then return end
    graphics.drawMosquitoChoicePopup(G.mosquito_popup_x, G.mosquito_popup_y)
end

function UI.drawHelpHint()
    if G.show_help then return end
    
    local hint_text = "Hold SPACE for controls"
    local font = love.graphics.getFont()
    local text_width = font:getWidth(hint_text)
    local padding = 10
    
    -- Position in bottom right corner
    local x = G.window_w - text_width - padding
    local y = G.window_h - font:getHeight() - padding
    
    -- Draw with slight transparency
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.print(hint_text, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Export module
return {
    drawPieceSelectorUI = UI.drawPieceSelectorUI,
    drawPieceSelectorTooltip = UI.drawPieceSelectorTooltip,
    drawCubeCoordinatesOverlay = UI.drawCubeCoordinatesOverlay,
    drawHoverCoordinates = UI.drawHoverCoordinates,
    drawStackTooltip = UI.drawStackTooltip,
    drawStatus = UI.drawStatus,
    drawGameOverScreen = UI.drawGameOverScreen,
    drawMosquitoPopup = UI.drawMosquitoPopup,
    drawHelpHint = UI.drawHelpHint,
    drawHelpOverlay = UI.drawHelpOverlay,
}
