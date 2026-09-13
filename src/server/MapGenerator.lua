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
local GROUND_SIZE = Vector3.new(800, 120, 800) -- thick enough that deep craters never punch through
local GROUND_COLOR = Color3.fromRGB(150, 70, 40)
local ARENA_RADIUS = 320
local BOULDER_COUNT = 70
local CRATER_COUNT = 22
local LAVA_CRATER_FRACTION = 1 -- every crater gets a glowing lava pool at its bottom
local MOUNTAIN_COUNT = 20
local ALIEN_SPAWN_COUNT = 8
local EGG_SPAWN_COUNT = 8
local TORCH_COUNT = 16
local EARTH_POSITION = Vector3.new(1600, 950, -2200) -- within FogEnd so it stays visible
local EARTH_SIZE = 600

-- Dark, thin-atmosphere Mars night sky: a visible starfield (via the Sky
-- object's own procedural stars, no texture assets needed) with a distant
-- blue "Earth" sphere, while keeping the ground lit enough to play by.
local function setupAtmosphere()
	Lighting.ClockTime = 1
	Lighting.Ambient = Color3.fromRGB(55, 45, 45)
	Lighting.OutdoorAmbient = Color3.fromRGB(75, 55, 55)
	Lighting.Brightness = 2
	Lighting.ColorShift_Top = Color3.fromRGB(120, 75, 65)
	Lighting.ColorShift_Bottom = Color3.fromRGB(90, 55, 45)
	Lighting.FogColor = Color3.fromRGB(55, 40, 40)
	Lighting.FogStart = 150
	Lighting.FogEnd = 6000 -- far enough that the distant Earth sphere isn't fogged out

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "MarsSky"
		sky.Parent = Lighting
	end
	sky.CelestialBodiesShown = true
	sky.StarCount = 6000
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
-- carved just outside the playable arena as a horizon backdrop, and a
-- scatter of craters within it. Returns the Y coordinate of the flat top
-- surface everything else is placed on, plus the list of craters generated
-- (so a lava pool can be dropped into some of their bottoms afterward).
local function createTerrainGround()
	local terrain = Workspace.Terrain
	-- Terrain lives outside the MarsMap folder, so deleting that folder to
	-- force a regeneration would otherwise leave old ground/mountains behind
	-- and stack a new set on top of them.
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Ground, GROUND_COLOR)
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(110, 55, 35))

	terrain:FillBlock(CFrame.new(0, -GROUND_SIZE.Y / 2, 0), GROUND_SIZE, Enum.Material.Ground)

	local craters = {}
	for _ = 1, CRATER_COUNT do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * ARENA_RADIUS * 0.9
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local radius = math.random(16, 36)
		local depth = radius * 0.65

		terrain:FillBall(Vector3.new(x, -depth, z), radius, Enum.Material.Air)
		table.insert(craters, { x = x, z = z, radius = radius, depth = depth })
	end

	for i = 1, MOUNTAIN_COUNT do
		local angle = (i - 1) / MOUNTAIN_COUNT * math.pi * 2 + math.random() * 0.2
		local distance = ARENA_RADIUS + 20 + math.random(0, 20)
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local radius = math.random(35, 60)

		terrain:FillBall(Vector3.new(x, radius * 0.6, z), radius, Enum.Material.Rock)
	end

	return 0, craters
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

-- A distant sphere standing in for a celestial body. No texture asset, just
-- a colored Part far enough away (but within FogEnd) that it reads as a
-- background object rather than getting fogged out.
local function createSkyBody(folder, name, position, size, color)
	local body = Instance.new("Part")
	body.Name = name
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(size, size, size)
	body.Position = position
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.Material = Enum.Material.Neon -- self-lit, so it stays visible against the dark night sky
	body.Color = color
	body.Parent = folder
end

