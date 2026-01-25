require "player"
require "game"

local function addPieceToMap(player_nb, id, map, x, y)
    highlight = 0
    removePieceFromStock(player_nb, id)
    map[y][x].player_id = player_nb
    map[y][x].piece = getPieceFromInventoryById(id)
end

local function isMapEmpty(map)
    local count = 0
    for i = 1, map.h do
        for j = 1, map.w do
            if (map[i][j].piece) then
                count = count + 1
            end
        end
    end
    if count == 0 then
        return true
    end
    return false
end

local function isNextToFriendly(map, x, y, w, h)
    local enemy_count = 0
    local friendly_count = 0

    enemy_count, friendly_count = countNearbyPlayer(map, x, y, w, h)
    --check for first and second piece
    if (turn_number[active_player_id] == 1) then
        local not_active = 1
        if active_player_id == 1 then
            not_active = 2
        end
        if (turn_number[not_active] == 2) then
            if (enemy_count ~= 1) then
                return false
            end
        end
        return true
    end
    if (friendly_count > 0 and enemy_count == 0) then
        return true
    end
    return false
end

function tryAddPieceToMap(player_nb, id, map, x, y)
    if getPiecesInStock(player_nb, id) == 0 then
            print("Player ", player_nb, " has no piece nb ", id, " in stock.")
        return false
    end
    if (map[y][x].piece) then
        print("Spot not empty")
        return false
    end
    if isMapEmpty(map) then
        addPieceToMap(player_nb, id, map, 6, 5)
        return true
    end
    if (turn_number[player_nb] == 4 and player[player_nb].pieces[1].inStock == 1 and id ~= 1) then
        print("Must place Queen bee")
        return false
    end
    if not isNextToFriendly(map, x, y, w, h) then
        return false
    end
    addPieceToMap(player_nb, id, map, x, y)
    return true
end

function init_map(w, h)

    map = {}
    map.w = w
    map.h = h

    for i = 1, h do
        map[i] = {}
        for j = 1, w do
            map[i][j] = {}
        end
    end

    return map
end

function print_map_pieces(map, w, h, x, y)
    count = 0
    for i = 1, h do
        for j = 1, w do
            if (map[i][j].piece) then
                love.graphics.print( map[i][j].piece.name.." ("..j..", "..i..") - placed by: player"..map[i][j].player_id, x, y + count*20)
                count = count + 1
            end
        end
    end
end

function mark_tmp_on_map(map, x, y, w, h)
    for i = 1, h do
        for j = 1, w do
            if (j % 2 == 0) then
                -- Neigbours: (X,Y-1),(X+1,Y-1),(X-1,Y),(X+1,Y),(X,Y+1),(X+1,Y+1)
                if (i == y - 1 and j == x) or (i == y - 1 and j == x + 1) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x) or (i == y - 1 and j == x - 1) then
                    map[i][j].tmp = true
                end
            else
                -- Neighbours: (X-1,Y-1),(X,Y-1),(X-1,Y),(X+1,Y),(X-1,Y+1),(X,Y+1)
                if (i == y + 1 and j == x + 1) or (i == y - 1 and j == x) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x - 1) or (i == y + 1 and j == x) then
                    map[i][j].tmp = true
                end
            end
        end
    end
end

function mark_neighbours_on_map(map, x, y, w, h)
    for i = 1, h do
        for j = 1, w do
            if (j % 2 == 0) then
                -- Neigbours: (X,Y-1),(X+1,Y-1),(X-1,Y),(X+1,Y),(X,Y+1),(X+1,Y+1)
                if (i == y - 1 and j == x) or (i == y - 1 and j == x + 1) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x) or (i == y - 1 and j == x - 1) then
                    map[i][j].neighbour = true
                end
            else
                -- Neighbours: (X-1,Y-1),(X,Y-1),(X-1,Y),(X+1,Y),(X-1,Y+1),(X,Y+1)
                if (i == y + 1 and j == x + 1) or (i == y - 1 and j == x) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x - 1) or (i == y + 1 and j == x) then
                    map[i][j].neighbour = true
                end
            end
        end
    end
end

function clear_all_tmp(map, w, h)
    for i = 1, h do
        for j = 1, w do
                map[i][j].tmp = nil
        end
    end
