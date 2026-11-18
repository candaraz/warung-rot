-- RebirthService: rebirths reset money and the base in exchange for a
-- permanent income multiplier. Each level needs cash plus at least one
-- owned brainrot of a minimum rarity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Rarities = require(Shared:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local RebirthService = {}

local registry = nil

function RebirthService.Init(services)
	registry = services
end

function RebirthService.GetRequirement(player)
	local state = registry.PlayerDataService.GetState(player)
	if state == nil then
		return nil
	end
	return Config.REBIRTHS[state.rebirthLevel + 1]
end

function RebirthService.RequestRebirth(player)
	local state = registry.PlayerDataService.GetState(player)
	if state == nil then
		return
	end
	local requirement = RebirthService.GetRequirement(player)
	if requirement == nil then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Kamu sudah mencapai rebirth tertinggi!",
			color = { 1, 0.8, 0.3 },
		})
		return
	end
	if state.cash < requirement.cash then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Rebirth butuh " .. Catalog.FormatMoney(requirement.cash) .. ".",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	local bestRarity = registry.PlayerDataService.GetBestOwnedRarity(player)
	if bestRarity < requirement.needRarity then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Rebirth butuh brainrot " .. Rarities.GetName(requirement.needRarity) .. " atau lebih langka di warungmu.",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	registry.BaseService.ClearPlacedModels(player)
	registry.BaseService.DestroyCarriedModels(player)
	registry.PlayerDataService.ResetForRebirth(player)
	registry.BaseService.RefreshGate(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = registry.PlayerDataService.GetWalkSpeed(player)
	end
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = "REBIRTH! Penghasilanmu sekarang x" .. tostring(requirement.multiplier) .. " selamanya!",
		color = { 1, 0.85, 0.3 },
	})
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "reveal",
		text = "REBIRTH x" .. tostring(requirement.multiplier),
		rarity = 6,
	})
end

return RebirthService
