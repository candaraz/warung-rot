-- BaseService: owns the eight player bases in the Workspace. It assigns a
-- base to each player, places and removes brainrot models on slots, shows
-- the lock state on the laser gate, teleports players to their own gate on
-- spawn, and floats carried brainrots above their carrier's head.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BaseService = {}

local registry = nil
local bases = {}
local carriedModels = {}

local function sortBaseFolders(a, b)
	local floorA = a:FindFirstChild("Floor")
	local floorB = b:FindFirstChild("Floor")
	if floorA == nil or floorB == nil then
		return a.Name < b.Name
	end
	local posA = floorA.Position
	local posB = floorB.Position
	if posA.Z ~= posB.Z then
		return posA.Z < posB.Z
	end
	return posA.X < posB.X
end

local function sortSlotPads(a, b)
	return a.Name < b.Name
end

function BaseService.Init(services)
	registry = services
	local basesFolder = Workspace:WaitForChild("Bases")
	local folders = basesFolder:GetChildren()
	table.sort(folders, sortBaseFolders)
	for _, folder in ipairs(folders) do
		local slotsFolder = folder:FindFirstChild("Slots")
		local pads = {}
		if slotsFolder ~= nil then
			local children = slotsFolder:GetChildren()
			table.sort(children, sortSlotPads)
			for _, pad in ipairs(children) do
				if pad:IsA("BasePart") then
					table.insert(pads, pad)
				end
			end
		end
		local signLabel = nil
		local signBoard = folder:FindFirstChild("SignBoard")
		if signBoard ~= nil then
			local gui = signBoard:FindFirstChild("SignGui")
			if gui ~= nil then
				signLabel = gui:FindFirstChild("OwnerLabel")
			end
		end
		table.insert(bases, {
			folder = folder,
			floor = folder:FindFirstChild("Floor"),
			gate = folder:FindFirstChild("LaserGate"),
			slots = pads,
			signLabel = signLabel,
			owner = nil,
		})
		folder:SetAttribute("OwnerUserId", 0)
	end
end

function BaseService.GetBaseOf(player)
	for _, base in ipairs(bases) do
		if base.owner == player then
			return base
		end
	end
	return nil
end

function BaseService.GetBaseByIndex(index)
	return bases[index]
end

function BaseService.GetAllBases()
	return bases
end

function BaseService.AssignBase(player)
	local base = BaseService.GetBaseOf(player)
	if base ~= nil then
		return base
	end
	for _, candidate in ipairs(bases) do
		if candidate.owner == nil then
			candidate.owner = player
			candidate.folder:SetAttribute("OwnerUserId", player.UserId)
			if candidate.signLabel ~= nil then
				candidate.signLabel.Text = player.DisplayName
			end
			return candidate
		end
	end
	return nil
end

function BaseService.ReleaseBase(player)
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return
	end
	BaseService.ClearPlacedModels(player)
	base.owner = nil
	base.folder:SetAttribute("OwnerUserId", 0)
	if base.signLabel ~= nil then
		base.signLabel.Text = "KOSONG"
	end
	BaseService.SetGateLocked(base, false)
end

function BaseService.SetGateLocked(base, locked)
	if base.gate == nil then
		return
	end
	if locked then
		base.gate.Color = Color3.new(1, 0.15, 0.15)
		base.gate.Transparency = 0.15
	else
		base.gate.Color = Color3.new(0.4, 1, 0.5)
		base.gate.Transparency = 0.7
	end
end

function BaseService.RefreshGate(player)
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return
	end
	BaseService.SetGateLocked(base, registry.PlayerDataService.IsLocked(player))
end

-- Locks expire on the server clock; the gate colours must follow even when
-- the player presses nothing, so the world loop refreshes every gate.
function BaseService.RefreshGateForAll()
	for _, player in ipairs(Players:GetPlayers()) do
		BaseService.RefreshGate(player)
	end
end

function BaseService.GetSlotCFrame(base, slotIndex)
	local pad = base.slots[slotIndex]
	if pad == nil then
		return nil
	end
	return pad.CFrame * CFrame.new(0, 1.6, 0)
end

