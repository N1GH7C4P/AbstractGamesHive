local player = require "player"
local PiecesEnum = require "pieces.pieces_enum"
local animation = require("animation")
local cubecoords = require "cubecoords"
local Config = require("config")

-- Forward declarations
local mark_neighbours_on_map_cube
local clear_all_neighbours
local get_hex
local expand_map
local flood_neighbours

-- Count nearby enemy and friendly pieces
local function countNearbyPlayer(map, cube)
    local enemy_count = 0
    local friendly_count = 0
    
    mark_neighbours_on_map_cube(map, cube)
    
    for _, hex in pairs(map.hexes) do
        if hex.neighbour then
            if hex.player_id == G.active_player_id then
                friendly_count = friendly_count + 1
            elseif hex.player_id then
                enemy_count = enemy_count + 1
            end
        end
    end
    
    clear_all_neighbours(map, G.w, G.h)
    return enemy_count, friendly_count
end

-- Map using cube coordinates
-- The map stores hexes using cube coordinate keys
-- Maintains backward compatibility through wrapper functions

local function addPieceToMap(player_nb, piece_template, map, cube)
    G.highlight = 0
    removePieceFromStock(player_nb, piece_template.id)
        local hex = get_hex(map, cube)
    if hex then
        hex.player_id = player_nb
        local new_piece = piece_template.class:new(player_nb)
        if not new_piece then
            print("ERROR: Failed to create piece from template: " .. piece_template.name)
            return
        end
        hex.piece = new_piece
        
        -- Check if piece was placed on outermost ring and expand if so
        local center = cubecoords.new(0, 0, 0)
        local distance = cubecoords.distance(center, cube)
        if distance >= map.current_radius then
            expand_map(map)
        end
    end
end

local function isMapEmpty(map)
    for _, hex in pairs(map.hexes) do
        if hex.piece then
            return false
        end
    end
    return true
end

local function isNextToFriendly(map, col, row)
    local enemy_count = 0
    local friendly_count = 0
    
    local cube = cubecoords.from_offset(col, row)
    enemy_count, friendly_count = countNearbyPlayer(map, cube)
    
    -- Check for first and second piece
    if (G.turn_number[G.active_player_id] == 1) then
        local not_active = 1
        if G.active_player_id == 1 then
            not_active = 2
        end
        if (G.turn_number[not_active] == 2) then
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

local function tryAddPieceToMap(player_nb, piece_template, map, cube)
    if getPiecesInStock(player_nb, piece_template.id) == 0 then
        print("Player ", player_nb, " has no piece ", piece_template.name, " in stock.")
        return false
    end
    
        local hex = get_hex(map, cube)
    
    if not hex then
        print("Hex out of bounds")
        return false
    end
    
    if hex.piece then
        print("Spot not empty")
        return false
    end
    
    if isMapEmpty(map) then
        -- Force first piece at center (0,0,0)
        local center_cube = cubecoords.new(0, 0, 0)
        local center_hex = get_hex(map, center_cube)
        if center_hex then
            G.highlight = 0
            removePieceFromStock(player_nb, piece_template.id)
            center_hex.player_id = player_nb
            center_hex.piece = piece_template.class:new(player_nb)
            
            -- Send network message if in multiplayer game
            if G.network and G.network.mode ~= "none" and G.network.connected then
                G.network.send_place(player_nb, piece_template.id, center_cube)
            end
            
            -- No need to expand for first piece at center
            return true
        end
        return false
    end
    
    if (G.turn_number[player_nb] == Config.rules.queenMustBePlacedByTurn and G.player[player_nb].pieces[1].inStock == 1 and piece_template.id ~= 1) then
        print("Must place Queen bee")
        return false
    end
    
    local col, row = cubecoords.to_offset(cube)
    if not isNextToFriendly(map, col, row) then
        return false
    end
    
    addPieceToMap(player_nb, piece_template, map, cube)
    
    -- Send network message if in multiplayer game
    if G.network and G.network.mode ~= "none" and G.network.connected then
        G.network.send_place(player_nb, piece_template.id, cube)
    end
    
    return true
