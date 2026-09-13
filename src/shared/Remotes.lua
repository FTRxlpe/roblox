-- Declares every RemoteEvent used for client/server communication and
-- provides helpers to create them (server) or wait for them (client/server).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAMES = {
	"ShopPurchaseRequest", -- client -> server: itemId
	"ShopPurchaseResult", -- server -> client: { success, itemId, message }
	"ShipProgressUpdated", -- server -> client: { current, required }
	"ShipVictory", -- server -> client: no payload
	"WeaponFire", -- client -> server: toolName, targetHumanoid (or nil on a miss)
}

local Remotes = {}

-- Must be called once, from the server, before any other script waits on
-- these remotes (Main.server.lua does this first thing on startup).
function Remotes.Setup()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	local remotes = {}
	for _, name in ipairs(REMOTE_NAMES) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		remotes[name] = remote
	end

	return remotes
end

-- Safe to call from server modules (after Remotes.Setup has run) or from
-- any client script; yields until the remotes have replicated.
function Remotes.Get()
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remotes = {}
	for _, name in ipairs(REMOTE_NAMES) do
		remotes[name] = folder:WaitForChild(name)
	end
	return remotes
end

return Remotes
