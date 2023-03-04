
local Modules = require(script.Parent.ModuleIndex)
local Replicator = require(Modules.ReplicatorAndUpdateLogger)
local ChunkClass = require(Modules.Chunk)
local VoxelLib = require(Modules.VoxelLib)
local AssetManager = require(Modules.AssetManager)
local PoolService = require(Modules.PoolService)
local Configuration = require(Modules.Configuration)
local StringCompression = require(script.StringCompression)

local VPInterface = require(script.UiSetup)

local UIS: UserInputService = game:GetService('UserInputService')
local HttpService: HttpService = game:GetService('HttpService')

local voxel_size : number = Configuration.GetVoxelSize()
local material_info = AssetManager.Material_Info

local mouse : PluginMouse = plugin:GetMouse()
local isBuilding : boolean = false
local isErasing : boolean = false
local init_starterGui_state : boolean

local min_size_x : number = 1
local min_size_z : number = 1
local max_size_x : number = 40
local max_size_z : number = 40

local currentBrush : Part
local currentPos : Vector3 = Vector3.new()
local locked_y_coord : number | nil

local clickConn : RBXScriptConnection
local clickConn2 : RBXScriptConnection
local inputConn : RBXScriptConnection

local MouseButton1Held : boolean = false

--configurable values
local lock_y_coord : boolean = false
local uniformBrushScaling : boolean = false
local current_size_x : number = 1
local current_size_z : number = 1
local currentMat : number = 1
local brushType : string = 'Spherical'

--creating button
local toolbar : PluginToolbar = plugin:CreateToolbar('Voxel Sea Dev Tools')
local button : PluginToolbarButton = toolbar:CreateButton('Start Building', 'Show or hide the Developer Tools widget', 'rbxassetid://6725202079')

--creating dock widget
function createWidgetUI()

    local DockWidgetInfo : DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Left,
        true,
        true,
        280,
        500,
        350,
        250
    )

    local DockWidget : DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui('MainWidget', DockWidgetInfo)
    DockWidget.Name = 'Voxel Sea Dev Tools'
    DockWidget.Title = 'Voxel Sea Dev Tools'

    local CTSectionClass = require(script.Parent.StudioWidgets.CollapsibleTitledSection)
    local LabeledTextInputClass = require(script.Parent.StudioWidgets.LabeledTextInput)
    local VerticalScrollingFrameClass = require(script.Parent.StudioWidgets.VerticalScrollingFrame)
    local CustomTextButtonClass = require(script.Parent.StudioWidgets.CustomTextButton)
    local LabeledCheckbox = require(script.Parent.StudioWidgets.LabeledCheckbox)
    local guiUtil = require(script.Parent.StudioWidgets.GuiUtilities)

    local BGFrame = Instance.new('Frame')
    BGFrame.Size = UDim2.new(1,0,1,0)
    BGFrame.ZIndex = -1
    guiUtil.syncGuiElementBackgroundColor(BGFrame)
    BGFrame.Parent = DockWidget

    local VerticalScrollingFrameObj = VerticalScrollingFrameClass.new('Main')
    local SectionFrame = VerticalScrollingFrameObj:GetSectionFrame()
    local MainFrame = VerticalScrollingFrameObj:GetContentsFrame()
    SectionFrame.Parent = DockWidget


    local DataCTSectionObj = CTSectionClass.new('Load/Save', 'Load/Save World', true, true, false)
    local DataCTSectionTitle = DataCTSectionObj:GetSectionFrame()
    local DataCTSectionFrame = DataCTSectionObj:GetContentsFrame()
    DataCTSectionTitle.Size = UDim2.new(1,0,0,20)
    DataCTSectionTitle.Parent = MainFrame

    local WorldID_input = LabeledTextInputClass.new('worldID', 'World ID', 'Enter World ID')
    WorldID_input:SetMaxGraphemes(1e10)
    local WorldID_inputFrame = WorldID_input:GetFrame()
    WorldID_inputFrame.Size = UDim2.new(1,0,0,25)
    WorldID_inputFrame.Parent = DataCTSectionFrame

    local LS_buttonFrame = Instance.new('Frame')
    LS_buttonFrame.Size = UDim2.new(1,0,0,40)
    guiUtil.syncGuiElementBackgroundColor(LS_buttonFrame)
    LS_buttonFrame.BorderSizePixel = 0
    LS_buttonFrame.Parent = DataCTSectionFrame

    local saveButton = CustomTextButtonClass.new('save', 'Save'):GetButton()
    saveButton.Size = UDim2.new(0.3,0,0,30)
    saveButton.Position = UDim2.new(0.35,0,0.5,0)
    saveButton.AnchorPoint = Vector2.new(0.5,0.5)
    saveButton.Parent = LS_buttonFrame

    local loadButton = CustomTextButtonClass.new('load', 'Load'):GetButton()
    loadButton.Size = UDim2.new(0.3,0,0,30)
    loadButton.Position = UDim2.new(0.65,0,0.5,0)
    loadButton.AnchorPoint = Vector2.new(0.5,0.5)
    loadButton.Parent = LS_buttonFrame

    local ConfigCTSectionObj = CTSectionClass.new('Configuration', 'Configuration', true, true, false)
    local ConfigCTSectionTitle = ConfigCTSectionObj:GetSectionFrame()
    local ConfigCTSectionFrame = ConfigCTSectionObj:GetContentsFrame()
    ConfigCTSectionTitle.Size = UDim2.new(1,0,0,50)
    ConfigCTSectionTitle.Parent = MainFrame

    local lock_y_coord_checkbox = LabeledCheckbox.new('lock_y', 'XZ Plane Locking', lock_y_coord, false)
    local function onLockY_ValueChanged(newValue)
        lock_y_coord = newValue
    end
    lock_y_coord_checkbox:SetValueChangedFunction(onLockY_ValueChanged)
    lock_y_coord_checkbox:GetFrame().Parent = ConfigCTSectionFrame

    local uniformBrushScaling_checkbox = LabeledCheckbox.new('UBS', 'Uniform Size Scaling', uniformBrushScaling, false)
    local function onUBS_ValueChanged(newValue)
        uniformBrushScaling = newValue
    end
    uniformBrushScaling_checkbox:SetValueChangedFunction(onUBS_ValueChanged)
    uniformBrushScaling_checkbox:GetFrame().Parent = ConfigCTSectionFrame

    return DockWidget, WorldID_input, saveButton, loadButton, lock_y_coord_checkbox, uniformBrushScaling_checkbox
