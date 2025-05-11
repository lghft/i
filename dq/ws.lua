repeat wait(6) until game:IsLoaded()

local plrs = game.Players:GetChildren()
if #plrs == 1 then
wait(4)
    print("LOADED?")
    getgenv().active = true
    while getgenv().active == true do
    --[[
    local args = {
        "405BF493-86B1-4B2D-A281-2BBFF16F6F13"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Explosive Mine"):WaitForChild("spellEvent"):FireServer(unpack(args))
    ]]

    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))

    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))

    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))

    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local args = {
        "80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"
    }
    game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild("Chain Lightning"):WaitForChild("abilityEvent"):FireServer(unpack(args))
    local bnsBut = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Bonus
    local rplyBut = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Retry
    if bnsBut.Visible == true and rplyBut.Visible == true then
    print("YeES")
        firesignal(lbyBut.Activated)
    elseif bnsBut.Visible == false and rplyBut.Visible == true then
        firesignal(rplyBut.Activated)
    end
    game:GetService("ReplicatedStorage"):WaitForChild("remotes"):WaitForChild("changeStartValue"):FireServer()
    wait()
    game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').WalkSpeed = 33
    end
end
