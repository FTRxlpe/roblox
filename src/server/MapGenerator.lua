-- One-shot utility that builds a basic Mars map directly in Workspace:
-- a terrain ground plate with a mountain backdrop, scattered boulders,
-- AlienSpawnN / EggSpawnN markers, ShipBuildZone and EarthTeleport pads,
-- a player SpawnLocation, and a warm Mars atmosphere/lighting setup.
--
-- This is NOT wired into Main.server.lua on purpose: run it once from the
-- Studio Command Bar while in EDIT mode (not Play), so the result gets
-- saved into the place file and you can freely decorate/move things by
-- hand afterwards:
--
--   require(game.ServerScriptService.MapGenerator).Generate()
--
-- Running it again is safe: it skips the ground/props/markers if
-- Workspace.MarsMap already exists instead of duplicating everything,
-- though the lighting/atmosphere setup is reapplied every time.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local MapGenerator = {}

local MAP_FOLDER_NAME = "MarsMap"
local GROUND_SIZE = Vector3.new(800, 16, 800)
local GROUND_COLOR = Color3.fromRGB(150, 70, 40)
local ARENA_RADIUS = 320
local BOULDER_COUNT = 70
local CRATER_COUNT = 14
local MOUNTAIN_COUNT = 20
local ALIEN_SPAWN_COUNT = 8
local EGG_SPAWN_COUNT = 8

local function setupAtmosphere()
	Lighting.Ambient = Color3.fromRGB(70, 45, 35)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 85, 65)
	Lighting.Brightness = 2
	Lighting.ColorShift_Top = Color3.fromRGB(255, 150, 100)
	Lighting.ColorShift_Bottom = Color3.fromRGB(120, 60, 40)
	Lighting.FogColor = Color3.fromRGB(190, 120, 85)
	Lighting.FogStart = 150
	Lighting.FogEnd = 1100
end

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

-- Flat terrain slab for the whole map, with a ring of rounded "mountains"
-- carved just outside the playable arena as a horizon backdrop. Returns the
-- Y coordinate of the flat top surface everything else is placed on.
local function createTerrainGround()
	local terrain = Workspace.Terrain
	-- Terrain lives outside the MarsMap folder, so deleting that folder to
	-- force a regeneration would otherwise leave old ground/mountains behind
	-- and stack a new set on top of them.
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Ground, GROUND_COLOR)
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(110, 55, 35))

	terrain:FillBlock(CFrame.new(0, -GROUND_SIZE.Y / 2, 0), GROUND_SIZE, Enum.Material.Ground)

	for _ = 1, CRATER_COUNT do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * ARENA_RADIUS * 0.9
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local radius = math.random(12, 28)

		terrain:FillBall(Vector3.new(x, -radius * 0.5, z), radius, Enum.Material.Air)
	end

	for i = 1, MOUNTAIN_COUNT do
		local angle = (i - 1) / MOUNTAIN_COUNT * math.pi * 2 + math.random() * 0.2
		local distance = ARENA_RADIUS + 20 + math.random(0, 20)
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local radius = math.random(35, 60)

		terrain:FillBall(Vector3.new(x, radius * 0.6, z), radius, Enum.Material.Rock)
	end

	return 0
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
	setupAtmosphere()

	if Workspace:FindFirstChild(MAP_FOLDER_NAME) then
		warn("MapGenerator: '" .. MAP_FOLDER_NAME .. "' already exists in Workspace, skipping ground/props. Delete it first if you want to regenerate those.")
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = MAP_FOLDER_NAME
	folder.Parent = Workspace

	local groundTopY = createTerrainGround()

	scatterBoulders(folder, groundTopY, ARENA_RADIUS, BOULDER_COUNT)
	createSpawnRing(folder, Config.Waves.SpawnNamePattern, ALIEN_SPAWN_COUNT, ARENA_RADIUS * 0.75, groundTopY, Color3.fromRGB(255, 70, 70))
	createSpawnRing(folder, Config.Eggs.SpawnNamePattern, EGG_SPAWN_COUNT, ARENA_RADIUS * 0.4, groundTopY, Color3.fromRGB(120, 230, 140))
	createShipBuildZone(folder, groundTopY)
	createEarthTeleport(folder, groundTopY, ARENA_RADIUS)
	createSpawnLocation(folder, groundTopY)

	print("MapGenerator: base Mars map generated in Workspace." .. MAP_FOLDER_NAME .. ". Save the place to keep it, then decorate freely in Studio.")
end

return MapGenerator