-- Approximates what's actually visible from Mars: Earth (as a small blue
-- "star"), its own moons Phobos and Deimos (much closer, so they look
-- bigger and move faster across the sky), and Jupiter as a bright dot.
local function createSkyBodies(folder)
	createSkyBody(folder, "EarthInSky", EARTH_POSITION, EARTH_SIZE, Color3.fromRGB(60, 140, 170))
	createSkyBody(folder, "Phobos", Vector3.new(500, 350, -650), 40, Color3.fromRGB(210, 205, 195))
	createSkyBody(folder, "Deimos", Vector3.new(-700, 300, -500), 22, Color3.fromRGB(220, 215, 205))
	createSkyBody(folder, "Jupiter", Vector3.new(-2200, 1300, 2600), 900, Color3.fromRGB(230, 190, 140))
end

-- Drops a glowing lava pool into a subset of the given craters, each with
-- its own light so it actually illuminates the surrounding dark scene.
local function scatterLavaPools(folder, craters, groundTopY)
	for _, crater in ipairs(craters) do
		if math.random() <= LAVA_CRATER_FRACTION then
			local poolRadius = crater.radius * 0.7

			local lava = Instance.new("Part")
			lava.Name = "LavaPool"
			lava.Shape = Enum.PartType.Cylinder
			lava.Size = Vector3.new(1, poolRadius * 2, poolRadius * 2)
			local bottomY = groundTopY - (crater.depth + crater.radius) + 0.5
			lava.CFrame = CFrame.new(crater.x, bottomY, crater.z) * CFrame.Angles(0, 0, math.rad(90))
			lava.Anchored = true
			lava.CanCollide = false
			lava.Material = Enum.Material.Neon
			lava.Color = Color3.fromRGB(255, 90, 20)
			lava.Parent = folder

			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 120, 40)
			light.Range = poolRadius * 4
			light.Brightness = 3
			light.Parent = lava
		end
	end
end

-- A simple sci-fi beacon: a dark pole topped with a glowing orb that also
-- casts real light, scattered around the arena so the dark night sky
-- doesn't leave the ground unreadable.
local function scatterTorches(folder, groundTopY, arenaRadius, count)
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2 + math.pi / count
		local distance = arenaRadius * (0.35 + math.random() * 0.5)
		local x = math.cos(angle) * distance
		local z = math.sin(angle) * distance
		local poleHeight = 8

		local pole = Instance.new("Part")
		pole.Name = "Torch"
		pole.Size = Vector3.new(1, poleHeight, 1)
		pole.Position = Vector3.new(x, groundTopY + poleHeight / 2, z)
		pole.Anchored = true
		pole.CanCollide = true
		pole.Material = Enum.Material.Metal
		pole.Color = Color3.fromRGB(60, 60, 65)
		pole.Parent = folder

		local orb = Instance.new("Part")
		orb.Name = "TorchLight"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1.6, 1.6, 1.6)
		orb.Position = pole.Position + Vector3.new(0, poleHeight / 2 + 0.5, 0)
		orb.Anchored = true
		orb.CanCollide = false
		orb.Material = Enum.Material.Neon
		orb.Color = Color3.fromRGB(90, 220, 255)
		orb.Parent = folder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(120, 220, 255)
		light.Range = 30
		light.Brightness = 2.5
		light.Parent = orb
	end
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

	local groundTopY, craters = createTerrainGround()

	scatterBoulders(folder, groundTopY, ARENA_RADIUS, BOULDER_COUNT)
	scatterLavaPools(folder, craters, groundTopY)
	scatterTorches(folder, groundTopY, ARENA_RADIUS, TORCH_COUNT)
	createSpawnRing(folder, Config.Waves.SpawnNamePattern, ALIEN_SPAWN_COUNT, ARENA_RADIUS * 0.75, groundTopY, Color3.fromRGB(255, 70, 70))
	createSpawnRing(folder, Config.Eggs.SpawnNamePattern, EGG_SPAWN_COUNT, ARENA_RADIUS * 0.4, groundTopY, Color3.fromRGB(120, 230, 140))
	createShipBuildZone(folder, groundTopY)
	createEarthTeleport(folder, groundTopY, ARENA_RADIUS)
	createSpawnLocation(folder, groundTopY)
	createSkyBodies(folder)

	print("MapGenerator: base Mars map generated in Workspace." .. MAP_FOLDER_NAME .. ". Save the place to keep it, then decorate freely in Studio.")
end

return MapGenerator