end
local DockWidget, WorldID_input, saveButton, loadButton, lock_y_coord_checkbox, uniformBrushScaling_checkbox = createWidgetUI()

--creating and updating bounding box
function updateBrush(position : Vector3)
    currentPos = position

    local function updateCurrentBrushType(brush)
        if brush:FindFirstChild("SelectionBox") then
            brush.SelectionBox:Destroy()
        elseif brush:FindFirstChild("SelectionSphere") then
            brush.SelectionSphere:Destroy()
        end

        if brushType == 'Cuboidal' then
            brush.Shape = Enum.PartType.Block
            local SelectionBox = Instance.new('SelectionBox')
            SelectionBox.SurfaceTransparency = 0.9
            
            if currentMat == 0 then
                SelectionBox.SurfaceColor3 = Color3.new(1,0.25,0.3)
                SelectionBox.Color3 = Color3.new(1,0.6,0.6)
            else
                SelectionBox.SurfaceColor3 = Color3.new(0,0.9,1)
                SelectionBox.Color3 = Color3.new(0.6,1,1)
            end

            SelectionBox.Adornee = brush
            SelectionBox.LineThickness = 0.01
            SelectionBox.Parent = brush

        elseif brushType == 'Spherical' then
            brush.Shape = Enum.PartType.Ball
            local SelectionSphere = Instance.new('SelectionSphere')
            SelectionSphere.SurfaceTransparency = 0.9

            if currentMat == 0 then
                SelectionSphere.SurfaceColor3 = Color3.new(1,0.25,0.3)
                SelectionSphere.Color3 = Color3.new(1,0.6,0.6)
            else
                SelectionSphere.SurfaceColor3 = Color3.new(0,0.9,1)
                SelectionSphere.Color3 = Color3.new(0.6,1,1)
            end
            
            SelectionSphere.Adornee = brush
            SelectionSphere.Parent = brush
        end
    end

    local brush : Part
    if currentBrush and (currentBrush:FindFirstChild('SelectionBox') or currentBrush:FindFirstChild('SelectionSphere')) then
        brush = currentBrush
        brush.Position = position

        if brushType == 'Cuboidal' and not currentBrush:FindFirstChild('SelectionBox') then
            updateCurrentBrushType(brush)
        elseif brushType == 'Spherical' and not currentBrush:FindFirstChild('SelectionSphere') then
            updateCurrentBrushType(brush)
        end

        if brushType == "Spherical" then
            brush.Size = Vector3.new(1,1,1) * voxel_size * math.max(current_size_x, current_size_z)
        elseif brushType == "Cuboidal" then
            brush.Size = Vector3.new(current_size_x, 1, current_size_z) * voxel_size
        end

        local selectionInstance = brush:FindFirstChildOfClass('SelectionBox') or brush:FindFirstChildOfClass('SelectionSphere')
        if currentMat == 0 or isErasing then
            selectionInstance.SurfaceColor3 = Color3.new(1,0.25,0.3)
            selectionInstance.Color3 = Color3.new(1,0.6,0.6)
        else
            selectionInstance.SurfaceColor3 = Color3.new(0,0.9,1)
            selectionInstance.Color3 = Color3.new(0.6,1,1)
        end
    else
        brush = Instance.new('Part')

        brush.Transparency = 1
        brush.Position = position
        brush.Name = '[Voxel Sea Builder Plugin] BoundingPart'
        brush.Locked = true
        brush.Parent = workspace

        updateCurrentBrushType(brush)
    end
    return brush
