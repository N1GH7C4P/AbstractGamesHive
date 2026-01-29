local PlayerClass = require("player")
local Config = require("config")
local PiecesEnum = require("pieces.pieces_enum")

function init_players()
    player = {}
    
    -- Create two players with pieces from configuration
    for i = 1, 2 do
        player[i] = PlayerClass:new(i, Config.pieceInventory)
    end
    
    return player
end

function countNearbyPlayer(map, cube)
    local enemy_count = 0
    local friendly_count = 0
    
    mark_neighbours_on_map_cube(map, cube)
    
    for _, hex in pairs(map.hexes) do
        if hex.neighbour then
            if hex.player_id == active_player_id then
                friendly_count = friendly_count + 1
            elseif hex.player_id then
                enemy_count = enemy_count + 1
            end
        end
    end
    
    clear_all_neighbours(map, w, h)
    return enemy_count, friendly_count
end

function checkIfWin(map, w, h)
    local enemy
    local friend

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
                enemy, friend = countNearbyPlayer(map, hex.cube)
                if enemy + friend == 6 then
                    game_over = true
                    who_won[queen_owner] = 1
                end
            end
        end
    end
end

function selectPieceOnMap(map, x, y, active_player_id)
    local cube = cubecoords.from_offset(x, y)
    local hex = map_get_hex(map, cube)
    if hex and hex.player_id == active_player_id then
        return true
    end
    return false
end

function printSelectedPieceInfo(map, selected_piece_x, selected_piece_y, move_mode, x, y)
    if move_mode == 1 and selected_piece_x > 0 and selected_piece_y > 0 then
        local cube = cubecoords.from_offset(selected_piece_x, selected_piece_y)
        local hex = map_get_hex(map, cube)
        if hex and hex.piece then
            love.graphics.print("Selected piece: "..hex.piece.name.." ("..selected_piece_x..", "..selected_piece_y..")", x, y)
        end
    end
end

function pass_turn(active_piece_id)
    if (active_player_id == 1) then
        move_mode = 0
        active_player_id = 2
        turn_number[1] = turn_number[1] + 1
        
        -- Clear movement flags for player 2 pieces from their previous turn
        -- (Player 2's turn is starting, so clear their old flags)
        for _, hex in pairs(map.hexes) do
            if hex.piece and hex.player_id == 2 then
                hex.piece.has_moved_last_turn = false
            end
        end
    elseif (active_player_id == 2) then
        move_mode = 0
        active_player_id = 1
        turn_number[2] = turn_number[2] + 1
        
        -- Clear movement flags for player 1 pieces from their previous turn
        -- (Player 1's turn is starting, so clear their old flags)
        for _, hex in pairs(map.hexes) do
            if hex.piece and hex.player_id == 1 then
                hex.piece.has_moved_last_turn = false
            end
        end
    end
    checkIfWin(map, w, h)
end
