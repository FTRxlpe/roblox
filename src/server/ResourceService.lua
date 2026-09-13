-- Owns the two player currencies (Resources, Materials), exposed through
-- leaderstats so they show up in the standard Roblox scoreboard.

local Players = game:GetService("Players")

local ResourceService = {}

local function onPlayerAdded(player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local resources = Instance.new("IntValue")
	resources.Name = "Resources"
	resources.Value = 0
	resources.Parent = leaderstats

	local materials = Instance.new("IntValue")
	materials.Name = "Materials"
	materials.Value = 0
	materials.Parent = leaderstats
end

function ResourceService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

local function getStat(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(statName)
end

function ResourceService.GetResources(player)
	local stat = getStat(player, "Resources")
	return stat and stat.Value or 0
end

function ResourceService.GetMaterials(player)
	local stat = getStat(player, "Materials")
	return stat and stat.Value or 0
end

function ResourceService.AddResources(player, amount)
	local stat = getStat(player, "Resources")
	if stat then
		stat.Value = math.max(0, stat.Value + amount)
	end
end

function ResourceService.AddMaterials(player, amount)
	local stat = getStat(player, "Materials")
	if stat then
		stat.Value = math.max(0, stat.Value + amount)
	end
end

function ResourceService.RemoveResources(player, amount)
	ResourceService.AddResources(player, -amount)
end

function ResourceService.RemoveMaterials(player, amount)
	ResourceService.AddMaterials(player, -amount)
end

-- Spends `amount` resources if the player can afford it. Returns false and
-- charges nothing otherwise; callers must treat this as the source of truth
-- and never trust a client-reported balance.
function ResourceService.TrySpendResources(player, amount)
	local stat = getStat(player, "Resources")
	if not stat or stat.Value < amount then
		return false
	end
	stat.Value = stat.Value - amount
	return true
end

return ResourceService
