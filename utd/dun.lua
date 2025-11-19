repeat wait(4) until game:IsLoaded()
local bulmaT = {}
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")
local wave = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.WaveIndex
local twrs = workspace.EntityModels.Towers
local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
local map = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.MapName
local itemDrops = game:GetService("Players").LocalPlayer.PlayerGui.MessagesGui.FullScreen
getgenv().Place = true
getgenv().Active = true
function startMatch()
    game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerVoteToStartMatch"):FireServer()
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

function autoUpgradeTower(unitFromTable)
    spawn(function()
        while task.wait(1) do
            remote2:FireServer(unitFromTable.Name)
        end
    end)
end

function dungeonWave()
    getgenv().Place = true
    getgenv().Active = true
    repeat wait() until wave.Text == "Wave 1/10" --1/20--1/10
	if wave.Text == "Wave 1/10" then

        spawn(function()
        while getgenv().Place = true do
        task.wait(1)
        local args = {
            "1823601662:230016", --dante
            vector.create(-181.26632690429688, -296.7763671875, -405.550048828125),
            0
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))

        local args = {
            "1823601662:54936", -- bulma
            vector.create(-209.62869262695312, -296.77911376953125, -400.42059326171875),
            0
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end    
        end)
        repeat wait() until #workspace.EntityModels.Towers:GetChildren() == 2
        autoUpgradeTower(twrs:GetChildren()[2])
        --place todo bulma bb 
        --max bulma
    end
    repeat wait() until wave.Text == "Wave 2/10"
    if wave.Text == "Wave 2/10" then
        spawn(function()
        while getgenv().Place = true do
        task.wait(1)
        local args = {
            "1823601662:129038", -- todo
            vector.create(-187.9666290283203, -296.7759094238281, -406.39569091796875),
            0
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))

        local args = {
            "1823601662:228582",
            vector.create(-146.5491943359375, -296.7837829589844, -391.651123046875), -- ulq
            0
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
       local args = {
            "1823601662:13421", --bb  1823601662:229949--ichi
            vector.create(-172.46365356445312, -296.7765197753906, -405.2992858886719),
            0
        }
        game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        --place ulq ichi
        --max ulq
        end    
        end)
    end
    repeat wait() until wave.Text == "Wave 4/10"
    if wave.Text == "Wave 4/10" then
        repeat wait() until #workspace.EntityModels.Towers:GetChildren() == 5
        for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
            if v.Name == "Spear" then
                autoUpgradeTower(v.Parent)
            end
        end
    end
    repeat wait() until wave.Text == "Wave 6/10" 
    if wave.Text == "Wave 6/10" then
        autoUpgradeTower(twrs:GetChildren()[3])
        autoUpgradeTower(twrs:GetChildren()[4])
    end
    repeat wait() until wave.Text == "Wave 9/10" 
	if wave.Text == "Wave 9/10" then
        --autoRage()
        clickButton(game:GetService("Players").LocalPlayer.PlayerGui.MainGui.HUD.Toolbox.Hotbar["1823601662:214394"].ToggleAuto.Button)
    end
    getgenv().Place = false
    repeat wait() until endGui.Visible == true
    task.wait(1)
    itemDrops.Visible = false
    endGui.Visible = true
    getgenv().Active = false
    if endGui.Visible == true then
        if itemDrops.Visible == true then
            clickButton(game:GetService("Players").LocalPlayer.PlayerGui.MessagesGui.FullScreen.Close.Button)
        end
        wait(1)
        if map.Text == "Forsaken Prison - Floor 10" then
            spawn(function()
                while getgenv().Active == false do
                task.wait(1)
                    --clickButton(game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Lobby)
                    game:GetService("ReplicatedStorage")
                    :WaitForChild("Modules")
                    :WaitForChild("GlobalInit")
                    :WaitForChild("RemoteEvents")
                    :WaitForChild("PlayerVoteReturn"):FireServer()
                end
            end)
        else
            print("Next")
            spawn(function()
                while getgenv().Active == false do
                task.wait(1)
                    --clickButton(game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Continue)
                    game:GetService("ReplicatedStorage")
                    :WaitForChild("Modules")
                    :WaitForChild("GlobalInit")
                    :WaitForChild("RemoteEvents")
                    :WaitForChild("PlayerVoteReplay"):FireServer()
                end
            end)
        end
    end
end
startMatch()
dungeonWave()
print("dungeon auto Start")
