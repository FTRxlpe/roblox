-- Minimal hostile behaviour for a spawned alien: chase the nearest player,
-- deal touch damage, and reward whoever's creator-tagged on it when it dies.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local CreatorTag = require(ReplicatedStorage:WaitForChild("CreatorTag"))
local ResourceService = require(script.Parent:WaitForChild("ResourceService"))

local AlienAI = {}

local function getNearestPlayerRootPart(fromPosition)
	local nearestRoot, nearestDistance = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart and humanoid.Health > 0 then
			local distance = (rootPart.Position - fromPosition).Magnitude
			if distance < nearestDistance then
				nearestRoot = rootPart
				nearestDistance = distance
			end
		end
	end

	return nearestRoot
end

local function startChaseLoop(alien, humanoid, rootPart)
	task.spawn(function()
		while alien.Parent and humanoid.Health > 0 do
			local targetRoot = getNearestPlayerRootPart(rootPart.Position)
			if targetRoot then
				humanoid:MoveTo(targetRoot.Position)
			end
			task.wait(1)
		end
	end)
end

local function startTouchDamage(alien, humanoid, rootPart)
	local damage = math.random(Config.Waves.MinAlienDamage, Config.Waves.MaxAlienDamage)
	local hitCooldownSeconds = 1
	local lastHitAt = {}

	rootPart.Touched:Connect(function(otherPart)
		local character = otherPart.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local targetHumanoid = character:FindFirstChildOfClass("Humanoid")
		if not targetHumanoid or targetHumanoid.Health <= 0 then
			return
		end

		local now = os.clock()
		if lastHitAt[player] and now - lastHitAt[player] < hitCooldownSeconds then
			return
		end
		lastHitAt[player] = now

		targetHumanoid:TakeDamage(damage)
	end)
end

-- `killReward` is how many Resources are granted to the creator-tagged
-- player when this alien dies.
function AlienAI.Setup(alien, killReward)
	local humanoid = alien:FindFirstChildOfClass("Humanoid")
	local rootPart = alien:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		warn("AlienAI: alien model is missing a Humanoid or HumanoidRootPart")
		return
	end

	humanoid.WalkSpeed = Config.Waves.AlienWalkSpeed

	startChaseLoop(alien, humanoid, rootPart)
	startTouchDamage(alien, humanoid, rootPart)

	humanoid.Died:Connect(function()
		local killer = CreatorTag.GetCreator(humanoid)
		if killer and killer:IsA("Player") then
			ResourceService.AddResources(killer, killReward)
		end

		task.wait(3) -- let death animation/ragdoll play before cleanup
		alien:Destroy()
	end)
end

return AlienAI
