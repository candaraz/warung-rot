-- CameraAndInput: key bindings and the interaction prompt. Keys are bound
-- with ContextActionService (never an InputBegan handler that drops
-- game-processed arrow keys), which also gives touch buttons on mobile.
-- Every frame it works out the nearest interactable -- a belt brainrot to
-- buy, the player's own base to place on, or a rival's slot to steal from
-- -- and shows the matching prompt. Pressing E sends the matching request;
-- the server validates everything.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local HudController = require(PlayerScripts:WaitForChild("HudController"))
local ShopController = require(PlayerScripts:WaitForChild("ShopController"))

local CameraAndInput = {}

local player = Players.LocalPlayer
local latestSnapshot = nil
local currentContext = nil

local function getRoot()
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function findOwnBase()
	local basesFolder = Workspace:FindFirstChild("Bases")
	if basesFolder == nil then
		return nil
	end
	for _, folder in ipairs(basesFolder:GetChildren()) do
		if folder:GetAttribute("OwnerUserId") == player.UserId then
			return folder
		end
	end
	return nil
end

local function findNearestBeltItem(root)
	local beltFolder = Workspace:FindFirstChild("BeltModels")
	if beltFolder == nil then
		return nil
	end
	local nearest = nil
	local nearestDistance = Config.INTERACT_RANGE
	for _, model in ipairs(beltFolder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart ~= nil then
			local distance = (model.PrimaryPart.Position - root.Position).Magnitude
			if distance <= nearestDistance then
				nearest = model
				nearestDistance = distance
			end
		end
	end
	return nearest
end

local function findStealTarget(root)
	local basesFolder = Workspace:FindFirstChild("Bases")
	if basesFolder == nil then
		return nil, nil
	end
	for _, folder in ipairs(basesFolder:GetChildren()) do
		local ownerId = folder:GetAttribute("OwnerUserId")
		if ownerId ~= nil and ownerId ~= 0 and ownerId ~= player.UserId then
			local slots = folder:FindFirstChild("Slots")
			if slots ~= nil then
				for _, pad in ipairs(slots:GetChildren()) do
					if pad:IsA("BasePart") and pad:FindFirstChildOfClass("Model") ~= nil then
						if (pad.Position - root.Position).Magnitude <= Config.INTERACT_RANGE + 4 then
							local victim = Players:GetPlayerByUserId(ownerId)
							if victim ~= nil then
								return victim, pad
							end
						end
					end
				end
			end
		end
	end
	return nil, nil
end

local function computeContext()
	local root = getRoot()
	if root == nil then
		return nil
	end
	local beltModel = findNearestBeltItem(root)
	if beltModel ~= nil then
		local characterId = beltModel:GetAttribute("CharacterId")
		local character = characterId and Catalog.GetCharacter(characterId)
		if character ~= nil then
			return {
				kind = "buy",
				text = "[E] Beli " .. character.name .. " - " .. Catalog.FormatMoney(character.price),
			}
		end
	end
	if latestSnapshot ~= nil and #latestSnapshot.carrying > 0 then
		local ownBase = findOwnBase()
		if ownBase ~= nil then
			local floor = ownBase:FindFirstChild("Floor")
			if floor ~= nil and (floor.Position - root.Position).Magnitude <= 30 then
				return {
					kind = "place",
					text = "[E] Taruh " .. latestSnapshot.carrying[1].name .. " di warungmu",
				}
			end
		end
	end
	local victim = findStealTarget(root)
	if victim ~= nil then
		return {
			kind = "steal",
			victim = victim,
			text = "[E] Curi dari warung " .. victim.DisplayName,
		}
	end
	return nil
end

local function onInteract(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end
	local context = currentContext
	if context == nil then
		return
	end
	if context.kind == "buy" then
		Remotes.GetRemote(Remotes.REQUEST_BUY):FireServer()
	elseif context.kind == "place" then
		Remotes.GetRemote(Remotes.REQUEST_PLACE):FireServer()
	elseif context.kind == "steal" then
		Remotes.GetRemote(Remotes.REQUEST_STEAL):FireServer(context.victim)
	end
end

local function onLock(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		Remotes.GetRemote(Remotes.REQUEST_LOCK):FireServer()
	end
end

local function onCast(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ShopController.ToggleCast()
	end
end

local function onShop(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ShopController.ToggleShop()
	end
end

local function onRebirth(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ShopController.RequestRebirth()
	end
end

function CameraAndInput.ApplySnapshot(snapshot)
	latestSnapshot = snapshot
end

function CameraAndInput.Init()
	ContextActionService:BindAction("WarungInteract", onInteract, true, Enum.KeyCode.E)
	ContextActionService:BindAction("WarungLock", onLock, true, Enum.KeyCode.L)
	ContextActionService:BindAction("WarungCast", onCast, true, Enum.KeyCode.C)
	ContextActionService:BindAction("WarungShop", onShop, true, Enum.KeyCode.U)
	ContextActionService:BindAction("WarungRebirth", onRebirth, true, Enum.KeyCode.R)
	ContextActionService:SetTitle("WarungInteract", "Ambil")
	ContextActionService:SetTitle("WarungLock", "Kunci")

	RunService.Heartbeat:Connect(function()
		currentContext = computeContext()
		if currentContext ~= nil then
			HudController.SetPrompt(currentContext.text)
		else
			HudController.SetPrompt("")
		end
		HudController.OnHeartbeat()
	end)
end

return CameraAndInput
