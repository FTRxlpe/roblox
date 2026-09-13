-- Standard Roblox "creator tag" pattern: attach an ObjectValue named
-- "creator" to a Humanoid to remember which Player last damaged it, so kill
-- rewards and PvP detection can look up the right player when it dies.

local Debris = game:GetService("Debris")

local CREATOR_TAG_NAME = "creator"
local CREATOR_TAG_LIFETIME = 15 -- seconds; stale tags stop counting as a kill

local CreatorTag = {}

function CreatorTag.Tag(humanoid, player)
	if not humanoid or not player then
		return
	end

	local tag = humanoid:FindFirstChild(CREATOR_TAG_NAME)
	if not tag then
		tag = Instance.new("ObjectValue")
		tag.Name = CREATOR_TAG_NAME
		tag.Parent = humanoid
	end
	tag.Value = player

	Debris:AddItem(tag, CREATOR_TAG_LIFETIME)
end

function CreatorTag.GetCreator(humanoid)
	if not humanoid then
		return nil
	end

	local tag = humanoid:FindFirstChild(CREATOR_TAG_NAME)
	if tag and tag:IsA("ObjectValue") then
		return tag.Value
	end

	return nil
end

return CreatorTag
