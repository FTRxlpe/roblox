-- Detects attacks and reports them to the server (which re-validates
-- everything before applying damage):
--   - A left click while no weapon Tool is equipped is a free punch.
--   - Activating a shop-bought weapon Tool fires that weapon instead.
-- Both raycast from the mouse to find a target humanoid.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local WeaponController = {}

local UNARMED_TOOL_NAME = "Unarmed"

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

-- Purely procedural swing (no Animation asset dependency, so it can't fail
-- to load): quickly rotates the shoulder joint forward and back, giving
-- visible feedback on every punch even when it doesn't land on anything.
local function getShoulderMotor(character)
	local rightUpperArm = character:FindFirstChild("RightUpperArm") -- R15
	local rightShoulderR15 = rightUpperArm and rightUpperArm:FindFirstChild("RightShoulder")
	if rightShoulderR15 then
		return rightShoulderR15
	end

	local torso = character:FindFirstChild("Torso") -- R6
	return torso and torso:FindFirstChild("Right Shoulder")
end

local activeSwings = {}

local function playPunchSwing(character)
	local motor = getShoulderMotor(character)
	if not motor or activeSwings[motor] then
		return
	end
	activeSwings[motor] = true

	local restC0 = motor.C0
	local swingC0 = restC0 * CFrame.Angles(math.rad(-100), 0, 0)

	local swingOut = TweenService:Create(motor, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { C0 = swingC0 })
	local swingBack = TweenService:Create(motor, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { C0 = restC0 })

	swingOut.Completed:Once(function()
		swingBack:Play()
	end)
	swingBack.Completed:Once(function()
		activeSwings[motor] = nil
	end)

	swingOut:Play()
end

local function hasToolEquipped()
	local character = player.Character
	return character ~= nil and character:FindFirstChildOfClass("Tool") ~= nil
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

local function initUnarmedPunch(remotes)
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if hasToolEquipped() then
			return -- an equipped weapon's own Activated handler covers this click
		end

		local character = player.Character
		if character then
			playPunchSwing(character)
		end

		local targetHumanoid = getMouseTargetHumanoid(Config.Combat.UnarmedRange)
		remotes.WeaponFire:FireServer(UNARMED_TOOL_NAME, targetHumanoid)
	end)
end

function WeaponController.Init()
	local remotes = Remotes.Get()

	if player.Character then
		onCharacterAdded(remotes, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(remotes, character)
	end)

	initUnarmedPunch(remotes)
end

return WeaponController
