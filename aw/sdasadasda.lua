function b()

local function autoUnitsUp(unit)
    local timeText = game.Players.LocalPlayer.PlayerGui.InterFace.Equip.val.Cash_Value.val
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
        wait(1)
        for _, v in pairs (workspace.Units:GetChildren())do
            if v.Name == unit then -- change part to the name you want to look for
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
        end
    end)
end

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 6/10"
autoUnitsUp("Shining Star Idol")
print("Idolup")

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 10/10"
print("Wv 10/10")
autoUnitsUp("Dragon Slayer[Red]")
wait()
autoUnitsUp("Kongkun")
wait()
autoUnitsUp("String Mage")
wait()
autoUnitsUp("Leader")

spawn(function()

print("autFOODD")
while true do
local args = {
        [1] = num
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("BuyMeat"):InvokeServer(unpack(args))
wait(1)
end

end)

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Equip.val.Cash_Value.val.Text == "4950 $"
b()
end

end
b()
