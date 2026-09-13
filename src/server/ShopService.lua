-- Handles purchase requests from the client. The server is the sole source
-- of truth for balances and item validity; the client's request only names
-- an itemId, never a price or outcome.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local ResourceService = require(script.Parent:WaitForChild("ResourceService"))

local ShopService = {}

local itemsById = {}
for _, item in ipairs(Config.Shop.Items) do
	itemsById[item.Id] = item
end

local function giveWeapon(player, item)
	local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
	local template = weaponsFolder and weaponsFolder:FindFirstChild(item.ToolName)
	if not template then
		warn(string.format("ShopService: weapon model '%s' not found in ServerStorage.Weapons", item.ToolName))
		return false
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return false
	end

	local tool = template:Clone()
	tool.Parent = backpack
	return true
end

local function giveMaterialPack(player, item)
	ResourceService.AddMaterials(player, item.MaterialsAmount)
	return true
end

local function handlePurchase(remotes, player, itemId)
	local item = itemsById[itemId]
	if not item then
		remotes.ShopPurchaseResult:FireClient(player, { success = false, itemId = itemId, message = "Unknown item." })
		return
	end

	if not ResourceService.TrySpendResources(player, item.Price) then
		remotes.ShopPurchaseResult:FireClient(player, { success = false, itemId = itemId, message = "Not enough resources." })
		return
	end

	local success
	if item.Type == "Weapon" then
		success = giveWeapon(player, item)
	elseif item.Type == "MaterialPack" then
		success = giveMaterialPack(player, item)
	else
		success = false
	end

	if not success then
		ResourceService.AddResources(player, item.Price) -- refund
		remotes.ShopPurchaseResult:FireClient(player, { success = false, itemId = itemId, message = "Purchase failed, refunded." })
		return
	end

	remotes.ShopPurchaseResult:FireClient(player, { success = true, itemId = itemId, message = item.Name .. " purchased!" })
end

function ShopService.Init()
	local remotes = Remotes.Get()
	remotes.ShopPurchaseRequest.OnServerEvent:Connect(function(player, itemId)
		if type(itemId) ~= "string" then
			return
		end
		handlePurchase(remotes, player, itemId)
	end)
end

return ShopService
