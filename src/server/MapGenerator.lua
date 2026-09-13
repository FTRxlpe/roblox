-- One-shot utility that builds a basic Mars map directly in Workspace:
-- a ground plate, scattered boulders, AlienSpawnN / EggSpawnN markers,
-- ShipBuildZone and EarthTeleport pads, and a player SpawnLocation.
--
-- This is NOT wired into Main.server.lua on purpose: run it once from the
-- Studio Command Bar while in EDIT mode (not Play), so the result gets
-- saved into the place file and you can freely decorate/move things by
-- hand afterwards:
--
--   require(game.ServerScriptService.MapGenerator).Generate()
--
-- Running it again is safe: it skips generation if Workspace.MarsMap
-- already exists instead of duplicating everything.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local MapGenerator = {}

local MAP_FOLDER_NAME = "MarsMap"
local GROUND_SIZE = Vector3.new(400, 4, 400)
local GROUND_COLOR = Color3.fromRGB(150, 70, 40)
local ARENA_RADIUS = 160
local BOULDER_COUNT = 40
local ALIEN_SPAWN_COUNT = 6
local EGG_SPAWN_COUNT = 6

local function createMarker(folder, name, position, size, color, canCollide)
	local marker = Instance.new("Part")
	marker.Name = name
	marker.Size = size
	marker.Position = position
	marker.Anchored = true
	marker.CanCollide = canCollide
	marker.Material = Enum.Material.Neon
	marker.Color = color
	marker.Transparency = 0.35
	marker.Parent = folder
	return marker
end

local function createGround(folder)
	local ground = Instance.new("Part")
	ground.Name = "MarsGround"
	ground.Size = GROUND_SIZE
	ground.Position = Vector3.new(0, 0, 0)
	ground.Anchored = true
	ground.CanCollide = true
	ground.Material = Enum.Material.Ground
	ground.Color = GROUND_COLOR
	ground.Parent = folder
	return ground
end

local function scatterBoulders(folder, groundTopY, arenaRadius, count)
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * arenaRadius
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance

		local size = Vector3.new(math.random(3, 8), math.random(3, 8), math.random(3, 8))

		local boulder = Instance.new("Part")
		boulder.Name = "Boulder"
		boulder.Size = size
		boulder.Position = Vector3.new(x, groundTopY + size.Y / 2, z)
		boulder.Anchored = true
		boulder.CanCollide = true
		boulder.Material = Enum.Material.Rock
		boulder.Color = Color3.fromRGB(120, 60, 40)
		boulder.Parent = folder
	end
end

local function createSpawnRing(folder, namePrefix, count, radius, groundTopY, color)
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2
		local position = Vector3.new(math.cos(angle) * radius, groundTopY + 0.3, math.sin(angle) * radius)
		createMarker(folder, namePrefix .. i, position, Vector3.new(6, 0.6, 6), color, false)
	end
end

local function createShipBuildZone(folder, groundTopY)
	createMarker(folder, Config.Ship.BuildZoneName, Vector3.new(0, groundTopY + 0.3, 0), Vector3.new(20, 0.6, 20), Color3.fromRGB(90, 170, 255), true)
end

local function createEarthTeleport(folder, groundTopY, arenaRadius)
	local position = Vector3.new(arenaRadius + 60, groundTopY + 0.3, 0)
	createMarker(folder, Config.Ship.EarthTeleportName, position, Vector3.new(16, 0.6, 16), Color3.fromRGB(90, 255, 140), true)
end

local function createSpawnLocation(folder, groundTopY)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MarsSpawn"
	spawn.Size = Vector3.new(8, 0.6, 8)
	spawn.Position = Vector3.new(0, groundTopY + 0.3, -60)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(200, 200, 200)
	spawn.Parent = folder
end

function MapGenerator.Generate()
	if Workspace:FindFirstChild(MAP_FOLDER_NAME) then
		warn("MapGenerator: '" .. MAP_FOLDER_NAME .. "' already exists in Workspace, skipping. Delete it first if you really want to regenerate.")
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = MAP_FOLDER_NAME
	folder.Parent = Workspace

	local ground = createGround(folder)
	local groundTopY = ground.Position.Y + ground.Size.Y / 2

	scatterBoulders(folder, groundTopY, ARENA_RADIUS, BOULDER_COUNT)
	createSpawnRing(folder, Config.Waves.SpawnNamePattern, ALIEN_SPAWN_COUNT, ARENA_RADIUS * 0.75, groundTopY, Color3.fromRGB(255, 70, 70))
	createSpawnRing(folder, Config.Eggs.SpawnNamePattern, EGG_SPAWN_COUNT, ARENA_RADIUS * 0.4, groundTopY, Color3.fromRGB(120, 230, 140))
	createShipBuildZone(folder, groundTopY)
	createEarthTeleport(folder, groundTopY, ARENA_RADIUS)
	createSpawnLocation(folder, groundTopY)

	print("MapGenerator: base Mars map generated in Workspace." .. MAP_FOLDER_NAME .. ". Save the place to keep it, then decorate freely in Studio.")
end

return MapGenerator
