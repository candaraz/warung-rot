-- EconomyService: the once-a-second income tick. Every placed brainrot
-- earns its money-per-second, multiplied by mutations, rebirths and the
-- active event. Earnings pile up into a floating "+$" notice every few
-- seconds so the client is not spammed every tick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local EconomyService = {}

local registry = nil
local pendingFloat = {}
local secondsSinceFloat = 0

function EconomyService.Init(services)
	registry = services
end

function EconomyService.OnSecond()
	local eventMultiplier = 1
	if registry ~= nil and registry.EventService ~= nil then
		eventMultiplier = registry.EventService.GetIncomeMultiplier()
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local income = registry.PlayerDataService.GetIncomePerSecond(player, eventMultiplier)
		if income > 0 then
			registry.PlayerDataService.AddCash(player, income)
			pendingFloat[player] = (pendingFloat[player] or 0) + income
		end
	end
	secondsSinceFloat = secondsSinceFloat + 1
	if secondsSinceFloat >= 5 then
		secondsSinceFloat = 0
		for player, amount in pairs(pendingFloat) do
			if amount > 0 then
				Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
					kind = "float",
					text = "+" .. Catalog.FormatMoney(amount),
				})
			end
		end
		pendingFloat = {}
	end
end

function EconomyService.OnPlayerRemoving(player)
	pendingFloat[player] = nil
end

return EconomyService
