--!nocheck
local replicator = {}

replicator.VoxelSeaBuilderPluginObjectsFolder = workspace:FindFirstChild("VoxelSeaBuilderPluginObjectsFolder")

replicator.RenderedChunkList = {}
replicator.LoadedChunkList = {}

local update_log = {}

-- Initialises the plugin
function replicator.Initialise()
	if replicator.VoxelSeaBuilderPluginObjectsFolder == nil then
		local folder = Instance.new("Folder")
		folder.Name = "VoxelSeaBuilderPluginObjects"
		folder.Parent = workspace
		replicator.VoxelSeaBuilderPluginObjectsFolder = folder
	end
end

--Function to log updates to chunks.
function replicator.LogUpdate(chunk, index : number, new_ID : number)
	local pos = chunk.Position
	update_log[pos] = update_log[pos] or {}
	update_log[pos][index] = new_ID
end

function replicator.GetUpdateLog()
	return update_log
end

function replicator.SetUpdateLog(newLog : {})
	assert(typeof(newLog) == "table", "Argument #1 must be a table! Type of arg 1: "..typeof(newLog))
	update_log = newLog
end

--returns the updates relevant to the given chunk.
function replicator.GetUpdatesForChunks(chunkPositions : {Vector3}) 
	local updates_to_return = {}
	for _, pos in pairs(chunkPositions) do

		if update_log[pos] then
			table.insert(updates_to_return, {pos, update_log[pos]})
		else
			continue
		end

	end
	return updates_to_return
end

return replicator