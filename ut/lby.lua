print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local plr = game.Players.LocalPlayer
plr.CharacterAdded:Wait()
local dun = false
local eve = false
local story = true
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plrAmount = #Players:GetPlayers()
local tele = workspace.Lobby.EventTeleporters:GetChildren()[2]["Cylinder.119"].VFX.hitbox
local dtele = workspace.Lobby.DungeonTeleporters.Teleporter2.Part
local ptyFind = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.HUD.Main2.PartyFinder
local remote = game.ReplicatedStorage.Modules.GlobalInit.RemoteEvents.PlayerActivateTowerAbility
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")

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

function autoclosesmtn()
    for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do

        if v.Name == "open/close detector" then
            if v.Parent.MainFrame.Visible == true then
                print(v)
                v.Parent.MainFrame.Visible = false
            end
        end
    end
end

spawn(function()
    print("cw")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lghft/i/refs/heads/main/ut/rdr.lua"))()

    local itaT = {}
    repeat wait() until me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text == "Wave 1/20"
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
    while true do
        remote:FireServer(itaT[1].Name)
        wait(0.9)
        remote2:FireServer(itaT[1].Name)
    end
end)

if plrAmount == 1 and game.Players.LocalPlayer and game.Workspace.Lobby then
    print("=1")
    if tele and eve == true then
        char:MoveTo(tele.Position)
    elseif dtele and dun == true then
        print("=1 dun")
        autoclosesmtn()
        char.PrimaryPart.CFrame = CFrame.new(-17.5384903, 10.3119678, 3940.68262, -0.766061664, 0, 0.642767608, 0, 1, 0, -0.642767608, 0, -0.766061664)
        --char:MoveTo()
        repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.Visible == true
        local hard = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.SelectedMap.Buttons.HardcoreButton
        firesignal(hard.Activated)
        wait(1)
        local strt = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.SelectedMap.Buttons.StartButton
        firesignal(strt.Activated)
        clickButton(strt)
    elseif story == true then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/couldntBeT/Main/refs/heads/main/Main.lua"))()
    end
elseif plrAmount > 1 and game.Workspace.Lobby then
    print(">1")
    if ptyFind.Visible == true then
        autoclosesmtn()
        --repeat
        wait(1)
        --[[
        local myServB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerButton.MyServerButton
        firesignal(myServB.Activated)
        wait(1)
        ]]
        local genServ = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.GenerateNewServerButton
        firesignal(genServ.Activated)
        wait(1)
        local jlservB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.Join
        firesignal(jlservB.Activated)
        wait()
        --until plrAmount == 1
    end
end
