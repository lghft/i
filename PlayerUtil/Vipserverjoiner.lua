local ServerType = game:GetService('RobloxReplicatedStorage').GetServerType:InvokeServer()
local linkCode = "";
if ServerType ~= "VIPServer" then
    local args = {
        placeId = game.PlaceId, 
        linkCode = tostring(code)
    }
    game:GetService("ExperienceService"):LaunchExperience(args)
    return true
end
