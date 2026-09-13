-- Client entry point: boots every UI module.

local ResourceHUD = require(script.Parent:WaitForChild("ResourceHUD"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local ShipProgressUI = require(script.Parent:WaitForChild("ShipProgressUI"))
local WeaponController = require(script.Parent:WaitForChild("WeaponController"))

ResourceHUD.Init()
ShopUI.Init()
ShipProgressUI.Init()
WeaponController.Init()
