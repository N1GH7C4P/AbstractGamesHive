-- Game state export functionality
GameState = {}

function GameState.export_to_file(map, w, h, filename)
    filename = filename or "gamestate.txt"
    
    local file = io.open(filename, "w")
    if not file then
        print("ERROR: Could not open file for writing: " .. filename)
        return false
    end
    
    file:write("=== HIVE GAME STATE ===\n")
    file:write("Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    
    -- Game info
    file:write("Active Player: " .. active_player_id .. "\n")
    file:write("Turn Numbers: Player 1: " .. turn_number[1] .. ", Player 2: " .. turn_number[2] .. "\n")
    file:write("Move Mode: " .. move_mode .. "\n")
    file:write("Game Over: " .. tostring(game_over) .. "\n\n")
    
    -- Selected piece
    if move_mode == 1 then
        file:write("Selected Piece: (" .. selected_piece_x .. ", " .. selected_piece_y .. ")\n")
        if map[selected_piece_y] and map[selected_piece_y][selected_piece_x] and map[selected_piece_y][selected_piece_x].piece then
            file:write("  Type: " .. map[selected_piece_y][selected_piece_x].piece.name .. "\n")
            file:write("  Owner: Player " .. map[selected_piece_y][selected_piece_x].player_id .. "\n")
        end
        file:write("\n")
    end
    
    -- Player inventory
    file:write("=== PLAYER INVENTORY ===\n")
    for p = 1, 2 do
        file:write("Player " .. p .. ":\n")
        for i = 1, 5 do
            file:write("  " .. player[p].pieces[i].template.name .. ": " .. player[p].pieces[i].inStock .. " in stock\n")
        end
        file:write("\n")
    end
    
    -- Pieces on board
    file:write("=== PIECES ON BOARD ===\n")
    local piece_count = 0
    local pieces_list = {}
    
    for i = 1, h do
        for j = 1, w do
            if map[i][j].piece then
                piece_count = piece_count + 1
                table.insert(pieces_list, {
                    x = j,
                    y = i,
                    piece = map[i][j].piece,
                    player_id = map[i][j].player_id
                })
            end
        end
    end
    
    file:write("Total pieces on board: " .. piece_count .. "\n\n")
    
    -- Sort by player then by position
    table.sort(pieces_list, function(a, b)
        if a.player_id == b.player_id then
            if a.y == b.y then
                return a.x < b.x
            end
            return a.y < b.y
        end
        return a.player_id < b.player_id
    end)
    
    for _, p in ipairs(pieces_list) do
        file:write(string.format("(%2d, %2d) - Player %d - %s (id:%d)", 
            p.x, p.y, p.player_id, p.piece.name, p.piece.id))
        
        if p.piece.under_piece then
            file:write(" [STACKED on " .. p.piece.under_piece.name .. "]")
        end
        file:write("\n")
        
        -- Show neighbors
        mark_neighbours_on_map(map, p.x, p.y, w, h)
        local neighbor_pieces = {}
        for i = 1, h do
            for j = 1, w do
                if map[i][j].neighbour and map[i][j].piece and not (i == p.y and j == p.x) then
                    table.insert(neighbor_pieces, "(" .. j .. "," .. i .. ")")
                end
            end
        end
        clear_all_neighbours(map, w, h)
        
        if #neighbor_pieces > 0 then
            file:write("  Adjacent pieces at: " .. table.concat(neighbor_pieces, ", ") .. "\n")
        end
    end
    
    file:write("\n=== BOARD MAP (visual) ===\n")
    for i = 1, h do
        local line = ""
        if i % 2 == 0 then
            line = "  "  -- Indent even rows for hex grid
        end
        for j = 1, w do
            if map[i][j].piece then
                line = line .. string.format("[%s%d]", map[i][j].piece.initials, map[i][j].player_id)
            else
                line = line .. " .. "
            end
            line = line .. " "
        end
        file:write(line .. "\n")
    end
    
    file:close()
    print("Game state exported to: " .. filename)
    return true
end

function GameState.load_from_file(map, w, h, filename)
    filename = filename or "gamestate.txt"
    
    local file = io.open(filename, "r")
    if not file then
        print("ERROR: Could not open file for reading: " .. filename)
        return false
    end
    
    print("Loading game state from: " .. filename)
    
    -- Clear current board
    for i = 1, h do
        for j = 1, w do
            map[i][j].piece = nil
            map[i][j].player_id = nil
            map[i][j].neighbour = nil
        end
    end
    
    -- Reset player inventories to full
    for p = 1, 2 do
        player[p].pieces[1].inStock = 1  -- Queen Bee
        player[p].pieces[2].inStock = 2  -- Beetle
        player[p].pieces[3].inStock = 3  -- Grasshopper
        player[p].pieces[4].inStock = 2  -- Spider
        player[p].pieces[5].inStock = 3  -- Soldier Ant
    end
    
    local pieces_loaded = 0
    local in_pieces_section = false
    
    for line in file:lines() do
        -- Check if we're in the pieces section
        if line:match("=== PIECES ON BOARD ===") then
            in_pieces_section = true
        elseif line:match("=== BOARD MAP") then
            in_pieces_section = false
        elseif in_pieces_section then
            -- Parse piece lines: ( 6,  5) - Player 1 - Soldier ant (id:5)
            local x, y, player_id, piece_name, piece_id = line:match("^%s*%(%s*(%d+),%s*(%d+)%)%s*%-%s*Player%s*(%d+)%s*%-%s*(.-)%s*%(id:(%d+)%)")
            
            if x and y and player_id and piece_id then
                x = tonumber(x)
                y = tonumber(y)
                player_id = tonumber(player_id)
                piece_id = tonumber(piece_id)
                
                -- Create piece instance based on ID
                local piece = nil
                if piece_id == 1 then
                    piece = QueenBee:new(player_id)
                elseif piece_id == 2 then
                    piece = Beetle:new(player_id)
                elseif piece_id == 3 then
                    piece = Grasshopper:new(player_id)
                elseif piece_id == 4 then
                    piece = Spider:new(player_id)
                elseif piece_id == 5 then
                    piece = SoldierAnt:new(player_id)
                end
                
                if piece then
                    -- Place piece on map
                    map[y][x].piece = piece
                    map[y][x].player_id = player_id
                    piece:place(x, y)
                    
                    -- Decrease from stock
                    player[player_id].pieces[piece_id].inStock = player[player_id].pieces[piece_id].inStock - 1
                    
                    pieces_loaded = pieces_loaded + 1
                    print("Loaded: " .. piece.name .. " at (" .. x .. ", " .. y .. ") for Player " .. player_id)
                end
            end
        end
        
        -- Parse turn numbers
        local turn1, turn2 = line:match("Turn Numbers: Player 1: (%d+), Player 2: (%d+)")
        if turn1 and turn2 then
            turn_number[1] = tonumber(turn1)
            turn_number[2] = tonumber(turn2)
            print("Set turn numbers: P1=" .. turn_number[1] .. ", P2=" .. turn_number[2])
        end
        
        -- Parse active player
        local active = line:match("Active Player: (%d+)")
        if active then
            active_player_id = tonumber(active)
            print("Set active player: " .. active_player_id)
        end
    end
    
    file:close()
    
    -- Reset game state
    move_mode = 0
    highlight = 0
    selected_piece_x = 0
    selected_piece_y = 0
    game_over = false
    who_won = {0, 0}
    
    print("Game state loaded successfully!")
    print("Pieces on board: " .. pieces_loaded)
    return true
end

return GameState
