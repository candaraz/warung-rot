-- ClientBootstrap: the client entry point. It builds the HUD, the shop,
-- the effects layer and the input bindings, then connects the server's
-- state, world, notification and wave signals to the controllers that
-- render them. The client never owns game state: it only sends requests
-- and renders what the server replicates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarities = require(Shared:WaitForChild("Rarities"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local HudController = require(PlayerScripts:WaitForChild("HudController"))
local ShopController = require(PlayerScripts:WaitForChild("ShopController"))
local EffectsController = require(PlayerScripts:WaitForChild("EffectsController"))
local CameraAndInput = require(PlayerScripts:WaitForChild("CameraAndInput"))

HudController.Init()
local gui = HudController.GetGui()
EffectsController.Init(gui)
ShopController.Init(gui)
CameraAndInput.Init()

Remotes.GetRemote(Remotes.STATE_SYNC).OnClientEvent:Connect(function(snapshot)
	HudController.ApplySnapshot(snapshot)
	ShopController.ApplySnapshot(snapshot)
	CameraAndInput.ApplySnapshot(snapshot)
end)

Remotes.GetRemote(Remotes.WORLD_SYNC).OnClientEvent:Connect(function(world)
	HudController.ApplyWorldSync(world)
end)

Remotes.GetRemote(Remotes.NOTIFY).OnClientEvent:Connect(function(payload)
	if payload.kind == "banner" then
		HudController.ShowBanner(payload.text, payload.color)
		EffectsController.PlaySound("click")
	elseif payload.kind == "float" then
		EffectsController.FloatText(payload.text)
	elseif payload.kind == "reveal" then
		local color = Rarities.GetColor(payload.rarity or 1)
		local text = payload.text
		if payload.mutation ~= nil then
			color = Mutations.GetColor(payload.mutation)
			text = text .. " (" .. payload.mutation .. ")"
		end
		EffectsController.Reveal(text, color)
	end
end)

Remotes.GetRemote(Remotes.WAVE_SIGNAL).OnClientEvent:Connect(function(phase, warnSeconds)
	if phase == "warn" then
		HudController.ShowWarning(true)
		EffectsController.Siren(warnSeconds or 20)
		EffectsController.PlaySound("splash")
	elseif phase == "start" then
		HudController.ShowWarning(false)
		EffectsController.Shake(1.6, 2.5)
		EffectsController.PlaySound("splash", 0.7)
	elseif phase == "end" then
		HudController.ShowWarning(false)
	end
end)
