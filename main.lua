-- Load modules
local Config = require("config")
local PiecesEnum = require("pieces/pieces_enum")
local pieces = require("pieces")
local game = require("game")
local graphics = require("graphics")
local ui = require("ui")
local console = require("console")
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

function love.draw()
    graphics.setupCanvases()
    graphics.drawGameBoard()
    
    local center_x, piece_size, display_player_id, piece_count = ui.drawPieceSelectorUI(graphics)
    ui.drawPieceSelectorTooltip(graphics, center_x, piece_size, display_player_id, piece_count)
    
    ui.drawCubeCoordinatesOverlay()
    local hover_hex = ui.drawHoverCoordinates()
    ui.drawStackTooltip(hover_hex)
    
    ui.drawStatus()
    ui.drawGameOverScreen()
    ui.drawMosquitoPopup(graphics)
    ui.drawHelpHint()
    
    console.draw(10, 400, 600, 350)
    
    -- Draw help overlay last (on top of everything)
    ui.drawHelpOverlay()
end
