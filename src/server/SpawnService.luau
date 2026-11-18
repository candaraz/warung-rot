-- SpawnService: the conveyor belt. Brainrots spawn at the west end, walk
-- east along the belt, and despawn at the east end. Rarity rolls use pity
-- timers so a long dry spell guarantees something good. Buying takes the
-- nearest belt brainrot in reach and puts it in the buyer's hands.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local SpawnService = {}

local registry = nil
local beltFolder = nil
local beltItems = {}
local nextItemId = 1
local spawnTimer = 0
local secondsSinceLegendary = 0
local secondsSinceMythic = 0

function SpawnService.Init(services)
	registry = services
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltModels"
	beltFolder.Parent = Workspace
	spawnTimer = 2
end

local function rollSpawn()
	local pityLegendary = secondsSinceLegendary >= Config.PITY_LEGENDARY_SECONDS
	local pityMythic = secondsSinceMythic >= Config.PITY_MYTHIC_SECONDS
	local rarity = Catalog.RollRarityWithPity(pityLegendary, pityMythic)
	local character = Catalog.GetRandomCharacterOfRarity(rarity)
	local mutation = Catalog.RollMutation()
	secondsSinceLegendary = secondsSinceLegendary + Config.BELT_SPAWN_SECONDS
	secondsSinceMythic = secondsSinceMythic + Config.BELT_SPAWN_SECONDS
	if rarity >= 4 then
		secondsSinceLegendary = 0
	end
	if rarity >= 5 then
		secondsSinceMythic = 0
	end
	return character, mutation
end

function SpawnService.SpawnOne(forceRarity)
	if #beltItems >= Config.MAX_BELT_ITEMS then
		return nil
	end
	local character, mutation
	if forceRarity ~= nil then
		character = Catalog.GetRandomCharacterOfRarity(forceRarity)
		mutation = Catalog.RollMutation()
	else
		character, mutation = rollSpawn()
	end
	local model = registry.BrainrotFactory.BuildModel(character.id, mutation)
	model:SetAttribute("Price", character.price)
	model.Parent = beltFolder
	local item = {
		id = nextItemId,
		model = model,
		characterId = character.id,
		mutation = mutation,
		x = Config.BELT_START_X,
	}
	nextItemId = nextItemId + 1
	table.insert(beltItems, item)
	model:PivotTo(CFrame.new(item.x, Config.BELT_TOP_Y + 1.6, Config.BELT_Z))
	return item
end

function SpawnService.SpawnBurst(count)
	for _ = 1, count do
		SpawnService.SpawnOne()
	end
end

function SpawnService.OnSecond()
	spawnTimer = spawnTimer - 1
	if spawnTimer > 0 then
		return
	end
	local interval = Config.BELT_SPAWN_SECONDS
	if registry.EventService ~= nil and registry.EventService.IsMemeRain() then
		interval = math.max(1, math.floor(interval / 2))
	end
	spawnTimer = interval
	SpawnService.SpawnOne()
end

function SpawnService.OnHeartbeat(dt)
	local timeNow = os.clock()
	local index = 1
	while index <= #beltItems do
		local item = beltItems[index]
		item.x = item.x + Config.BELT_SPEED * dt
		if item.x > Config.BELT_END_X then
			item.model:Destroy()
			table.remove(beltItems, index)
		else
			local bob = math.sin(timeNow * 2.5 + item.id) * 0.15
			item.model:PivotTo(CFrame.new(item.x, Config.BELT_TOP_Y + 1.6 + bob, Config.BELT_Z))
			index = index + 1
		end
	end
end

local function findNearestBuyable(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return nil
	end
	local nearest = nil
	local nearestDistance = Config.INTERACT_RANGE
	for _, item in ipairs(beltItems) do
		local distance = (item.model:GetPivot().Position - root.Position).Magnitude
		if distance <= nearestDistance then
			nearest = item
			nearestDistance = distance
		end
	end
	return nearest
end

local function removeBeltItem(target)
	for index, item in ipairs(beltItems) do
		if item == target then
			table.remove(beltItems, index)
			return
		end
	end
end

function SpawnService.RequestBuy(player)
	local state = registry.PlayerDataService.GetState(player)
	if state == nil then
		return
	end
	local item = findNearestBuyable(player)
	if item == nil then
		return
	end
	local character = Catalog.GetCharacter(item.characterId)
	if #state.carrying >= registry.PlayerDataService.GetCarryCapacity(player) then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Tanganmu penuh! Taruh dulu di warungmu.",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	if not registry.PlayerDataService.SpendCash(player, character.price) then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Uang kurang: " .. character.name .. " harganya " .. Catalog.FormatMoney(character.price) .. ".",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	removeBeltItem(item)
	registry.PlayerDataService.AddCarried(player, {
		characterId = item.characterId,
		mutation = item.mutation,
	})
	registry.BaseService.AttachCarried(player, item.model)
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = "Kamu membeli " .. character.name .. "! Bawa pulang ke warungmu.",
		color = { 0.6, 1, 0.6 },
	})
	if character.rarity >= 4 or item.mutation ~= nil then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "reveal",
			text = character.name,
			rarity = character.rarity,
			mutation = item.mutation,
		})
	end
end

return SpawnService
