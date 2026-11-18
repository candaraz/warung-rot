-- EffectsController: juice. Floating "+$" numbers, screen shake, the
-- rarity reveal flash, and sounds. Sounds use only the client-shipped
-- rbxasset:// clips, wrapped in pcall, so a failed asset never breaks the
-- game and no private audio is needed.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local EffectsController = {}

local player = Players.LocalPlayer
local playerGui = nil
local floatLayer = nil
local revealFrame = nil
local revealLabel = nil
local shakeUntil = 0
local shakePower = 0

local SOUNDS = {
	buy = "rbxasset://sounds/electronicpingshort.wav",
	click = "rbxasset://sounds/button.wav",
	coin = "rbxasset://sounds/electronicpingshort.wav",
	siren = "rbxasset://sounds/electronicpingshort.wav",
	splash = "rbxasset://sounds/button.wav",
}

function EffectsController.PlaySound(name, playbackSpeed)
	local soundId = SOUNDS[name]
	if soundId == nil then
		return
	end
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		if playbackSpeed ~= nil then
			sound.PlaybackSpeed = playbackSpeed
		end
		sound.Parent = SoundService
		sound:Play()
		Debris:AddItem(sound, 3)
	end)
end

local function makeFloatLabel(text, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(220, 40)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = 30
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	return label
end

function EffectsController.FloatText(text, color)
	if floatLayer == nil then
		return
	end
	local label = makeFloatLabel(text, color or Color3.new(0.6, 1, 0.6))
	local xOffset = math.random(-60, 60)
	label.Position = UDim2.new(0.5, xOffset - 110, 0.62, 0)
	label.Parent = floatLayer
	local tween = TweenService:Create(label, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, xOffset - 110, 0.5, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

function EffectsController.Shake(power, duration)
	shakePower = math.max(shakePower, power)
	shakeUntil = os.clock() + duration
end

function EffectsController.Reveal(text, color)
	if revealFrame == nil or revealLabel == nil then
		return
	end
	revealLabel.Text = text
	revealLabel.TextColor3 = color
	revealFrame.BackgroundTransparency = 0.35
	revealFrame.Visible = true
	revealLabel.TextTransparency = 0
	EffectsController.PlaySound("coin", 1.3)
	local tween = TweenService:Create(revealFrame, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	local labelTween = TweenService:Create(revealLabel, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
	})
	tween:Play()
	labelTween:Play()
	labelTween.Completed:Connect(function()
		revealFrame.Visible = false
	end)
end

function EffectsController.Siren(seconds)
	task.spawn(function()
		local endAt = os.clock() + seconds
		local high = true
		while os.clock() < endAt do
			EffectsController.PlaySound("siren", high and 1.4 or 0.9)
			high = not high
			task.wait(0.55)
		end
	end)
end

function EffectsController.Init(gui)
	playerGui = gui
	floatLayer = Instance.new("Frame")
	floatLayer.Name = "FloatLayer"
	floatLayer.BackgroundTransparency = 1
	floatLayer.Size = UDim2.fromScale(1, 1)
	floatLayer.Parent = gui

	revealFrame = Instance.new("Frame")
	revealFrame.Name = "RevealFlash"
	revealFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	revealFrame.Position = UDim2.fromScale(0.5, 0.38)
	revealFrame.Size = UDim2.fromOffset(520, 90)
	revealFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	revealFrame.BackgroundTransparency = 1
	revealFrame.BorderSizePixel = 0
	revealFrame.Visible = false
	revealFrame.Parent = gui

	revealLabel = Instance.new("TextLabel")
	revealLabel.BackgroundTransparency = 1
	revealLabel.Size = UDim2.fromScale(1, 1)
	revealLabel.Font = Enum.Font.GothamBlack
	revealLabel.Text = ""
	revealLabel.TextSize = 40
	revealLabel.TextColor3 = Color3.new(1, 1, 1)
	revealLabel.TextStrokeTransparency = 0.1
	revealLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	revealLabel.Parent = revealFrame

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now >= shakeUntil then
			shakePower = 0
			return
		end
		local camera = Workspace.CurrentCamera
		if camera == nil then
			return
		end
		local remaining = (shakeUntil - now)
		local strength = shakePower * math.min(1, remaining)
		local offset = Vector3.new(
			(math.random() - 0.5) * strength,
			(math.random() - 0.5) * strength,
			0
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
	end)
end

return EffectsController
