-- pieces/movement_utils.lua
-- Shared movement logic for Hive pieces
-- Provides: can_move_through_gap, simple_move_piece, neighbor utilities
-- Used by: all piece classes

local cubecoords = require("cubecoords")
local map_module = require("map")

local MovementUtils = {}

-- Find the common neighbors between two adjacent hexes
-- Returns a table of cube coordinates (should be exactly 2 for adjacent hexes)
function MovementUtils.get_common_neighbors(from_cube, to_cube)
    local from_neighbors = cubecoords.all_neighbors(from_cube)
    local to_neighbors = cubecoords.all_neighbors(to_cube)

    local common_neighbors = {}
    for _, fn in ipairs(from_neighbors) do
        for _, tn in ipairs(to_neighbors) do
            if cubecoords.equals(fn, tn) then
                table.insert(common_neighbors, fn)
            end
        end
    end

    return common_neighbors
end

-- Check if a piece can move through the gap between from_cube and to_cube
-- Implements the "freedom of movement" rule from Hive
-- A piece cannot move through a gap if both sides are blocked
function MovementUtils.can_move_through_gap(map, from_cube, to_cube)
    -- Get the two hexes that are common neighbors of both from and to
    local common_neighbors = MovementUtils.get_common_neighbors(from_cube, to_cube)

    -- Need exactly 2 common neighbors (the ones on either side of the gap)
    if #common_neighbors ~= 2 then
        return false
    end

    -- Check if both sides are blocked (if so, cannot move through)
    local hex1 = map_module.get_hex(map, common_neighbors[1])
    local hex2 = map_module.get_hex(map, common_neighbors[2])

    local blocked1 = hex1 and hex1.piece ~= nil
    local blocked2 = hex2 and hex2.piece ~= nil

    -- If both sides are blocked, cannot move through
    if blocked1 and blocked2 then
        return false
    end

    -- At least one side is open, can move through
    return true
end

-- Standard piece movement (for pieces that don't have special stacking behavior)
-- Transfers the piece from src_cube to dest_cube and marks it as moved
function MovementUtils.simple_move_piece(map, src_cube, dest_cube)
    local src_hex = map_module.get_hex(map, src_cube)
    local dest_hex = map_module.get_hex(map, dest_cube)

    if not src_hex or not dest_hex then
        return false
    end

    -- Mark piece as moved this turn
    src_hex.piece.has_moved_last_turn = true

    -- Transfer piece to destination
    dest_hex.piece = src_hex.piece
    dest_hex.player_id = src_hex.player_id

    -- Clear source
    src_hex.piece = nil
    src_hex.player_id = nil

    return true
end

-- Check if a hex has at least one adjacent piece
-- Used for verifying hive connectivity
-- exclude_cube: optional cube to exclude from the check (e.g., the piece being moved)
function MovementUtils.has_adjacent_piece(map, cube, exclude_cube)
    local neighbors = cubecoords.all_neighbors(cube)

    for _, neighbor_cube in ipairs(neighbors) do
        -- Skip the excluded cube if provided
        if exclude_cube and cubecoords.equals(neighbor_cube, exclude_cube) then
            goto continue
        end

        local hex = map_module.get_hex(map, neighbor_cube)
        if hex and hex.piece then
            return true
        end

        ::continue::
    end

    return false
end

-- Calculate the height of a piece stack
-- Returns the number of pieces stacked at this location
function MovementUtils.get_stack_height(piece)
    if not piece then
        return 0
    end

    local height = 1
    local current = piece.under_piece
    while current do
        height = height + 1
        current = current.under_piece
    end

    return height
end

return MovementUtils
