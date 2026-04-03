getgenv().TDX_Config = getgenv().TDX_Config or {}
local loadout = tostring(getgenv().TDX_Config.loadout or "0")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local screen = player:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("LoadoutSelectionScreen")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LoadoutSelectionChanged")

local called = false

local function checkLoadoutSelected()
	if loadout == "0" then
		local selected = screen:WaitForChild("Top"):WaitForChild("Skip"):WaitForChild("Selected")
		return selected.Visible
	else
		local cardName = "LoadoutCard" .. loadout
		local card = screen:WaitForChild("Bottom"):WaitForChild("Inner"):WaitForChild(cardName)
		return card:WaitForChild("BackgroundSelected").Visible
	end
end

local function trySelectLoadout()
	if called then return end
	called = true

	local args = { tonumber(loadout) }
	remote:FireServer(unpack(args))

	-- chờ để kiểm tra xem đã chọn đúng loadout chưa
	task.spawn(function()
		for i = 1, 60 do -- chờ tối đa 3 giây (60 lần, mỗi lần 0.05s)
			if checkLoadoutSelected() then break end
			task.wait(0.05)
		end
	end)
end

screen:GetPropertyChangedSignal("Visible"):Connect(function()
	if screen.Visible then
		trySelectLoadout()
	end
end)

-- Nếu màn hình đã hiện sẵn
if screen.Visible then
	trySelectLoadout()
end
