repeat wait(6) until game:IsLoaded()
local plrHud = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.PlayerStatus
plrHud.Visible = false
local plrHud2 = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Mobile.PlayerStatus
plrHud2.Visible = false
local plrTag = game.Players.LocalPlayer.Character.Head.playerNameplate
plrTag.Enabled = false
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 10 -- default 10 second timeout
    local startTime = os.time()
    local child
    
    while not child and os.time() - startTime < timeout do
        child = parent:FindFirstChild(childName)
        if not child then
            wait()
        end
    end
    
    if not child then
        error("Timed out waiting for child: " .. childName)
    end
    
    return child
end

local plrs = game.Players:GetChildren()
if #plrs == 1 then
    wait(4)
    print("LOADED?")

    spawn(function()
                	while true do
                local backpack = game:GetService("Players").LocalPlayer:WaitForChild("Backpack", 10)
                local chainLightning = safeWaitForChild(backpack, "Chain Lightning", 10)
                local abilityEvent = safeWaitForChild(chainLightning, "abilityEvent", 10)
                local args1 = {"80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"}
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        wait()
                	end
                end)
    spawn(function()
                	while true do
                local backpack = game:GetService("Players").LocalPlayer:WaitForChild("Backpack", 10)
                local chainLightning = safeWaitForChild(backpack, "Chain Lightning", 10)
                local abilityEvent = safeWaitForChild(chainLightning, "abilityEvent", 10)
                local args1 = {"80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"}
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        wait()
                	end
                end)
     spawn(function()
                	while true do
                local backpack = game:GetService("Players").LocalPlayer:WaitForChild("Backpack", 10)
                local chainLightning = safeWaitForChild(backpack, "Chain Lightning", 10)
                local abilityEvent = safeWaitForChild(chainLightning, "abilityEvent", 10)
                local args1 = {"80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"}
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        abilityEvent:FireServer(unpack(args1))
                        wait(0.1)
                	end
                end)
    getgenv().active = true
    while getgenv().active == true do
        local success, err = pcall(function()
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
            -- Handle retry button
            local rplyBut = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Retry
            firesignal(rplyBut.Activated)
            local startMenu = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Main.StartButton
            startMenu.Visible = true
            local startMenu2 = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Mobile.StartButton
            startMenu2.Visible = true
            -- Change start value
            local changeStartValue = game:GetService("ReplicatedStorage"):WaitForChild("remotes", 10):WaitForChild("changeStartValue", 10)
            changeStartValue:FireServer()
            
            firesignal(startMenu.Activated)
            firesignal(startMenu2.Activated)
            -- Set walk speed
            local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid.WalkSpeed = 33
            end
        end)
        
        wait()
    end
end
