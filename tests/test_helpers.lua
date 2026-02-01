-- tests/test_helpers.lua
-- Helper functions for integration testing of piece movements
-- Provides simple notation for setting up board configurations

local cubecoords = require("cubecoords")
local map_module = require("map")

-- Piece class imports
local QueenBee = require("pieces.queenbee")
local Beetle = require("pieces.beetle")
local Grasshopper = require("pieces.grasshopper")
local Spider = require("pieces.spider")
local SoldierAnt = require("pieces.soldierant")
local Ladybug = require("pieces.ladybug")
local Mosquito = require("pieces.mosquito")
local Pillbug = require("pieces.pillbug")

local test_helpers = {}

-- Compass direction lookup for neighboring hexes (flat-topped)
local COMPASS_DIRECTIONS = {
    ["0,-1,1"] = "N",
    ["1,-1,0"] = "NE",
    ["1,0,-1"] = "SE",
    ["0,1,-1"] = "S",
    ["-1,1,0"] = "SW",
    ["-1,0,1"] = "NW"
}

-- Get compass direction name for a cube coordinate (if it's a neighbor of origin)
local function get_compass_direction(cube)
    local key = string.format("%d,%d,%d", cube.x, cube.y, cube.z)
    return COMPASS_DIRECTIONS[key]
end

-- Format cube coordinate with compass direction if applicable
local function format_cube_with_direction(cube)
    local cube_str = string.format("%d,%d,%d", cube.x, cube.y, cube.z)
    local direction = get_compass_direction(cube)
    if direction then
        return string.format("%s (%s)", cube_str, direction)
    end
    return cube_str
end

-- Initialize minimal global state for testing
local function init_test_globals()
    if not G then
        G = {}
    end

    -- Minimal required globals for piece movement tests
    G.active_player_id = 1
    G.w = 50  -- Legacy map dimensions
    G.h = 50
    G.turn_number = {2, 2}  -- Both players past turn 1 (so queen placement not required)
    G.animating = false
    G.network = {mode = "none", connected = false}

    -- Player data structure (minimal)
    if not G.player then
        G.player = {
            [1] = {pieces = {{inStock = 0}}},  -- Queen already placed
            [2] = {pieces = {{inStock = 0}}}
        }
    end
end

-- Map piece codes to piece classes
local PIECE_CODE_TO_CLASS = {
    QB = QueenBee,
    A = SoldierAnt,
    B = Beetle,
    G = Grasshopper,
    S = Spider,
    L = Ladybug,
    M = Mosquito,
    P = Pillbug
}

-- Parse a cube coordinate string "x,y,z" into {x, y, z}
function test_helpers.parse_cube(str)
    if type(str) == "table" then
        -- Already a cube coordinate
        return str
    end

    local x, y, z = str:match("([^,]+),([^,]+),([^,]+)")
    if not x or not y or not z then
        error("Invalid cube coordinate string: " .. tostring(str))
    end

    return cubecoords.new(tonumber(x), tonumber(y), tonumber(z))
end

-- Format a cube coordinate as a string
function test_helpers.cube_to_string(cube)
    return string.format("%d,%d,%d", cube.x, cube.y, cube.z)
end

-- Parse a piece notation string "x,y,z:player:piece"
-- Returns: {cube, player, piece_code}
local function parse_piece_string(str)
    local coord_part, player, piece_code = str:match("([^:]+):([^:]+):([^:]+)")

    if not coord_part or not player or not piece_code then
        error("Invalid piece string format: " .. str .. "\nExpected: x,y,z:player:piece")
    end

    local cube = test_helpers.parse_cube(coord_part)
    local player_num = tonumber(player)

    if not player_num or (player_num ~= 1 and player_num ~= 2) then
        error("Invalid player number: " .. tostring(player) .. " (must be 1 or 2)")
    end

    if not PIECE_CODE_TO_CLASS[piece_code] then
        error("Unknown piece code: " .. piece_code .. "\nValid codes: QB, A, B, G, S, L, M, P")
    end

    return {
        cube = cube,
        player = player_num,
        piece_code = piece_code
    }
end

-- Create a test map from an array of piece notation strings
-- Format: {"x,y,z:player:piece", ...}
-- Example: {"0,0,0:1:QB", "1,-1,0:2:A"}
function test_helpers.setup_test_map(pieces)
    -- Initialize global state required by game logic
    init_test_globals()

    local map = map_module.init_map()

    if not pieces or #pieces == 0 then
        return map
    end

    -- Parse all piece strings
    local parsed_pieces = {}
    for _, piece_str in ipairs(pieces) do
        table.insert(parsed_pieces, parse_piece_string(piece_str))
    end

    -- Place pieces on the map
    for _, piece_data in ipairs(parsed_pieces) do
        local hex = map_module.get_hex(map, piece_data.cube)

        if not hex then
            -- Expand map if needed
            map_module.expand_map(map)
            hex = map_module.get_hex(map, piece_data.cube)
        end

        if not hex then
            error("Failed to get hex at " .. test_helpers.cube_to_string(piece_data.cube))
        end

        -- Create piece instance
        local PieceClass = PIECE_CODE_TO_CLASS[piece_data.piece_code]
        local piece_instance = PieceClass:new(piece_data.player)

        -- Place piece on hex
        hex.piece = piece_instance
        hex.player_id = piece_data.player
    end

    return map
end

-- Get legal moves for a piece at the given position
-- Returns array of cube coordinates
function test_helpers.get_legal_moves(map, cube_or_string)
    local cube = test_helpers.parse_cube(cube_or_string)

    -- Call mark_legal_moves to set flags
    map_module.mark_legal_moves_for_piece(map, cube)

    -- Collect all hexes marked as legal moves
    local legal_moves = {}

    for _, hex in pairs(map.hexes) do
        if hex.can_move or hex.can_special then
            table.insert(legal_moves, hex.cube)
        end
    end

    -- Clear the flags
    map_module.clear_all_neighbours(map)

    return legal_moves
end

-- Execute a move on the map (for multi-step tests)
-- Returns: success boolean
function test_helpers.execute_move(map, from_cube, to_cube)
    from_cube = test_helpers.parse_cube(from_cube)
    to_cube = test_helpers.parse_cube(to_cube)

    local src_hex = map_module.get_hex(map, from_cube)
    local dest_hex = map_module.get_hex(map, to_cube)

    if not src_hex or not dest_hex then
        return false
    end

    if not src_hex.piece then
        return false
    end

    -- Use the piece's try_to_move and move_piece methods
    if not src_hex.piece:try_to_move(map, from_cube, to_cube) then
        return false
    end

    -- Execute the move
    if src_hex.piece.move_piece then
        src_hex.piece:move_piece(map, from_cube, to_cube, src_hex.player_id)
        return true
    end

    return false
end

-- Get hex at position (helper)
function test_helpers.get_hex_at(map, cube_or_string)
    local cube = test_helpers.parse_cube(cube_or_string)
    return map_module.get_hex(map, cube)
end

-- Assertion: Check that a move is in the legal moves array
function test_helpers.assert_has_move(moves, expected_cube)
    expected_cube = test_helpers.parse_cube(expected_cube)

    for _, move_cube in ipairs(moves) do
        if cubecoords.equals(move_cube, expected_cube) then
            return true  -- Found it
        end
    end

    -- Build helpful error message with compass directions
    local move_strs = {}
    for _, cube in ipairs(moves) do
        table.insert(move_strs, format_cube_with_direction(cube))
    end

    local error_msg = string.format(
        "Expected move to %s not found.\nLegal moves: [%s]",
        format_cube_with_direction(expected_cube),
        table.concat(move_strs, ", ")
    )

    error(error_msg)
end

-- Assertion: Check that a move is NOT in the legal moves array
function test_helpers.assert_no_move(moves, forbidden_cube)
    forbidden_cube = test_helpers.parse_cube(forbidden_cube)

    for _, move_cube in ipairs(moves) do
        if cubecoords.equals(move_cube, forbidden_cube) then
            local error_msg = string.format(
                "Forbidden move to %s was found in legal moves",
                format_cube_with_direction(forbidden_cube)
            )
            error(error_msg)
        end
    end

    return true  -- Not found, which is what we want
end

-- Assertion: Check that the number of legal moves matches expected count
function test_helpers.assert_move_count(moves, expected_count)
    local actual_count = #moves

    if actual_count ~= expected_count then
        local move_strs = {}
        for _, cube in ipairs(moves) do
            table.insert(move_strs, format_cube_with_direction(cube))
        end

        local error_msg = string.format(
            "Expected %d legal moves but found %d.\nLegal moves: [%s]",
            expected_count,
            actual_count,
            table.concat(move_strs, ", ")
        )

        error(error_msg)
    end

    return true
end

-- Get pickable pieces for Pillbug special ability
-- Returns array of cube coordinates of pieces that can be picked up
function test_helpers.get_pickable_pieces(map, cube_or_string)
    local cube = test_helpers.parse_cube(cube_or_string)
    local hex = map_module.get_hex(map, cube)

    if not hex or not hex.piece then
        return {}
    end

    -- Only Pillbug and Mosquito (mimicking Pillbug) have this ability
    if hex.piece.get_pickable_pieces then
        return hex.piece:get_pickable_pieces(map, cube)
    end

    return {}
end

-- Get drop locations for Pillbug special ability after picking up a piece
-- Returns array of cube coordinates where the piece can be dropped
function test_helpers.get_drop_locations(map, pillbug_cube, target_cube)
    pillbug_cube = test_helpers.parse_cube(pillbug_cube)
    target_cube = test_helpers.parse_cube(target_cube)

    local hex = map_module.get_hex(map, pillbug_cube)

    if not hex or not hex.piece then
        return {}
    end

    if hex.piece.get_drop_locations then
        return hex.piece:get_drop_locations(map, pillbug_cube, target_cube)
    end

    return {}
end

-- Check if a cube is in a list of cubes
function test_helpers.cube_in_list(cube, cube_list)
    cube = test_helpers.parse_cube(cube)
    for _, list_cube in ipairs(cube_list) do
        if cubecoords.equals(cube, list_cube) then
            return true
        end
    end
    return false
end

-- Set has_moved_last_turn flag on a piece
function test_helpers.set_piece_moved_last_turn(map, cube_or_string, moved)
    local cube = test_helpers.parse_cube(cube_or_string)
    local hex = map_module.get_hex(map, cube)
    if hex and hex.piece then
        hex.piece.has_moved_last_turn = moved
    end
end

-- Get hexes with dual options (both Beetle climb and Pillbug pick)
-- Returns array of cube coordinates that have has_dual_option set
function test_helpers.get_dual_option_hexes(map, cube_or_string)
    local cube = test_helpers.parse_cube(cube_or_string)

    -- Call mark_legal_moves to set flags including has_dual_option
    map_module.mark_legal_moves_for_piece(map, cube)

    -- Collect all hexes marked with dual option
    local dual_hexes = {}

    for _, hex in pairs(map.hexes) do
        if hex.has_dual_option then
            table.insert(dual_hexes, hex.cube)
        end
    end

    -- Clear the flags
    map_module.clear_all_neighbours(map)

    return dual_hexes
end

-- Simulate clicking on a special target (for Pillbug/Mosquito special ability)
-- Returns the result of handle_special_click if available
function test_helpers.simulate_special_click(map, src_cube, target_cube, mouseX, mouseY)
    src_cube = test_helpers.parse_cube(src_cube)
    target_cube = test_helpers.parse_cube(target_cube)
    mouseX = mouseX or 100
    mouseY = mouseY or 100

    local src_hex = map_module.get_hex(map, src_cube)
    if not src_hex or not src_hex.piece then
        return false
    end

    -- First mark legal moves to set up the dual option flags
    map_module.mark_legal_moves_for_piece(map, src_cube)

    -- Store reference to map in global for pieces that need it
    G.map = map

    if src_hex.piece.handle_special_click then
        return src_hex.piece:handle_special_click(map, src_cube, target_cube, mouseX, mouseY)
    end

    return false
end

-- Check if mosquito choice popup was triggered
function test_helpers.is_mosquito_popup_active()
    return G.mosquito_choice_popup == true
end

-- Clear mosquito popup state (for cleanup between tests)
function test_helpers.clear_mosquito_popup_state()
    G.mosquito_choice_popup = nil
    G.mosquito_choice_dest = nil
    G.mosquito_popup_x = nil
    G.mosquito_popup_y = nil
end

-- Debug helper: Print the current board state
function test_helpers.print_board(map)
    print("\n=== Board State ===")

    local pieces = {}
    for _, hex in pairs(map.hexes) do
        if hex.piece then
            local cube_str = test_helpers.cube_to_string(hex.cube)
            local piece_name = hex.piece.name or hex.piece.initials or "?"
            local player = hex.player_id or "?"
            table.insert(pieces, string.format("  %s: P%s %s", cube_str, player, piece_name))
        end
    end

    table.sort(pieces)

    if #pieces == 0 then
        print("  (empty)")
    else
        for _, line in ipairs(pieces) do
            print(line)
        end
    end

    print("===================\n")
end

return test_helpers
