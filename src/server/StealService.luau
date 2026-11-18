-- StealService: stealing between players, plus the NPC thief. A player
-- can take a brainrot from another player's unlocked base; the victim's
-- lock blocks it. The thief bot ("Maling Karung") walks out of its den on
-- a timer, steals from a random unlocked base, and hauls the loot home, so
-- stealing is visible even with one player in the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local StealService = {}

local registry = nil
local thiefTimer = 0
local thiefRunning = false

local THIEF_DEN_POSITION = Vector3.new(120, 1.5, -56)
local THIEF_WALK_TIMEOUT = 20

function StealService.Init(services)
	registry = services
	thiefTimer = Config.THIEF_EVERY_SECONDS
end

local function findStealableSlot(thief, victim)
	local victimBase = registry.BaseService.GetBaseOf(victim)
	if victimBase == nil then
		return nil
	end
	local character = thief.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return nil
	end
	local state = registry.PlayerDataService.GetState(victim)
	if state == nil then
		return nil
	end
	for slotIndex = 1, Config.SLOTS_PER_BASE do
		if state.slots[slotIndex] ~= nil then
			local slotCFrame = registry.BaseService.GetSlotCFrame(victimBase, slotIndex)
			if slotCFrame ~= nil and (slotCFrame.Position - root.Position).Magnitude <= Config.INTERACT_RANGE + 4 then
				return slotIndex
			end
		end
	end
	return nil
end

function StealService.RequestSteal(player, victim)
	if victim == nil or victim == player or not victim:IsA("Player") then
		return
	end
	local state = registry.PlayerDataService.GetState(player)
	if state == nil then
		return
	end
	if registry.PlayerDataService.IsLocked(victim) then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Warung " .. victim.DisplayName .. " sedang dikunci!",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	if not registry.PlayerDataService.CanSteal(player) then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Tunggu sebentar sebelum mencuri lagi.",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	if #state.carrying >= registry.PlayerDataService.GetCarryCapacity(player) then
		Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
			kind = "banner",
			text = "Tanganmu penuh! Taruh dulu di warungmu.",
			color = { 1, 0.4, 0.4 },
		})
		return
	end
	local slotIndex = findStealableSlot(player, victim)
	if slotIndex == nil then
		return
	end
	local entry = registry.PlayerDataService.TakeFromSlot(victim, slotIndex)
	if entry == nil then
		return
	end
	local model = registry.BaseService.RemoveModelFromSlot(victim, slotIndex)
	if model == nil then
		model = registry.BrainrotFactory.BuildModel(entry.characterId, entry.mutation)
	end
	registry.PlayerDataService.AddCarried(player, entry)
	registry.BaseService.AttachCarried(player, model)
	registry.PlayerDataService.MarkSteal(player)
	local character = Catalog.GetCharacter(entry.characterId)
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(player, {
		kind = "banner",
		text = "Kamu mencuri " .. character.name .. " dari " .. victim.DisplayName .. "!",
		color = { 1, 0.8, 0.3 },
	})
	Remotes.GetRemote(Remotes.NOTIFY):FireClient(victim, {
		kind = "banner",
		text = player.DisplayName .. " mencuri " .. character.name .. " dari warungmu! Kunci warungmu (L)!",
		color = { 1, 0.4, 0.4 },
	})
end

