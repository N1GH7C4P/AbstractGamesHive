local PlayerClass = require("player")
local Config = require("config")
local PiecesEnum = require("pieces.pieces_enum")
local globals = require("globals")
local hexagon = require("hexagon")
local pieces = require("pieces")
local map = require("map")

local Game = {}

function Game.init()
    -- Initialize game state (called on startup and restart)
    
    globals.init()
    
    -- Load configuration into globals
    G.menu_offset_x = Config.game.menuOffsetX
    G.window_w = Config.game.windowWidth
    G.window_h = Config.game.windowHeight
    G.w = Config.game.mapWidth
    G.h = Config.game.mapHeight
    G.size = Config.game.hexSize
    
    -- Initialize game components
    G.grid = hexagon.grid(G.w, G.h, G.size, false, false)
    G.piecesInvetory = pieces.init_pieces()
    G.player = Game.init_players()
    G.map = map.init_map()
    
    -- Center camera
    G.camera_x = G.window_w / 2
    G.camera_y = G.window_h / 2
    
    -- Create canvas objects
    G.canvas = love.graphics.newCanvas(G.window_w, G.window_h)
    G.overlay = love.graphics.newCanvas(G.window_w, G.window_h)
end

function Game.init_players()
    G.player = {}
    
    -- Create two players with pieces from configuration
    for i = 1, 2 do
        G.player[i] = PlayerClass:new(i, Config.pieceInventory)
    end
    
    return G.player
end

function Game.checkIfWin(map, w, h)
    local surrounded_queens = {}

    -- First pass: check all queens to see if any are surrounded
    for _, hex in pairs(map.hexes) do
        if hex.piece then
            -- Check the entire stack for Queen Bees (including under other pieces)
            local current_piece = hex.piece
            local queen_owner = nil
            
            -- Traverse the stack to find any Queen Bee
            while current_piece do
                if current_piece.id == PiecesEnum.QUEEN_BEE then
                    -- Found a Queen Bee in the stack
                    queen_owner = current_piece.owner
                    break
                end
                current_piece = current_piece.under_piece
            end
            
            -- If a Queen Bee was found, check if it's surrounded
            if queen_owner then
                -- Count occupied neighbors (regardless of player)
                local neighbors = cubecoords.all_neighbors(hex.cube)
                local occupied_count = 0
                
                for _, neighbor_cube in ipairs(neighbors) do
                    local neighbor_hex = map_get_hex(map, neighbor_cube)
                    if neighbor_hex and neighbor_hex.piece then
                        occupied_count = occupied_count + 1
                    end
                end
                
                print("Queen at [" .. hex.cube.x .. "," .. hex.cube.y .. "," .. hex.cube.z .. "] has " .. occupied_count .. " neighbors")
                
                if occupied_count == 6 then
                    print("Player " .. queen_owner .. " Queen is surrounded!")
                    surrounded_queens[queen_owner] = true
                end
            end
        end
    end
    
    -- Second pass: set game_over and who_won based on surrounded queens
    -- This handles ties when both queens are surrounded in the same turn
    if surrounded_queens[1] or surrounded_queens[2] then
        G.game_over = true
        if surrounded_queens[1] then
            G.who_won[1] = 1
        end
        if surrounded_queens[2] then
            G.who_won[2] = 1
        end
    end
end

function Game.selectPieceOnMap(map, cube, active_player_id)
    local hex = map_get_hex(map, cube)
    if hex and hex.player_id == active_player_id then
        return true
    end
    return false
end

function Game.printSelectedPieceInfo(map, selected_piece_cube, move_mode, x, y, active_player_id)
    if move_mode == 1 and selected_piece_cube then
        if Game.selectPieceOnMap(map, selected_piece_cube, active_player_id) then
            local hex = map_get_hex(map, selected_piece_cube)
            if hex and hex.piece then
                love.graphics.print("Selected piece: "..hex.piece.name.." ("..selected_piece_cube.x..", "..selected_piece_cube.y..", "..selected_piece_cube.z..")", x, y)
            end
        end
    end
end

function Game.pass_turn(active_piece_id)
    if (G.active_player_id == 1) then
        G.move_mode = 0
        G.active_player_id = 2
        G.turn_number[1] = G.turn_number[1] + 1
        
        -- Clear movement flags for player 2 pieces from their previous turn
        -- (Player 2's turn is starting, so clear their old flags)
        for _, hex in pairs(G.map.hexes) do
            if hex.piece and hex.player_id == 2 then
                hex.piece.has_moved_last_turn = false
            end
        end
    elseif (G.active_player_id == 2) then
        G.move_mode = 0
        G.active_player_id = 1
        G.turn_number[2] = G.turn_number[2] + 1
        
        -- Clear movement flags for player 1 pieces from their previous turn
        -- (Player 1's turn is starting, so clear their old flags)
        for _, hex in pairs(G.map.hexes) do
            if hex.piece and hex.player_id == 1 then
                hex.piece.has_moved_last_turn = false
            end
        end
    end
    Game.checkIfWin(G.map, G.w, G.h)
end

return Game
