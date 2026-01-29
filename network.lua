-- Network multiplayer module using lua socket
local Network = {}

Network.socket = nil
Network.server = nil
Network.client = nil
Network.mode = "none" -- "none", "server", "client"
Network.connected = false
Network.pending_moves = {}
Network.is_local_turn = true

-- Network protocol messages
local MSG = {
    CONNECT = "CONNECT",
    DISCONNECT = "DISCONNECT",
    MOVE = "MOVE",
    PLACE = "PLACE",
    GAME_STATE = "GAME_STATE",
    TURN_CHANGE = "TURN_CHANGE",
    GAME_OVER = "GAME_OVER"
}

function Network.init()
    local success, socket = pcall(require, "socket")
    if success then
        Network.socket = socket
        print("Lua socket loaded successfully")
        return true
    else
        print("WARNING: Lua socket not available. Multiplayer disabled.")
        print("Install lua socket for LÖVE: luarocks install luasocket")
        return false
    end
end

-- Start hosting a game (server mode)
function Network.host(port)
    port = port or 12345
    
    if not Network.socket then
        print("ERROR: Socket not available")
        return false
    end
    
    Network.server = Network.socket.tcp()
    Network.server:settimeout(0) -- Non-blocking
    
    local success, err = Network.server:bind("*", port)
    if not success then
        print("ERROR: Failed to bind server: " .. tostring(err))
        Network.server = nil
        return false
    end
    
    Network.server:listen(1)
    Network.mode = "server"
    Network.is_local_turn = true -- Server is player 1, goes first
    Network.local_player_id = 1  -- Host is player 1
    active_player_id = 1
    
    print("Server started on port " .. port)
    print("Waiting for client to connect...")
    return true
end

-- Join a game (client mode)
function Network.join(host, port)
    host = host or "localhost"
    port = port or 12345
    
    if not Network.socket then
        print("ERROR: Socket not available")
        return false
    end
    
    Network.client = Network.socket.tcp()
    Network.client:settimeout(5) -- 5 second timeout for connection
    
    local success, err = Network.client:connect(host, port)
    if not success then
        print("ERROR: Failed to connect to server: " .. tostring(err))
        Network.client:close()
        Network.client = nil
        return false
    end
    
    Network.client:settimeout(0) -- Non-blocking after connection
    Network.mode = "client"
    Network.connected = true
    Network.is_local_turn = false -- Client is player 2, waits for server
    Network.local_player_id = 2  -- Client is player 2
    active_player_id = 1  -- Game starts with player 1's turn
    
    -- Send connect message
    Network.send({type = MSG.CONNECT, player_id = 2})
    
    print("Connected to server at " .. host .. ":" .. port)
    return true
end

-- Disconnect from network game
function Network.disconnect()
    if Network.mode == "server" and Network.client then
        Network.send({type = MSG.DISCONNECT})
        Network.client:close()
        Network.client = nil
    elseif Network.mode == "client" and Network.client then
        Network.send({type = MSG.DISCONNECT})
        Network.client:close()
        Network.client = nil
    end
    
    if Network.server then
        Network.server:close()
        Network.server = nil
    end
    
    Network.mode = "none"
    Network.connected = false
    Network.is_local_turn = true
    print("Disconnected from network game")
end

-- Send data over network
function Network.send(data)
    local connection = Network.mode == "server" and Network.client or Network.client
    if not connection then
        return false
    end
    
    local json_data = Network.serialize(data)
    local success, err = connection:send(json_data .. "\n")
    if not success then
        print("ERROR: Failed to send data: " .. tostring(err))
        return false
    end
    return true
end

-- Receive data from network (non-blocking)
function Network.receive()
    local connection = Network.mode == "server" and Network.client or Network.client
    if not connection then
        return nil
    end
    
    local data, err, partial = connection:receive("*l")
    if data then
        return Network.deserialize(data)
    end
    return nil
end

-- Simple JSON-like serialization
function Network.serialize(data)
    if type(data) ~= "table" then
        return tostring(data)
    end
    
    local result = "{"
    local first = true
    for k, v in pairs(data) do
        if not first then
            result = result .. ","
        end
        first = false
        
        result = result .. '"' .. tostring(k) .. '":'
        if type(v) == "table" then
            result = result .. Network.serialize(v)
        elseif type(v) == "string" then
            result = result .. '"' .. v .. '"'
        else
            result = result .. tostring(v)
        end
    end
    result = result .. "}"
    return result
