function a()

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Esper City] [Master] Wave 1/13"
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Skip.Visible == true
game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SkipEvent"):FireServer()


repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Esper City] [Master] Wave 7/13"
spawn(function()
while true do 
game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SkipEvent"):FireServer()
wait(1)
end
end)

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Esper City] [Master] Wave 13/13"

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.Announce.BossList.Boss_Info.Visible == true

wait(10)
local args = {
    [1] = "Enuma Elish",
    [2] = workspace:WaitForChild("Units"):WaitForChild("King of Heroes")
}

game:GetService("ReplicatedStorage"):WaitForChild("Remote"):Wikitorial("UnitAbility"):FireServer(unpack(args))

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Equip.val.Cash_Value.val.Text == "4950 $"
a()
end

end
a()
