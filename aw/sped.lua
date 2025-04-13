repeat wait(4) until game:IsLoaded()
function spd()
local args = {
    [1] = "x2"
}

game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer(unpack(args))
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Enabled == false
    if game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Enabled == false then
        print("3x prolly")
        repeat wait() untilgame:GetService("Players").LocalPlayer.PlayerGui.InterFace.Enabled == true
        spd()
    end
end


spd()
