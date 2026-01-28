-- Game state save/load functionality
GameState = {}

-- Simple JSON encoder with pretty-printing
local function json_encode(obj, indent)
    indent = indent or 0
    local indent_str = string.rep("  ", indent)
    local next_indent_str = string.rep("  ", indent + 1)
    local t = type(obj)
    
    if t == "table" then
        local is_array = true
        local max_index = 0
        for k, v in pairs(obj) do
            if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
                is_array = false
                break
            end
            max_index = math.max(max_index, k)
        end
        
        if is_array then
            local parts = {}
            for i = 1, max_index do
                parts[i] = next_indent_str .. json_encode(obj[i], indent + 1)
            end
            if #parts == 0 then
                return "[]"
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent_str .. "]"
        else
            local parts = {}
            for k, v in pairs(obj) do
                local key = type(k) == "string" and ('"' .. k .. '"') or tostring(k)
                table.insert(parts, next_indent_str .. key .. ": " .. json_encode(v, indent + 1))
            end
            if #parts == 0 then
                return "{}"
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent_str .. "}"
        end
    elseif t == "string" then
        return '"' .. obj:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(obj)
    else
        return "null"
    end
end

-- Simple JSON decoder
local function json_decode(str)
    str = str:gsub("^%s*", ""):gsub("%s*$", "")
    
    if str == "null" or str == "" then
        return nil
    elseif str == "true" then
        return true
    elseif str == "false" then
        return false
    elseif str:match("^%-?%d+%.?%d*$") then
        return tonumber(str)
    elseif str:sub(1, 1) == '"' then
        return str:sub(2, -2):gsub('\\"', '"'):gsub('\\\\', '\\'):gsub('\\n', '\n')
    elseif str:sub(1, 1) == '[' then
        local arr = {}
        local content = str:sub(2, -2)
        if content ~= "" then
            local depth = 0
            local current = ""
            for i = 1, #content do
                local c = content:sub(i, i)
                if c == '{' or c == '[' then
                    depth = depth + 1
                    current = current .. c
                elseif c == '}' or c == ']' then
                    depth = depth - 1
                    current = current .. c
                elseif c == ',' and depth == 0 then
                    table.insert(arr, json_decode(current))
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                table.insert(arr, json_decode(current))
            end
        end
        return arr
    elseif str:sub(1, 1) == '{' then
        local obj = {}
        local content = str:sub(2, -2)
        if content ~= "" then
            local depth = 0
            local current = ""
            local pairs_arr = {}
            for i = 1, #content do
                local c = content:sub(i, i)
                if c == '{' or c == '[' then
                    depth = depth + 1
                    current = current .. c
                elseif c == '}' or c == ']' then
                    depth = depth - 1
                    current = current .. c
                elseif c == ',' and depth == 0 then
                    table.insert(pairs_arr, current)
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                table.insert(pairs_arr, current)
            end
            
            for _, pair in ipairs(pairs_arr) do
                local colon_pos = pair:find(":")
                if colon_pos then
                    local key_str = pair:sub(1, colon_pos - 1):gsub("^%s*", ""):gsub("%s*$", "")
                    local val_str = pair:sub(colon_pos + 1):gsub("^%s*", ""):gsub("%s*$", "")
                    local key = key_str:sub(1, 1) == '"' and key_str:sub(2, -2) or tonumber(key_str)
                    obj[key] = json_decode(val_str)
                end
            end
        end
        return obj
    end
    
    return nil
end

-- Save complete game state to file
function GameState.save(filename)
    filename = filename or "savegame.json"
    
    local file = io.open(filename, "w")
    if not file then
        print("ERROR: Could not open file for writing: " .. filename)
        return false
    end
    
    -- Build save data structure
    local save_data = {}
    
    -- Global game state
    save_data.game_state = {
        active_player_id = active_player_id,
        active_piece_id = active_piece_id,
        turn_number = {turn_number[1], turn_number[2]},
        move_mode = move_mode,
        game_over = game_over,
        who_won = {who_won[1], who_won[2]},
        selected_piece_x = selected_piece_x,
        selected_piece_y = selected_piece_y,
        highlight = highlight
    }
    
    -- Camera state
    save_data.camera = {
        x = camera_x,
        y = camera_y,
        zoom = camera_zoom
    }
    
    -- Player inventories
    save_data.players = {}
    for p = 1, 2 do
        save_data.players[p] = {
            id = player[p].id,
            pieces = {}
        }
        for i, piece_info in ipairs(player[p].pieces) do
            save_data.players[p].pieces[i] = {
                id = piece_info.id,
                name = piece_info.name,
                inStock = piece_info.inStock
            }
        end
    end
    
    -- Pieces on board
    save_data.board = {}
    for cube_key, hex in pairs(map.hexes) do
        if hex.piece then
            local piece_entry = {
                cube = {x = hex.cube.x, y = hex.cube.y, z = hex.cube.z},
                piece_id = hex.piece.id,
                player_id = hex.player_id,
                has_under_piece = hex.piece.under_piece ~= nil
            }
            
            -- Save complete under_piece information if it exists
            if hex.piece.under_piece then
                piece_entry.under_piece = {
                    id = hex.piece.under_piece.id,
                    player_id = hex.piece.under_piece.player_id or hex.piece.under_piece.owner
                }
            end
            
            table.insert(save_data.board, piece_entry)
        end
    end
    
    -- Map metadata
    save_data.map = {
        current_radius = map.current_radius
    }
    
    -- Write to file
    file:write(json_encode(save_data))
    file:close()
    print("Game saved to: " .. filename)
    return true
