local Modules = require(script.Parent.Parent.ModuleIndex)
local Configuration = require(Modules.Configuration)

local chunk_size = Configuration.GetChunkSize()
local vert_chunk_size = Configuration.GetVertChunkSize()

local EncodingUtil = {}

function EncodingUtil.EncodeTableToString(t: {}): string
    local s = "{"
    for k, v in pairs(t) do
        -- Check for special key types
        if typeof(k) == "Vector3" then
            s = s .. "[" .. k.X .. "," .. k.Y .. "," .. k.Z .. "]:"
        elseif typeof(k) == "number" or typeof(k) == "string" then
            s = s .. k .. ":"
        end
        
        -- Check for special value types
        if typeof(v) == "table" then
            s = s .. EncodingUtil.EncodeTableToString(v)
        elseif typeof(v) == "EnumItem" then
            s = s .. "EI=" .. v.Name
        elseif typeof(v) == "Color3" then
            s = s .. "C3=" .. v:ToHex()
        else
            s = s .. v
        end
        
        s = s .. ","
    end
    
    return s .. "}"
end

function EncodingUtil.DecodeStringToTable(s)
    local pos = 1
    
    function decode_value()
        local char = s:sub(pos, pos)
        if char == "{" then
            return decode_table()
        elseif char == "[" then
            return decode_vector()
        elseif char == "E" then
            return decode_enumitem()
        elseif char == "C" then
            return decode_color3()
        else
            return decode_primitive(1)
        end
    end
    
    function decode_table()
        local t = {}
        pos = pos + 1
        while true do
            local char = s:sub(pos, pos)
            if char == "}" then
                pos = pos + 1
                break
            elseif char == "," then
                pos = pos + 1
            else
                local key = nil
                if char == "[" then
                    key = decode_vector()
                else
                    key = decode_primitive(0)
                end
                pos = pos + 1 -- skip colon
                local value = decode_value()
                t[key] = value
            end
        end
        return t
    end
    
    function decode_vector()
        local i = s:find(",", pos)
        local x = tonumber(s:sub(pos+1, i-1))
        pos = i + 1
        i = s:find(",", pos)
        local y = tonumber(s:sub(pos, i-1))
        pos = i + 1
        i = s:find("%]", pos)
        local z = tonumber(s:sub(pos, i-1))
        pos = i + 2
        return Vector3.new(x, y, z)
    end
    
    function decode_enumitem()
        pos = pos + 3 -- skip "EI="
        local i = s:find(",", pos)
        local name = s:sub(pos, i-1)
        pos = i + 1
        return Enum.Material[name]
    end
    
    function decode_color3()
        pos = pos + 3 -- skip "C3="
        local hex = s:sub(pos, pos+5)
        pos = pos + 6
        return Color3.fromHex(hex)
    end
    
    function decode_primitive(a: number)
        local sep = if a == 0 then ":" else ","
        local i = s:find(sep, pos)
        local value = s:sub(pos, i-1)
        pos = i + 1
        if value == "true" or value == "false" then
            return value == "true"
        elseif tonumber(value) then
            return tonumber(value)
        else
            return value
        end
    end
    
    return decode_table()
end




--run length encoding
function EncodingUtil.RLEncode(t: {})
    local encoded = {}
    local start_key = nil

    for k = 1, chunk_size ^ 2  * vert_chunk_size do
        if start_key == nil then
            start_key = k
        elseif t[k] == t[k-1] then
            continue
        else
            if t[k-1] then
                table.insert(encoded, {start_key, k-1, t[k-1]})
            end

            start_key = k
        end
    end

    return encoded
end

--run length decoding
function EncodingUtil.RLDecode(encoded)
    local function deepCopy(t: {})
        local copy = {}
        for k, v in t do
            if type(v) == 'table' then
                v = deepCopy(v)
            end
            if tonumber(k) then
				copy[tonumber(k)] = v
			else
				copy[k] = v
			end
        end
        return copy
    end

    local decoded = {}
    for _, run in encoded do
        local start_key, end_key, value = run["1"], run["2"], run["3"]
        for k = start_key, end_key do
            decoded[k] = if typeof(value) == "table" then deepCopy(value) else value
        end
    end
    return decoded
end

return EncodingUtil

