repeat wait(4) until game:IsLoaded()
local plrs = game.Players
local plrAmount = #plrs:GetPlayers()


function startMatch()
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SkipEvent"):FireServer()
end
function createLby()
    local char = game.Players.LocalPlayer.Character

    char.HumanoidRootPart.CFrame = CFrame.new(347,-82, 209)
    wait(2)
    local args = {
        {
            StageSelect = "Shadow Realm II",
            Image = "rbxassetid://15334750270",
            FriendOnly = true,
            Difficult = "Master"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CreateRoom"):FireServer(unpack(args))
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local changeModeRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("ChangeUnitModeFunction")

local targetModes = {
    "First",
    "Last",
    "Strongest",
    "Weakest",
    "Nearest",
    "Flying",
    "Stop"
}

function getModeIndex(mode)
    for i, v in ipairs(targetModes) do
        if v == mode then
            return i
        end
    end
    return nil
end

-- Sets the TargetMode of a specific unit to the desiredMode
function setUnitTargetMode(unitUsed, desiredMode)
    local info = unitUsed:FindFirstChild("Info")
    if not info then
        warn("Unit has no Info child:", unitUsed.Name)
        return
    end
    local targetModeValue = info:FindFirstChild("TargetMode")
    if not targetModeValue or not targetModeValue:IsA("StringValue") then
        warn("Unit has no TargetMode StringValue:", unitUsed.Name)
        return
    end

    while targetModeValue.Value ~= desiredMode do
        changeModeRemote:InvokeServer(unit)
        -- Wait for the value to update (avoid spamming)
        repeat
            task.wait(0.1)
        until targetModeValue.Value == targetModes[(getModeIndex(targetModeValue.Value) or 1)]
    end

    print("TargetMode set to:", targetModeValue.Value, "for unit:", unitUsed.Name)
end

function clickButton(ClickOnPart)
        local vim = game:GetService("VirtualInputManager")
        local inset1, inset2 = game:GetService('GuiService'):GetGuiInset()
        local insetOffset = inset1 - inset2
        -- Replace "button location here" with the actual GUI object (e.g., a TextButton)
        local part = ClickOnPart
        -- Calculate the center of the GUI element
        local topLeft = part.AbsolutePosition + insetOffset
        local center = topLeft + (part.AbsoluteSize / 2)
        -- Adjust the click position if needed
        local X = center.X + 15
        local Y = center.Y
        -- Simulate a mouse click
        vim:SendMouseButtonEvent(X, Y, 0, true, game, 0) -- Mouse down
        task.wait(0.1) -- Small delay to simulate a real click
        vim:SendMouseButtonEvent(X, Y, 0, false, game, 0) -- Mouse up
        task.wait(1)
        print("Clicked")
end
function sr2mac()
    local char = game.Players.LocalPlayer.Character
    char.HumanoidRootPart.CFrame = CFrame.new(-109, 6, 17)
    local args = {
	"Vending Machine",
	CFrame.new(-105.38169860839844, 4.996660232543945, 32.78748321533203, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	1,
	{
		"1",
		"1",
		"1",
		"1"
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))

startMatch()
--Place
spawn(function() 
    while true do
    local args = {
	"Vending Machine",
        CFrame.new(-105.71138000488281, 18.03795051574707, 30.91839027404785, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))

    local args = {
        "Umu",
        CFrame.new(-97.70669555664062, 4.954528331756592, 64.87602233886719, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))

    local args = {
	"Leader",
        CFrame.new(-102.72235107421875, 18.429485321044922, 25.169254302978516, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))


    local args = {
        "Casual Hero",
        CFrame.new(-97.07447814941406, 4.996660232543945, 36.81475067138672, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))


    local args = {
        "Stone Doctor",
        CFrame.new(-93.76461791992188, 4.996660232543945, 46.77920150756836, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))

    local args = {
        "Gappy [Beyond]",
        CFrame.new(-103.39106750488281, 4.996660232543945, -37.01251220703125, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        1,
        {
            "1",
            "1",
            "1",
            "1"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("SpawnUnit"):InvokeServer(unpack(args))
        wait(1)
    end
end)
repeat wait() until game.Players.LocalPlayer.PlayerGui.InterFace.Day.Text == "[Shadow Realm II] [Master] Wave 3/10" --up1
spawn(function()
    while true do
        for _, v in pairs (workspace.Units:GetChildren())do
            if v.Name == 'Leader' then -- change part to the name you want to look for
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Vending Machine" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Stone Doctor" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
        end
        wait(1)
    end
end)

repeat wait() until game.Players.LocalPlayer.PlayerGui.InterFace.Day.Text == "[Shadow Realm II] [Master] Wave 5/10" --up2
spawn(function()
    while true do
        for _, v in pairs (workspace.Units:GetChildren())do
            if v.Name == "Umu" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Casual Hero" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Gappy [Beyond]" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
        end
        wait()
    end
end)

repeat wait() until game.Players.LocalPlayer.PlayerGui.InterFace.Day.Text == "[Shadow Realm II] [Master] Wave 6/10" --buffs
spawn(function()
while true do
    local args = {
        [1] = "Flowers on Earth",
        [2] = workspace:WaitForChild("Units"):WaitForChild("Umu")
    }
        
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))    
    local args = {
            [1] = "Heal Bubble",
            [2] = workspace:WaitForChild("Units"):WaitForChild("Gappy [Beyond]")
        }
        
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args)) 
    wait(1)
end
end)   
--lab buff 
spawn(function()
    while true do
        local args = {
        "BuySenkuInvation",
        workspace:WaitForChild("Units"):WaitForChild("Stone Doctor"),
        "Science Laboratory"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))

        local args = {
        "BuySenkuInvation",
        workspace:WaitForChild("Units"):WaitForChild("Stone Doctor"),
        "Chrome's Storehouse"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))

        local args = {
        "BuySenkuInvation",
        workspace:WaitForChild("Units"):WaitForChild("Stone Doctor"),
        "Ramen Cart"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))

        local args = {
        "BuySenkuInvation",
        workspace:WaitForChild("Units"):WaitForChild("Stone Doctor"),
        "Energy Generator"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))
        
        local args = {
        "BuySenkuInvation",
        workspace:WaitForChild("Units"):WaitForChild("Stone Doctor"),
        "Makeshift Chassis"
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))
        wait(1)
    end
end)
repeat wait() until game.Players.LocalPlayer.PlayerGui.InterFace.Day.Text == "[Shadow Realm II] [Master] Wave 10/10" --ups again
spawn(function()
    while true do
        for _, v in pairs (workspace.Units:GetChildren())do
            if v.Name == 'Leader' then -- change part to the name you want to look for
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Vending Machine" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Stone Doctor" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
        end
        wait(1)
    end
end)
spawn(function()
    while true do
        for _, v in pairs (workspace.Units:GetChildren())do
            if v.Name == "Umu" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Casual Hero" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
            if v.Name == "Gappy [Beyond]" then
                local args = {
                    [1] = v
                }
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("UpgradeUnit"):InvokeServer(unpack(args))
            end
        end
        wait()
    end
end)
    local unit = workspace.Units.Leader
    setUnitTargetMode(unit, "Strongest")
end

if plrAmount > 1 then
createLby()
spawn(function()
    while true do
        clickButton(game:GetService("Players").LocalPlayer.PlayerGui.InRoomUi.RoomUI.QuickStart)
        wait()
    end
end)

elseif plrAmount == 1 and game.Players.LocalPlayer then
    sr2mac()
end
