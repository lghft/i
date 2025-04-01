repeat wait(5) until game:IsLoaded()
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plrAmount = #Players:GetPlayers()
local tele = workspace.Lobby.EventTeleporters:GetChildren()[2]["Cylinder.119"].VFX.hitbox
local ptyFind = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.HUD.Main2.PartyFinder

if plrAmount == 1 and game.Players.LocalPlayer and game.Workspace.Lobby then
    if tele then
        char:MoveTo(tele.Position)
    end
elseif plrAmount > 1 and game.Workspace.Lobby then
    if ptyFind.Visible == true then
        firesignal(ptyFind.Frame.Activated)
        wait(1)
        local myServB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerButton.MyServerButton 
        firesignal(myServB.Activated)
        wait(1)
        local genServ = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.GenerateNewServerButton
        firesignal(genServ.Activated)
        wait(1)
        local jlservB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.Join
        firesignal(jlservB.Activated)
        wait(1)
    end
end