end

--actual build function
function build()
    game:GetService('RunService'):BindToRenderStep('build', 1, function()

		local unitRay = mouse.UnitRay
		
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {currentBrush}
		params.FilterType = Enum.RaycastFilterType.Exclude
		
		local results = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
		
		if results and results.Instance:IsA('BasePart') then
			local hitPos : Vector3
            if currentMat == 0 or isErasing then
                hitPos = results.Position - results.Normal * voxel_size/2
            else
                hitPos = results.Position + results.Normal * voxel_size/2
            end

            local x,y,z = CFrame.new(hitPos):GetComponents()

            local function getSign(num1 : number, num2 : number, num3 : number) : number
                if num2%2 == 0 then 
                    return 0    
                end

                local frac = (num1/num3)%1
                if frac >= 0.5 then return -1
                else return 1
                end
            end


            local pos_x = voxel_size * (math.floor(x/voxel_size + 0.5) + getSign(x, current_size_x, voxel_size)*1/2)
            local pos_y = locked_y_coord or voxel_size * (math.floor(y/voxel_size + 0.5) + getSign(y, 1, voxel_size)*1/2)
            local pos_z = voxel_size * (math.floor(z/voxel_size + 0.5) + getSign(z, current_size_z, voxel_size)*1/2)

            local box_pos = Vector3.new(pos_x, pos_y, pos_z)

            currentBrush = updateBrush(box_pos)
		end

    end)
end

--onclick function for when the user clicks to build
function onMouseClick()
    MouseButton1Held = true
    repeat
        local effectiveMat : number = currentMat

        if isErasing then
            effectiveMat = 0
        end
        if lock_y_coord then
            locked_y_coord = currentPos.Y
        end

        local voxelsInBrush : {}
        if brushType == 'Cuboidal' then
            voxelsInBrush = VoxelLib.GetVoxelsInCuboid(currentPos, currentBrush.Size)
        elseif brushType == 'Spherical' then
            voxelsInBrush = VoxelLib.GetVoxelsInSphere(currentPos, currentBrush.Size.X/2)
        end

        local chunks_to_update = {}

        for _, voxel in pairs(voxelsInBrush) do

            local chunk = voxel[1]
            local index = voxel[2]

            if VoxelLib.GetMaterial(chunk.Voxels[index]) ~= effectiveMat then
                chunk.Voxels[index] = VoxelLib.GetUpdatedID(chunk.Voxels[index], false, effectiveMat)
                if not table.find(chunks_to_update, chunk) then
                    table.insert(chunks_to_update, chunk)
                end
                Replicator.LogUpdate(chunk, index, chunk.Voxels[index])
            end
        end

        for _, chunk in pairs(chunks_to_update) do
            chunk:Update()
        end
        task.wait(0.1)
    until not MouseButton1Held
end

--Viewport Interface update function
function updateViewportInterface()
    local material_indicator : ImageLabel = VPInterface['Material Indicator']
    local textureID : string
    if currentMat ~= 0 then
        for _, material in ipairs(material_info) do
            if currentMat == material['Code'] then
                textureID = material['Textures']['Front'].Texture
            end
        end
        material_indicator.ImageTransparency = 0
        material_indicator.Image = textureID
    else
        material_indicator.ImageTransparency = 1
        material_indicator.Image = ''
    end

		
