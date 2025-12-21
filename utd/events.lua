repeat wait(1) until game:IsLoaded()
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.LoadingScreen.Visible == false
print("loaded evntsF#$%^^)$()%)@!@#$%^&*()_+")
local bulmaT = {}
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerToggleAutoAbility")
local remote2 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerUpgradeTower")
local remote3 = game:GetService("ReplicatedStorage"):WaitForChild("GenericModules"):WaitForChild("Service"):WaitForChild("Network"):WaitForChild("PlayerPlaceTower")
local remote4 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("ClientRequestGameSpeed")
local remote5 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerSetTowerTargetMode")
local remote7 = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GlobalInit"):WaitForChild("RemoteEvents"):WaitForChild("PlayerActivateTowerAbility")



local remote6 = game:GetService("ReplicatedStorage").GenericModules.Service.Network.PlayerSellTower
local wave = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.WaveIndex
local twrs = workspace.EntityModels.Towers
local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
local map = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.MapName
local itemDrops = game:GetService("Players").LocalPlayer.PlayerGui.MessagesGui.FullScreen
local pathbtn = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.UpgradePathSelection.Frame["2"]
local paths = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.UpgradePathSelection
local unitManagerFrames = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.UnitManager.Frame.ScrollingFrame
local autoskipBtn = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.AutoSkip
local autoskipCheck = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.AutoSkip.Checkmark
local TeleportService = game:GetService("TeleportService") :: TeleportService
local GuiService = game:GetService("GuiService") :: GuiService
local plrs = game.Players
local LPlayer = (game:GetService("Players") :: Players).LocalPlayer
local plrAmount = #plrs:GetPlayers()
getgenv().Active = true
getgenv().Active2 = true
getgenv().Place = true
getgenv().Ability = true
getgenv().Sacrifice = true
getgenv().Sacrifice2 = true
getgenv().dragos = true


GuiService.ErrorMessageChanged:Connect(function()
	TeleportService:Teleport(game.PlaceId, LPlayer)
end)

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
    remote7:FireServer(unitFromTable.Name)
end

function speedUp()
    local args = {
        "2"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Modules")
    :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
    :WaitForChild("ClientRequestGameSpeed"):FireServer(unpack(args))
end
function skipWave()
    game:GetService("ReplicatedStorage"):WaitForChild("Modules")
    :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
    :WaitForChild("PlayerReadyForNextWave"):FireServer()
end
function autoChristmasRaid()
    getgenv().Place = true 
    getgenv().Ability = true
    getgenv().Sacrifice = true
    getgenv().Sacrifice2 = true
    getgenv().dragos = true

    --place dante
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:230016",
                vector.create(74.33049011230469, -104.15394592285156, -2069.264404296875),
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
    --place rukia
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:228713",--rukia
                vector.create(77.34989929199219, -104.15394592285156, -2077.585205078125),
                0
            }
            game:GetService("ReplicatedStorage")
            :WaitForChild("GenericModules")
            :WaitForChild("Service")
            :WaitForChild("Network")
            :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)
    repeat wait() until #twrs:GetChildren() == 2
    --start match
    
    speedUp()
    startMatch()
    
    --place ulq
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:228582",--ulq
                vector.create(30.212833404541016, -104.15394592285156, -2113.5341796875),
                0
            }
            game:GetService("ReplicatedStorage")
            :WaitForChild("GenericModules")
            :WaitForChild("Service")
            :WaitForChild("Network")
            :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)
    repeat wait() until #twrs:GetChildren() == 3
    --place aizen
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:231880",--aizen
                vector.create(30.33566665649414, -104.15394592285156, -2108.03271484375),
                0
            }
            game:GetService("ReplicatedStorage")
            :WaitForChild("GenericModules")
            :WaitForChild("Service")
            :WaitForChild("Network")
            :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)

    repeat wait() until #twrs:GetChildren() == 4

    task.spawn(function() -- dragos
        repeat wait() until wave.Text == "Wave 3/30"
        if wave.text == "Wave 3/30" then
            --auto dragos
            task.spawn(function()
                while getgenv().dragos == true do
                    local args = {
                        "1823601662:214394",--red:1823601662:214394 green:1823601662:48456
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
                    task.wait(9)
                end
            end)
        end
    end)
    wait()
    getgenv().Place = false
    repeat wait() until wave.Text == "Wave 4/30"
    task.spawn(function() --rukia ability
        task.wait(4)
        for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
            if v.Name == "rukia-sword" then
                local args = {
                    v.Parent.Name
                }
                remote:FireServer(unpack(args))
            end
        end
    end)
    
    task.spawn(function()--sacrifice1
        while getgenv().Sacrifice == true do
            task.wait(4)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "Handle" then
                    if v.SpecialMesh.TextureId == "rbxassetid://17788596237" then
                        useAbility(v.Parent)
                    end
                    
                end
            end
            task.wait()
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "Handle" then
                    if v.SpecialMesh.TextureId == "rbxassetid://121927500929396" then
                        getgenv().Sacrifice = false
                    end
                end
            end
        end
    end)
    
    repeat wait() until wave.Text == "Wave 6/30"
    task.spawn(function()--rukia ability2
        while getgenv().Ability == true do
            task.wait(0.1)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "rukia-sword" then
                    useAbility(v.Parent)
                end
            end
        end
    end)
    repeat wait() until wave.Text == "Wave 10/30"
    task.spawn(function()--sacrifice2
        while getgenv().Sacrifice2 == true do
            task.wait(4)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "Handle" then
                    if v.SpecialMesh.TextureId == "rbxassetid://121927500929396" then
                        useAbility(v.Parent)
                    end
                end
            end
        end
    end)

    repeat wait() until wave.Text == "Wave 30/30"

    task.spawn(function() --sell dante move to boss area
        task.wait()
        for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
            if v.Name == "Sword" then
                if v.MeshId == "rbxassetid://75773538717904" then
                    local args = {
                        v.Parent.Name
                    }
                    remote6:FireServer(unpack(args))
                end
            end
        end
    end)
    wait(1)
    task.spawn(function()
        task.wait(1)
        local args = {
            "1823601662:230016",
            vector.create(-20, -101, -2187),
            0
        }
        game:GetService("ReplicatedStorage")
        :WaitForChild("GenericModules")
        :WaitForChild("Service")
        :WaitForChild("Network")
        :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
    end)
    task.wait(1)

    task.spawn(function()--aizen ability2
        while getgenv().Ability == true do
            task.wait(0.1)
            for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
                if v.Name == "Wings" then
                    useAbility(v.Parent)
                end
            end
        end
    end)

    print("Wave 30/30")
    local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
    repeat wait() until endGui.Visible == true
    if endGui.Visible == true then
        getgenv().dragos = false
        getgenv().Ability = false
        getgenv().Sacrifice2 = false
        task.wait()
        game:GetService("ReplicatedStorage"):WaitForChild("Modules")
        :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
        :WaitForChild("PlayerRequestReturnLobby"):FireServer()
    end
end

if plrAmount == 1 then
    while task.wait(1) do
        if wave.text == "Wave 0/30"  then
            print("evntsstarting?!?!@#$%^&")
            autoChristmasRaid()
        elseif wave.text == "Wave 0/25" then
            print("evsvemthard???>S?/nSle;")
            --autoAnniHard()
        end
    end
end


--game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()[28].Frame["3"].ItemSlot.FullSlot.Portrait.Display.Amount
