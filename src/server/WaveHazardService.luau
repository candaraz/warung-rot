-- WaveHazardService: the flood wave. A wall of water sweeps the map from
-- west to east on a timer. A warning banner and siren go out first; any
-- player caught by the wall while carrying brainrots loses them and gets
-- knocked back. The countdown board in the plaza shows the live timer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local WaveHazardService = {}

local registry = nil
local nextWaveAt = 0
local warningSent = false
local sweeping = false
local wallPart = nil
local wallX = 0
local hitThisSweep = {}
local timerLabel = nil
local eventLabel = nil

local function findBoardLabels()
	local board = Workspace:FindFirstChild("CountdownBoard")
	if board == nil then
		return
	end
	local gui = board:FindFirstChild("BoardGui")
	if gui == nil then
		return
	end
	timerLabel = gui:FindFirstChild("TimerLabel")
	eventLabel = gui:FindFirstChild("EventLabel")
end

function WaveHazardService.Init(services)
	registry = services
	nextWaveAt = os.time() + Config.WAVE_FIRST_SECONDS
	findBoardLabels()
end

function WaveHazardService.GetTimeLeft()
	if sweeping then
		return 0
	end
	return math.max(0, nextWaveAt - os.time())
end

function WaveHazardService.IsSweeping()
	return sweeping
end

function WaveHazardService.SetEventLabel(text)
	if eventLabel ~= nil then
		eventLabel.Text = text
	end
end

function WaveHazardService.TriggerNow()
	if sweeping then
		return
	end
	nextWaveAt = os.time()
	warningSent = true
end

local function formatTimeLeft(seconds)
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%d:%02d", minutes, rest)
end

local function updateBoard()
	if timerLabel == nil then
		return
	end
	if sweeping then
		timerLabel.Text = "BANJIR!"
	else
		timerLabel.Text = "Banjir: " .. formatTimeLeft(WaveHazardService.GetTimeLeft())
	end
end

local function startSweep()
	sweeping = true
	hitThisSweep = {}
	wallX = Config.WAVE_START_X
	wallPart = Instance.new("Part")
	wallPart.Name = "FloodWall"
	wallPart.Size = Vector3.new(4, 30, 230)
	wallPart.CFrame = CFrame.new(wallX, 14, 0)
	wallPart.Color = Color3.new(0.2, 0.5, 0.95)
	wallPart.Material = Enum.Material.SmoothPlastic
	wallPart.Transparency = 0.25
	wallPart.Anchored = true
	wallPart.CanCollide = false
	wallPart.CanQuery = false
	wallPart.CanTouch = false
	wallPart.Parent = Workspace
	Remotes.GetRemote(Remotes.WAVE_SIGNAL):FireAllClients("start")
	updateBoard()
end

local function endSweep()
	sweeping = false
	if wallPart ~= nil then
		wallPart:Destroy()
		wallPart = nil
	end
	nextWaveAt = os.time() + Config.WAVE_EVERY_SECONDS
	warningSent = false
	Remotes.GetRemote(Remotes.WAVE_SIGNAL):FireAllClients("end")
	updateBoard()
end

local function catchCarriers()
	for _, player in ipairs(Players:GetPlayers()) do
		if hitThisSweep[player] then
			continue
		end
		local state = registry.PlayerDataService.GetState(player)
		if state == nil or #state.carrying == 0 then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root == nil then
			continue
		end
		if math.abs(root.Position.X - wallX) < 8 then
			hitThisSweep[player] = true
			registry.PlayerDataService.ClearCarried(player)
			registry.BaseService.DestroyCarriedModels(player)
			root.AssemblyLinearVelocity = Vector3.new(55, 25, 0)
			Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
				kind = "banner",
				text = "Banjir menyapu bawaanmu! Lari lebih cepat lain kali.",
				color = { 1, 0.4, 0.4 },
			})
		end
	end
end

function WaveHazardService.OnSecond()
	updateBoard()
	if sweeping then
		return
	end
	local timeLeft = WaveHazardService.GetTimeLeft()
	if timeLeft <= Config.WAVE_WARN_SECONDS and not warningSent then
		warningSent = true
		Remotes.GetRemote(Remotes.WAVE_SIGNAL):FireAllClients("warn", Config.WAVE_WARN_SECONDS)
	end
	if timeLeft <= 0 then
		startSweep()
	end
end

function WaveHazardService.OnHeartbeat(dt)
	if not sweeping or wallPart == nil then
		return
	end
	wallX = wallX + Config.WAVE_SPEED * dt
	wallPart.CFrame = CFrame.new(wallX, 14, 0)
	catchCarriers()
	if wallX > Config.WAVE_END_X then
		endSweep()
	end
end

return WaveHazardService
