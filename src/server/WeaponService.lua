-- Validates weapon fire requests from clients and applies damage.
-- The client only reports which humanoid it thinks it hit; the server
-- re-checks the player actually holds that weapon, isn't on cooldown, and
-- that the target is within a plausible range before trusting any of it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local CreatorTag = require(ReplicatedStorage:WaitForChild("CreatorTag"))

local WeaponService = {}

local weaponsByToolName = {}
for _, item in ipairs(Config.Shop.Items) do
	if item.Type == "Weapon" then
		weaponsByToolName[item.ToolName] = item
	end
end

local FIRE_COOLDOWN_SECONDS = 0.3
local RANGE_TOLERANCE_STUDS = 5

local lastFiredAt = {}

local function handleFire(player, toolName, targetHumanoid)
	local weapon = weaponsByToolName[toolName]
	if not weapon then
		return
	end

	local character = player.Character
	local tool = character and character:FindFirstChild(toolName)
	if not tool or not tool:IsA("Tool") then
		return -- player doesn't actually have this weapon equipped
	end

	local now = os.clock()
	if lastFiredAt[player] and now - lastFiredAt[player] < FIRE_COOLDOWN_SECONDS then
		return
	end
	lastFiredAt[player] = now

	if typeof(targetHumanoid) ~= "Instance" or not targetHumanoid:IsA("Humanoid") or targetHumanoid.Health <= 0 then
		return -- a miss; nothing to damage
	end

	local targetRoot = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not playerRoot then
		return
	end

	if (targetRoot.Position - playerRoot.Position).Magnitude > weapon.Range + RANGE_TOLERANCE_STUDS then
		return
	end

	CreatorTag.Tag(targetHumanoid, player)
	targetHumanoid:TakeDamage(weapon.Damage)
end

function WeaponService.Init()
	local remotes = Remotes.Get()
	remotes.WeaponFire.OnServerEvent:Connect(function(player, toolName, targetHumanoid)
		if type(toolName) ~= "string" then
			return
		end
		handleFire(player, toolName, targetHumanoid)
	end)
end

return WeaponService
