repeat task.wait() until game:IsLoaded()

if game.PlaceId == 12886143095 or game.PlaceId == 18583778121 then
    local args = {
        [1] = "GetGlobalData"
    }
    game:GetService("ReplicatedStorage").Remotes.InfiniteCastleManager:FireServer(unpack(args))

    task.wait(0.4)

    local args = {
        [1] = "GetData"
    }
    game:GetService("ReplicatedStorage").Remotes.InfiniteCastleManager:FireServer(unpack(args))

    task.wait(1)

    local args = {
        [1] = "Play",
        [2] = 0,
        [3] = "True"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("InfiniteCastleManager"):FireServer(unpack(args))
else
    task.wait(3)
    local unit = game:GetService("Players")[game.Players.LocalPlayer.Name].Slots.Slot2.Value
    local args = {
        [1] = unit,
        [2] = CFrame.new(-164.9412384033203, 197.93942260742188, 15.210136413574219) * CFrame.Angles(-0, 0, -0)
    }
    game:GetService("ReplicatedStorage").Remotes.PlaceTower:FireServer(unpack(args))

    while not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") do wait() end wait() game:GetService("ReplicatedStorage").Remotes.TeleportBack:FireServer()
end
