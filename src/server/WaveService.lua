-- Periodically spawns waves of aliens at named spawn points in the
-- Workspace. Wave size and alien health are re-rolled independently every
-- time (see Config.Waves) so difficulty stays unpredictable instead of
-- ramping up, keeping the game approachable for players who join late.

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local AlienAI = require(script.Parent:WaitForChild("AlienAI"))

local WaveService = {}

local function getAlienSpawnPoints()
	local pattern = "^" .. Config.Waves.SpawnNamePattern .. "%d+$"
	local spawnPoints = {}

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("BasePart") and string.match(child.Name, pattern) then
			table.insert(spawnPoints, child)
		end
	end

	return spawnPoints
end

local function spawnAlien(spawnPoint)
	local template = ServerStorage:FindFirstChild("AlienNPC")
	if not template then
		warn("WaveService: 'AlienNPC' model not found in ServerStorage")
		return
	end

	local alien = template:Clone()
	local humanoid = alien:FindFirstChildOfClass("Humanoid")
	local rootPart = alien:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		warn("WaveService: AlienNPC model must contain a Humanoid and HumanoidRootPart")
		alien:Destroy()
		return
	end

	local health = math.random(Config.Waves.MinAlienHealth, Config.Waves.MaxAlienHealth)
	humanoid.MaxHealth = health
	humanoid.Health = health

	alien.Parent = Workspace
	rootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)

	local killReward = math.random(Config.Resources.MinPerAlienKill, Config.Resources.MaxPerAlienKill)
	AlienAI.Setup(alien, killReward)
end

local function spawnWave()
	local spawnPoints = getAlienSpawnPoints()
	if #spawnPoints == 0 then
		warn("WaveService: no parts matching '" .. Config.Waves.SpawnNamePattern .. "N' found in Workspace")
		return
	end

	local waveSize = math.random(Config.Waves.MinAliensPerWave, Config.Waves.MaxAliensPerWave)
	for _ = 1, waveSize do
		spawnAlien(spawnPoints[math.random(1, #spawnPoints)])
	end
end

function WaveService.Init()
	task.spawn(function()
		while true do
			task.wait(Config.Waves.IntervalSeconds)
			spawnWave()
		end
	end)
end

return WaveService
