-- Simple JSON encoder/decoder module

local Json = {}

-- JSON encoder with pretty-printing
function Json.encode(obj, indent)
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
                parts[i] = next_indent_str .. Json.encode(obj[i], indent + 1)
            end
            if #parts == 0 then
                return "[]"
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent_str .. "]"
        else
            local parts = {}
            for k, v in pairs(obj) do
                local key = type(k) == "string" and ('"' .. k .. '"') or tostring(k)
                table.insert(parts, next_indent_str .. key .. ": " .. Json.encode(v, indent + 1))
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

-- JSON decoder
function Json.decode(str)
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
                    table.insert(arr, Json.decode(current))
                    current = ""
                else
                    current = current .. c
                end
            end
            if current ~= "" then
                table.insert(arr, Json.decode(current))
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
                    obj[key] = Json.decode(val_str)
                end
            end
        end
        return obj
    end
    
    return nil
end

return Json
