local PlayerClass = require("player")
local Config = require("config")

function init_players()
    player = {}
    
    -- Create two players with pieces from configuration
    for i = 1, 2 do
        player[i] = PlayerClass:new(i, Config.pieceInventory)
        
        -- Add backward compatibility: pieces array with template structure
        for pieceIndex, pieceData in ipairs(player[i].pieces) do
            pieceData.template = piecesInventory[pieceData.id] or {
                name = pieceData.name,
                initials = pieceData.initials,
                id = pieceData.id
            }
        end
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
            local queen_player_id = nil
            
            -- Traverse the stack to find any Queen Bee
            while current_piece do
                if current_piece.id == 1 then
                    -- Found a Queen Bee in the stack
                    queen_player_id = current_piece.player_id
                    break
                end
                current_piece = current_piece.under_piece
            end
            
            -- If a Queen Bee was found, check if it's surrounded
            if queen_player_id then
                enemy, friend = countNearbyPlayer(map, hex.cube)
                if enemy + friend == 6 then
                    game_over = true
                    who_won[queen_player_id] = 1
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
    elseif (active_player_id == 2) then
        move_mode = 0
        active_player_id = 1
        turn_number[2] = turn_number[2] + 1
    end
    checkIfWin(map, w, h)
end
