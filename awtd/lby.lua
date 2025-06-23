repeat wait(4) until game:IsLoaded()
local plrs = game.Players
local plrAmount = #plrs:GetPlayers()

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
function createLby()
    wait(1)
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
if plrAmount > 1 then
createLby()
spawn(function()
    while true do
        clickButton(game:GetService("Players").LocalPlayer.PlayerGui.InRoomUi.RoomUI.QuickStart)
        wait()
    end
end)
end
