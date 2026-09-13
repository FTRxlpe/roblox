-- Periodically spawns alien eggs at named spawn points. Each egg explodes
-- after a random fuse delay and grants Materials to every player within
-- range at the moment of explosion.

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ResourceService = require(script.Parent:WaitForChild("ResourceService"))

local EggService = {}

local activeEggCount = 0

local function getEggSpawnPoints()
	local pattern = "^" .. Config.Eggs.SpawnNamePattern .. "%d+$"
	local spawnPoints = {}

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("BasePart") and string.match(child.Name, pattern) then
			table.insert(spawnPoints, child)
		end
	end

	return spawnPoints
end

local function getEggPosition(egg)
	local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

local function explodeEgg(egg)
	activeEggCount = math.max(0, activeEggCount - 1)

	local position = getEggPosition(egg)
	if not position then
		egg:Destroy()
		return
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 0 -- visual/sound only, no physics damage or knockback
	explosion.BlastPressure = 0
	explosion.Parent = Workspace

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9125715070"
	sound.Volume = 1
	sound.Parent = Workspace
	sound.PlayOnRemove = true
	Debris:AddItem(sound, 3)

	local reward = math.random(Config.Eggs.MinMaterialsReward, Config.Eggs.MaxMaterialsReward)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart and (rootPart.Position - position).Magnitude <= Config.Eggs.ExplosionRadiusStuds then
			ResourceService.AddMaterials(player, reward)
		end
	end

	egg:Destroy()
end

local function spawnEgg(spawnPoint)
	local template = ServerStorage:FindFirstChild("AlienEgg")
	if not template then
		warn("EggService: 'AlienEgg' model not found in ServerStorage")
		return
	end

	local egg = template:Clone()
	local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		warn("EggService: AlienEgg model must contain at least one BasePart")
		egg:Destroy()
		return
	end

	egg.Parent = Workspace
	if egg.PrimaryPart then
		egg:SetPrimaryPartCFrame(spawnPoint.CFrame + Vector3.new(0, 2, 0))
	else
		part.CFrame = spawnPoint.CFrame + Vector3.new(0, 2, 0)
	end

	activeEggCount = activeEggCount + 1

	local fuseSeconds = math.random(Config.Eggs.MinFuseSeconds, Config.Eggs.MaxFuseSeconds)
	task.delay(fuseSeconds, function()
		if egg.Parent then
			explodeEgg(egg)
		else
			activeEggCount = math.max(0, activeEggCount - 1)
		end
	end)
end

function EggService.Init()
	task.spawn(function()
		while true do
			task.wait(Config.Eggs.SpawnIntervalSeconds)

			if activeEggCount < Config.Eggs.MaxActiveEggs then
				local spawnPoints = getEggSpawnPoints()
				if #spawnPoints > 0 then
					spawnEgg(spawnPoints[math.random(1, #spawnPoints)])
				else
					warn("EggService: no parts matching '" .. Config.Eggs.SpawnNamePattern .. "N' found in Workspace")
				end
			end
		end
	end)
end

return EggService