end

local function init_map()
    local map = {}
    map.hexes = {}
    map.current_radius = 10  -- Track current grid radius
    
    -- Build hexes in rings radiating from center (0,0,0)
    -- Start with 10 rings around the center
    local center = cubecoords.new(0, 0, 0)
    local rings = 10
    local all_hexes = cubecoords.spiral(center, rings)
    
    for _, cube in ipairs(all_hexes) do
        local key = cubecoords.to_key(cube)
        
        map.hexes[key] = {
            cube = cube,
            piece = nil,
            player_id = nil,
            neighbour = nil,
            tmp = nil
        }
    end
    
    return map
end

-- Expand the map by adding one more ring
function expand_map(map)
    map.current_radius = map.current_radius + 1
    local center = cubecoords.new(0, 0, 0)
    local new_ring = cubecoords.ring(center, map.current_radius)
    
    for _, cube in ipairs(new_ring) do
        local key = cubecoords.to_key(cube)
        
        map.hexes[key] = {
            cube = cube,
            piece = nil,
            player_id = nil,
            neighbour = nil,
            tmp = nil
        }
    end
    
    print("Map expanded to radius " .. map.current_radius)
end

-- Check if any neighbors of a cube are outside the map, and expand if needed
local function ensure_map_coverage(map, cube)
    local neighbors = cubecoords.all_neighbors(cube)
    local needs_expansion = false
    
    for _, neighbor in ipairs(neighbors) do
        local hex = get_hex(map, neighbor)
            if not get_hex(map, neighbor) then
            needs_expansion = true
            break
        end
    end
    
    if needs_expansion then
        expand_map(map)
    end
end

-- Helper to get hex by cube coordinates
function get_hex(map, cube)
    local key = cubecoords.to_key(cube)
    return map.hexes[key]
end

-- Helper to get hex by offset coordinates (backward compat)
local function get_hex_offset(map, col, row)
    if not map.offset_to_key[row] or not map.offset_to_key[row][col] then
        return nil
    end
    local key = map.offset_to_key[row][col]
    return map.hexes[key]
end

function mark_neighbours_on_map_cube(map, cube)
    local neighbors = cubecoords.all_neighbors(cube)
    for i, ncube in ipairs(neighbors) do
            local hex = get_hex(map, ncube)
        if hex then
            hex.neighbour = true
        end
    end
end

-- Backward compat wrapper
local function mark_neighbours_on_map(map, col, row, w, h)
    local cube = cubecoords.from_offset(col, row)
    mark_neighbours_on_map_cube(map, cube)
end

local function mark_tmp_on_map(map, col, row, w, h)
    local cube = cubecoords.from_offset(col, row)
    local neighbors = cubecoords.all_neighbors(cube)
    for _, ncube in ipairs(neighbors) do
        local hex = get_hex(map, ncube)
        if hex then
            hex.tmp = true
        end
    end
end

local function clear_all_tmp(map, w, h)
    for _, hex in pairs(map.hexes) do
        hex.tmp = nil
    end
end

function clear_all_neighbours(map, w, h)
    for _, hex in pairs(map.hexes) do
        hex.neighbour = nil
        hex.can_move = nil
        hex.can_special = nil
        hex.is_beetle_move = nil
        hex.has_dual_option = nil
        hex.can_drop = nil
    end
end