local function buildThiefModel()
	local model = Instance.new("Model")
	model.Name = "MalingKarung"

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Color = Color3.new(0.2, 0.2, 0.25)
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.CanCollide = true
	rootPart.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(0, 0, 0)
	torso.Color = Color3.new(0.15, 0.15, 0.2)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.6, 1.4, 1.6)
	head.CFrame = CFrame.new(0, 1.7, 0)
	head.Color = Color3.new(0.9, 0.7, 0.5)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(1.7, 0.6, 0.4)
	mask.CFrame = CFrame.new(0, 1.8, 0.7)
	mask.Color = Color3.new(0.1, 0.1, 0.12)
	mask.Material = Enum.Material.SmoothPlastic
	mask.Parent = model

	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Shape = Enum.PartType.Ball
	sack.Size = Vector3.new(1.6, 1.6, 1.6)
	sack.CFrame = CFrame.new(0, 0.6, -1.1)
	sack.Color = Color3.new(0.6, 0.45, 0.25)
	sack.Material = Enum.Material.SmoothPlastic
	sack.Parent = model

	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= rootPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.Parent = part
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 12
	humanoid.Parent = model
	model.PrimaryPart = rootPart

	local gui = Instance.new("BillboardGui")
	gui.Name = "ThiefLabel"
	gui.Size = UDim2.new(0, 160, 0, 40)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = "MALING KARUNG!"
	label.TextSize = 20
	label.TextColor3 = Color3.new(1, 0.3, 0.3)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = gui
	gui.Parent = model

	return model
end

local function walkThiefTo(model, destination)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	if humanoid == nil or root == nil then
		return false
	end
	humanoid:MoveTo(destination)
	local waited = 0
	while waited < THIEF_WALK_TIMEOUT do
		if (root.Position - destination).Magnitude < 4 then
			return true
		end
		task.wait(0.5)
		waited = waited + 0.5
		if humanoid:GetState() == Enum.HumanoidStateType.Dead then
			return false
		end
	end
	model:PivotTo(CFrame.new(destination + Vector3.new(0, 2, 0)))
	return true
end

local function pickVictim()
	local candidates = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = registry.PlayerDataService.GetState(player)
		if state ~= nil and not registry.PlayerDataService.IsLocked(player) then
			local owned = 0
			for _ in pairs(state.slots) do
				owned = owned + 1
			end
			if owned > 0 then
				table.insert(candidates, player)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(#candidates)]
end

local function runThief()
	if thiefRunning then
		return
	end
	local victim = pickVictim()
	if victim == nil then
		return
	end
	thiefRunning = true
	local model = buildThiefModel()
	model:PivotTo(CFrame.new(THIEF_DEN_POSITION))
	model.Parent = Workspace

	Remotes.GetRemote(Remotes.NOTIFY):FireAllClients({
		kind = "banner",
		text = "Maling Karung keluar dari sarangnya! Kunci warungmu (L)!",
		color = { 1, 0.5, 0.3 },
	})

	local victimBase = registry.BaseService.GetBaseOf(victim)
	local reached = false
	local slotIndex = nil
	if victimBase ~= nil and victimBase.floor ~= nil then
		reached = walkThiefTo(model, victimBase.floor.Position + Vector3.new(0, 2, 0))
	end
	if reached and not registry.PlayerDataService.IsLocked(victim) then
		local state = registry.PlayerDataService.GetState(victim)
		if state ~= nil then
			for index = 1, Config.SLOTS_PER_BASE do
				if state.slots[index] ~= nil then
					slotIndex = index
					break
				end
			end
		end
	end
	if slotIndex ~= nil then
		local entry = registry.PlayerDataService.TakeFromSlot(victim, slotIndex)
		local stolen = registry.BaseService.RemoveModelFromSlot(victim, slotIndex)
		if entry ~= nil and stolen ~= nil then
			local character = Catalog.GetCharacter(entry.characterId)
			registry.BrainrotFactory.WeldModelToPart(stolen, model.PrimaryPart)
			stolen.Parent = model
			Remotes.GetRemote(Remotes.NOTIFY):FireClient(victim, {
				kind = "banner",
				text = "Maling Karung mencuri " .. character.name .. " dari warungmu!",
				color = { 1, 0.4, 0.4 },
			})
		end
	end
	walkThiefTo(model, THIEF_DEN_POSITION)
	model:Destroy()
	thiefRunning = false
end

function StealService.OnSecond()
	thiefTimer = thiefTimer - 1
	if thiefTimer <= 0 then
		thiefTimer = Config.THIEF_EVERY_SECONDS
		task.spawn(runThief)
	end
end

return StealService
