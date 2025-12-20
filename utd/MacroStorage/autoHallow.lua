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
