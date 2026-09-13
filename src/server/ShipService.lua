-- Tracks the server-wide shared materials pool for the ship. Players
-- deposit their carried Materials by walking into the ShipBuildZone part;
-- once the shared total reaches the goal, everyone is teleported to Earth.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ResourceService = require(script.Parent:WaitForChild("ResourceService"))

local ShipService = {}

local totalMaterialsDeposited = 0
local victoryTriggered = false
local depositCooldownSeconds = 1
local lastDepositAt = {}

local function broadcastProgress(remotes)
	remotes.ShipProgressUpdated:FireAllClients({
		current = totalMaterialsDeposited,
		required = Config.Ship.MaterialsRequired,
	})
end

local function triggerVictory(remotes)
	if victoryTriggered then
		return
	end
	victoryTriggered = true

	remotes.ShipVictory:FireAllClients()

	local earthTeleport = Workspace:FindFirstChild(Config.Ship.EarthTeleportName)
	if not earthTeleport then
		warn(string.format("ShipService: '%s' part not found in Workspace", Config.Ship.EarthTeleportName))
		return
	end

	task.delay(Config.Ship.TakeoffSequenceSeconds, function()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.CFrame = earthTeleport.CFrame + Vector3.new(0, 3, 0)
			end
		end
	end)
end

local function depositMaterials(remotes, player)
	if victoryTriggered then
		return
	end

	local now = os.clock()
	if lastDepositAt[player] and now - lastDepositAt[player] < depositCooldownSeconds then
		return
	end
	lastDepositAt[player] = now

	local amount = ResourceService.GetMaterials(player)
	if amount <= 0 then
		return
	end

	ResourceService.RemoveMaterials(player, amount)
	totalMaterialsDeposited = totalMaterialsDeposited + amount
	broadcastProgress(remotes)

	if totalMaterialsDeposited >= Config.Ship.MaterialsRequired then
		triggerVictory(remotes)
	end
end

function ShipService.Init()
	local remotes = Remotes.Get()

	local buildZone = Workspace:FindFirstChild(Config.Ship.BuildZoneName)
	if not buildZone then
		warn(string.format("ShipService: '%s' part not found in Workspace", Config.Ship.BuildZoneName))
		return
	end

	buildZone.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			depositMaterials(remotes, player)
		end
	end)

	broadcastProgress(remotes)
end

return ShipService
