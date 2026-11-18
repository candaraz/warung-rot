-- EventService: random world events. "Meme Rain" floods the belt with
-- extra brainrots and doubles the spawn rate; "Harga Naik" doubles all
-- income; "Banjir Kilat" brings the flood wave early. Events are announced
-- to every player and shown on the plaza countdown board.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local EventService = {}

local registry = nil
local eventTimer = 0
local activeEvent = nil

local MEME_RAIN_SECONDS = 45
local DOUBLE_INCOME_SECONDS = 60

function EventService.Init(services)
	registry = services
	eventTimer = Config.EVENT_EVERY_SECONDS
end

function EventService.GetIncomeMultiplier()
	if activeEvent ~= nil and activeEvent.name == "Harga Naik" then
		return 2
	end
	return 1
end

function EventService.IsMemeRain()
	return activeEvent ~= nil and activeEvent.name == "Meme Rain"
end

function EventService.GetActiveEvent()
	if activeEvent == nil then
		return nil
	end
	return {
		name = activeEvent.name,
		secondsLeft = math.max(0, activeEvent.endsAt - os.time()),
	}
end

local function announce(text, color)
	Remotes.GetRemote(Remotes.NOTIFY):FireAllClients({
		kind = "banner",
		text = text,
		color = color,
	})
end

local function startEvent(name)
	local now = os.time()
	if name == "Meme Rain" then
		activeEvent = { name = name, endsAt = now + MEME_RAIN_SECONDS }
		registry.SpawnService.SpawnBurst(8)
		announce("MEME RAIN! Brainrot berjatuhan di conveyor!", { 1, 0.5, 0.9 })
	elseif name == "Harga Naik" then
		activeEvent = { name = name, endsAt = now + DOUBLE_INCOME_SECONDS }
		announce("HARGA NAIK! Semua penghasilan x2 selama 60 detik!", { 1, 0.85, 0.3 })
	elseif name == "Banjir Kilat" then
		activeEvent = nil
		announce("BANJIR KILAT! Gelombang datang lebih cepat!", { 0.4, 0.7, 1 })
		registry.WaveHazardService.TriggerNow()
	end
	if registry.WaveHazardService ~= nil then
		if activeEvent ~= nil then
			registry.WaveHazardService.SetEventLabel(activeEvent.name)
		else
			registry.WaveHazardService.SetEventLabel("")
		end
	end
end

function EventService.OnSecond()
	if activeEvent ~= nil and os.time() >= activeEvent.endsAt then
		activeEvent = nil
		if registry.WaveHazardService ~= nil then
			registry.WaveHazardService.SetEventLabel("")
		end
	end
	eventTimer = eventTimer - 1
	if eventTimer > 0 then
		return
	end
	eventTimer = Config.EVENT_EVERY_SECONDS
	local names = { "Meme Rain", "Harga Naik", "Banjir Kilat" }
	startEvent(names[math.random(#names)])
end

return EventService
