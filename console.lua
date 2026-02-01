-- In-game console for debugging
Console = {}
Console.messages = {}
Console.max_messages = 30
Console.visible = true
Console.original_print = print
Console.log_file = nil

-- Override print to capture messages
function Console.init()
    -- Open log file
    Console.log_file = io.open("output/debug.log", "w")
    if Console.log_file then
        Console.log_file:write("=== Debug Log Started ===\n")
        Console.log_file:flush()
    end
    
    print = function(...)
        local args = {...}
        local message = ""
        for i, v in ipairs(args) do
            message = message .. tostring(v)
            if i < #args then
                message = message .. "\t"
            end
        end
        
        -- Add to console buffer
        table.insert(Console.messages, message)
        
        -- Keep only last max_messages
        if #Console.messages > Console.max_messages then
            table.remove(Console.messages, 1)
        end
        
        -- Write to log file
        if Console.log_file then
            Console.log_file:write(message .. "\n")
            Console.log_file:flush()  -- Flush immediately so we can see logs even if game crashes
        end
        
        -- Also call original print for terminal output
        Console.original_print(...)
    end
end

function Console.draw(x, y, width, height)
    if not Console.visible then
        return
    end
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Draw title
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print("Console (Press C to toggle)", x + 5, y + 5)
    
    -- Draw messages
    love.graphics.setColor(1, 1, 1, 1)
    local line_height = 15
    local start_y = y + 25
    local visible_lines = math.floor((height - 30) / line_height)
    local start_index = math.max(1, #Console.messages - visible_lines + 1)
    
    for i = start_index, #Console.messages do
        local message = Console.messages[i]
        local draw_y = start_y + (i - start_index) * line_height
        
        love.graphics.print(message, x + 5, draw_y)
    end
end

function Console.toggle()
    Console.visible = not Console.visible
end

function Console.clear()
    Console.messages = {}
    if Console.log_file then
        Console.log_file:write("=== Console Cleared ===\n")
        Console.log_file:flush()
    end
end

return Console
