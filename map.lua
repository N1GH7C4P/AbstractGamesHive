require "player"
require "game"

local function addPieceToMap(player_nb, id, map, x, y)
    highlight = 0
    removePieceFromStock(player_nb, id)
    print("Removed one "..getPieceFromInventoryById(id).name.." from player"..player_nb.."'s stock.")
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

function print_neighbours(map, x, y, w, h)
    for i = 1, h do
        for j = 1, w do
            if map[i][j].neighbour then
                print("Neighbour: ("..j..", "..i..")")
            end
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

function remove_piece_from_map(map, x, y)
    if map[y][x].piece then
        print("Removed piece from: "..tostring(x)..", "..tostring(y))
        map[y][x].piece = nil
        return true
    end
        print("Failed to remove piece from: "..tostring(x)..", "..tostring(y))
    return false
end

function move_piece_on_map(map, src_x, src_y, dest_x, dest_y)
    if (map[src_y][src_x].piece.id == 2) then
        print("Trying to move beetle.")
        move_beetle(src_x, src_y, dest_x, dest_y, active_player_id)
        print("moved piece: "..map[dest_y][dest_x].piece.name.." from ("..src_x..", "..src_y..") to ("..dest_x..", "..dest_y..").")
    elseif(not map[dest_y][dest_x].piece) then
        map[dest_y][dest_x].piece = map[src_y][src_x].piece
        map[dest_y][dest_x].player_id = map[src_y][src_x].player_id
        map[src_y][src_x].piece = nil
        map[src_y][src_x].player_id = nil
        print("moved piece: "..map[dest_y][dest_x].piece.name.." from ("..src_x..", "..src_y..") to ("..dest_x..", "..dest_y..").")
    end
end