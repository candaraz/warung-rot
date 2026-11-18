-- ShopController: the upgrade shop, the rebirth button, and the cast
-- list. The shop panel lists the three upgrades with their level and next
-- price; the cast panel lists every brainrot with its rarity colour, price
-- and money per second. Buttons only send validated requests; the server
-- decides whether a purchase goes through.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Rarities = require(Shared:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopController = {}

local player = Players.LocalPlayer
local shopPanel = nil
local castPanel = nil
local upgradeRows = {}
local rebirthButton = nil
local rebirthLabel = nil
local latestSnapshot = nil

local UPGRADE_KEYS = { "speed", "carry", "lock" }

local function makeButton(parent, text, position, size, textSize)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.new(0.15, 0.45, 0.2)
	button.BorderSizePixel = 0
	button.Position = position
	button.Size = size
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextSize = textSize
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function makeLabel(parent, text, position, size, textSize, color, align)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextXAlignment = align or Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function buildShopPanel(gui)
	shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
	shopPanel.BackgroundTransparency = 0.1
	shopPanel.BorderSizePixel = 0
	shopPanel.AnchorPoint = Vector2.new(1, 0.5)
	shopPanel.Position = UDim2.new(1, -16, 0.5, 0)
	shopPanel.Size = UDim2.fromOffset(360, 430)
	shopPanel.Visible = false
	shopPanel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = shopPanel

	makeLabel(shopPanel, "WARUNG UPGRADES", UDim2.new(0, 20, 0, 14), UDim2.fromOffset(320, 32), 26, Color3.new(1, 0.85, 0.3), Enum.TextXAlignment.Center)

	for index, key in ipairs(UPGRADE_KEYS) do
		local spec = Config.UPGRADES[key]
		local top = 60 + (index - 1) * 88
		makeLabel(shopPanel, spec.label, UDim2.new(0, 20, 0, top), UDim2.fromOffset(220, 28), 22)
		makeLabel(shopPanel, spec.detail, UDim2.new(0, 20, 0, top + 28), UDim2.fromOffset(220, 22), 17, Color3.new(0.8, 0.8, 0.8))
		local levelLabel = makeLabel(shopPanel, "Lv 0", UDim2.new(0, 20, 0, top + 50), UDim2.fromOffset(100, 24), 20, Color3.new(0.6, 1, 0.6))
		local button = makeButton(shopPanel, "Beli", UDim2.new(0, 240, 0, top + 8), UDim2.fromOffset(100, 48), 22)
		button.MouseButton1Click:Connect(function()
			Remotes.GetRemote(Remotes.REQUEST_UPGRADE):FireServer(key)
		end)
		upgradeRows[key] = { levelLabel = levelLabel, button = button }
	end

	rebirthLabel = makeLabel(shopPanel, "", UDim2.new(0, 20, 0, 326), UDim2.fromOffset(320, 26), 19, Color3.new(1, 0.85, 0.3), Enum.TextXAlignment.Center)
	rebirthButton = makeButton(shopPanel, "REBIRTH", UDim2.new(0, 60, 0, 356), UDim2.fromOffset(240, 52), 26)
	rebirthButton.BackgroundColor3 = Color3.new(0.6, 0.25, 0.7)
	rebirthButton.MouseButton1Click:Connect(function()
		Remotes.GetRemote(Remotes.REQUEST_REBIRTH):FireServer()
	end)
end

local function buildCastPanel(gui)
	castPanel = Instance.new("Frame")
	castPanel.Name = "CastPanel"
	castPanel.BackgroundColor3 = Color3.new(0.08, 0.08, 0.1)
	castPanel.BackgroundTransparency = 0.1
	castPanel.BorderSizePixel = 0
	castPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	castPanel.Position = UDim2.fromScale(0.5, 0.5)
	castPanel.Size = UDim2.fromOffset(560, 470)
	castPanel.Visible = false
	castPanel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = castPanel

	makeLabel(castPanel, "DAFTAR BRAINROT WARUNG ROT", UDim2.new(0, 0, 0, 12), UDim2.new(1, 0, 0, 32), 26, Color3.new(1, 0.85, 0.3), Enum.TextXAlignment.Center)

	local scroller = Instance.new("ScrollingFrame")
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.new(0, 16, 0, 54)
	scroller.Size = UDim2.new(1, -32, 1, -70)
	scroller.CanvasSize = UDim2.new(0, 0, 0, #Catalog.CHARACTERS * 34)
	scroller.ScrollBarThickness = 6
	scroller.Parent = castPanel

	for index, character in ipairs(Catalog.CHARACTERS) do
		local top = (index - 1) * 34
		makeLabel(scroller, character.name, UDim2.new(0, 8, 0, top), UDim2.fromOffset(250, 30), 20)
		makeLabel(scroller, Rarities.GetName(character.rarity), UDim2.new(0, 262, 0, top), UDim2.fromOffset(110, 30), 20, Rarities.GetColor(character.rarity))
		makeLabel(scroller, Catalog.FormatMoney(character.price) .. "  |  " .. Catalog.FormatMoney(character.income) .. "/s", UDim2.new(0, 376, 0, top), UDim2.fromOffset(150, 30), 19, Color3.new(0.6, 1, 0.6), Enum.TextXAlignment.Right)
	end
end

function ShopController.Init(gui)
	buildShopPanel(gui)
	buildCastPanel(gui)
end

function ShopController.ToggleShop()
	shopPanel.Visible = not shopPanel.Visible
	if shopPanel.Visible then
		castPanel.Visible = false
	end
end

function ShopController.ToggleCast()
	castPanel.Visible = not castPanel.Visible
	if castPanel.Visible then
		shopPanel.Visible = false
	end
end

function ShopController.RequestRebirth()
	Remotes.GetRemote(Remotes.REQUEST_REBIRTH):FireServer()
end

function ShopController.ApplySnapshot(snapshot)
	latestSnapshot = snapshot
	for key, row in pairs(upgradeRows) do
		local spec = Config.UPGRADES[key]
		local level = snapshot.upgrades[key] or 0
		row.levelLabel.Text = "Lv " .. tostring(level) .. " / " .. tostring(#spec.costs)
		if level >= #spec.costs then
			row.button.Text = "MAX"
		else
			row.button.Text = Catalog.FormatMoney(spec.costs[level + 1])
		end
	end
	local nextRebirth = Config.REBIRTHS[snapshot.rebirthLevel + 1]
	if nextRebirth == nil then
		rebirthLabel.Text = "Rebirth maksimal tercapai!"
		rebirthButton.Text = "MAX"
	else
		rebirthLabel.Text = "Butuh " .. Catalog.FormatMoney(nextRebirth.cash) .. " + brainrot "
			.. Rarities.GetName(nextRebirth.needRarity) .. "  ->  x" .. tostring(nextRebirth.multiplier)
	end
end

return ShopController