local function mark_legal_moves_for_piece(map, src_cube, w, h)
    print("=== mark_legal_moves_for_piece called ===")
    print("Source cube: [" .. src_cube.x .. "," .. src_cube.y .. "," .. src_cube.z .. "]")
    
    clear_all_neighbours(map, w, h)
    
    local src_hex = get_hex(map, src_cube)
    
    if not src_hex or not src_hex.piece then
        print("ERROR: No piece at source!")
        return
    end
    
    print("Piece: " .. src_hex.piece.name)
    
    -- Delegate to the piece's mark_legal_moves method
    local result = src_hex.piece:mark_legal_moves(map, src_cube)
    
    -- Mark normal moves
    for _, hex in ipairs(result.normal_moves) do
        hex.can_move = true
    end
    
    -- Mark special ability targets
    for _, hex in ipairs(result.special_targets) do
        hex.can_special = true
    end
    
    print("Marked " .. #result.normal_moves .. " normal moves and " .. #result.special_targets .. " special targets")
    print("=== Complete ===")
end

local function remove_piece_from_map(map, col, row)
    local cube = cubecoords.from_offset(col, row)
    local hex = get_hex(map, cube)
    if hex and hex.piece then
        print("Removed piece from: "..tostring(col)..", "..tostring(row))
        hex.piece = nil
        return true
    end
    print("Failed to remove piece from: "..tostring(col)..", "..tostring(row))
    return false
end

local function tmp_to_neighbor(map)
    for _, hex in pairs(map.hexes) do
        if hex.tmp then
            hex.neighbour = true
        end
    end
end

local function flood_neighbours_neighbours_jump(map, col, row, w, h)
    clear_all_tmp(map, w, h)
    for _, hex in pairs(map.hexes) do
        if hex.neighbour then
            local hcol, hrow = cubecoords.to_offset(hex.cube)
            mark_tmp_on_map(map, hcol, hrow, w, h)
        end
    end
    clear_all_neighbours(map, w, h)
    tmp_to_neighbor(map)
    clear_all_tmp(map, w, h)
end

local function flood_neighbours_neighbours(map, col, row, w, h)
    clear_all_tmp(map, w, h)
    for _, hex in pairs(map.hexes) do
        if hex.neighbour then
            local hcol, hrow = cubecoords.to_offset(hex.cube)
            mark_tmp_on_map(map, hcol, hrow, w, h)
        end
    end
    tmp_to_neighbor(map)
    clear_all_tmp(map, w, h)
end

-- Global counter for debugging
local flood_call_count = 0
local MAX_FLOOD_CALLS = 100

function flood_neighbours(map, cube)
    flood_call_count = flood_call_count + 1
    if flood_call_count > MAX_FLOOD_CALLS then
        print("ERROR: flood_neighbours called too many times! Infinite loop detected!")
        print("Current cube: " .. cubecoords.to_key(cube))
        flood_call_count = flood_call_count - 1
        return
    end

    local hex = get_hex(map, cube)
    if not hex then
        flood_call_count = flood_call_count - 1
        return
    end

    local neighbors = cubecoords.all_neighbors(cube)
    for _, ncube in ipairs(neighbors) do
        local nhex = get_hex(map, ncube)
        if nhex and not nhex.neighbour then
            if nhex.piece then
                nhex.neighbour = true
                flood_neighbours(map, ncube)
            end
        end
        if nhex and nhex.piece then
            nhex.neighbour = true
        end
    end
    flood_call_count = flood_call_count - 1
end

local function firstPieceCoords(map)
    for _, hex in pairs(map.hexes) do
        if hex.piece then
            return hex.cube
        end
    end
    return nil
end

local function pieceCanDetach(map, cube)
    local hex = get_hex(map, cube)
    if not hex then 
        return false 
    end
    
    -- If this piece has something underneath it (beetle stacking),
    -- it can always detach because the under_piece maintains hive cohesion
    if hex.piece and hex.piece.under_piece then
        return true
    end
    
    local tmp = hex.piece
    hex.piece = nil
    clear_all_neighbours(map, map.w, map.h)
    
    local first_cube = firstPieceCoords(map)
    if not first_cube then
        hex.piece = tmp
        return true
    end
    
    flood_neighbours(map, first_cube)

    -- Mark the starting piece as visited (flood_neighbours only marks neighbors)
    local first_hex = get_hex(map, first_cube)
    if first_hex then
        first_hex.neighbour = true
    end

    hex.piece = tmp
    hex.neighbour = true

    for _, check_hex in pairs(map.hexes) do
        if check_hex.piece and not check_hex.neighbour then
            clear_all_neighbours(map, map.w, map.h)
            return false
        end
    end
    
    clear_all_neighbours(map, map.w, map.h)
    return true
end

local function try_self_detach(map, src_cube, dest_cube)
    -- Only clear neighbour flags, not can_move/can_special which are being set during move marking
    for _, hex in pairs(map.hexes) do
        hex.neighbour = nil
    end

    local src_hex = get_hex(map, src_cube)
    if not src_hex then return false end

    local tmp = src_hex.player_id

    -- If piece has under_piece, source location still has a piece after moving
    if src_hex.piece and src_hex.piece.under_piece then
        src_hex.player_id = src_hex.piece.under_piece.player_id
    else
        src_hex.player_id = nil
    end

    -- Check if destination would be connected to the hive
    local enemy, friend = countNearbyPlayer(map, dest_cube)
    if (enemy + friend == 0) then
        src_hex.player_id = tmp
        return false
    end

    src_hex.player_id = tmp
    return true
end

local function try_move_piece_on_map(map, src_cube, dest_cube)
    if not pieceCanDetach(map, src_cube) then
        return false
    end
    if not try_self_detach(map, src_cube, dest_cube) then
        return false
    end

    clear_all_neighbours(map, map.w, map.h)
    
    local src_hex = get_hex(map, src_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    -- Only beetles and mosquitos can climb on top of pieces
    if dest_hex.piece and src_hex.piece.id ~= PiecesEnum.BEETLE and src_hex.piece.id ~= PiecesEnum.MOSQUITO then
        return false
    end
    
    -- Call the piece's try_to_move method
    if src_hex.piece and src_hex.piece.try_to_move then
        return src_hex.piece:try_to_move(map, src_cube, dest_cube)
    end
    
    return false
end

local function move_piece_on_map(map, src_cube, dest_cube, on_complete_callback)
    if not try_move_piece_on_map(map, src_cube, dest_cube) then
        return false
    end
    
    local src_hex = get_hex(map, src_cube)
    local dest_hex = get_hex(map, dest_cube)
    
    -- Store piece reference for animation
    local moving_piece = src_hex.piece
    
    -- Start animation, then actually move the piece when animation completes
    animation.start_move(moving_piece, src_cube, dest_cube, function()
        -- This callback executes when animation completes
        local src_hex = get_hex(map, src_cube)
        local dest_hex = get_hex(map, dest_cube)
        
        if src_hex.piece and src_hex.piece.move_piece then
            src_hex.piece:move_piece(map, src_cube, dest_cube, G.active_player_id)
            
            -- Check if piece moved to outermost ring and expand if so
            local center = cubecoords.new(0, 0, 0)
            local distance = cubecoords.distance(center, dest_cube)
            if distance >= map.current_radius then
                expand_map(map)
            end
            
            -- Send network message if in multiplayer game
            if G.network and G.network.mode ~= "none" and G.network.connected then
                G.network.send_move(G.active_player_id, src_cube, dest_cube)
            end
            
            -- Call the completion callback if provided
            if on_complete_callback then
                on_complete_callback()
            end
        end
    end)
    
    return true
end

-- Export module
return {
    init_map = init_map,
    tryAddPieceToMap = tryAddPieceToMap,
    move_piece_on_map = move_piece_on_map,
    expand_map = expand_map,
    get_hex = get_hex,
    mark_neighbours_on_map_cube = mark_neighbours_on_map_cube,
    clear_all_neighbours = clear_all_neighbours,
    mark_legal_moves_for_piece = mark_legal_moves_for_piece,
    flood_neighbours = flood_neighbours,
    flood_neighbours_neighbours = flood_neighbours_neighbours,
    pieceCanDetach = pieceCanDetach,
    try_self_detach = try_self_detach,
    try_move_piece_on_map = try_move_piece_on_map,
    firstPieceCoords = firstPieceCoords,
}
