-- Detects attacks and reports them to the server (which re-validates
-- everything before applying damage):
--   - A left click while no weapon Tool is equipped is a free punch.
--   - Activating a shop-bought weapon Tool fires that weapon instead.
-- Both target the nearest humanoid within range of the character, rather
-- than raycasting from the camera: the camera sits well behind the
-- character in third person, so a chunk of any camera-based ray gets spent
-- just closing that gap before it could ever reach a target in front of the
-- player, and how much varies with zoom. Proximity to the character's own
-- root part works regardless of camera distance or angle.

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

local function getNearestHumanoidInRange(range)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not rootPart then
		return nil
	end

	local nearestHumanoid, nearestDistance = nil, range

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") and descendant ~= ownHumanoid and descendant.Health > 0 then
			local targetRoot = descendant.Parent and descendant.Parent:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local distance = (targetRoot.Position - rootPart.Position).Magnitude
				if distance <= nearestDistance then
					nearestHumanoid = descendant
					nearestDistance = distance
				end
			end
		end
	end

	return nearestHumanoid
end

-- Rig joints (Motor6D.C0) turned out to be unreliable to animate by script
-- in some contexts (Studio's split client/server test session refused
-- writes to it outright). A screen flash needs no rig at all, so it can't
-- fail the same way, and still gives clear feedback on every attack.
local hitFlash

local function getHitFlash()
	if hitFlash then
		return hitFlash
	end

	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HitFlash"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.ZIndex = 10
	flash.Parent = screenGui

	hitFlash = flash
	return flash
end

local function playAttackFeedback()
	local flash = getHitFlash()
	flash.BackgroundTransparency = 0.75
	TweenService:Create(flash, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
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
		local targetHumanoid = getNearestHumanoidInRange(range)
		remotes.WeaponFire:FireServer(tool.Name, targetHumanoid)
		playAttackFeedback()
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

		local targetHumanoid = getNearestHumanoidInRange(Config.Combat.UnarmedRange)
		remotes.WeaponFire:FireServer(UNARMED_TOOL_NAME, targetHumanoid)
		playAttackFeedback()
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
