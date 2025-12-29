local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

task.spawn(function()
    if game:GetService("Players").LocalPlayer.PlayerGui.EndUI.UI then
        local endUI = game:GetService("Players").LocalPlayer.PlayerGui.EndUI.UI
        endUI.Position = UDim2.new(0.5, 0, 2, 0)
    end
end)

local Window = Fluent:CreateWindow({
    Title = "AWTD",
    SubTitle = "Made By Kero:33",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local MACRO_FOLDER = "AWTD_Macros_Kero"
local CALC_DELAY = 0.5 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local isRecording = false
local isPlaying = false
local currentMacroData = {} 
local currentMacroName = "" 
local startTime = 0
local playbackMode = "Hybrid" 

local AllowedRemotes = {
    ["SpawnUnit"] = true, ["SellUnit"] = true, ["UpgradeUnit"] = true,
    ["UnitAbility"] = true, ["BuyMeat"] = true, ["FeedAll"] = true,
    ["SkipEvent"] = true, ["x2Event"] = true
}

if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

local function SmartFire(remote, args)
    if not remote then return end
    args = args or {}
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote:FireServer(unpack(args))
    elseif remote:IsA("RemoteFunction") then
        task.spawn(function() pcall(function() remote:InvokeServer(unpack(args)) end) end)
    end
end

local function CFrameToTable(cf) return {cf:GetComponents()} end
local function TableToCFrame(tab) return CFrame.new(unpack(tab)) end

local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    return (ls and ls:FindFirstChild("Cash")) and ls.Cash.Value or 0
end

local function findUnitByCFrame(targetCFrame)
    if not Workspace:FindFirstChild("Units") then return nil end
    for _, unit in pairs(Workspace.Units:GetChildren()) do
        local root = unit:FindFirstChild("HumanoidRootPart") or unit.PrimaryPart
        if root and (root.Position - targetCFrame.Position).Magnitude < 1.5 then return unit end
    end
    return nil
end

local function speedUp()
    if workspace.TimeSpeed.Value == 1 then
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer()
        wait(0.5)
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer()
    end
    if workspace.TimeSpeed.Value == 2 then
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("x2Event"):FireServer()
        wait(0.5)
    end
end

local function getUiButton(name)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local success, btn = pcall(function()
        return pg.EndUI.UI.Stage_Grid.Frame[name].Button
    end)
    return (success and btn) or nil
end
local function getUiOfButton(name)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local success, btn = pcall(function()
        return pg.EndUI.UI.Stage_Grid.Frame[name]
    end)
    return (success and btn) or nil
end

local function firebutton(Button)
    if not Button or not Button:IsA("GuiButton") then return end

    local oldNav = GuiService.GuiNavigationEnabled

    GuiService.GuiNavigationEnabled = true
    GuiService.SelectedObject = Button  -- This should work fine if Button is valid/selectable
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    
    task.wait(0.05)
    
    GuiService.GuiNavigationEnabled = oldNav
    GuiService.SelectedObject = nil
    -- Remove this line entirely:
    -- GuiService.SelectedObject = oldSel
end

local function clickButton(ClickOnPart)
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
        --print("Clicked")
end

local function SaveCurrentMacro()
    if currentMacroName == "" then return end
    local exportData = {}
    for _, act in ipairs(currentMacroData) do
        local entry = table.clone(act)
        if entry.CFrame then entry.CFrame = CFrameToTable(entry.CFrame) end
        table.insert(exportData, entry)
    end
    writefile(MACRO_FOLDER.."/"..currentMacroName..".json", HttpService:JSONEncode(exportData))
    Fluent:Notify({Title="System", Content="Saved: "..currentMacroName, Duration=2})
end

local function LoadMacro(name)
    if not isfile(MACRO_FOLDER.."/"..name..".json") then return end
    local content = readfile(MACRO_FOLDER.."/"..name..".json")
    local decoded = HttpService:JSONDecode(content)
    currentMacroData = {}
    for _, act in ipairs(decoded) do
        if act.CFrame then act.CFrame = TableToCFrame(act.CFrame) end
        table.insert(currentMacroData, act)
    end
    currentMacroName = name
end

local function GetMacroFiles()
    local files = listfiles(MACRO_FOLDER)
    local names = {}
    for _, file in ipairs(files) do
        local name = file:match("([^/]+)%.json$")
        if name then table.insert(names, name) end
    end
    return names
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    if checkcaller() then return oldNamecall(self, ...) end
    if not isRecording then return oldNamecall(self, ...) end
    local method = getnamecallmethod()
    if (method == "InvokeServer" or method == "FireServer") and AllowedRemotes[self.Name] then
        local rName = self.Name
        local args = {...}
        task.spawn(function()
            pcall(function()
                local currentTime = tick() - startTime
                local preCash = getCash()

                if rName == "SpawnUnit" then
                    task.wait(CALC_DELAY)
                    local realCost = math.max(0, preCash - getCash())
                    table.insert(currentMacroData, {Action="Place", Time=currentTime, Cost=realCost, UnitName=args[1], CFrame=args[2], Slot=args[3], Data=args[4]})
                    Fluent:Notify({Title="Rec", Content="Place", Duration=1})
                elseif rName == "SellUnit" then
                    local u = args[1]; if u and u.PrimaryPart then table.insert(currentMacroData, {Action="Sell", Time=currentTime, Cost=0, CFrame=u.PrimaryPart.CFrame}); Fluent:Notify({Title="Rec", Content="Sell", Duration=1}) end
                elseif rName == "UpgradeUnit" then
                    task.wait(CALC_DELAY)
                    local realCost = math.max(0, preCash - getCash())
                    local u = args[1]; if u and u.PrimaryPart then table.insert(currentMacroData, {Action="Upgrade", Time=currentTime, Cost=realCost, CFrame=u.PrimaryPart.CFrame}); Fluent:Notify({Title="Rec", Content="Upgrade", Duration=1}) end
                elseif rName == "UnitAbility" then
                      local u = args[2]; if u and u.PrimaryPart then table.insert(currentMacroData, {Action="Ability", Time=currentTime, Cost=0, SkillName=args[1], CFrame=u.PrimaryPart.CFrame}) end
                elseif rName == "BuyMeat" then 
                    task.wait(CALC_DELAY)
                    table.insert(currentMacroData, {Action="BuyMeat", Time=currentTime, Cost=math.max(0, preCash - getCash()), Args=args})
                    Fluent:Notify({Title="Rec", Content="Buy Meat", Duration=1})
                elseif rName == "FeedAll" then table.insert(currentMacroData, {Action="FeedAll", Time=currentTime, Cost=0})
                elseif rName == "SkipEvent" then table.insert(currentMacroData, {Action="SkipWave", Time=currentTime, Cost=0})
                elseif rName == "x2Event" then table.insert(currentMacroData, {Action="AutoSpeed", Time=currentTime, Cost=0})
                end
            end)
        end)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

local Tabs = {
    Macro = Window:AddTab({ Title = "Macro Manager", Icon = "file-cog" }),
    Lobby = Window:AddTab({ Title = "Lobby Manager", Icon = "home" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options
local StatusParagraph = Tabs.Macro:AddParagraph({ Title = "Status: Idle", Content = "Waiting..." })

local function UpdateStatus(status, details)
    StatusParagraph:SetTitle("Status: " .. status)
    StatusParagraph:SetDesc(details or "")
end

Tabs.Macro:AddInput("InputMacroName", {Title = "New Macro Name", Placeholder = "MapName_Diff", Callback = function() end})
Tabs.Macro:AddButton({Title = "Create New File", Callback = function() local name = Options.InputMacroName.Value; if name~="" then currentMacroName=name; currentMacroData={}; SaveCurrentMacro(); Options.FileSelect:SetValues(GetMacroFiles()); Options.FileSelect:SetValue(name) end end})
Tabs.Macro:AddDropdown("FileSelect", {Title = "Select File", Values = GetMacroFiles(), Default = 1, Callback = function(v) if v then LoadMacro(v) end end})
task.delay(1, function() local f=GetMacroFiles(); if #f>0 then LoadMacro(f[1]); Options.FileSelect:SetValue(f[1]) end end)
Tabs.Macro:AddButton({Title = "Refresh / Delete", Callback = function() if currentMacroName~="" and isfile(MACRO_FOLDER.."/"..currentMacroName..".json") then delfile(MACRO_FOLDER.."/"..currentMacroName..".json"); currentMacroName=""; currentMacroData={}; Options.FileSelect:SetValues(GetMacroFiles()); Options.FileSelect:SetValue(nil) else Options.FileSelect:SetValues(GetMacroFiles()) end end})

Tabs.Macro:AddToggle("RecordToggle", {Title = "Record", Default = false }):OnChanged(function(v)
    if v then isPlaying=false; isRecording=true; currentMacroData={}; startTime=tick(); UpdateStatus("Recording", "Started...")
    else isRecording=false; SaveCurrentMacro(); UpdateStatus("Stopped", "Saved.") end
end)

Tabs.Macro:AddDropdown("ModeSelect", {Title = "Mode", Values = {"Time", "Money", "Hybrid"}, Default = "Hybrid", Callback = function(v) playbackMode = v end})

Tabs.Macro:AddToggle("PlayToggle", {Title = "Play", Default = false }):OnChanged(function(v)
    if v then isRecording=false; playMacro() else isPlaying=false; UpdateStatus("Stopped", "User Cancelled") end
end)

Tabs.Lobby:AddToggle("AutoRestart", {Title = "Auto Restart", Default = false })
Tabs.Lobby:AddToggle("AutoNext", {Title = "Auto Next", Default = false })
Tabs.Lobby:AddToggle("AutoLeave", {Title = "Auto Leave", Default = false })

Tabs.Lobby:AddSection("Abyss Bypass")

local abyssFloorVal = "40"

Tabs.Lobby:AddInput("AbyssFloorInput", {
    Title = "Bypass Abyss Floor",
    Default = "40",
    Placeholder = "40",
    Numeric = true,
    Finished = false,
    Callback = function(Value)
        abyssFloorVal = Value
    end
})

Tabs.Lobby:AddToggle("AutoJoinAbyss", {Title = "Auto Join Abyss", Default = false }):OnChanged(function(Value)
    getgenv().AutoJoinAbyssLoop = Value
    if Value then
        task.spawn(function()
            while getgenv().AutoJoinAbyssLoop do
                local remote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("TeleportToStage")
                if remote then
                    local args = "Abyss_" .. abyssFloorVal
                    remote:FireServer(args)
                end
                task.wait(2)
            end
        end)
    end
end)

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(Tabs.Settings)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

function playMacro()
    if #currentMacroData == 0 then
        Fluent:Notify({Title="Error", Content="No macro loaded!", Duration=3})
        Options.PlayToggle:SetValue(false)  -- Auto-turn off toggle
        return
    end

    local Remotes = ReplicatedStorage:FindFirstChild("Remote")
    if not Remotes then
        Fluent:Notify({Title="Error", Content="Remotes not loaded yet!", Duration=3})
        Options.PlayToggle:SetValue(false)
        return
    end

    isPlaying = true
    speedUp()
    task.wait(0.1)
    speedUp()
    task.spawn(function()
        UpdateStatus("Starting...", "Match Start")
        local startT = tick()
        local step = 1
        local Remotes = ReplicatedStorage:WaitForChild("Remote")
        local R = {
            Spawn=Remotes:FindFirstChild("SpawnUnit"), Sell=Remotes:FindFirstChild("SellUnit"),
            Upgrade=Remotes:FindFirstChild("UpgradeUnit"), Ability=Remotes:FindFirstChild("UnitAbility"),
            BuyMeat=Remotes:FindFirstChild("BuyMeat"), FeedAll=Remotes:FindFirstChild("FeedAll"),
            Skip=Remotes:FindFirstChild("SkipEvent"), Speed=Remotes:FindFirstChild("x2Event")
        }

        while isPlaying do
            local eff = Workspace:FindFirstChild("Effect")
            if eff and eff:FindFirstChild("Gameover") then
                isPlaying = false
                UpdateStatus("Stopped", "Gameover Detected")
                break
            end

            if step <= #currentMacroData then
                local act = currentMacroData[step]
                local passed = tick() - startT
                local cash = getCash()
                local cost = act.Cost or 0
                local readyT = passed >= act.Time
                local readyM = true
                if playbackMode ~= "Time" and cost > 0 then readyM = cash >= cost end
                
                if (playbackMode == "Time" and readyT) or (playbackMode == "Money" and readyM) or (readyT and readyM) then
                    UpdateStatus("Playing", "Step: "..step.." | "..act.Action)
                    if act.Action == "Place" and R.Spawn then SmartFire(R.Spawn, {act.UnitName, act.CFrame, act.Slot, act.Data})
                    elseif act.Action == "Upgrade" and R.Upgrade then local u = findUnitByCFrame(act.CFrame); if u then SmartFire(R.Upgrade, {u}) end
                    elseif act.Action == "Sell" and R.Sell then local u = findUnitByCFrame(act.CFrame); if u then SmartFire(R.Sell, {u}) end
                    elseif act.Action == "Ability" and R.Ability then local u = findUnitByCFrame(act.CFrame); if u then SmartFire(R.Ability, {act.SkillName, u}) end
                    elseif act.Action == "BuyMeat" and R.BuyMeat then SmartFire(R.BuyMeat, act.Args or {}) 
                    elseif act.Action == "FeedAll" and R.FeedAll then SmartFire(R.FeedAll, {})
                    elseif act.Action == "SkipWave" and R.Skip then SmartFire(R.Skip, {})
                    elseif act.Action == "AutoSpeed" and R.Speed then SmartFire(R.Speed, {})
                    end
                    step = step + 1
                else
                        if not readyT then UpdateStatus("Waiting", string.format("Time: %.1fs", act.Time - passed))
                        elseif not readyM then UpdateStatus("Waiting", "Cash: "..cash.."/"..cost) end
                end
            else
                UpdateStatus("Idle", "Macro Finished.")
                break
            end
            task.wait(0.1)
        end
    end)
end

task.spawn(function()
    local waitingForReplay = false

    while task.wait(0.5) do
        local eff = Workspace:FindFirstChild("Effect")
        local gameover = eff and eff:FindFirstChild("Gameover")
        local endUI = game:GetService("Players").LocalPlayer.PlayerGui.EndUI.UI
        

        if gameover or endUI.Position == UDim2.new(0.5, 0, 0.5, 0) and workspace.Day.Value >= 1 then
            print("Game OVER")
            waitingForReplay = true
            isPlaying = false

            if Options.AutoRestart.Value then
                firebutton(getUiButton("Restart"))
                --clickButton(getUiofButton("Restart"))
            elseif Options.AutoNext.Value then
                --firebutton(getUiButton("Next"))
                --clickButton(getUiofButton("Next"))
            elseif Options.AutoLeave.Value then
                --firebutton(getUiButton("Back"))
                --clickButton(getUiofButton("Back"))
            end
            
            task.wait(0.5)
        else
            print("Not GameOver")
            if waitingForReplay then
                print("Waiting For Replaying")
                waitingForReplay = false
                
                task.delay(0.5, function()
                    if Options.PlayToggle.Value then
                        playMacro()
                    end
                end)
            end
        end
    end
end)
