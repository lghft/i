local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local placeId = game.PlaceId

local function reconnect()
    local success, error = pcall(function()
        TeleportService:Teleport(placeId)
    end)
    
    if not success then
        warn("Failed to reconnect:", error)
        task.wait(5)
        reconnect()
    end
end

-- Listen for disconnection
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
    if child.Name == 'ErrorPrompt' then
        task.wait(1)
        reconnect()
    end
end)

print("Auto reconnect script loaded!")
