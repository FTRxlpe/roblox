-- Server entry point: creates the shared RemoteEvents first (services
-- below require them to already exist), then boots every gameplay system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
Remotes.Setup()

local ResourceService = require(script.Parent:WaitForChild("ResourceService"))
local PvPService = require(script.Parent:WaitForChild("PvPService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))
local ShipService = require(script.Parent:WaitForChild("ShipService"))
local WaveService = require(script.Parent:WaitForChild("WaveService"))
local EggService = require(script.Parent:WaitForChild("EggService"))

ResourceService.Init()
PvPService.Init()
ShopService.Init()
ShipService.Init()
WaveService.Init()
EggService.Init()

print("Mars Escape: server systems initialized.")
