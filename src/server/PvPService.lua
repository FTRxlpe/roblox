-- When a player is killed by another player (per the creator tag), drops a
-- percentage of their Resources on the ground as loot anyone can pick up.
-- Deaths to aliens or the environment never drop loot.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local CreatorTag = require(ReplicatedStorage:WaitForChild("CreatorTag"))
local ResourceService = require(script.Parent:WaitForChild("ResourceService"))

local PvPService = {}

local function dropLoot(position, amount)
	if amount <= 0 then
		return
	end

	local loot = Instance.new("Part")
	loot.Name = "ResourceLoot"
	loot.Shape = Enum.PartType.Ball
	loot.Size = Vector3.new(1.5, 1.5, 1.5)
	loot.Material = Enum.Material.Neon
	loot.Color = Color3.fromRGB(255, 200, 60)
	loot.CanCollide = false
	loot.Position = position
	loot.Parent = Workspace

	local amountValue = Instance.new("IntValue")
	amountValue.Name = "Amount"
	amountValue.Value = amount
	amountValue.Parent = loot

	local collected = false
	local connection
	connection = loot.Touched:Connect(function(otherPart)
		if collected then
			return
		end

		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		collected = true
		connection:Disconnect()
		ResourceService.AddResources(player, amountValue.Value)
		loot:Destroy()
	end)

	Debris:AddItem(loot, Config.PvP.LootDespawnSeconds)
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		local killer = CreatorTag.GetCreator(humanoid)
		if not (killer and killer:IsA("Player")) or killer == player then
			return -- not a PvP death (alien, environment, or self)
		end

		local lootAmount = math.floor(ResourceService.GetResources(player) * Config.PvP.ResourceLossPercent)
		if lootAmount <= 0 then
			return
		end

		ResourceService.RemoveResources(player, lootAmount)

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		dropLoot(rootPart and rootPart.Position or Vector3.new(0, 5, 0), lootAmount)
	end)
end

function PvPService.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end)
end

return PvPService
