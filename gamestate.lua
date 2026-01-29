-- Game state save/load functionality
local Globals = require("globals")
local json = require("json")
local map_module = require("map")

GameState = {}

-- Build game state data structure
local function buildGameStateData()
    return {
        active_player_id = G.active_player_id,
        active_piece_id = G.active_piece_id,
        turn_number = {G.turn_number[1], G.turn_number[2]},
        move_mode = G.move_mode,
        game_over = G.game_over,
        who_won = {G.who_won[1], G.who_won[2]},
        selected_piece_x = G.selected_piece_x,
        selected_piece_y = G.selected_piece_y,
        highlight = G.highlight
    }
end

-- Build camera state data
local function buildCameraData()
    return {
        x = G.camera_x,
        y = G.camera_y,
        zoom = G.camera_zoom
    }
end

-- Build player inventory data
local function buildPlayerData()
    local players = {}
    for p = 1, 2 do
        players[p] = {
            id = G.player[p].id,
            pieces = {}
        }
        for i, piece_info in ipairs(G.player[p].pieces) do
            players[p].pieces[i] = {
                id = piece_info.id,
                name = piece_info.name,
                inStock = piece_info.inStock
            }
        end
    end
    return players
end

-- Build board piece data
local function buildBoardData()
    local board = {}
    for cube_key, hex in pairs(G.map.hexes) do
        if hex.piece then
            local piece_entry = {
                cube = {x = hex.cube.x, y = hex.cube.y, z = hex.cube.z},
                piece_id = hex.piece.id,
                player_id = hex.player_id,
                has_under_piece = hex.piece.under_piece ~= nil
            }
            
            -- Save complete under_piece information if it exists
            if hex.piece.under_piece then
                piece_entry.under_piece = {
                    id = hex.piece.under_piece.id,
                    player_id = hex.piece.under_piece.player_id or hex.piece.under_piece.owner
                }
            end
            
            table.insert(board, piece_entry)
        end
    end
    return board
end

-- Build map metadata
local function buildMapData()
    return {
        current_radius = G.map.current_radius
    }
end

-- Save complete game state to file
function GameState.save(filename)
    filename = filename or "output/savegame.json"
    
    local file = io.open(filename, "w")
    if not file then
        print("ERROR: Could not open file for writing: " .. filename)
        return false
    end
    
    -- Build save data structure
    local save_data = {
        game_state = buildGameStateData(),
        camera = buildCameraData(),
        players = buildPlayerData(),
        board = buildBoardData(),
        map = buildMapData()
    }
    
    -- Write to file
    file:write(json.encode(save_data))
    file:close()
    print("Game saved to: " .. filename)
    return true
end

-- Clear all pieces from the board
local function clearBoard()
    for cube_key, hex in pairs(G.map.hexes) do
        hex.piece = nil
        hex.player_id = nil
        hex.neighbour = nil
        hex.can_move = nil
        hex.can_special = nil
    end
end

-- Restore game state from save data
local function restoreGameState(game_state_data)
    if not game_state_data then return end
    
    G.active_player_id = game_state_data.active_player_id or 1
    G.active_piece_id = game_state_data.active_piece_id or 1
    G.turn_number = {
        game_state_data.turn_number[1] or 1,
        game_state_data.turn_number[2] or 1
    }
    G.move_mode = game_state_data.move_mode or 0
    G.game_over = game_state_data.game_over or false
    G.who_won = {
        game_state_data.who_won[1] or 0,
        game_state_data.who_won[2] or 0
    }
    G.selected_piece_x = game_state_data.selected_piece_x or 0
    G.selected_piece_y = game_state_data.selected_piece_y or 0
    G.highlight = game_state_data.highlight or 0
end

-- Restore camera state from save data
local function restoreCamera(camera_data)
    if not camera_data then return end
    
    G.camera_x = camera_data.x or 0
    G.camera_y = camera_data.y or 0
    G.camera_zoom = camera_data.zoom or 0.8
end

-- Restore player inventories from save data
local function restorePlayers(players_data)
    if not players_data then return end
    
    for p = 1, 2 do
        if players_data[p] then
            for i, piece_data in ipairs(players_data[p].pieces) do
                if G.player[p].pieces[i] then
                    G.player[p].pieces[i].inStock = piece_data.inStock
                end
            end
        end
    end
end

-- Restore map metadata from save data
local function restoreMapMetadata(map_data)
    if not map_data then return end
    
    G.map.current_radius = map_data.current_radius or 10
end

-- Restore non-stacked pieces on board
local function restoreBasePieces(board_data)
    for _, piece_data in ipairs(board_data) do
        if not piece_data.has_under_piece then
            local cube = cubecoords.new(piece_data.cube.x, piece_data.cube.y, piece_data.cube.z)
            local hex = map_module.get_hex(G.map, cube)
            
            if hex then
                local piece_template = piecesInventory[piece_data.piece_id]
                if piece_template then
                    hex.piece = piece_template.class:new(piece_data.player_id)
                    hex.player_id = piece_data.player_id
                end
            end
        end
    end
end

-- Restore stacked pieces on board (beetles/mosquitos on top)
local function restoreStackedPieces(board_data)
    for _, piece_data in ipairs(board_data) do
        if piece_data.has_under_piece and piece_data.under_piece then
            local cube = cubecoords.new(piece_data.cube.x, piece_data.cube.y, piece_data.cube.z)
            local hex = map_module.get_hex(G.map, cube)
            
            if hex then
                -- Create the piece that goes underneath
                local under_template = piecesInventory[piece_data.under_piece.id]
                if under_template then
                    local under_piece = under_template.class:new(piece_data.under_piece.player_id)
                    
                    -- Create the piece that goes on top
                    local top_template = piecesInventory[piece_data.piece_id]
                    if top_template then
                        local top_piece = top_template.class:new(piece_data.player_id)
                        
                        -- Set up the stacking relationship
                        top_piece.under_piece = under_piece
                        under_piece.player_id = piece_data.under_piece.player_id
                        
                        -- Place on map
                        hex.piece = top_piece
                        hex.player_id = piece_data.player_id
                    end
                end
            end
        end
    end
end

-- Load game state from file
function GameState.load(filename)
    filename = filename or "output/savegame.json"
    
    local file = io.open(filename, "r")
    if not file then
        print("ERROR: Could not open file for reading: " .. filename)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse save data
    local save_data = json.decode(content)
    if not save_data then
        print("ERROR: Failed to parse save file")
        return false
    end
    
    -- Clear and restore game state
    clearBoard()
    restoreGameState(save_data.game_state)
    restoreCamera(save_data.camera)
    restorePlayers(save_data.players)
    restoreMapMetadata(save_data.map)
    
    -- Restore pieces on board
    if save_data.board then
        restoreBasePieces(save_data.board)
        restoreStackedPieces(save_data.board)
    end
    
    -- Reset transient UI state
    Globals.reset_ui_state()
    
    print("Game loaded from: " .. filename)
    return true
end

-- Export module
return {
    save = GameState.save,
    load = GameState.load,
}
