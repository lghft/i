repeat wait() until game:IsLoaded()
local args = {
    [1] = "x2"
}

game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer(unpack(args))
