-- Remotes: the one list of RemoteEvent names the game uses, plus the
-- helpers that create them on the server and find them on the client. All
-- client-to-server traffic is a validated request; all server-to-client
-- traffic is state, world timers, or notifications.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

Remotes.FOLDER_NAME = "WarungRemotes"

-- Client -> server requests.
Remotes.REQUEST_BUY = "RequestBuy"
Remotes.REQUEST_PLACE = "RequestPlace"
Remotes.REQUEST_STEAL = "RequestSteal"
Remotes.REQUEST_LOCK = "RequestLock"
Remotes.REQUEST_UPGRADE = "RequestUpgrade"
Remotes.REQUEST_REBIRTH = "RequestRebirth"

-- Server -> client updates.
Remotes.STATE_SYNC = "StateSync"
Remotes.WORLD_SYNC = "WorldSync"
Remotes.NOTIFY = "Notify"
Remotes.WAVE_SIGNAL = "WaveSignal"

local ALL_NAMES = {
	Remotes.REQUEST_BUY,
	Remotes.REQUEST_PLACE,
	Remotes.REQUEST_STEAL,
	Remotes.REQUEST_LOCK,
	Remotes.REQUEST_UPGRADE,
	Remotes.REQUEST_REBIRTH,
	Remotes.STATE_SYNC,
	Remotes.WORLD_SYNC,
	Remotes.NOTIFY,
	Remotes.WAVE_SIGNAL,
}

function Remotes.CreateAll()
	assert(RunService:IsServer(), "Remotes.CreateAll runs on the server only")
	local folder = Instance.new("Folder")
	folder.Name = Remotes.FOLDER_NAME
	for _, name in ipairs(ALL_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.GetRemote(name)
	local folder = ReplicatedStorage:WaitForChild(Remotes.FOLDER_NAME)
	return folder:WaitForChild(name)
end

return Remotes