end

--Encodes the update_log to allow for saving by the Data Manager. [Incomplete. Need custom RLE]
function encodeUpdates(update_log): string

    local function deepCopy(t: {})
        local copy = {}
        for k, v in pairs(t) do
            if type(v) == 'table' then
                v = deepCopy(v)
            end
            copy[k] = v
        end
        return copy
    end

    local function tableEquals(t1, t2)
        for k, v in ipairs(t1) do
            if t2[k] ~= v then
                return false
            end
        end
        return true
    end

    local deepCopiedUpdateLog = deepCopy(update_log)

    local chunk_size = Configuration.GetChunkSize()
	local vert_chunk_size = Configuration.GetVertChunkSize()

	local encoded_update_log = {}

	for pos, chunk in pairs(deepCopiedUpdateLog) do
        local curr_update_log_index = pos.X .. "," .. pos.Y .. "," .. pos.Z
		encoded_update_log[curr_update_log_index] = {}
		local curr_encoded_part = encoded_update_log[curr_update_log_index]
		local current = 0
		local next_index = 0
		local runLength = 1

		for i = 1, chunk_size^2 * vert_chunk_size + 1  do
			current = chunk[i] or VoxelLib.new()
			next_index = chunk[i+1] or VoxelLib.new()

			if tableEquals(next_index, current) then
				runLength += 1
				continue
			else
				if runLength > 1 then
					curr_encoded_part[#curr_encoded_part + 1] = {runLength, current}
				else
					curr_encoded_part[#curr_encoded_part + 1] = current
				end

				runLength = 1
			end
		end

        encoded_update_log[curr_update_log_index] = curr_encoded_part
	end

    for _, chunk in pairs(encoded_update_log) do
        for _, element in pairs(chunk) do
            if #element == 2 then
                element[2][5] = (element[2][5] :: EnumItem).Name :: string
                element[2][6] = (element[2][6] :: Color3):ToHex() :: string
            else
                element[5] = (element[5] :: EnumItem).Name :: string
                element[6] = (element[6] :: Color3):ToHex() :: string
            end
        end
    end

	local encoded_string = HttpService:JSONEncode(encoded_update_log)
    local compressed_string = StringCompression.Compress(encoded_string)
	return compressed_string
end

function decodeUpdates(encoded_string: string) : {}
	local decoded_log = {}

    local decompressed_string = StringCompression.Decompress(encoded_string)
	local encoded_log = HttpService:JSONDecode(decompressed_string)
    
	for index, encoded_log_part in encoded_log do
        local pos = Vector3.new(unpack(string.split(index, ",")))

		decoded_log[pos] = {}
		local decoded_log_part = decoded_log[pos]

		for _,v in encoded_log_part do
			if #v == 2 then
                local voxelID = VoxelLib.new(v[2][2], v[2][3], v[2][4], Enum.Material[v[2][5]], Color3.fromHex(v[2][6]))
				for _ = 1, v[1]+1 do
					decoded_log_part[#decoded_log_part+1] = voxelID
				end
			else
                local voxelID = VoxelLib.new(v[2], v[3], v[4], Enum.Material[v[5]], Color3.fromHex(v[6]))
				decoded_log_part[#decoded_log_part+1] = voxelID
			end
		end

	end

	return decoded_log
end

function saveWorld()
    local update_log: {} = Replicator.GetUpdateLog()
    local encoded_log: string = encodeUpdates(update_log)

    local stringVal = Instance.new("StringValue")
    stringVal.Value = encoded_log
    stringVal.Name = "Saved World ID"
    stringVal.Parent = workspace
end

function loadWorld()
    local encoded_log: string = WorldID_input:GetValue()
    local decoded_update_log: {} = decodeUpdates(encoded_log)

    Replicator.SetUpdateLog(decoded_update_log)

    for chunkPos, _ in Replicator.GetUpdateLog() do
        local chunk = ChunkClass.GetChunkFromPos(chunkPos) or ChunkClass.Load({chunkPos})[1]
        chunk:Update()
    end
end

-- saveButton.MouseButton1Down:Connect(saveWorld)
-- loadButton.MouseButton1Down:Connect(loadWorld)

--Toolbar button onclick connection
button.Click:Connect(function()
    if not isBuilding then
        plugin:Activate(true)
        DockWidget.Enabled = true

        --viewport interface setup
        init_starterGui_state = game:GetService('StarterGui').ShowDevelopmentGui
        game:GetService('StarterGui').ShowDevelopmentGui = false
        VPInterface.Parent = game:GetService('CoreGui')

        --getting saved settings
        uniformBrushScaling = plugin:GetSetting('uniformBrushScaling') or true
        lock_y_coord = plugin:GetSetting('lock_y') or false
        currentMat = plugin:GetSetting('currentMat') or 1
        current_size_x = plugin:GetSetting('current_x') or min_size_x
        current_size_z = plugin:GetSetting('current_z') or min_size_z

        lock_y_coord_checkbox:SetValue(lock_y_coord)
        uniformBrushScaling_checkbox:SetValue(uniformBrushScaling)

        updateViewportInterface()
        Replicator.Initialise()

        isBuilding = true
        build()

        clickConn = mouse.Button1Down:Connect(onMouseClick)
        clickConn2 = mouse.Button1Up:Connect(function()
            MouseButton1Held = false
            locked_y_coord = nil
        end)

        inputConn = UIS.InputBegan:Connect(function(input)

            if input.KeyCode == Enum.KeyCode.Z then
                currentMat -= 1
                isErasing = false
            elseif input.KeyCode == Enum.KeyCode.X then
                currentMat += 1
                isErasing = false
            elseif input.KeyCode == Enum.KeyCode.C then
                if currentMat ~= 0 then
                    isErasing = not isErasing
                else
                    return
                end
            end

            if uniformBrushScaling then
                if input.KeyCode == Enum.KeyCode.T then
                    current_size_x = math.min(current_size_x, current_size_z)
                    current_size_x += 1
                    current_size_z = current_size_x
                elseif input.KeyCode == Enum.KeyCode.G then
                    current_size_x = math.min(current_size_x, current_size_z)
                    current_size_x -= 1
                    current_size_z = current_size_x
                end

            elseif input.KeyCode == Enum.KeyCode.T then
                current_size_x += 1
            elseif input.KeyCode == Enum.KeyCode.G then
                current_size_x -= 1
            elseif input.KeyCode == Enum.KeyCode.Y then
                current_size_z += 1
            elseif input.KeyCode == Enum.KeyCode.H then
                current_size_z -= 1
            end

            if input.KeyCode == Enum.KeyCode.B then
                if brushType == 'Cuboidal' then
                    brushType = 'Spherical'
                else
                    brushType = 'Cuboidal'
                end
            end

            currentMat = math.clamp(currentMat, 0, #material_info - 1)
            current_size_x = math.clamp(current_size_x, min_size_x, max_size_x)
            current_size_z = math.clamp(current_size_z, min_size_z, max_size_z)
            if currentMat == 0 then
                isErasing = false
            end

            currentBrush = updateBrush(currentPos)
            updateViewportInterface()
        end)

    else
        plugin:Deactivate()
    end
end)

--plugin cleanup
plugin.Deactivation:Connect(function()
    MouseButton1Held = false
    locked_y_coord = nil
    isBuilding = false
    isErasing = false
    currentPos = Vector3.new()

    game:GetService('StarterGui').ShowDevelopmentGui = init_starterGui_state
    VPInterface.Parent = script.Parent

    PoolService.FlushPools()

    Replicator.RenderedChunkList = {}
    Replicator.LoadedChunkList = {}
    Replicator.VoxelSeaBuilderPluginObjectsFolder:Destroy()
    Replicator.VoxelSeaBuilderPluginObjectsFolder = nil
    Replicator.SetUpdateLog({})

    if currentBrush then currentBrush:Destroy() end
    if clickConn then  clickConn:Disconnect() end
    if clickConn2 then clickConn2:Disconnect() end
    if inputConn then inputConn:Disconnect() end
    game:GetService('RunService'):UnbindFromRenderStep('build')

    --saving settings!
    plugin:SetSetting('lock_y', lock_y_coord)
    plugin:SetSetting('uniformBrushScaling', uniformBrushScaling)
    plugin:SetSetting('currentMat', currentMat)
    plugin:SetSetting('current_x', current_size_x)
    plugin:SetSetting('current_z', current_size_z)
end)
