local remote3 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower")

function spawnRageDrago() --2557
	local args = {
		[1] = tostring(game.Players.LocalPlayer.UserId .. ":" .. "214394"),
		[2] = Vector3.new(-18.642507553100586, 15.319265365600586, -814.8670654296875)
	}
	
	game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
end

function spawnBlueDrago()
	local args = {
		[1] = tostring(game.Players.LocalPlayer.UserId .. ":" .. "12900"),
		[2] = Vector3.new(-961.4971923828125, 10.068592071533203, 876.1779174804688)
	}
	
	game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
	
end

function spawnGreenDrago()
	local args = {
		[1] = tostring(game.Players.LocalPlayer.UserId .. ":" .. "48456"),
		[2] = Vector3.new(-961.4971923828125, 10.068592071533203, 876.1779174804688)
	}
	
	game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
	
end

function spawnGoldDrago()
	local args = {
		[1] = tostring(game.Players.LocalPlayer.UserId .. ":" .. "66955"),
		[2] = Vector3.new(-991.3324584960938, 8.822690963745117, 883.49072265625)
	}
	
	game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
	
end
function autoRage()
	local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		spawnRageDrago()
	end)
end

function autoBlueDrago()
	local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		spawnBlueDrago()
	end)
end

function autoGreenDrago()
	local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		spawnGreenDrago()
	end)
end

function autoGoldDrago()
	local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		spawnGoldDrago()
	end)
end

function useAbility(towerIndex)
	local towers = game.Workspace.EntityModels.Towers:GetChildren()
	local args = {
		[1] = tostring(towers[towerIndex])
	}

	game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerActivateTowerAbility"):FireServer(unpack(args))    
end

function autoAbility(towerIndex)
    local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		useAbility(towerIndex)
	end)
end
function clickButton(ClickOnPart)
    local vim = game:GetService("VirtualInputManager")
    local inset1, inset2 = game:GetService('GuiService'):GetGuiInset()
    local insetOffset = inset1 - inset2
    -- Replace "button location here" with the actual GUI object (e.g., a TextButton)
    local part = ClickOnPart
    -- Calculate the center of the GUI element
    local topLeft = part.AbsolutePosition + insetOffset
    local center = topLeft + (part.AbsoluteSize / 2)
    -- Adjust the click position if needed
    local X = center.X + 15
    local Y = center.Y
    -- Simulate a mouse click
    vim:SendMouseButtonEvent(X, Y, 0, true, game, 0) -- Mouse down
    task.wait(0.1) -- Small delay to simulate a real click
    vim:SendMouseButtonEvent(X, Y, 0, false, game, 0) -- Mouse up
    task.wait(1)
    print("Clicked: ", ClickOnPart)
end
function sjwpath()
    local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
    local paths = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.UpgradePathSelection.Frame
    if paths.Visible == true then
        clickButton(paths["2"])
        clickButton(paths["2"])
    end
    end)
end
function autoclosesmtn()
    local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
    for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do

        if v.Name == "open/close detector" then
            if v.Parent.MainFrame.Visible == true then
                print(v)
            clickButton(v)
            end
        end
    end
end)
end
function plrkck()
	local plrs = game.Players:GetChildren()
	if plrs > 1 then
		game:Shutdown()
	end
end
function startMatch()
    game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerVoteToStartMatch"):FireServer()
end

local wave = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.WaveIndex

repeat wait() until game:IsLoaded()
autoclosesmtn()
--[[
plrkck()
wait()
wait(4)
startMatch()

	repeat wait() until wave.Text == "Wave 1/20" 
	if wave.Text == "Wave 1/20" then
        sjwpath()
        autoclosesmtn()
        autoAbility(4)
        autoAbility(3)
    end
]]
repeat wait() until wave.Text == "Wave 11/20" 
	if wave.Text == "Wave 11/20" then
		game.Players.LocalPlayer.PlayerGui.MainGui.UpgradePathSelection.Frame.Visible = false
        autoRage()
        autoGreenDrago()
    end
	--[[
	repeat wait() until	game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true
	if game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true then
		game:Shutdown()
	end
	]]
