repeat wait(1) until game:IsLoaded()
repeat wait() until game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.LoadingScreen.Visible == false
print("loaded evnts")
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
local pathbtn = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.UpgradePathSelection.Frame["2"]
local paths = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.UpgradePathSelection
local unitManagerFrames = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.UnitManager.Frame.ScrollingFrame
local autoskipBtn = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.AutoSkip
local autoskipCheck = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MainFrames.Wave.AutoSkip.Checkmark
local plrs = game.Players
local plrAmount = #plrs:GetPlayers()
getgenv().Active = true
getgenv().Active2 = true
getgenv().Place = true
getgenv().Ability = true
getgenv().Sacrifice = true
getgenv().Sacrifice2 = true
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
function skipWave()
    game:GetService("ReplicatedStorage"):WaitForChild("Modules")
    :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
    :WaitForChild("PlayerReadyForNextWave"):FireServer()
end
function autoHallow()--hallow 2025
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
            task.wait(0.1)
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
            game:GetService("ReplicatedStorage")
            :WaitForChild("Modules")
            :WaitForChild("GlobalInit")
            :WaitForChild("RemoteEvents")
            :WaitForChild("PlayerVoteReturn"):FireServer()
        end
    end
end

function autoAnniHard() -- anniversary 2025
    getgenv().Active = true
    getgenv().Place = true
    getgenv().Ability = true
    getgenv().Sacrifice = true
    getgenv().dragos = true
    --place dante
    task.wait()
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(0.5)
            local args = {
                "1823601662:230016",
                vector.create(1422.881103515625, 2.9365665912628174, 1447.567626953125),
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
    task.spawn(function()--rukia
        while getgenv().Place == true do
            task.wait()
            local args = {
                "1823601662:228713",
                vector.create(1416.3607177734375, 2.936622381210327, 1445.8538818359375),
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
                vector.create(1411.6158447265625, 2.936708688735962, 1437.2164306640625),
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
                vector.create(1414.55224609375, 2.936663866043091, 1441.145751953125),
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
            task.wait(1)
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
            game:GetService("ReplicatedStorage")
            :WaitForChild("Modules")
            :WaitForChild("GlobalInit")
            :WaitForChild("RemoteEvents")
            :WaitForChild("PlayerVoteReturn"):FireServer()
        end
    end
end

function autoAnniRaid()
    getgenv().Active = true
    getgenv().Active2 = true
    getgenv().Place = true 
    getgenv().Ability = true
    getgenv().Sacrifice = true
    getgenv().Sacrifice2 = true
    getgenv().dragos = true
    getgenv().Skip = false
    --[[
    task.spawn(function()
        repeat wait() until paths.Visible == true
        if paths.Visible == true and paths.Frame["2"].PathName.Text == "Bride" then
            repeat wait() firesignal(pathbtn.Activated) until paths.Visible == false
            print("fired")
        end
    end)
    ]]
    --place dante
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:230016",
                vector.create(1381.7218017578125, 570.0113525390625, -951.8095703125),
                0
            }
            game:GetService("ReplicatedStorage")
            :WaitForChild("GenericModules")
            :WaitForChild("Service")
            :WaitForChild("Network")
            :WaitForChild("PlayerPlaceTower"):FireServer(unpack(args))
        end
    end)
    --start match
    repeat wait() until #twrs:GetChildren() == 1
    speedUp()
    startMatch()
    --place rukia
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:228713",--rukia
                vector.create(1381.6451416015625, 570.0113525390625, -958.4227905273438),
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
    --place ulq
    task.spawn(function()
        while getgenv().Place == true do
            task.wait(1)
            local args = {
                "1823601662:228582",--ulq
                vector.create(1387.756591796875, 570.0113525390625, -963.3370971679688),
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
                vector.create(1386.7733154296875, 570.0113525390625, -971.0331420898438),
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
    getgenv().Skip = true
    if autoskipCheck.Visible == false then
        firesignal(autoskipBtn.Activated)
    end
    task.spawn(function() -- skip waves
        while getgenv().Skip == true do
            task.wait(0.1)
            skipWave()
        end
    end)
    task.spawn(function() -- dragos
        repeat wait() until wave.Text == "Wave 4/30"
        if wave.text == "Wave 4/30" then
            --auto dragos
            task.spawn(function()
                while getgenv().dragos == true do
                    task.wait(4)
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
                end
            end)
        end
    end)
    wait()
    getgenv().Place = false
    local upgradeOrder = {
        {name = "Rukia",  image = "rbxassetid://87872399229257", max = "Upgrade 6/6"},
        {name = "Ulquiorra", image = "rbxassetid://134225242455885", max = "Upgrade 6/6"},
        {name = "Dante",  image = "rbxassetid://77699047724001", max = "Upgrade 5/5"},
        {name = "Aizen",  image = "rbxassetid://77961303424965", max = "Upgrade 6/6"},
    }

    local function findTower(imageId)
        for _, twr in pairs(unitManagerFrames:GetChildren()) do
            if twr:IsA("TextButton") and twr.Name ~= "TemplateSlot" then
                local imgLabel = twr:FindFirstChild("FilledSlot", true)
                        and twr.FilledSlot:FindFirstChild("Portrait", true)
                        and twr.FilledSlot.Portrait:FindFirstChild("UnitDisplay", true)
                        and twr.FilledSlot.Portrait.UnitDisplay:FindFirstChild("ImageLabel")
                local unitlvl = twr.FilledSlot.Portrait.UnitDisplay:FindFirstChild("UnitLevel")
                
                if imgLabel and unitlvl and imgLabel.Image == imageId then
                    return twr, unitlvl
                end
            end
        end
        return nil, nil
    end

    local function upgradeUntilMax(tower, unitlvl, maxText)
        if not tower then return end
        if unitlvl.Text == maxText then return end

        print("Upgrading", tower.Name, "-", unitlvl.Text, "→", maxText)
        repeat
            remote2:FireServer(tower.Name)
            task.wait(0.5)
        until not unitlvl.Parent or unitlvl.Text == maxText
        print("Finished upgrading", tower.Name)
    end

    task.spawn(function()-- first upgrades
        task.wait()
        while getgenv().Active == true do
            local allMaxed = true

            for _, unit in ipairs(upgradeOrder) do
                local tower, unitlvl = findTower(unit.image)

                if tower and unitlvl and unitlvl.Text ~= unit.max then
                    allMaxed = false
                    upgradeUntilMax(tower, unitlvl, unit.max)
                end
            end

            if allMaxed then
                print("All priority units are fully upgraded!")
                getgenv().Active2 = false
                break
            end

            task.wait(1) -- small delay before next full check
        end
    end)
    task.spawn(function() --rukia ability
        task.wait(4)
        for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
            if v.Name == "rukia-sword" then
                local args = {
                    v.Parent.Name
                }
                game:GetService("ReplicatedStorage")
                :WaitForChild("Modules")
                :WaitForChild("GlobalInit")
                :WaitForChild("RemoteEvents")
                :WaitForChild("PlayerToggleAutoAbility"):FireServer(unpack(args))
            end
        end
    end)
    
    task.spawn(function()--sacrifice
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
    repeat wait() until wave.Text == "Wave 6/30"
    for i, tower in ipairs(twrs:GetChildren()) do
        autoUpgradeTower(tower)
    end
    
    --turn off around wave 12
    repeat wait() until wave.Text == "Wave 12/30"
    --toggle skip off
    getgenv().Skip = false
    if autoskipCheck.Visible == true then
        firesignal(autoskipBtn.Activated)
    end
    task.spawn(function()--sacrifice
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
    repeat wait() until wave.Text == "Wave 20/30"
    getgenv().Active = true
    wait(4)
    if autoskipCheck.Visible == false then
        firesignal(autoskipBtn.Activated)
    end
    --[[
    for _,v in pairs(workspace.EntityModels.Towers:GetChildren()) do
        if v:IsA("Model") then
            if v.CharacterMesh.MeshId == 48112070 then
                print("Yes Correct MeshId")
                local args = {
                    v.Name
                }
                game:GetService("ReplicatedStorage")
                :WaitForChild("Modules")
                :WaitForChild("GlobalInit")
                :WaitForChild("RemoteEvents")
                :WaitForChild("PlayerToggleAutoAbility"):FireServer(unpack(args))
            end
        end
    end
    ]]

    repeat wait() until wave.Text == "Wave 21/30"
    
    task.spawn(function() --aizen ability
        task.wait(4)
        for _,v in pairs(workspace.EntityModels.Towers:GetDescendants()) do
            if v.Name == "Wings" then
                local args = {
                    v.Parent.Name
                }
                game:GetService("ReplicatedStorage")
                :WaitForChild("Modules")
                :WaitForChild("GlobalInit")
                :WaitForChild("RemoteEvents")
                :WaitForChild("PlayerToggleAutoAbility"):FireServer(unpack(args))
            end
        end
    end)
    repeat wait() until wave.Text == "Wave 30/30"
    print("Wave 30/30")
    local endGui = game.Players.LocalPlayer.PlayerGui.MainGui.MainFrames.RoundOver
    repeat wait() until endGui.Visible == true
    if endGui.Visible == true then
        getgenv().dragos = false
        getgenv().Active = false
        getgenv().Ability = false
        getgenv().Sacrifice = false

        task.wait()
        game:GetService("ReplicatedStorage"):WaitForChild("Modules")
        :WaitForChild("GlobalInit"):WaitForChild("RemoteEvents")
        :WaitForChild("PlayerRequestReturnLobby"):FireServer()
    end
end

if plrAmount == 1 then
    while task.wait(1) do
        if wave.text == "Wave 0/30"  then
            print("evntsstarting?")
            --autoAnniRaid()
        elseif wave.text == "Wave 0/25" then
            print("evsvemthard???>S?/nSle;")
            autoAnniHard()
        end
    end
end
