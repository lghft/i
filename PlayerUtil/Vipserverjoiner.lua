local code = "66632761641938203785126344046015"

if code ~= nil then
    local ServerType = game:GetService('RobloxReplicatedStorage').GetServerType:InvokeServer()
    
    if ServerType ~= "VIPServer" then
        local args = {
            placeId = game.PlaceId, 
            linkCode = tostring(code)
        }
        game:GetService("ExperienceService"):LaunchExperience(args)
        return true
    end
end
