repeat wait(6) until game:IsLoaded()
wait(10)
local function executeScript()
    
    local plrs = game.Players:GetChildren()
    if #plrs == 1 then
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
end

-- Connect to character death event
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        -- Execute the script twice when player dies
        executeScript()
        executeScript()
    end)
end)

-- Initial execution
executeScript()
