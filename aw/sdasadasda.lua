repeat wait(4) until game:IsLoaded() 
local args = {
    [1] = "x2"
}

game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer(unpack(args))

print("scripttppt")
function b()
local auto = true
print("funciont loading")
local function spawnUnit(unit,x,y,z)
    local args = {
        [1] = unit,
        [2] = CFrame.new(x,y,z),
        [3] = 1,
        [4] = {
            [1] = "1",
            [2] = "1",
            [3] = "1",
            [4] = "1"
        }
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))
    
end

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

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 2/10"
print("spawing Leader")
spawn(function()
while auto == true do
spawnUnit("Leader",-203.10141, 200.626892, 1003.362, 1, 0, 0, 0, 1, 0, 0, 0, 1)
spawnUnit("StringMage",-214.64122, 204.85199, 1001.27405, 1, 0, 0, 0, 1, 0, 0, 0, 1)
spawnUnit("Dragon Slayer[Red]",-189.481644, 200.629745, 1016.27631, 1, 0, 0, 0, 1, 0, 0, 0, 1)
spawnUnit("Kongkun",-176.959732, 206.929962, 998.194214, -0.419992685, 0, 0.907527447, 0, 1, 0, -0.907527447, 0, -0.419992685)
--spawnUnit("Denis",-201.169022, 200.629761, 991.351074, 1, 0, 0, 0, 1, 0, 0, 0, 1)
wait()
end
end)
autoUnitsUp("Leader")
autoUnitsUp("Shining Star Idol")
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 4/10"
autoUnitsUp("Vending Machine")

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 9/10"
print("Wv 9/10")
autoUnitsUp("Dragon Slayer[Red]")
wait()
autoUnitsUp("Kongkun")
wait()
autoUnitsUp("String Mage")
wait()

spawn(function()

print("autFOODD")
while auto == true do
local args = {
        [1] = 10
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("BuyMeat"):InvokeServer(unpack(args))
wait(1)
end

end)

repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Day.Text == "[Island of Snipers] [Master] Wave 10/10"
warn("10 stuf")
auto = false
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.InterFace.Equip.val.Cash_Value.val.Text == "4950 $"
b()
end

b()
