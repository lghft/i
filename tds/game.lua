print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plr = Players.LocalPlayer
local plrAmount = #Players:GetPlayers()

function clickButton(ClickOnPart)
    local vim = game:GetService("VirtualInputManager")
    local inset1, inset2 = game:GetService('GuiService'):GetGuiInset()
    local insetOffset = inset1 - inset2
    local part = ClickOnPart
    local topLeft = part.AbsolutePosition + insetOffset
    local center = topLeft + (part.AbsoluteSize / 2)
    local X = center.X + 15
    local Y = center.Y
    vim:SendMouseButtonEvent(X, Y, 0, true, game, 0)
    task.wait(0.1)
    vim:SendMouseButtonEvent(X, Y, 0, false, game, 0)
    task.wait(1)
    print("Clicked: ", ClickOnPart)
end

if plrAmount == 1 and game.Players.LocalPlayer and plrAmount < 2 then
    print("game?")
    repeat wait() until plr.PlayerGui:FindFirstChild("ReactGameTopGameDisplay")
    local wave = plr.PlayerGui.ReactGameTopGameDisplay.Frame.wave.container.value
    local Ending = plr.PlayerGui.ReactGameRewards.Frame.gameOver
    local leave = Ending.content.buttons.lobby.content
    
    repeat wait() until game.ReplicatedStorage:FindFirstChild("RemoteFunction")
    print("yezfunc")
    
    spawn(function()
        while true do
            if wave.Text == "1" then
                print("its wave 1")
                local args = {
                    "Voting",
                    "Skip"
                }
                game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
            end
            if Ending.Visible == true then
                clickButton(leave)
            end
            if wave.Text == "40" then
                for i,v in pairs(workspace.Towers:GetChildren()) do
                        local args = {
                        "Troops",
                        "Upgrade",
                        "Set",
                        {
                            Troop = v,
                            Path = 1
                        }
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
                
                end
            end
            wait(0.5)
        end
    end)

    spawn(function()
        while true do
            if wave.Text == "39" then
            for i,v in pairs(workspace.Towers:GetChildren()) do
                if v.Name == "Masquerade" then
                    local args = {
                    "Troops",
                    "Option",
                    "Set",
                        {
                            Troop = v,
                            Name = "Track",
                            Value = "Red"
                        }
                    }
                    game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
                end
            end
        end
            for i,v in pairs(workspace.Towers:GetChildren()) do
                if v.Name == "Masquerade" then
                    local args = {
                    "Troops",
                    "Abilities",
                    "Activate",
                        {
                            Troop = v,
                            Name = "Drop The Beat",
                            Data = {}
                        }
                    }
                    game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
                end
            end
        end
        wait(0.5)
    end
end)
    
elseif plrAmount > 1 then
    local args = {
        "Multiplayer",
        "v2:start",
        {
            difficulty = "Fallen",
            mode = "survival",
            count = 1
        }
    }
    game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(unpack(args))
end
