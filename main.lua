-- Load modules
local hexagon = require("hexagon")
local cubecoords = require("cubecoords")
local Config = require("config")
local globals = require("globals")
local PiecesEnum = require("pieces/pieces_enum")
local pieces = require("pieces")
local player = require("player")
local game = require("game")
local graphics = require("graphics")
local map = require("map")
local console = require("console")
local gamestate = require("gamestate")
local input = require("input")
local network = require("network")
local animation = require("animation")

function love.load()
    -- Initialize console to capture print statements
    console.init()
    console.visible = false  -- Start with console hidden
    
    -- Initialize network module
    network.init()

    -- Set up window
    love.window.setMode(Config.game.windowWidth, Config.game.windowHeight)
	love.window.setTitle("hive")

    -- Initialize game state
    game.init()
end

function love.keypressed(key)
    input.keypressed(key)
end

function love.keyreleased(key)
    input.keyreleased(key)
end

function love.mousepressed(x, y, button, istouch)
    input.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    input.mousereleased(x, y, button, istouch)
end

function love.wheelmoved(x, y)
    input.wheelmoved(x, y)
end

function love.update(dt)
    animation.update(dt)
    input.update_mouse(dt)
    network.update(dt)
end

local function setup_canvases()
    love.graphics.setCanvas(G.canvas)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas(G.overlay)
    love.graphics.clear(0,0,0,0)
    love.graphics.setCanvas()
end

local function draw_game_board()
    love.graphics.setColor(0,1,0,1)
    drawBackground(G.canvas, G.window_w, G.window_h)
    drawGridHexes(G.map, G.canvas, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    drawAddedPieces(G.map, G.overlay, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    love.graphics.draw(G.canvas)
    love.graphics.draw(G.overlay)
    if (G.highlight == 1 and G.move_mode == 1) then
        drawSelected(G.map, G.selected_piece_x, G.selected_piece_y, G.grid, G.camera_x, G.camera_y, G.camera_zoom)
    end
end

local function draw_piece_selector_ui()
    local display_player_id = (network and network.mode ~= "none" and network.local_player_id) or G.active_player_id
    local piece_count = #G.player[display_player_id].pieces
    local piece_size = 30
    local piece_spacing = piece_size * 2.5
    local total_width = (piece_count - 1) * piece_spacing
    local center_x = (G.window_w - total_width) / 2
    drawPieceSelector(G.player, display_player_id, center_x, 20, piece_size)
    return center_x, piece_size, display_player_id, piece_count
end

local function draw_piece_selector_tooltip(center_x, piece_size, display_player_id, piece_count)
    local hover_piece_idx, hover_piece_id, hover_piece_name, hover_stock = getPieceSelectorHover(G.player, display_player_id, G.mouseX, G.mouseY, center_x, 20, piece_size)
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

local function draw_cube_coordinates_overlay()
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

local function draw_hover_coordinates()
    local pixel_x = (G.mouseX - G.camera_x) / G.camera_zoom
    local pixel_y = (G.mouseY - G.camera_y) / G.camera_zoom
    local hover_cube = cubecoords.from_pixel(pixel_x, pixel_y, G.size)
    local hover_hex = map_get_hex(G.map, hover_cube)
    
    if not hover_hex then
        love.graphics.print("Out of grid", 0, G.window_h - 20)
    else
        love.graphics.print("Hexagon coordinates: ["..hover_cube.x..","..hover_cube.y..","..hover_cube.z.."]", 0, G.window_h - 20)
    end
    
    return hover_hex
end

local function draw_stack_tooltip(hover_hex)
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

local function draw_ui_status()
    love.graphics.print("Zoom: " .. string.format("%.1f", G.camera_zoom) .. "x", 0, G.window_h - 40)
    
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

local function draw_game_over_screen()
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

local function draw_mosquito_popup()
    if not G.mosquito_choice_popup then return end
    drawMosquitoChoicePopup(G.mosquito_popup_x, G.mosquito_popup_y)
end

local function draw_help_hint()
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

function love.draw()
    setup_canvases()
    draw_game_board()
    
    local center_x, piece_size, display_player_id, piece_count = draw_piece_selector_ui()
    draw_piece_selector_tooltip(center_x, piece_size, display_player_id, piece_count)
    
    draw_cube_coordinates_overlay()
    local hover_hex = draw_hover_coordinates()
    draw_stack_tooltip(hover_hex)
    
    draw_ui_status()
    draw_game_over_screen()
    draw_mosquito_popup()
    draw_help_hint()
    
    console.draw(10, 400, 600, 350)
    
    -- Draw help overlay last (on top of everything)
    input.draw_help_overlay()
end
