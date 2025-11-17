repeat wait(4) until game:IsLoaded()
local bulmaT = {}
local remote = game.ReplicatedStorage.Modules.GlobalInit.RemoteEvents.PlayerActivateTowerAbility
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")
local remote3 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower")
local remote4 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("ClientRequestGameSpeed")
local remote5 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerSetTowerTargetMode")
local wave = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.WaveIndex
local twrs = workspace.EntityModels.Towers
local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
local map = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.MapName
local itemDrops = game:GetService("Players").LocalPlayer.PlayerGui.MessagesGui.FullScreen
local plrs = game.Players
local plrAmount = #plrs:GetPlayers()
getgenv().Active = true
getgenv().Place = true
getgenv().Ability = true
getgenv().Sacrifice = true
getgenv().dragos = true
function startMatch()
    game:GetService("ReplicatedStorage")
    :WaitForChild("Modules")
    :WaitForChild("GlobalInit")
    :WaitForChild("RemoteEvents")
    :WaitForChild("PlayerVoteToStartMatch"):FireServer()
end
function clickguiPart(ClickOnPart)
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
    --print("Clicked: ", ClickOnPart)
end


function autoUpgradeTower(unitFromTable)
    spawn(function()
        while getgenv().Active == true do
            task.wait(1)
            remote2:FireServer(unitFromTable.Name)
        end
    end)
end

function useAbility(unitFromTable)
    remote:FireServer(unitFromTable.Name)
end

function speedUp()
    local args = {
        "2"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Modules")
    :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
    :WaitForChild("ClientRequestGameSpeed"):FireServer(unpack(args))
end

function autoHallow()
    getgenv().Active = true
    getgenv().Place = true
    getgenv().Ability = true
    getgenv().Sacrifice = true
    getgenv().dragos = true
    --place dante
    task.wait()
    task.spawn(function()
        while getgenv().Place == true do
            task.wait()
            local args = {
                "1823601662:230016",
                vector.create(10057.6689453125, 18.482038497924805, -86.61033630371094),
                0
            }
            game:GetService("ReplicatedStorage")
            :WaitForChild("GenericModules")
            :WaitForChild("Service")
            :WaitForChild("Network")
            :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))

        end
    end)
    repeat wait() until #twrs:GetChildren() == 1
    speedUp()
    task.wait()
    startMatch()
    --place rukia
    task.wait()
    task.spawn(function()
        while getgenv().Place == true do
            task.wait()
            local args = {
                "1823601662:228713",
                vector.create(10053.0498046875, 18.482038497924805, -86.48387145996094),
                0
            }
            game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))

        end
    end)
    repeat wait() until #twrs:GetChildren() == 2
    --place ulq
    task.wait()
    task.spawn(function()
        while getgenv().Place == true do
            task.wait()
            local args = {
                "1823601662:228582",
                vector.create(10062.87890625, 18.482040405273438, -86.63890075683594),
                0
            }
            game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)
    repeat wait() until #twrs:GetChildren() == 3
    --place aizen
    task.wait()
    task.spawn(function()
        while getgenv().Place == true do
            task.wait()
            local args = {
                "1823601662:231880",
                vector.create(10069.3916015625, 18.482038497924805, -85.98697662353516),
                0
            }
            game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)
    repeat wait() until #twrs:GetChildren() == 4
    wait()
    getgenv().Place = false
    for i, tower in ipairs(twrs:GetChildren()) do
        autoUpgradeTower(tower)
    end
    task.spawn(function()
        while getgenv().Ability == true do
            task.wait(4)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "rukia-sword" then
                    useAbility(v.Parent)
                end
            end
        end
    end)
    task.spawn(function()
    while getgenv().Sacrifice == true do
            task.wait(4)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "Handle" then
                    if v.SpecialMesh.TextureId == "rbxassetid://17788596237" then
                        useAbility(v.Parent)
                    end
                end
            end
        end
    end)
    repeat wait() until wave.Text == "Wave 10/25"
    if wave.text == "Wave 10/25" then
        --auto dragos
        task.spawn(function()
            while getgenv().dragos == true do
                task.wait(4)
                local args = {
                    "1823601662:214394",
                    vector.create(10089.8515625, 22.843599319458008, -78.88304138183594)
                }
                game:GetService("ReplicatedStorage")
                :WaitForChild("GenericModules")
                :WaitForChild("Service")
                :WaitForChild("Network")
                :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
                local args = {
                    "1823601662:66955",
                    vector.create(10089.78125, 22.80770492553711, -78.888671875)
                }
                game:GetService("ReplicatedStorage")
                :WaitForChild("GenericModules"):WaitForChild("Service")
                :WaitForChild("Network")
                :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
            end
        end)
    end
    repeat wait() until wave.Text == "Wave 15/25"
    for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
        if v.Name == "Wings" then
            getgenv().Sacrifice = false
        end
    end
    repeat wait() until wave.Text == "Wave 25/25"
    print("wave 25")
    local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
    repeat wait() until endGui.Visible == true
    if endGui.Visible == true then
        getgenv().dragos = false
        getgenv().Active = false
        getgenv().Ability = false
        task.wait()
        if endGui.Continue.Visible == true then
            game:GetService("ReplicatedStorage")
            :WaitForChild("Modules")
            :WaitForChild("GlobalInit")
            :WaitForChild("RemoteEvents")
            :WaitForChild("PlayerVoteReplay"):FireServer()
        else
            clickguiPart(endGui.Lobby)
        end
    end
end

if plrAmount == 1 then
    autoHallow()
    while task.wait(1) do
        if wave.text == "Wave 0/25" then
            autoHallow()
        end
    end
end
