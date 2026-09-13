-- Detects clicks while a shop-bought weapon Tool is equipped, raycasts from
-- the mouse to find a target humanoid, and reports the attempt to the
-- server (which re-validates everything before applying damage).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local WeaponController = {}

local player = Players.LocalPlayer

local weaponRangeByToolName = {}
for _, item in ipairs(Config.Shop.Items) do
	if item.Type == "Weapon" then
		weaponRangeByToolName[item.ToolName] = item.Range
	end
end

local function getMouseTargetHumanoid(range)
	local character = player.Character
	local camera = Workspace.CurrentCamera
	local mouse = player:GetMouse()
	if not character or not camera then
		return nil
	end

	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * range, raycastParams)
	if not result or not result.Instance then
		return nil
	end

	local hitCharacter = result.Instance.Parent
	local humanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end

	return nil
end

local function onToolEquipped(remotes, tool)
	local range = weaponRangeByToolName[tool.Name]
	if not range then
		return
	end

	tool.Activated:Connect(function()
		local targetHumanoid = getMouseTargetHumanoid(range)
		remotes.WeaponFire:FireServer(tool.Name, targetHumanoid)
	end)
end

local function onCharacterAdded(remotes, character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onToolEquipped(remotes, child)
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			onToolEquipped(remotes, child)
		end
	end
end

function WeaponController.Init()
	local remotes = Remotes.Get()

	if player.Character then
		onCharacterAdded(remotes, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(remotes, character)
	end)
end

return WeaponController
