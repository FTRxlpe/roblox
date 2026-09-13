-- Validates attack requests from clients and applies damage. Every player
-- can always punch for free (Config.Combat); an equipped shop weapon deals
-- more damage / reaches further, making it a genuine upgrade rather than a
-- requirement.
--
-- The client only reports which humanoid it thinks it hit; the server
-- re-checks the player actually holds that weapon (or has none, for the
-- unarmed case), isn't on cooldown, and that the target is within a
-- plausible range before trusting any of it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local CreatorTag = require(ReplicatedStorage:WaitForChild("CreatorTag"))

local WeaponService = {}

local UNARMED_TOOL_NAME = "Unarmed"

local weaponsByToolName = {}
for _, item in ipairs(Config.Shop.Items) do
	if item.Type == "Weapon" then
		weaponsByToolName[item.ToolName] = item
	end
end

local FIRE_COOLDOWN_SECONDS = 0.3
local RANGE_TOLERANCE_STUDS = 5

local lastFiredAt = {}

-- Returns the damage/range to use for this attack, or nil if the request
-- doesn't check out (unknown weapon, or claims a weapon the player doesn't
-- actually have equipped).
local function resolveAttack(player, toolName)
	if toolName == UNARMED_TOOL_NAME then
		return Config.Combat.UnarmedDamage, Config.Combat.UnarmedRange
	end

	local weapon = weaponsByToolName[toolName]
	if not weapon then
		return nil
	end

	local character = player.Character
	local tool = character and character:FindFirstChild(toolName)
	if not tool or not tool:IsA("Tool") then
		return nil -- player doesn't actually have this weapon equipped
	end

	return weapon.Damage, weapon.Range
end

local function handleFire(player, toolName, targetHumanoid)
	local damage, range = resolveAttack(player, toolName)
	if not damage then
		return
	end

	local now = os.clock()
	if lastFiredAt[player] and now - lastFiredAt[player] < FIRE_COOLDOWN_SECONDS then
		return
	end
	lastFiredAt[player] = now

	if typeof(targetHumanoid) ~= "Instance" or not targetHumanoid:IsA("Humanoid") or targetHumanoid.Health <= 0 then
		return -- a miss; nothing to damage
	end

	local character = player.Character
	local targetRoot = targetHumanoid.Parent and targetHumanoid.Parent:FindFirstChild("HumanoidRootPart")
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not playerRoot then
		return
	end

	if (targetRoot.Position - playerRoot.Position).Magnitude > range + RANGE_TOLERANCE_STUDS then
		return
	end

	CreatorTag.Tag(targetHumanoid, player)
	targetHumanoid:TakeDamage(damage)
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