end

-- Simple JSON-like deserialization
function Network.deserialize(str)
    -- This is a simple parser - for production use a proper JSON library
    local data = {}
    
    -- Remove outer braces
    str = str:gsub("^{", ""):gsub("}$", "")
    
    -- Split by commas (simple version, doesn't handle nested objects perfectly)
    for pair in str:gmatch('[^,]+') do
        local key, value = pair:match('"([^"]+)"%s*:%s*(.+)')
        if key and value then
            -- Remove quotes from string values
            if value:match('^".*"$') then
                value = value:gsub('^"', ""):gsub('"$', "")
            else
                value = tonumber(value) or value
            end
            data[key] = value
        end
    end
    
    return data
end

-- Update function to be called every frame
function Network.update(dt)
    if Network.mode == "none" then
        return
    end
    
    -- Server: Accept new client connections
    if Network.mode == "server" and not Network.client then
        local client = Network.server:accept()
        if client then
            client:settimeout(0)
            Network.client = client
            Network.connected = true
            print("Client connected!")
        end
    end
    
    -- Receive and process messages
    local msg = Network.receive()
    if msg then
        Network.handle_message(msg)
    end
end

-- Handle incoming network messages
function Network.handle_message(msg)
    if not msg or not msg.type then
        return
    end
    
    if msg.type == MSG.CONNECT then
        print("Player " .. msg.player_id .. " connected")
        -- Send current game state to new player
        Network.send_game_state()
        
    elseif msg.type == MSG.DISCONNECT then
        print("Player disconnected")
        Network.disconnect()
        
    elseif msg.type == MSG.PLACE then
        -- Remote player placed a piece
        print("Remote player placed piece: id=" .. msg.piece_id .. " at [" .. msg.x .. "," .. msg.y .. "," .. msg.z .. "]")
        local cube = cubecoords.new(msg.x, msg.y, msg.z)
        
        -- Get the piece template from player inventory
        local piece_info = player[msg.player_id]:getPieceInfo(msg.piece_id)
        if piece_info and piece_info.template then
            -- Place the piece
            tryAddPieceToMap(msg.player_id, piece_info.template, map, cube)
            pass_turn(msg.player_id)
            Network.is_local_turn = true
        end
        
    elseif msg.type == MSG.MOVE then
        -- Remote player moved a piece
        print("Remote player moved piece from [" .. msg.from_x .. "," .. msg.from_y .. "," .. msg.from_z .. "] to [" .. msg.to_x .. "," .. msg.to_y .. "," .. msg.to_z .. "]")
        local from_cube = cubecoords.new(msg.from_x, msg.from_y, msg.from_z)
        local to_cube = cubecoords.new(msg.to_x, msg.to_y, msg.to_z)
        
        -- Move the piece
        move_piece_on_map(map, from_cube, to_cube)
        pass_turn(msg.player_id)
        Network.is_local_turn = true
        
    elseif msg.type == MSG.GAME_STATE then
        print("Received game state from server")
        -- Could sync full game state here if needed
        
    elseif msg.type == MSG.GAME_OVER then
        print("Game over!")
        game_over = true
    end
end

-- Send game state to connected player
function Network.send_game_state()
    local state = {
        type = MSG.GAME_STATE,
        active_player = active_player_id,
        turn_numbers = turn_number[1] .. "," .. turn_number[2]
    }
    Network.send(state)
end

-- Send piece placement to opponent
function Network.send_place(player_id, piece_id, cube)
    if not Network.connected or Network.is_local_turn == false then
        return
    end
    
    local msg = {
        type = MSG.PLACE,
        player_id = player_id,
        piece_id = piece_id,
        x = cube.x,
        y = cube.y,
        z = cube.z
    }
    Network.send(msg)
    Network.is_local_turn = false
end

-- Send piece movement to opponent
function Network.send_move(player_id, from_cube, to_cube)
    if not Network.connected or Network.is_local_turn == false then
        return
    end
    
    local msg = {
        type = MSG.MOVE,
        player_id = player_id,
        from_x = from_cube.x,
        from_y = from_cube.y,
        from_z = from_cube.z,
        to_x = to_cube.x,
        to_y = to_cube.y,
        to_z = to_cube.z
    }
    Network.send(msg)
    Network.is_local_turn = false
end

return Network