function BaseService.PlaceModelOnSlot(player, slotIndex, model)
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return false
	end
	local slotCFrame = BaseService.GetSlotCFrame(base, slotIndex)
	if slotCFrame == nil then
		return false
	end
	model:PivotTo(slotCFrame)
	model.Parent = base.slots[slotIndex]
	return true
end

function BaseService.RemoveModelFromSlot(player, slotIndex)
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return nil
	end
	local pad = base.slots[slotIndex]
	if pad == nil then
		return nil
	end
	local model = pad:FindFirstChildOfClass("Model")
	if model ~= nil then
		model.Parent = nil
	end
	return model
end

function BaseService.ClearPlacedModels(player)
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return
	end
	for _, pad in ipairs(base.slots) do
		local model = pad:FindFirstChildOfClass("Model")
		if model ~= nil then
			model:Destroy()
		end
	end
end

function BaseService.RestoreOwned(player)
	local state = registry.PlayerDataService.GetState(player)
	if state == nil then
		return
	end
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return
	end
	for slotIndex, entry in pairs(state.slots) do
		local model = registry.BrainrotFactory.BuildModel(entry.characterId, entry.mutation)
		BaseService.PlaceModelOnSlot(player, slotIndex, model)
	end
end

function BaseService.RequestPlace(player)
	local state = registry.PlayerDataService.GetState(player)
	if state == nil or #state.carrying == 0 then
		return
	end
	local base = BaseService.GetBaseOf(player)
	if base == nil then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or base.floor == nil then
		return
	end
	if (root.Position - base.floor.Position).Magnitude > 30 then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Terlalu jauh dari warungmu!",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	local slotIndex = registry.PlayerDataService.FindEmptySlot(player)
	if slotIndex == nil then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Warungmu penuh!",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	local entry = registry.PlayerDataService.TakeFirstCarried(player)
	if entry == nil then
		return
	end
	local models = carriedModels[player]
	local model = nil
	if models ~= nil and #models > 0 then
		model = table.remove(models, 1)
	end
	if model == nil then
		model = registry.BrainrotFactory.BuildModel(entry.characterId, entry.mutation)
	end
	registry.PlayerDataService.PlaceInSlot(player, slotIndex, entry)
	BaseService.PlaceModelOnSlot(player, slotIndex, model)
	local characterData = Catalog.GetCharacter(entry.characterId)
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = characterData.name .. " mulai jualan di warungmu!",
		color = { 0.6, 1, 0.6 },
	})
end

function BaseService.AttachCarried(player, model)
	local models = carriedModels[player]
	if models == nil then
		models = {}
		carriedModels[player] = models
	end
	table.insert(models, model)
	model.Parent = Workspace
end

function BaseService.TakeCarriedModels(player)
	local models = carriedModels[player] or {}
	carriedModels[player] = {}
	return models
end

function BaseService.DestroyCarriedModels(player)
	for _, model in ipairs(BaseService.TakeCarriedModels(player)) do
		model:Destroy()
	end
end

function BaseService.OnHeartbeat()
	for player, models in pairs(carriedModels) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root == nil then
			continue
		end
		local headTop = root.Position + Vector3.new(0, 3.4, 0)
		for index, model in ipairs(models) do
			if model.Parent ~= nil then
				local sway = math.sin(os.clock() * 2 + index) * 0.25
				model:PivotTo(CFrame.new(headTop + Vector3.new(sway, (index - 1) * 2.6, 0)))
			end
		end
	end
end

function BaseService.TeleportToGate(player)
	local base = BaseService.GetBaseOf(player)
	local character = player.Character
	if base == nil or character == nil or base.gate == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local gatePosition = base.gate.Position
	local beltSide = 1
	if gatePosition.Z > 0 then
		beltSide = -1
	end
	local spawnPosition = Vector3.new(gatePosition.X, gatePosition.Y - 2, gatePosition.Z + beltSide * 7)
	local lookTarget = Vector3.new(spawnPosition.X, spawnPosition.Y, 0)
	character:PivotTo(CFrame.new(spawnPosition, lookTarget))
end

function BaseService.OnPlayerRemoving(player)
	BaseService.DestroyCarriedModels(player)
	BaseService.ReleaseBase(player)
end

return BaseService
