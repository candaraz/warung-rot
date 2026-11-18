-- PlayerDataService: the ONE authoritative store of player state. Every
-- other service reads and writes player data through here, never through
-- its own copy. Persistence goes through a DataStore wrapped in pcall, so
-- the game keeps working in Studio when DataStore access fails.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = {}

local DATASTORE_NAME = "WarungRotSaveV1"
local SAVE_KEY_PREFIX = "WarungRot_v1_"

local states = {}
local store = nil

local function openStore()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		store = result
	end
	return ok
end

local function defaultState()
	return {
		cash = Config.START_CASH,
		rebirthLevel = 0,
		upgrades = { speed = 0, carry = 0, lock = 0 },
		slots = {},
		carrying = {},
		lockUntil = 0,
		stealCooldownUntil = 0,
		loadedFromStore = false,
	}
end

function PlayerDataService.Init()
	openStore()
end

function PlayerDataService.GetState(player)
	return states[player]
end

function PlayerDataService.LoadPlayer(player)
	local state = defaultState()
	states[player] = state
	if store ~= nil then
		local ok, saved = pcall(function()
			return store:GetAsync(SAVE_KEY_PREFIX .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			if type(saved.cash) == "number" then
				state.cash = math.max(0, math.floor(saved.cash))
			end
			if type(saved.rebirthLevel) == "number" then
				state.rebirthLevel = math.clamp(math.floor(saved.rebirthLevel), 0, #Config.REBIRTHS)
			end
			if type(saved.upgrades) == "table" then
				for key, value in pairs(saved.upgrades) do
					if state.upgrades[key] ~= nil and type(value) == "number" then
						state.upgrades[key] = math.max(0, math.floor(value))
					end
				end
			end
			if type(saved.slots) == "table" then
				for slotIndex, entry in pairs(saved.slots) do
					if type(entry) == "table" and Catalog.GetCharacter(entry.characterId) ~= nil then
						local index = tonumber(slotIndex)
						if index ~= nil and index >= 1 and index <= Config.SLOTS_PER_BASE then
							state.slots[index] = {
								characterId = entry.characterId,
								mutation = entry.mutation,
							}
						end
					end
				end
			end
			state.loadedFromStore = true
		end
	end
	return state
end

function PlayerDataService.SavePlayer(player)
	local state = states[player]
	if state == nil or store == nil then
		return false
	end
	local savedSlots = {}
	for slotIndex, entry in pairs(state.slots) do
		savedSlots[slotIndex] = {
			characterId = entry.characterId,
			mutation = entry.mutation,
		}
	end
	local payload = {
		cash = state.cash,
		rebirthLevel = state.rebirthLevel,
		upgrades = state.upgrades,
		slots = savedSlots,
	}
	local ok = pcall(function()
		store:SetAsync(SAVE_KEY_PREFIX .. player.UserId, payload)
	end)
	return ok
end

function PlayerDataService.SaveAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService.SavePlayer(player)
	end
end

function PlayerDataService.RemovePlayer(player)
	PlayerDataService.SavePlayer(player)
	states[player] = nil
end

function PlayerDataService.AddCash(player, amount)
	local state = states[player]
	if state == nil then
		return
	end
	state.cash = math.max(0, state.cash + amount)
end

function PlayerDataService.SpendCash(player, amount)
	local state = states[player]
	if state == nil or state.cash < amount then
		return false
	end
	state.cash = state.cash - amount
	return true
end

function PlayerDataService.GetRebirthMultiplier(player)
	local state = states[player]
	if state == nil or state.rebirthLevel <= 0 then
		return 1
	end
	local step = Config.REBIRTHS[state.rebirthLevel]
	if step == nil then
		return 1
	end
	return step.multiplier
end

function PlayerDataService.GetIncomePerSecond(player, eventMultiplier)
	local state = states[player]
	if state == nil then
		return 0
	end
	local total = 0
	for _, entry in pairs(state.slots) do
		local character = Catalog.GetCharacter(entry.characterId)
		if character ~= nil then
			total = total + Catalog.GetIncomeWithMutation(character, entry.mutation)
		end
	end
	return total * PlayerDataService.GetRebirthMultiplier(player) * (eventMultiplier or 1)
end

function PlayerDataService.GetCarryCapacity(player)
	local state = states[player]
	if state == nil then
		return Config.BASE_CARRY_CAPACITY
	end
	return Config.BASE_CARRY_CAPACITY + state.upgrades.carry
end

function PlayerDataService.GetLockSeconds(player)
	local state = states[player]
	if state == nil then
		return Config.BASE_LOCK_SECONDS
	end
	return Config.BASE_LOCK_SECONDS
		+ state.upgrades.lock * 15
		+ state.rebirthLevel * Config.REBIRTH_LOCK_BONUS
end

function PlayerDataService.GetWalkSpeed(player)
	local state = states[player]
	if state == nil then
		return Config.BASE_WALK_SPEED
	end
	return Config.BASE_WALK_SPEED
		+ state.upgrades.speed * 2
		+ state.rebirthLevel * Config.REBIRTH_WALK_BONUS
end

function PlayerDataService.IsLocked(player)
	local state = states[player]
	if state == nil then
		return false
	end
	return os.time() < state.lockUntil
end

function PlayerDataService.GetLockSecondsLeft(player)
	local state = states[player]
	if state == nil then
		return 0
	end
	return math.max(0, state.lockUntil - os.time())
end

function PlayerDataService.LockBase(player)
	local state = states[player]
	if state == nil then
		return 0
	end
	local seconds = PlayerDataService.GetLockSeconds(player)
	state.lockUntil = os.time() + seconds
	return seconds
end

function PlayerDataService.CanSteal(player)
	local state = states[player]
	if state == nil then
		return false
	end
	return os.time() >= state.stealCooldownUntil
end

function PlayerDataService.MarkSteal(player)
	local state = states[player]
	if state == nil then
		return
	end
	state.stealCooldownUntil = os.time() + Config.STEAL_COOLDOWN_SECONDS
end

function PlayerDataService.FindEmptySlot(player)
	local state = states[player]
	if state == nil then
		return nil
	end
	for index = 1, Config.SLOTS_PER_BASE do
		if state.slots[index] == nil then
			return index
		end
	end
	return nil
end

function PlayerDataService.PlaceInSlot(player, slotIndex, entry)
	local state = states[player]
	if state == nil or state.slots[slotIndex] ~= nil then
		return false
	end
	state.slots[slotIndex] = entry
	return true
end

function PlayerDataService.TakeFromSlot(player, slotIndex)
	local state = states[player]
	if state == nil then
		return nil
	end
	local entry = state.slots[slotIndex]
	state.slots[slotIndex] = nil
	return entry
end

function PlayerDataService.AddCarried(player, entry)
	local state = states[player]
	if state == nil then
		return false
	end
	if #state.carrying >= PlayerDataService.GetCarryCapacity(player) then
		return false
	end
	table.insert(state.carrying, entry)
	return true
end

function PlayerDataService.TakeFirstCarried(player)
	local state = states[player]
	if state == nil or #state.carrying == 0 then
		return nil
	end
	return table.remove(state.carrying, 1)
end

function PlayerDataService.ClearCarried(player)
	local state = states[player]
	if state == nil then
		return {}
	end
	local carried = state.carrying
	state.carrying = {}
	return carried
end

function PlayerDataService.ClearSlots(player)
	local state = states[player]
	if state == nil then
		return
	end
	state.slots = {}
end

function PlayerDataService.ResetForRebirth(player)
	local state = states[player]
	if state == nil then
		return
	end
	state.cash = Config.START_CASH
	state.slots = {}
	state.carrying = {}
	state.lockUntil = 0
	state.rebirthLevel = state.rebirthLevel + 1
end

function PlayerDataService.GetBestOwnedRarity(player)
	local state = states[player]
	if state == nil then
		return 0
	end
	local best = 0
	for _, entry in pairs(state.slots) do
		local character = Catalog.GetCharacter(entry.characterId)
		if character ~= nil and character.rarity > best then
			best = character.rarity
		end
	end
	return best
end

function PlayerDataService.BuyUpgrade(player, upgradeKey)
	local state = states[player]
	local spec = Config.UPGRADES[upgradeKey]
	if state == nil or spec == nil then
		return false, "Upgrade tidak dikenal."
	end
	local level = state.upgrades[upgradeKey]
	if level >= #spec.costs then
		return false, spec.label .. " sudah maksimal."
	end
	local cost = spec.costs[level + 1]
	if state.cash < cost then
		return false, "Uang kurang: butuh " .. Catalog.FormatMoney(cost) .. "."
	end
	state.cash = state.cash - cost
	state.upgrades[upgradeKey] = level + 1
	return true, spec.label .. " naik ke level " .. tostring(level + 1) .. "!"
end

function PlayerDataService.BuildSnapshot(player, eventMultiplier)
	local state = states[player]
	if state == nil then
		return nil
	end
	local carryingNames = {}
	for _, entry in ipairs(state.carrying) do
		local character = Catalog.GetCharacter(entry.characterId)
		if character ~= nil then
			table.insert(carryingNames, {
				name = character.name,
				rarity = character.rarity,
				mutation = entry.mutation,
			})
		end
	end
	local usedSlots = 0
	for _ in pairs(state.slots) do
		usedSlots = usedSlots + 1
	end
	return {
		cash = state.cash,
		incomePerSecond = PlayerDataService.GetIncomePerSecond(player, eventMultiplier),
		rebirthLevel = state.rebirthLevel,
		rebirthMultiplier = PlayerDataService.GetRebirthMultiplier(player),
		upgrades = {
			speed = state.upgrades.speed,
			carry = state.upgrades.carry,
			lock = state.upgrades.lock,
		},
		carrying = carryingNames,
		carryCapacity = PlayerDataService.GetCarryCapacity(player),
		usedSlots = usedSlots,
		totalSlots = Config.SLOTS_PER_BASE,
		lockSecondsLeft = PlayerDataService.GetLockSecondsLeft(player),
	}
end

function PlayerDataService.BroadcastState(player, eventMultiplier)
	local snapshot = PlayerDataService.BuildSnapshot(player, eventMultiplier)
	if snapshot == nil then
		return
	end
	Remotes.GetRemote(Remotes.STATE_SYNC):FireClient(player, snapshot)
end

function PlayerDataService.BroadcastAllStates(eventMultiplier)
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService.BroadcastState(player, eventMultiplier)
	end
end

return PlayerDataService
