-- Mutations: the four income multipliers that can roll on a brainrot when
-- it spawns. At most one mutation per brainrot. Pure data plus the roll.

local Mutations = {}

-- Checked in order, rarest first, so the table reads top-down by value.
Mutations.LIST = {
	{ name = "Rainbow", chance = 0.005, multiplier = 6, color = { 1, 0.3, 0.8 } },
	{ name = "Cursed", chance = 0.01, multiplier = 4, color = { 0.55, 0.2, 0.9 } },
	{ name = "Diamond", chance = 0.04, multiplier = 3, color = { 0.6, 0.9, 1 } },
	{ name = "Gold", chance = 0.08, multiplier = 2, color = { 1, 0.85, 0.2 } },
}

local byName = {}
for _, mutation in ipairs(Mutations.LIST) do
	byName[mutation.name] = mutation
end

function Mutations.Roll()
	for _, mutation in ipairs(Mutations.LIST) do
		if math.random() < mutation.chance then
			return mutation.name
		end
	end
	return nil
end

function Mutations.GetMultiplier(mutationName)
	if mutationName == nil then
		return 1
	end
	local mutation = byName[mutationName]
	if mutation == nil then
		return 1
	end
	return mutation.multiplier
end

function Mutations.GetColor(mutationName)
	local mutation = byName[mutationName]
	if mutation == nil then
		return Color3.new(1, 1, 1)
	end
	return Color3.new(mutation.color[1], mutation.color[2], mutation.color[3])
end

return Mutations
