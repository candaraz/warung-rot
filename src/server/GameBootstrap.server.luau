-- GameBootstrap: the server entry point. It creates the remotes, loads the
-- services in dependency order, wires every client request to the service
-- that validates it, and runs the once-a-second world loop and the
-- per-frame movement loop. All state lives in PlayerDataService; this
-- script only connects the pieces.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ServerScriptService = game:GetService("ServerScriptService")
local PlayerDataService = require(ServerScriptService:WaitForChild("PlayerDataService"))
local EconomyService = require(ServerScriptService:WaitForChild("EconomyService"))
local BaseService = require(ServerScriptService:WaitForChild("BaseService"))
local BrainrotFactory = require(ServerScriptService:WaitForChild("BrainrotFactory"))
local SpawnService = require(ServerScriptService:WaitForChild("SpawnService"))
local WaveHazardService = require(ServerScriptService:WaitForChild("WaveHazardService"))
local StealService = require(ServerScriptService:WaitForChild("StealService"))
local RebirthService = require(ServerScriptService:WaitForChild("RebirthService"))
local EventService = require(ServerScriptService:WaitForChild("EventService"))

Remotes.CreateAll()

local registry = {
	PlayerDataService = PlayerDataService,
	EconomyService = EconomyService,
	BaseService = BaseService,
	BrainrotFactory = BrainrotFactory,
	SpawnService = SpawnService,
	WaveHazardService = WaveHazardService,
	StealService = StealService,
	RebirthService = RebirthService,
	EventService = EventService,
}

PlayerDataService.Init(registry)
BaseService.Init(registry)
EconomyService.Init(registry)
SpawnService.Init(registry)
WaveHazardService.Init(registry)
StealService.Init(registry)
RebirthService.Init(registry)
EventService.Init(registry)

local function applyWalkSpeed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = PlayerDataService.GetWalkSpeed(player)
	end
end

local function onCharacterAdded(player)
	applyWalkSpeed(player)
	BaseService.TeleportToGate(player)
end

local function onPlayerAdded(player)
	PlayerDataService.LoadPlayer(player)
	local base = BaseService.AssignBase(player)
	if base == nil then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Semua warung penuh! Tunggu ada yang kosong.",
			color = { 1, 0.4, 0.4 },
		})
	end
	BaseService.RestoreOwned(player)
	if player.Character ~= nil then
		onCharacterAdded(player)
	end
	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)
end

local function onPlayerRemoving(player)
	EconomyService.OnPlayerRemoving(player)
	BaseService.OnPlayerRemoving(player)
	PlayerDataService.RemovePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Remotes.GetRemote(Remotes.REQUEST_BUY).OnServerEvent:Connect(function(player)
	SpawnService.RequestBuy(player)
end)

Remotes.GetRemote(Remotes.REQUEST_PLACE).OnServerEvent:Connect(function(player)
	BaseService.RequestPlace(player)
end)

Remotes.GetRemote(Remotes.REQUEST_STEAL).OnServerEvent:Connect(function(player, victim)
	StealService.RequestSteal(player, victim)
end)

Remotes.GetRemote(Remotes.REQUEST_LOCK).OnServerEvent:Connect(function(player)
	local seconds = PlayerDataService.LockBase(player)
	BaseService.RefreshGate(player)
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = "Warungmu terkunci selama " .. tostring(seconds) .. " detik!",
		color = { 0.4, 1, 0.5 },
	})
end)

Remotes.GetRemote(Remotes.REQUEST_UPGRADE).OnServerEvent:Connect(function(player, upgradeKey)
	local ok, message = PlayerDataService.BuyUpgrade(player, upgradeKey)
	if ok then
		applyWalkSpeed(player)
	end
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = message,
		color = ok and { 0.6, 1, 0.6 } or { 1, 0.4, 0.4 },
	})
end)

Remotes.GetRemote(Remotes.REQUEST_REBIRTH).OnServerEvent:Connect(function(player)
	RebirthService.RequestRebirth(player)
end)

RunService.Heartbeat:Connect(function(dt)
	SpawnService.OnHeartbeat(dt)
	WaveHazardService.OnHeartbeat(dt)
	BaseService.OnHeartbeat()
end)

local autosaveTimer = Config.AUTOSAVE_SECONDS

while true do
	task.wait(1)
	EconomyService.OnSecond()
	SpawnService.OnSecond()
	WaveHazardService.OnSecond()
	StealService.OnSecond()
	EventService.OnSecond()
	BaseService.RefreshGateForAll()
	local eventMultiplier = EventService.GetIncomeMultiplier()
	PlayerDataService.BroadcastAllStates(eventMultiplier)
	Remotes.GetRemote(Remotes.WORLD_SYNC):FireAllClients({
		waveSecondsLeft = WaveHazardService.GetTimeLeft(),
		waveSweeping = WaveHazardService.IsSweeping(),
		event = EventService.GetActiveEvent(),
	})
	autosaveTimer = autosaveTimer - 1
	if autosaveTimer <= 0 then
		autosaveTimer = Config.AUTOSAVE_SECONDS
		PlayerDataService.SaveAllPlayers()
	end
end
