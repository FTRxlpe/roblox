-- Shared ship-building progress bar, updated in real time from the server,
-- plus a victory banner shown when the ship is complete.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ShipProgressUI = {}

local player = Players.LocalPlayer

function ShipProgressUI.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local remotes = Remotes.Get()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShipProgressUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local barBackground = Instance.new("Frame")
	barBackground.Size = UDim2.new(0, 400, 0, 28)
	barBackground.Position = UDim2.new(0.5, -200, 0, 20)
	barBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	barBackground.Parent = screenGui

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(90, 170, 255)
	barFill.Parent = barBackground

	local barLabel = Instance.new("TextLabel")
	barLabel.Size = UDim2.new(1, 0, 1, 0)
	barLabel.BackgroundTransparency = 1
	barLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	barLabel.Font = Enum.Font.GothamBold
	barLabel.TextScaled = true
	barLabel.Text = string.format("Ship: 0 / %d", Config.Ship.MaterialsRequired)
	barLabel.Parent = barBackground

	local victoryLabel = Instance.new("TextLabel")
	victoryLabel.Size = UDim2.new(1, 0, 0, 80)
	victoryLabel.Position = UDim2.new(0, 0, 0.4, 0)
	victoryLabel.BackgroundTransparency = 1
	victoryLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	victoryLabel.Font = Enum.Font.GothamBlack
	victoryLabel.TextScaled = true
	victoryLabel.Visible = false
	victoryLabel.Text = "SHIP READY FOR LAUNCH!"
	victoryLabel.Parent = screenGui

	remotes.ShipProgressUpdated.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then
			return
		end

		local current = data.current or 0
		local required = data.required or Config.Ship.MaterialsRequired
		local ratio = math.clamp(current / math.max(required, 1), 0, 1)

		TweenService:Create(barFill, TweenInfo.new(0.3), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		barLabel.Text = string.format("Ship: %d / %d", current, required)
	end)

	remotes.ShipVictory.OnClientEvent:Connect(function()
		victoryLabel.Visible = true
	end)
end

return ShipProgressUI
