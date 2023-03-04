local voxel_size = require(require(script.Parent.ModuleIndex).Configuration).GetVoxelSize()

local assetManager = {}

local userConfigFileInstance = game.ServerStorage:FindFirstChild("VoxelSeaBuilderPlugin Configuration")
if not userConfigFileInstance then
   warn("No Voxel Sea Builder Plugin Configuration file detected. Yielding until one is found.")
end
repeat task.wait()
    userConfigFileInstance = game.ServerStorage:FindFirstChild("VoxelSeaBuilderPlugin Configuration")
until userConfigFileInstance

userConfigFileInstance:Clone().Parent = script
local userConfigFile = require(script["VoxelSeaBuilderPlugin Configuration"])

assetManager.Material_Info = userConfigFile.TexturesTable

function assetManager.GetNameFromMaterialCode(code : number) : string
	assert(typeof(code) == "number", "[[Voxel Sea Builder Plugin]][AssetManager.GetNameFromMaterialCode] Argument #1 must be a number.")

	local materialName : string
    for _, material in pairs(assetManager.Material_Info) do
        if material.Code == code then
            materialName = material.Name
        end
    end
	return materialName
end

function  assetManager.GetTextureCopies(material : number | string) : {Texture}
	assert(typeof(material) == "number" or typeof(material) == "string", "[[Voxel Sea Builder Plugin]][AssetManager.GetNameTextureCopies] Argument #1 must be either a number or a string.")

	local materialName : string
    local textureCopies : {Texture} = {}

    if typeof(material) == "number" then
        materialName = assetManager.GetNameFromMaterialCode(material)
	elseif typeof(material) == "string" then
		materialName = material
	end

    for _, mat in pairs(assetManager.Material_Info) do
        if mat.Name == materialName then
            for _, texture in pairs (mat.Textures:GetChildren()) do
                local textureCopy = texture:Clone()
                textureCopy.StudsPerTileU = voxel_size
				textureCopy.StudsPerTileV = voxel_size

				table.insert(textureCopies, textureCopy)
            end
        end
    end
    return textureCopies
end

return assetManager