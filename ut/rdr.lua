repeat wait(4) until game:IsLoaded() print("DRAG LOAD")
local itaT = {}
local starT = {}
local auto = true
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")

function spawnRageDrago() --2557
	local args = {
		[1] = tostring(game.Players.LocalPlayer.UserId .. ":" .. "214394"),
		[2] = Vector3.new(-18.642507553100586, 15.319265365600586, -814.8670654296875)
	}
	
	game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
end

function autoRage()
   while auto == true do
	spawnRageDrago()
	wait(1)
   end
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
function match()
    local wave = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.WaveIndex
    auto = true
    print("drago script")
    repeat wait() until wave.Text == "Wave 12/20" 
        if wave.Text == "Wave 12/20" then
            print("12/20")
            wait()
            autoRage()
	    print("Starkk")
		--[[
            repeat for _,v in pairs(game:GetService("Workspace").EntityModels.Towers:GetChildren()) do
                    for i,v in pairs(v:GetChildren()) do
                        if v.Name == "Head" then
                            for i,v in pairs(v:GetChildren()) do
                                if v.Name == "starrk" then
                                    table.insert(starT, v.Parent)
                                    --print(v.Parent)
                                end
                            end
                        end
                    end
                end
                wait()
            until #starT == 1

            local args = {
                [1] = tostring(starT[1].Name),
                [2] = "Strong"
            }
            
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerSetTowerTargetMode"):FireServer(unpack(args))
		]]
        print("ita")
            repeat for _,v in pairs(game:GetService("Workspace").EntityModels.Towers:GetChildren()) do
                    for i,v in pairs(v:GetChildren()) do
                        if v.Name == "Hair" then
                            table.insert(itaT, v.Parent)
                            --print(v.Parent)
                        end
                    end
                end
                wait()
            until #itaT == 1

        local args = {
            [1] = tostring(itaT[1].Name)
        }
        
        game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerToggleAutoAbility"):FireServer(unpack(args))
        wait(1)
        remote2:FireServer(itaT[1].Name)
        wait(1)
    end
	repeat wait() until wave.Text == "Wave 20/20" 
	if wave.Text == "Wave 20/20" then
		print("20/20")
	    auto = false
            for k in pairs (itaT) do
                itaT[k] = nil
            end
            for k in pairs (starT) do
                starT[k] = nil
            end
	end
	 repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true
        if game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true then
            --game:Shutdown()
            print("GameEnd")
            wait()
            match()
        end
end
match()
