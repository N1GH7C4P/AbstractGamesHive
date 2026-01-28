local Piece = require("pieces.piece")

-- Beetle class
Beetle = setmetatable({}, {__index = Piece})
Beetle.__index = Beetle

function Beetle:new(owner)
    local instance = Piece.new(self, owner)
    instance.name = "Beetle"
    instance.initials = "Be"
    instance.color = {0.5, 0.2, 0, 1}
    instance.id = 2
    instance.image_path = "img/beetle.png"
    return instance
end

function Beetle:try_to_move(map, src_cube, dest_cube)
    -- Beetle can move one space and can climb on top of pieces
    local distance = cubecoords.distance(src_cube, dest_cube)
    if distance ~= 1 then
        return false
    end
    
    -- Check freedom to move rule (unless climbing on top of destination piece)
    local dest_hex = map_get_hex(map, dest_cube)
    if dest_hex and not dest_hex.piece then
        -- Moving to empty space, check freedom of movement
        local can_move = self:can_move_through_gap(map, src_cube, dest_cube)
        if not can_move then
            local col, row = cubecoords.to_offset(dest_cube)
            print("    Beetle BLOCKED by freedom of movement to (" .. col .. "," .. row .. ")")
        end
        return can_move
    end
    -- If moving onto a piece, beetle can always move (climbing on top)
    
    return true
end

-- Helper to check if a move through a gap is allowed (freedom to move)
function Beetle:can_move_through_gap(map, from_cube, to_cube)
    -- Get the two hexes that are common neighbors of both from and to
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
    
    -- Need exactly 2 common neighbors (the ones on either side of the gap)
    if #common_neighbors ~= 2 then
        return false
    end
    
    -- Get stack heights for origin and destination
    local from_hex = map_get_hex(map, from_cube)
    local to_hex = map_get_hex(map, to_cube)
    
    -- Calculate height of origin (without the beetle on it)
    local from_height = 0
    if from_hex and from_hex.piece then
        -- Count the stack under the beetle
        local current = from_hex.piece.under_piece
        while current do
            from_height = from_height + 1
            current = current.under_piece
        end
    end
    
    -- Calculate height of destination
    local to_height = 0
    if to_hex and to_hex.piece then
        to_height = self:get_stack_height(to_hex.piece)
    end
    
    -- Check if both sides are blocked by stacks higher than origin and destination
    local hex1 = map_get_hex(map, common_neighbors[1])
    local hex2 = map_get_hex(map, common_neighbors[2])
    
    local height1 = 0
    if hex1 and hex1.piece then
        height1 = self:get_stack_height(hex1.piece)
    end
    
    local height2 = 0
    if hex2 and hex2.piece then
        height2 = self:get_stack_height(hex2.piece)
    end
    
    -- Beetle cannot move through gap if both sides are higher than both origin and destination
    if height1 > from_height and height1 > to_height and 
       height2 > from_height and height2 > to_height then
        return false
    end
    
    -- At least one side is low enough, can move through
    return true
end

-- Helper to calculate stack height
function Beetle:get_stack_height(piece)
    if not piece then return 0 end
    
    local height = 1
    local current = piece.under_piece
    while current do
        height = height + 1
        current = current.under_piece
    end
    return height
end

function Beetle:move_piece(map, src_cube, dest_cube, active_player_id)
    -- Beetle can move on top of other pieces
    local src_hex = map_get_hex(map, src_cube)
    local dest_hex = map_get_hex(map, dest_cube)
    
    if not src_hex or not dest_hex then return false end
    
    local tempPiece = nil
    if dest_hex.piece then
        tempPiece = dest_hex.piece
        tempPiece.player_id = dest_hex.player_id
        dest_hex.piece = src_hex.piece
    else
        dest_hex.piece = src_hex.piece
    end
    
    dest_hex.player_id = active_player_id
    
    -- If the source hex has an under_piece, restore it
    if src_hex.piece.under_piece then
        local underpiece = src_hex.piece.under_piece
        src_hex.piece.under_piece = nil
        src_hex.player_id = underpiece.player_id
        src_hex.piece = underpiece
        underpiece = nil
    else
        src_hex.piece = nil
        src_hex.player_id = nil
    end
    
    -- Temp piece becomes the new under_piece
    if tempPiece then
        dest_hex.piece.under_piece = tempPiece
        dest_hex.piece.under_piece.player_id = tempPiece.player_id
        tempPiece = nil
    end
    
    return true
end

return Beetle
