-- Shop window listing every item from Config.Shop.Items with a Buy button.
-- Purchases go through the server via RemoteEvent; this UI only reflects
-- the result the server reports back, it never assumes success locally.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ShopUI = {}

local player = Players.LocalPlayer

local function createItemRow(parent, item, layoutOrder, remotes, feedbackLabel)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = string.format("  %s  (%d)", item.Name, item.Price)
	nameLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.35, 0, 0.8, 0)
	buyButton.Position = UDim2.new(0.63, 0, 0.1, 0)
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextScaled = true
	buyButton.Text = "Buy"
	buyButton.Parent = row

	buyButton.MouseButton1Click:Connect(function()
		feedbackLabel.Text = ""
		remotes.ShopPurchaseRequest:FireServer(item.Id)
	end)
end

function ShopUI.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local remotes = Remotes.Get()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 100, 0, 40)
	toggleButton.Position = UDim2.new(1, -120, 0, 20)
	toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.TextScaled = true
	toggleButton.Text = "Shop (B)"
	toggleButton.Parent = screenGui

	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Size = UDim2.new(0, 380, 0, 360)
	shopFrame.Position = UDim2.new(0.5, -190, 0.5, -180)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	shopFrame.Visible = false
	shopFrame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Text = "Mars Escape Shop"
	title.Parent = shopFrame

	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Size = UDim2.new(1, 0, 0, 24)
	feedbackLabel.Position = UDim2.new(0, 0, 1, -24)
	feedbackLabel.BackgroundTransparency = 1
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	feedbackLabel.Font = Enum.Font.Gotham
	feedbackLabel.TextScaled = true
	feedbackLabel.Text = ""
	feedbackLabel.Parent = shopFrame

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -20, 1, -80)
	listFrame.Position = UDim2.new(0, 10, 0, 40)
	listFrame.BackgroundTransparency = 1
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.ScrollBarThickness = 6
	listFrame.Parent = shopFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = listFrame

	for index, item in ipairs(Config.Shop.Items) do
		createItemRow(listFrame, item, index, remotes, feedbackLabel)
	end

	local function toggleShop()
		shopFrame.Visible = not shopFrame.Visible
	end

	toggleButton.MouseButton1Click:Connect(toggleShop)

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			toggleShop()
		end
	end)

	remotes.ShopPurchaseResult.OnClientEvent:Connect(function(result)
		if typeof(result) ~= "table" then
			return
		end
		feedbackLabel.TextColor3 = result.success and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(255, 120, 120)
		feedbackLabel.Text = result.message or ""
	end)
end

return ShopUI
