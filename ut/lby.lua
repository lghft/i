print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local dun = true
local eve = false
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plrAmount = #Players:GetPlayers()
local tele = workspace.Lobby.EventTeleporters:GetChildren()[2]["Cylinder.119"].VFX.hitbox
local dtele = workspace.Lobby.DungeonTeleporters.Teleporter2.Part
local ptyFind = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.HUD.Main2.PartyFinder

if plrAmount == 1 and game.Players.LocalPlayer and game.Workspace.Lobby then
    print("=1")
    if tele and eve == true then
        char:MoveTo(tele.Position)
    elseif dtele and dun == true then
        print("=1 dun")
        char.PrimaryPart.CFrame = CFrame.new(-17.5384903, 10.3119678, 3940.68262, -0.766061664, 0, 0.642767608, 0, 1, 0, -0.642767608, 0, -0.766061664)
        --char:MoveTo()
        repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.Visible == true
        local hard = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.SelectedMap.Buttons.HardcoreButton
        firesignal(hard.Activated)
        wait(1)
        local strt = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.FloorSelection.SelectedMap.Buttons.StartButton
        firesignal(strt.Activated)
    end
elseif plrAmount > 1 and game.Players.LocalPlayer and not game.Workspace.Lobby then
    game:Shutdown()
elseif plrAmount > 1 and game.Workspace.Lobby then
    print(">1")
    if ptyFind.Visible == true then
        --repeat 
        firesignal(ptyFind.Activated)
        local genServ = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.GenerateNewServerButton
        firesignal(genServ.Activated)
        wait(1)
        local jlservB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.Join
        firesignal(jlservB.Activated)
        wait()
        --until plrAmount == 1
    end
end
