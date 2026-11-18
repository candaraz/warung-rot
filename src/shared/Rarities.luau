-- Rarities: the six rarity tiers of Warung Rot, their colours and their
-- spawn weights. Pure data; both the server and the client require it.

local Rarities = {}

Rarities.LIST = {
	{ name = "Common", color = { 0.78, 0.78, 0.78 }, weight = 45 },
	{ name = "Rare", color = { 0.25, 0.6, 1 }, weight = 28 },
	{ name = "Epic", color = { 0.65, 0.35, 1 }, weight = 14 },
	{ name = "Legendary", color = { 1, 0.65, 0 }, weight = 7.5 },
	{ name = "Mythic", color = { 1, 0.25, 0.35 }, weight = 4 },
	{ name = "Secret", color = { 0.3, 1, 0.7 }, weight = 1.5 },
}

function Rarities.GetName(rarityIndex)
	local rarity = Rarities.LIST[rarityIndex]
	if rarity == nil then
		return "Common"
	end
	return rarity.name
end

function Rarities.GetColor(rarityIndex)
	local rarity = Rarities.LIST[rarityIndex]
	if rarity == nil then
		return Color3.new(0.78, 0.78, 0.78)
	end
	return Color3.new(rarity.color[1], rarity.color[2], rarity.color[3])
end

function Rarities.GetCount()
	return #Rarities.LIST
end

return Rarities
