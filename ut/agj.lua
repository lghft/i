repeat wait() until game:IsLoaded() print("loaded")
local me = game.Players.LocalPlayer
local unitM = me.PlayerGui.MainGui.MainFrames.UnitManager
local remote = game.ReplicatedStorage.Modules.GlobalInit.RemoteEvents.PlayerActivateTowerAbility
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")
local remote3 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower")
local remote4 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("ClientRequestGameSpeed")
local remote5 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerSetTowerTargetMode")

local shinyG = {}
local krumiT = {}
local itaT = {}
local count = 0

function kurumiAbilityUsed()
	count = count + 1
	print("Function called! Count:", count)

	-- Your function logic here --
end

function autoupgrade(unitFromTable)
    local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		remote2:FireServer(unitFromTable.Name)
	end)
end

function autoAbility(unitFromTable)
    local timeText = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.Time
	timeText:GetPropertyChangedSignal("Text"):Connect(function()
		remote:FireServer(unitFromTable.Name)
	end)
end

game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerVoteToStartMatch"):FireServer()

repeat wait() until me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text == "Wave 1/30"
print("first Wave")
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "227490"), Vector3.new(-4.237037658691406, 221.0968017578125, -285.95379638671875), 0)
wait()
remote4:FireServer("1.5")

repeat for _,v in pairs(game:GetService("Workspace").EntityModels.Towers:GetChildren()) do
        for i,v in pairs(v:GetChildren()) do
            if v.Name == "Hair" then
                table.insert(itaT, v.Parent)
                --print(v.Parent)
            end
        end
    end
    wait()
until #itaT == 1
--itadori
print("found Itadori")

if #itaT == 1 then
    autoupgrade(itaT[1])
end
print("Autoup")
repeat
    wait()
    local found = false
    for _, slot in ipairs(unitM.Frame.ScrollingFrame:GetChildren()) do
        if slot.Name:find(itaT[1].Name) and slot:FindFirstChild("FilledSlot") then
            local levelText = slot.FilledSlot.Portrait.UnitDisplay.UnitLevel.Text
            if levelText == "Upgrade 6/6" then
                found = true
                print(slot)
                print(levelText)
                break
            end
        end
    end
until found -- inside UnitManager

warn("Itadori MAXED")
print(me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text)
repeat wait() until me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text == "Wave 6/30"
print(me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text)
wait(1)
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "226581"), Vector3.new(-4.066734313964844, 221.0968017578125, -306.2311096191406), 0)
print("krumi placed proly")
repeat for _,v in pairs(game:GetService("Workspace").EntityModels.Towers:GetChildren()) do
        for i,v in pairs(v:GetChildren()) do
            if v.Name == "Gun" then
                table.insert(krumiT, v.Parent)
                print(v.Parent)
            end
        end
    end
    wait()
until #krumiT == 1

--kurumi
remote4:FireServer("1")

if #krumiT == 1 then
    print("1 krumi")
    remote2:FireServer(krumiT[1].Name, 2)
    me.PlayerGui.MainGui.UpgradePathSelection.Visible = false
    me.PlayerGui.MainGui.HUD.Visible = true
    me.PlayerGui.MainGui.MainFrames.Visible = true

    autoupgrade(krumiT[1])
    print("auto upgrade")
end

remote5:FireServer(krumiT[1].Name, "Strong")

repeat
    wait()
    local found = false
    for _, slot in ipairs(unitM.Frame.ScrollingFrame:GetChildren()) do
        if slot.Name:find(krumiT[1].Name) and slot:FindFirstChild("FilledSlot") then
            local levelText = slot.FilledSlot.Portrait.UnitDisplay.UnitLevel.Text
            if levelText == "Upgrade 6/6" then
                found = true
                print(slot)
                print(levelText)
                break
            end
        end
    end
until found -- inside UnitManager
warn("Kurumi MAXED")

-- place gojos
print("Placing GOJOS?")
wait(1)
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "227596"), Vector3.new(-24.677661895751953, 221.0968017578125, -302.59112548828125), 0)
wait(1)
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "227588"), Vector3.new(-24.90053939819336, 221.0968017578125, -298.7460021972656), 0)
wait(1)
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "157368"), Vector3.new(-24.754215240478516, 221.0968017578125, -294.8587646484375), 0)
wait(1)
remote3:FireServer(tostring(game.Players.LocalPlayer.UserId .. ":" .. "225295"), Vector3.new(-24.981365203857422, 221.0968017578125, -291.3843994140625), 0)
--gojo ability
print("finished placing Gojos")
wait(2)
for _,v in pairs(game:GetService("Workspace").EntityModels.Towers:GetChildren()) do
    for i,v in pairs(v:GetChildren()) do
        if v.Name == "gojo-collar" then
            table.insert(shinyG, v.Parent)
            print(v.Parent)
        end
    end
end
print("added To shinyG Table")
if #shinyG == 4 then
    for i,v in pairs(shinyG) do
        autoupgrade(shinyG[i])
    end
end

repeat
    wait()
    local found = false
    for _, slot in ipairs(unitM.Frame.ScrollingFrame:GetChildren()) do
        if slot.Name:find(shinyG[4].Name) and slot:FindFirstChild("FilledSlot") then
            local levelText = slot.FilledSlot.Portrait.UnitDisplay.UnitLevel.Text
            if levelText == "Upgrade 5/5" then
                found = true
                print(slot)
                print(levelText)
                break
            end
        end
    end
until found -- inside UnitManager

print("Auto Gojo ABILITY")
if #shinyG == 4 then
    remote:FireServer(shinyG[1].Name)
    wait(7)
    remote:FireServer(shinyG[2].Name)
    wait(7)
    remote:FireServer(shinyG[3].Name)
    wait(7)
    remote:FireServer(shinyG[4].Name)
    wait(7)
    spawn(function()
        while true do
            remote:FireServer(shinyG[1].Name)
            remote:FireServer(shinyG[2].Name)
            remote:FireServer(shinyG[3].Name)
            remote:FireServer(shinyG[4].Name)
            wait()
        end
   end)()
end

print("Auto KrumI ABILITY?")
repeat wait() until me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text == "Wave 28/30"
print(me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text)
coroutine.wrap(function()
	while true do
        remote:FireServer(krumiT[1].Name)
        wait()
        print(me.PlayerGui.MainGui.MainFrames.Wave.WaveIndex.Text)
	end
end)
--[[
BorosShoulderGuard
HeadAccessories
]]
repeat wait() until	game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true
	if game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver.Visible == true then
		game:Shutdown()
	end
