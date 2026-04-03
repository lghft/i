local v1 = game:GetService("ReplicatedStorage")
local v2 = game:GetService("Players")

local v3 = v2.LocalPlayer
if not v3 then return end

local v4 = v3:WaitForChild("PlayerGui")
local v5 = v4:WaitForChild("Interface")
local v6 = v5:WaitForChild("GameOverScreen")

local v7 = v1:WaitForChild("Remotes")
local v8 = v7:FindFirstChild("RequestTeleportToLobby")

if not v8 or not (v8:IsA("RemoteEvent") or v8:IsA("RemoteFunction")) then
    return
end

local function v9()
    local v10 = 5
    for _ = 1, v10 do
        local v11 = pcall(function()
            task.wait(1)
            if v8:IsA("RemoteEvent") then
                v8:FireServer()
            else
                v8:InvokeServer()
            end
        end)

        if v11 then
            return true
        else
            task.wait(1)
        end
    end
    return false
end

local function v12()
    while true do
        if v6 and v6.Visible then
            v9()
        end
        task.wait(4)
    end
end

if v6 and v6.Visible then
    v9()
end

if v6 then
    v6:GetPropertyChangedSignal("Visible"):Connect(function()
        if v6.Visible then
            coroutine.wrap(v12)()
        end
    end)
end

local v13 = v5:WaitForChild("CutsceneScreen")

local function v14()
    task.wait(1)
    v1:WaitForChild("Remotes"):WaitForChild("CutsceneVoteCast"):FireServer(true)
end

if v13.Visible then
    v14()
else
    local v15
    v15 = v13:GetPropertyChangedSignal("Visible"):Connect(function()
        if v13.Visible then
            v14()
            v15:Disconnect()
        end
    end)
end
