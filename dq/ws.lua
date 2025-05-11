repeat wait(6) until game:IsLoaded()

local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 10 -- default 10 second timeout
    local startTime = os.time()
    local child
    
    while not child and os.time() - startTime < timeout do
        child = parent:FindFirstChild(childName)
        if not child then
            wait(1)
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
    
    getgenv().active = true
    while getgenv().active == true do
        local success, err = pcall(function()
            local backpack = game:GetService("Players").LocalPlayer:WaitForChild("Backpack", 10)
            local chainLightning = safeWaitForChild(backpack, "Chain Lightning", 10)
            local abilityEvent = safeWaitForChild(chainLightning, "abilityEvent", 10)
            
            local args = {"80E25D5E-935D-44E3-8CAE-C0FEDE8E9F3F"}
            
            abilityEvent:FireServer(unpack(args))
            
            -- Handle retry button
            local rplyBut = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Retry
            firesignal(rplyBut.Activated)
            
            -- Change start value
            local changeStartValue = game:GetService("ReplicatedStorage"):WaitForChild("remotes", 10):WaitForChild("changeStartValue", 10)
            changeStartValue:FireServer()
            
            -- Set walk speed
            local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid.WalkSpeed = 33
            end
        end)
        
        if not success then
            warn("Error in loop: " .. tostring(err))
            wait(5) -- Wait longer if there was an error
        else
            wait() -- Normal wait if everything succeeded
        end
    end
end
