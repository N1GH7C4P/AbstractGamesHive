-- Game action execution (movement, placement, special abilities)

local Actions = {}

local cubecoords = require("cubecoords")
local globals = require("globals")
local game = require("game")
local map_module = require("map")

-------------------
-- PIECE PLACEMENT
-------------------

-- Place a piece from inventory onto the map
-- Returns: true if placement succeeded, false otherwise
function Actions.place_piece(player_id, piece_template, cube)
    if not map_module.tryAddPieceToMap(player_id, piece_template, G.map, cube) then
        return false
    end

    game.checkIfWin(G.map, G.w, G.h)
    game.pass_turn(player_id)

    return true
end

-------------------
-- PIECE SELECTION
-------------------

-- Select a piece on the map for movement
-- Returns: true if selection succeeded, false otherwise
function Actions.select_piece_on_map(cube, player_id)
    if not game.selectPieceOnMap(G.map, cube, player_id) then
        return false
    end

    local offset_x, offset_y = cubecoords.to_offset(cube)
    globals.select_piece(offset_x, offset_y)
    map_module.clear_all_neighbours(G.map, G.w, G.h)
    map_module.mark_legal_moves_for_piece(G.map, cube, G.w, G.h)

    -- Only allow movement after queen is placed
    if G.player[player_id].pieces[1].inStock == 0 then
        G.move_mode = 1
    end

    return true
end

-------------------
-- PIECE MOVEMENT
-------------------

-- Move a piece from source to destination
-- Returns: true if move succeeded, false otherwise
function Actions.move_piece(src_cube, dest_cube)
    local did_move = map_module.move_piece_on_map(G.map, src_cube, dest_cube, function()
        game.checkIfWin(G.map, G.w, G.h)
    end)

    if did_move then
        game.pass_turn(G.active_player_id)
        return true
    end

    return false
end

-------------------
-- INVENTORY NAVIGATION
-------------------

-- Select next piece in inventory
-- Returns: true if changed, false if already at last piece
function Actions.select_next_piece()
    local maxPieceId = #Config.pieceInventory
    if G.active_piece_id < maxPieceId then
        G.active_piece_id = G.active_piece_id + 1
        return true
    end
    return false
end

-- Select previous piece in inventory
-- Returns: true if changed, false if already at first piece
function Actions.select_previous_piece()
    if G.active_piece_id > 1 then
        G.active_piece_id = G.active_piece_id - 1
        return true
    end
    return false
end

-- Select specific piece in inventory by id
function Actions.select_piece_by_id(piece_id)
    G.active_piece_id = piece_id
end

-------------------
-- SPECIAL ABILITIES
-------------------

-- Enter pillbug special ability mode (phase 1: target selected)
-- Returns: drop_locations table
function Actions.enter_pillbug_mode(src_cube, target_cube)
    local src_hex = map_module.get_hex(G.map, src_cube)
    if not src_hex or not src_hex.piece then
        return {}
    end

    globals.enter_pillbug_mode(src_cube, target_cube)
    map_module.clear_all_neighbours(G.map, G.w, G.h)

    -- Get and mark valid drop locations
    local drop_locations
    if src_hex.piece.get_drop_locations then
        drop_locations = src_hex.piece:get_drop_locations(G.map, src_cube, target_cube)
    else
        drop_locations = {}
    end

    for _, dest_cube in ipairs(drop_locations) do
        local hex = map_module.get_hex(G.map, dest_cube)
        if hex then
            hex.can_drop = true
        end
    end

    return drop_locations
end

-- Execute drop phase of pillbug special ability
-- Returns: true if drop succeeded, false otherwise
function Actions.execute_drop(src_cube, target_cube, drop_cube)
    local src_hex = map_module.get_hex(G.map, src_cube)
    if not src_hex or not src_hex.piece then
        return false
    end

    local success = src_hex.piece:execute_drop(G.map, src_cube, target_cube, drop_cube)

    if success then
        game.pass_turn(G.active_player_id)
        return true
    end

    return false
end

-------------------
-- MOSQUITO CHOICES
-------------------

-- Execute mosquito's beetle power choice (climbing move)
-- Returns: true if move succeeded, false otherwise
function Actions.execute_mosquito_beetle_choice(src_cube, dest_cube)
    local did_move = map_module.move_piece_on_map(G.map, src_cube, dest_cube, function()
        game.checkIfWin(G.map, G.w, G.h)
    end)

    if did_move then
        game.pass_turn(G.active_player_id)
        return true
    end

    return false
end

-- Execute mosquito's pillbug power choice (enter pillbug mode)
-- Returns: drop_locations table
function Actions.execute_mosquito_pillbug_choice(src_cube, target_cube)
    local src_hex = map_module.get_hex(G.map, src_cube)
    if not src_hex or not src_hex.piece then
        return {}
    end

    globals.enter_pillbug_mode(src_cube, target_cube)
    map_module.clear_all_neighbours(G.map, G.w, G.h)

    -- Get and mark valid drop locations using pillbug logic
    local drop_locations
    if src_hex.piece.get_drop_locations_as_pillbug then
        drop_locations = src_hex.piece:get_drop_locations_as_pillbug(G.map, src_cube, target_cube)
    elseif src_hex.piece.get_drop_locations then
        drop_locations = src_hex.piece:get_drop_locations(G.map, src_cube, target_cube)
    else
        drop_locations = {}
    end

    for _, dest_cube in ipairs(drop_locations) do
        local hex = map_module.get_hex(G.map, dest_cube)
        if hex then
            hex.can_drop = true
        end
    end

    return drop_locations
end

return {
    place_piece = Actions.place_piece,
    select_piece_on_map = Actions.select_piece_on_map,
    move_piece = Actions.move_piece,
    select_next_piece = Actions.select_next_piece,
    select_previous_piece = Actions.select_previous_piece,
    select_piece_by_id = Actions.select_piece_by_id,
    enter_pillbug_mode = Actions.enter_pillbug_mode,
    execute_drop = Actions.execute_drop,
    execute_mosquito_beetle_choice = Actions.execute_mosquito_beetle_choice,
    execute_mosquito_pillbug_choice = Actions.execute_mosquito_pillbug_choice,
}
