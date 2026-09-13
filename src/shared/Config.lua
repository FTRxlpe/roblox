-- Centralized, tweakable game balance values.
-- Every "magic number" used by the server or client systems should live here.

local Config = {}

Config.Waves = {
	IntervalSeconds = 45, -- time between wave spawns
	MinAliensPerWave = 3,
	MaxAliensPerWave = 8,
	MinAlienHealth = 20,
	MaxAlienHealth = 45,
	MinAlienDamage = 5,
	MaxAlienDamage = 15,
	AlienWalkSpeed = 10,
	-- Wave size/health are randomized independently each wave (not scaled up
	-- over time) so difficulty stays unpredictable and late joiners aren't
	-- overwhelmed.
	SpawnNamePattern = "AlienSpawn",
}

Config.Resources = {
	MinPerAlienKill = 5,
	MaxPerAlienKill = 15,
}

Config.Eggs = {
	SpawnNamePattern = "EggSpawn",
	SpawnIntervalSeconds = 20,
	MinFuseSeconds = 5,
	MaxFuseSeconds = 20,
	ExplosionRadiusStuds = 15,
	MinMaterialsReward = 3,
	MaxMaterialsReward = 8,
	MaxActiveEggs = 6,
}

Config.PvP = {
	ResourceLossPercent = 0.3,
	LootDespawnSeconds = 30,
}

-- Baseline unarmed attack every player can use for free. Shop weapons deal
-- more damage / reach further than this, making them a genuine upgrade.
Config.Combat = {
	UnarmedDamage = 8,
	UnarmedRange = 8,
}

Config.Shop = {
	Items = {
		{ Id = "BasicBlaster", Name = "Basic Blaster", Type = "Weapon", Price = 50, ToolName = "BasicBlaster", Damage = 15, Range = 40 },
		{ Id = "PlasmaRifle", Name = "Plasma Rifle", Type = "Weapon", Price = 200, ToolName = "PlasmaRifle", Damage = 35, Range = 60 },
		{ Id = "SmallMaterialPack", Name = "Small Materials Pack", Type = "MaterialPack", Price = 30, MaterialsAmount = 20 },
		{ Id = "LargeMaterialPack", Name = "Large Materials Pack", Type = "MaterialPack", Price = 100, MaterialsAmount = 80 },
	},
}

Config.Ship = {
	MaterialsRequired = 500,
	BuildZoneName = "ShipBuildZone",
	EarthTeleportName = "EarthTeleport",
	TakeoffSequenceSeconds = 6,
}

return Config