end

function clear_all_neighbours(map, w, h)
    for i = 1, h do
        for j = 1, w do
            map[i][j].neighbour = nil
        end
    end
end

function mark_legal_moves_for_piece(map, src_x, src_y, w, h)
    print("=== mark_legal_moves_for_piece called ===")
    print("Source: (" .. src_x .. ", " .. src_y .. ")")
    
    -- Clear all previous neighbour markings
    clear_all_neighbours(map, w, h)
    
    -- Get the piece at the source position
    local piece = map[src_y][src_x].piece
    if not piece then
        print("ERROR: No piece at source!")
        return
    end
    
    print("Piece: " .. piece.name)
    
    -- For Queen, let's specifically test adjacent positions
    if piece.id == 1 then
        print("Testing Queen moves - checking adjacent hexes only")
        mark_neighbours_on_map(map, src_x, src_y, w, h)
        local adjacent_positions = {}
        for i = 1, h do
            for j = 1, w do
                if map[i][j].neighbour and not (i == src_y and j == src_x) then
                    table.insert(adjacent_positions, {x = j, y = i})
                end
            end
        end
        clear_all_neighbours(map, w, h)
        
        print("Found " .. #adjacent_positions .. " adjacent hexes")
        local legal_moves = {}
        
        for _, pos in ipairs(adjacent_positions) do
            print("Testing adjacent hex (" .. pos.x .. ", " .. pos.y .. ")")
            
            -- Check if destination is occupied
            if map[pos.y][pos.x].piece then
                print("  BLOCKED: hex occupied")
            else
                -- Test the move
                local can_detach = pieceCanDetach(map, src_x, src_y, pos.x, pos.y)
                print("  pieceCanDetach: " .. tostring(can_detach))
                
                if can_detach then
                    local can_self_detach = try_self_detach(map, src_x, src_y, pos.x, pos.y)
                    print("  try_self_detach: " .. tostring(can_self_detach))
                    
                    if can_self_detach then
                        table.insert(legal_moves, {x = pos.x, y = pos.y})
                        print("  LEGAL MOVE!")
                    end
                end
            end
        end
        
        print("Total legal moves: " .. #legal_moves)
        for _, move in ipairs(legal_moves) do
            map[move.y][move.x].neighbour = true
        end
        
        print("=== Complete ===")
        return
    end
    
    -- Original logic for other pieces
    local legal_moves = {}
    local tests_run = 0
    local max_tests = 200
    
    for i = 1, h do
        for j = 1, w do
            if not (i == src_y and j == src_x) then
                tests_run = tests_run + 1
                
                if tests_run > max_tests then
                    print("WARNING: Hit test limit!")
                    break
                end
                
                local has_nearby = false
                mark_neighbours_on_map(map, j, i, w, h)
                for ii = 1, h do
                    for jj = 1, w do
                        if map[ii][jj].neighbour and map[ii][jj].piece then
                            has_nearby = true
                            break
                        end
                    end
                    if has_nearby then break end
                end
                clear_all_neighbours(map, w, h)
                
                if has_nearby or not map[i][j].piece then
                    if try_move_piece_on_map(map, src_x, src_y, j, i) then
                        table.insert(legal_moves, {x = j, y = i})
                    end
                end
            end
        end
        if tests_run > max_tests then break end
    end
    
    print("Tests: " .. tests_run .. ", Legal moves: " .. #legal_moves)
    
    for _, move in ipairs(legal_moves) do
        map[move.y][move.x].neighbour = true
    end
    
    print("=== Complete ===")
end

function remove_piece_from_map(map, x, y)
    if map[y][x].piece then
        print("Removed piece from: "..tostring(x)..", "..tostring(y))
        map[y][x].piece = nil
        return true
    end
        print("Failed to remove piece from: "..tostring(x)..", "..tostring(y))
    return false
end

function tmp_to_neighbor()
    for i = 1, map.h do
        for j = 1, map.w do
            if map[i][j].tmp then
                map[i][j].neighbour = true
            end
        end
    end
end

function flood_neighbours_neighbours_jump(map, x, y, w, h)
    clear_all_tmp(map, map.w, map.h)
    for i = 1, h do
        for j = 1, w do
            if map[i][j].neighbour then
                mark_tmp_on_map(map, j, i, w, h)
            end
        end
    end
    clear_all_neighbours(map, w, h)
    tmp_to_neighbor()
    clear_all_tmp(map, map.w, map.h)
end

function flood_neighbours_neighbours(map, x, y, w, h)
    clear_all_tmp(map, map.w, map.h)
    for i = 1, h do
        for j = 1, w do
            if map[i][j].neighbour then
                mark_tmp_on_map(map, j, i, w, h)
            end
        end
    end
    tmp_to_neighbor()
    clear_all_tmp(map, map.w, map.h)
end

function flood_neighbours(map, x, y, w, h)
    for i = 1, h do
        for j = 1, w do
            if (j % 2 == 0) then
                if (i == y - 1 and j == x) or (i == y - 1 and j == x + 1) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x) or (i == y - 1 and j == x - 1) then
                    if not map[i][j].neighbour then
                        if map[i][j].piece then
                            map[i][j].neighbour = true
                            flood_neighbours(map, j, i, w, h)
                        end
                    end
                    if map[i][j].piece then
                        map[i][j].neighbour = true
                    end
                end
            else
                if (i == y + 1 and j == x + 1) or (i == y - 1 and j == x) or (i == y and j == x - 1) or (i == y and j == x + 1) or (i == y + 1 and j == x - 1) or (i == y + 1 and j == x) then
                    if not map[i][j].neighbour  then
                        if map[i][j].piece then
                            map[i][j].neighbour = true
                            flood_neighbours(map, j, i, w, h)
                        end
                    end
                    if map[i][j].piece then
                        map[i][j].neighbour = true
                    end
                end
            end
        end
    end
end

function firstPieceCoords(map)
    for i = 1, h do
        for j = 1, w do
            if map[i][j].piece then
                return j, i
            end
        end
    end
end

function pieceCanDetach(map, x, y)
    local tmp = map[y][x].piece
    map[y][x].piece = nil
    clear_all_neighbours(map, w, h)
    local firstx, firsty = firstPieceCoords(map)
    flood_neighbours(map, firstx, firsty, w, h)
    map[y][x].piece = tmp
    map[y][x].neighbour = true
    for i = 1, h do
        for j = 1, w do
            if map[i][j].piece and not map[i][j].neighbour then
                clear_all_neighbours(map, w, h)
                return false
            end
        end
    end
    clear_all_neighbours(map, w, h)
    return true
end

function try_self_detach(map, src_x, src_y, dest_x, dest_y)
    clear_all_neighbours(map, w, h)
    local tmp = map[src_y][src_x].player_id
    map[src_y][src_x].player_id = nil
    local enemy, friend = countNearbyPlayer(map, dest_x, dest_y, w, h)
    if (enemy + friend == 0) then
        map[src_y][src_x].player_id = tmp
        return false
    end
    map[src_y][src_x].player_id = tmp
    return true
end

function try_move_piece_on_map(map, src_x, src_y, dest_x, dest_y)
    if (not pieceCanDetach(map, src_x, src_y, dest_x, dest_y)) then
        return false
    end
    if not try_self_detach(map, src_x, src_y, dest_x, dest_y) then
        return false
    end

    clear_all_neighbours(map, map.w, map.h)
    if (map[dest_y][dest_x].piece and map[src_y][src_x].piece.id ~= 2) then
        return false
    end
    
    -- Call the piece's try_to_move method
    if map[src_y][src_x].piece and map[src_y][src_x].piece.try_to_move then
        return map[src_y][src_x].piece:try_to_move(map, src_x, src_y, dest_x, dest_y, map.w, map.h)
    end
    
    return false
end

function move_piece_on_map(map, src_x, src_y, dest_x, dest_y)
    if not try_move_piece_on_map(map, src_x, src_y, dest_x, dest_y) then
        return false
    end
    
    -- Call the piece's move_piece method if available
    if map[src_y][src_x].piece and map[src_y][src_x].piece.move_piece then
        return map[src_y][src_x].piece:move_piece(map, src_x, src_y, dest_x, dest_y, active_player_id)
    end
    
    return false
end