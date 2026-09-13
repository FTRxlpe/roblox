-- Small always-visible HUD mirroring the player's Resources/Materials
-- leaderstats values.

local Players = game:GetService("Players")

local ResourceHUD = {}

local player = Players.LocalPlayer

local function createLabel(parent, position, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 220, 0, 30)
	label.Position = position
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = parent
	return label
end

local function bindStat(label, statValue, prefix)
	label.Text = prefix .. statValue.Value
	statValue:GetPropertyChangedSignal("Value"):Connect(function()
		label.Text = prefix .. statValue.Value
	end)
end

function ResourceHUD.Init()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ResourceHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 220, 0, 70)
	container.Position = UDim2.new(0, 20, 0, 20)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local resourcesLabel = createLabel(container, UDim2.new(0, 0, 0, 0), "Resources: 0")
	local materialsLabel = createLabel(container, UDim2.new(0, 0, 0, 36), "Materials: 0")

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats")
		bindStat(resourcesLabel, leaderstats:WaitForChild("Resources"), "Resources: ")
		bindStat(materialsLabel, leaderstats:WaitForChild("Materials"), "Materials: ")
	end)
end

return ResourceHUD
