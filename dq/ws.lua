local plrs = game.Players:GetChildren()
if #plrs == 1 then
    getgenv().active = true
    while getgenv().active == true do
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local args = {
        {
            {
                ["\003"] = "vote",
                vote = true
            },
            "/"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
    game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("changeStartValue"):FireServer()
    wait()
    game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = 35
    end
end