end

-- Load game state from file
function GameState.load(filename)
    filename = filename or "savegame.json"
    
    local file = io.open(filename, "r")
    if not file then
        print("ERROR: Could not open file for reading: " .. filename)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parse save data
    local save_data = json_decode(content)
    if not save_data then
        print("ERROR: Failed to parse save file")
        return false
    end
    
    -- Clear current game state
    for cube_key, hex in pairs(map.hexes) do
        hex.piece = nil
        hex.player_id = nil
        hex.neighbour = nil
        hex.can_move = nil
        hex.can_special = nil
    end
    
    -- Restore global game state
    if save_data.game_state then
        active_player_id = save_data.game_state.active_player_id or 1
        active_piece_id = save_data.game_state.active_piece_id or 1
        turn_number = {
            save_data.game_state.turn_number[1] or 1,
            save_data.game_state.turn_number[2] or 1
        }
        move_mode = save_data.game_state.move_mode or 0
        game_over = save_data.game_state.game_over or false
        who_won = {
            save_data.game_state.who_won[1] or 0,
            save_data.game_state.who_won[2] or 0
        }
        selected_piece_x = save_data.game_state.selected_piece_x or 0
        selected_piece_y = save_data.game_state.selected_piece_y or 0
        highlight = save_data.game_state.highlight or 0
    end
    
    -- Restore camera
    if save_data.camera then
        camera_x = save_data.camera.x or 0
        camera_y = save_data.camera.y or 0
        camera_zoom = save_data.camera.zoom or 0.8
    end
    
    -- Restore player inventories
    if save_data.players then
        for p = 1, 2 do
            if save_data.players[p] then
                for i, piece_data in ipairs(save_data.players[p].pieces) do
                    if player[p].pieces[i] then
                        player[p].pieces[i].inStock = piece_data.inStock
                    end
                end
            end
        end
    end
    
    -- Restore map metadata
    if save_data.map then
        map.current_radius = save_data.map.current_radius or 10
    end
    
    -- Restore pieces on board
    if save_data.board then
        -- First pass: place all pieces without stacking
        for _, piece_data in ipairs(save_data.board) do
            if not piece_data.has_under_piece then
                local cube = cubecoords.new(piece_data.cube.x, piece_data.cube.y, piece_data.cube.z)
                local hex = map_get_hex(map, cube)
                
                if hex then
                    -- Get piece template and create instance
                    local piece_template = piecesInventory[piece_data.piece_id]
                    if piece_template then
                        hex.piece = piece_template.class:new(piece_data.player_id)
                        hex.player_id = piece_data.player_id
                    end
                end
            end
        end
        
        -- Second pass: handle stacked pieces (beetles, mosquitos on top)
        for _, piece_data in ipairs(save_data.board) do
            if piece_data.has_under_piece and piece_data.under_piece then
                local cube = cubecoords.new(piece_data.cube.x, piece_data.cube.y, piece_data.cube.z)
                local hex = map_get_hex(map, cube)
                
                if hex then
                    -- First, create the piece that goes underneath
                    local under_template = piecesInventory[piece_data.under_piece.id]
                    if under_template then
                        local under_piece = under_template.class:new(piece_data.under_piece.player_id)
                        
                        -- Then create the piece that goes on top
                        local top_template = piecesInventory[piece_data.piece_id]
                        if top_template then
                            local top_piece = top_template.class:new(piece_data.player_id)
                            
                            -- Set up the stacking relationship
                            top_piece.under_piece = under_piece
                            under_piece.player_id = piece_data.under_piece.player_id
                            
                            -- Place on map
                            hex.piece = top_piece
                            hex.player_id = piece_data.player_id
                        end
                    end
                end
            end
        end
    end
    
    -- Reset Pillbug special move state
    pillbug_special_mode = false
    pillbug_cube = nil
    pillbug_target_cube = nil
    
    print("Game loaded from: " .. filename)
    return true
end

return GameState
