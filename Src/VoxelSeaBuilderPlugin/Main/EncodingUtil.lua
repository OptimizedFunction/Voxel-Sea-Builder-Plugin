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

function EncodingUtil.DecodeStringToTable(s: string):{}
    local pos = 1 --ignore the first {
    local decodedTable = {}

    --removing the first brace
    s = s:sub(2)

    local function decodeKey(key: string)
        if key:sub(1, 1) == "[" then
            local xStart = 2
            local xEnd = key:find(",", xStart)
            local x = tonumber(key:sub(xStart, xEnd - 1))

            local yStart = xEnd + 1
            local yEnd = key:find(",", yStart)
            local y = tonumber(key:sub(yStart, yEnd - 1))

            local zStart = yEnd + 1
            local zEnd = key:find("]", zStart)
            local z = tonumber(key:sub(zStart, zEnd - 1))

            return Vector3.new(x, y, z)
        elseif tonumber(key) then
            return tonumber(key)
        else
            return key
        end
    end

    local function decodeValue(val: string)
        if val:sub(1, 3) == "EI=" then
            return Enum.Material[val:sub(4)]
        elseif val:sub(1, 3) == "C3=" then
            return Color3.fromHex(val:sub(4))
        elseif tonumber(val) then
            return tonumber(val)
        else
            return val
        end
    end

    while pos <= #s do
        if s:sub(pos, pos) == "}" or s:sub(pos, pos) == "," then
            pos = pos + 1
            continue
        end

        local keyStart = pos
        local keyEnd = s:find(":", keyStart)
        if not keyEnd then break end --no keys remain. This means we are done!

        local key = s:sub(keyStart, keyEnd - 1)
        key = decodeKey(key) -- handles numbers, strings, and Vector3s only.

        pos = keyEnd + 1 -- skip the :

        local valStart = pos
        if s:sub(valStart, valStart) == "{" then
            local openBraces = 1
            local strEnd = nil

            for i = valStart+1, #s do
                if s:sub(i, i) == "{" then openBraces += 1
                elseif s:sub(i, i) == "}" then openBraces -= 1
                end
                if openBraces == 0 then
                    strEnd = i
                    break
                end
            end
            if not strEnd then print(openBraces) continue end
            local subStr = string.sub(s, pos, strEnd)
            local val = EncodingUtil.DecodeStringToTable(subStr)
            pos = strEnd + 1
            decodedTable[key] = val
            continue
        end
        local valEnd = s:find(",", valStart)
        local val = s:sub(valStart, if valEnd then valEnd-1 else nil)
        val = decodeValue(val) -- handles Color3s, Enum.Material EnumItems and other basic types.

        pos = if valEnd then valEnd + 1 else #s -- skip the ,

        decodedTable[key] = val
    end
    
    return decodedTable
end

--run length encoding
function EncodingUtil.RLEncode(t: {}): {}
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
function EncodingUtil.RLDecode(encoded: {}): {}
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
        local start_key, end_key, value = unpack(run)
        for k = start_key, end_key do
            decoded[k] = if typeof(value) == "table" then deepCopy(value) else value
        end
    end
    return decoded
end

return EncodingUtil

