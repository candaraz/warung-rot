-- BrainrotFactory: builds the 3D model of one brainrot from its catalog
-- recipe, plus the floating label above it (name, rarity, money per
-- second). Every part is anchored and non-colliding: belt, carried and
-- placed models are all moved by setting their CFrame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Rarities = require(Shared:WaitForChild("Rarities"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local BrainrotFactory = {}

local SHAPE_MAP = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
	Wedge = Enum.PartType.Wedge,
}

local function colorFromRole(character, role)
	local pick = character[role]
	return Color3.new(pick[1], pick[2], pick[3])
end

local function makeLabel(text, size, color, offsetY)
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size + 6)
	label.Position = UDim2.new(0, 0, 0, offsetY)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	return label
end

function BrainrotFactory.BuildLabel(character, mutationName)
	local income = Catalog.GetIncomeWithMutation(character, mutationName)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 190, 0, 92)
	gui.StudsOffset = Vector3.new(0, 3.6 * character.scale + 1.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0

	local nameLabel = makeLabel(character.name, 22, Color3.new(1, 1, 1), 0)
	nameLabel.Name = "NameLabel"
	nameLabel.Parent = gui

	local rarityLabel = makeLabel(Rarities.GetName(character.rarity), 19, Rarities.GetColor(character.rarity), 28)
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Parent = gui

	local incomeLabel = makeLabel(Catalog.FormatMoney(income) .. "/s", 20, Color3.new(0.6, 1, 0.6), 54)
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Parent = gui

	if mutationName ~= nil then
		local mutationLabel = makeLabel(mutationName .. " x" .. Mutations.GetMultiplier(mutationName), 18, Mutations.GetColor(mutationName), 78)
		mutationLabel.Name = "MutationLabel"
		mutationLabel.Parent = gui
		gui.Size = UDim2.new(0, 190, 0, 108)
	end

	return gui
end

function BrainrotFactory.BuildModel(characterId, mutationName)
	local character = Catalog.GetCharacter(characterId)
	assert(character ~= nil, "Unknown brainrot id: " .. tostring(characterId))

	local model = Instance.new("Model")
	model.Name = character.name

	local firstPart = nil
	for _, recipe in ipairs(character.parts) do
		local shapeName, size, offset, role, transparency = recipe[1], recipe[2], recipe[3], recipe[4], recipe[5]
		local part = Instance.new("Part")
		part.Name = shapeName
		part.Shape = SHAPE_MAP[shapeName] or Enum.PartType.Block
		part.Size = Vector3.new(size[1] * character.scale, size[2] * character.scale, size[3] * character.scale)
		part.CFrame = CFrame.new(offset[1] * character.scale, offset[2] * character.scale, offset[3] * character.scale)
		part.Color = colorFromRole(character, role)
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		if transparency ~= nil then
			part.Transparency = transparency
		end
		part.Parent = model
		if firstPart == nil then
			firstPart = part
		end
	end

	if mutationName ~= nil then
		local gem = Instance.new("Part")
		gem.Name = "MutationGem"
		gem.Shape = Enum.PartType.Ball
		gem.Size = Vector3.new(0.9, 0.9, 0.9) * character.scale
		gem.CFrame = CFrame.new(0, 2.6 * character.scale, 0)
		gem.Color = Mutations.GetColor(mutationName)
		gem.Material = Enum.Material.Neon
		gem.Anchored = true
		gem.CanCollide = false
		gem.CanQuery = false
		gem.CanTouch = false
		gem.Parent = model
	end

	model.PrimaryPart = firstPart
	BrainrotFactory.BuildLabel(character, mutationName).Parent = model
	model:SetAttribute("CharacterId", characterId)
	if mutationName ~= nil then
		model:SetAttribute("Mutation", mutationName)
	end
	return model
end

-- Welds every part of a model to one anchor part, for the thief bot's stolen
-- loot. The model's parts are unanchored first; the caller destroys the
-- welds (or the model) when done.
function BrainrotFactory.WeldModelToPart(model, anchorPart)
	local primary = model.PrimaryPart
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = anchorPart
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
	if primary ~= nil then
		primary.CFrame = anchorPart.CFrame * CFrame.new(0, 3.5, 0)
	end
end

return BrainrotFactory
