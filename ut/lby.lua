print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plrAmount = #Players:GetPlayers()
local tele = workspace.Lobby.EventTeleporters:GetChildren()[2]["Cylinder.119"].VFX.hitbox
local ptyFind = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.HUD.Main2.PartyFinder

if plrAmount == 1 and game.Players.LocalPlayer and game.Workspace.Lobby then
    if tele then
        char:MoveTo(tele.Position)
    end
end

spawn(function()
    while true do
        if plrAmount > 1 and game.Workspace.Lobby then
            if ptyFind.Visible == true then
                wait(1)
                wait(1)
                local genServ = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.GenerateNewServerButton
                firesignal(genServ.Activated)
                wait(1)
                local jlservB = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.PartyFinder.Main.MyServerPanel.Main.Content.LastSavedServer.Panel.Join
                firesignal(jlservB.Activated)
                wait(1)
            end
        end
    end
end)
