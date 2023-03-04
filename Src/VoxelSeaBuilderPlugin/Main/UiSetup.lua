local voxaria_Viewport_Interface = Instance.new("ScreenGui")
voxaria_Viewport_Interface.Name = "Voxaria Viewport Interface"

local material_Indicator = Instance.new("ImageLabel")
material_Indicator.Name = "Material Indicator"
material_Indicator.Image = "rbxassetid://6716441162"
material_Indicator.AnchorPoint = Vector2.new(0, 1)
material_Indicator.BackgroundColor3 = Color3.new(1, 1, 1)
material_Indicator.BackgroundTransparency = 1
material_Indicator.Position = UDim2.new(0, 15, 1, -15)
material_Indicator.Size = UDim2.fromScale(0.15, 0.15)
material_Indicator.SizeConstraint = Enum.SizeConstraint.RelativeYY

local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0.075, 0)
uICorner.Parent = material_Indicator

local textLabel = Instance.new("TextLabel")
textLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textLabel.Text = "X"
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextScaled = true
textLabel.TextSize = 14
textLabel.TextStrokeTransparency = 0
textLabel.TextWrapped = true
textLabel.AnchorPoint = Vector2.new(0, 0.5)
textLabel.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel.BackgroundTransparency = 1
textLabel.Position = UDim2.fromScale(1, 0.5)
textLabel.Size = UDim2.fromScale(0.2, 0.2)
textLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
textLabel.Parent = material_Indicator

local textLabel1 = Instance.new("TextLabel")
textLabel1.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textLabel1.Text = "Z"
textLabel1.TextColor3 = Color3.new(1, 1, 1)
textLabel1.TextScaled = true
textLabel1.TextSize = 14
textLabel1.TextStrokeTransparency = 0
textLabel1.TextWrapped = true
textLabel1.AnchorPoint = Vector2.new(0, 0.5)
textLabel1.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel1.BackgroundTransparency = 1
textLabel1.Position = UDim2.fromScale(-0.2, 0.5)
textLabel1.Size = UDim2.fromScale(0.2, 0.2)
textLabel1.SizeConstraint = Enum.SizeConstraint.RelativeYY
textLabel1.Parent = material_Indicator

local textLabel2 = Instance.new("TextLabel")
textLabel2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textLabel2.Text = "Erase: C"
textLabel2.TextColor3 = Color3.new(1, 1, 1)
textLabel2.TextScaled = true
textLabel2.TextSize = 14
textLabel2.TextStrokeTransparency = 0
textLabel2.TextWrapped = true
textLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
textLabel2.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel2.BackgroundTransparency = 1
textLabel2.Position = UDim2.fromScale(0.5, -0.15)
textLabel2.Size = UDim2.fromScale(0.7, 0.2)
textLabel2.SizeConstraint = Enum.SizeConstraint.RelativeYY
textLabel2.Parent = material_Indicator

material_Indicator.Parent = voxaria_Viewport_Interface

local sizeIncrement = Instance.new("ImageButton")
sizeIncrement.Name = "SizeIncrement"
sizeIncrement.Image = "rbxassetid://12683193093"
sizeIncrement.AnchorPoint = Vector2.new(0, 0.5)
sizeIncrement.BackgroundColor3 = Color3.new(1, 1, 1)
sizeIncrement.BackgroundTransparency = 0.8
sizeIncrement.Position = UDim2.fromScale(0, 0.5)
sizeIncrement.Size = UDim2.fromScale(0.05, 0.05)
sizeIncrement.SizeConstraint = Enum.SizeConstraint.RelativeYY

local uICorner1 = Instance.new("UICorner")
uICorner1.CornerRadius = UDim.new(0.2, 0)
uICorner1.Parent = sizeIncrement

local textLabel3 = Instance.new("TextLabel")
textLabel3.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textLabel3.Text = "T"
textLabel3.TextColor3 = Color3.new(1, 1, 1)
textLabel3.TextScaled = true
textLabel3.TextSize = 14
textLabel3.TextStrokeTransparency = 0
textLabel3.TextWrapped = true
textLabel3.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel3.BackgroundTransparency = 1
textLabel3.Position = UDim2.fromScale(0.9, -0.2)
textLabel3.Size = UDim2.fromScale(0.5, 0.5)
textLabel3.SizeConstraint = Enum.SizeConstraint.RelativeYY
textLabel3.Parent = sizeIncrement

sizeIncrement.Parent = voxaria_Viewport_Interface

local sizeDecrement = Instance.new("ImageButton")
sizeDecrement.Name = "SizeDecrement"
sizeDecrement.Image = "rbxassetid://12683193943"
sizeDecrement.AnchorPoint = Vector2.new(0, 0.5)
sizeDecrement.BackgroundColor3 = Color3.new(1, 1, 1)
sizeDecrement.BackgroundTransparency = 0.8
sizeDecrement.Position = UDim2.fromScale(0, 0.56)
sizeDecrement.Size = UDim2.fromScale(0.05, 0.05)
sizeDecrement.SizeConstraint = Enum.SizeConstraint.RelativeYY

local uICorner2 = Instance.new("UICorner")
uICorner2.CornerRadius = UDim.new(0.2, 0)
uICorner2.Parent = sizeDecrement

local textLabel4 = Instance.new("TextLabel")
textLabel4.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textLabel4.Text = "G"
textLabel4.TextColor3 = Color3.new(1, 1, 1)
textLabel4.TextScaled = true
textLabel4.TextSize = 14
textLabel4.TextStrokeTransparency = 0
textLabel4.TextWrapped = true
textLabel4.BackgroundColor3 = Color3.new(1, 1, 1)
textLabel4.BackgroundTransparency = 1
textLabel4.Position = UDim2.fromScale(0.9, -0.2)
textLabel4.Size = UDim2.fromScale(0.5, 0.5)
textLabel4.SizeConstraint = Enum.SizeConstraint.RelativeYY
textLabel4.Parent = sizeDecrement

sizeDecrement.Parent = voxaria_Viewport_Interface

return voxaria_Viewport_Interface