if getgenv().StopAllMacros then
    getgenv().StopAllMacros = true
    task.wait(0.2)
end
getgenv().StopAllMacros = false
getgenv().AutoUrara = false
getgenv().NativeAutoSkill = false
getgenv().AutoJoinAbyssLoop = false
getgenv().AutoCreateLoop = false
getgenv().AutoEventTimeLoop = false 
getgenv().AutoGraveLoop = false
getgenv().AutoResumeState = false
getgenv().WebhookEnabled = false 

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

if CoreGui:FindFirstChild("FluentMobileToggle_Fix_Duc") then CoreGui.FluentMobileToggle_Fix_Duc:Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("FluentMobileToggle_Fix_Duc") then LocalPlayer.PlayerGui.FluentMobileToggle_Fix_Duc:Destroy() end
for _, v in pairs(CoreGui:GetChildren()) do
    if v:IsA("ScreenGui") and v:FindFirstChild("Frame") and v.Frame:FindFirstChild("Title") and v.Frame.Title.Text == "AWTD" then
        v:Destroy()
    end
end

local function ParseTime(timeStr)
    if not timeStr then return "00:00" end
    local min, sec = timeStr:match("(%d+)%s*min%s*(%d+)%s*sec")
    if min and sec then return string.format("%02d:%02d", tonumber(min), tonumber(sec)) end
    return timeStr
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "AWTD",
    SubTitle = "Made By Kero:33",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

task.spawn(function()
    local IconImageID = "rbxassetid://80972749206953" 
    local ToggleGui = Instance.new("ScreenGui")
    local ToggleBtn = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    pcall(function() ToggleGui.Parent = CoreGui end)
    if not ToggleGui.Parent then ToggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    ToggleGui.Name = "FluentMobileToggle_Fix_Duc"
    ToggleGui.DisplayOrder = 10000 
    ToggleBtn.Parent = ToggleGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0) 
    ToggleBtn.Size = UDim2.fromOffset(55, 55)
    ToggleBtn.Image = IconImageID 
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true 
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = ToggleBtn
    UIStroke.Parent = ToggleBtn
    UIStroke.Thickness = 2
    UIStroke.Color = Color3.fromRGB(255, 105, 180)
    ToggleBtn.MouseButton1Click:Connect(function()
        local bind = Enum.KeyCode.RightControl
        if Fluent.Options.MenuKeybind and Fluent.Options.MenuKeybind.Value then bind = Fluent.Options.MenuKeybind.Value
        elseif Window.MinimizeKey then bind = Window.MinimizeKey end
        if typeof(bind) == "string" then bind = Enum.KeyCode[bind] end
        VirtualInputManager:SendKeyEvent(true, bind, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, bind, false, game)
    end)
end)

local MACRO_FOLDER = "AWTD_Macros_Kero"
local AutoConfigName = "AWTD_AutoSave_Kero" 
if getgenv().AutoResumeState == nil then getgenv().AutoResumeState = false end
local isRecording = false
local isPlaying = getgenv().AutoResumeState 
local currentMacroData = {} 
local currentMacroName = "" 
local startTime = 0
local playbackMode = "Hybrid" 
local AutoSkillConnections = {} 
local AllowedRemotes = { ["SpawnUnit"]=true, ["SellUnit"]=true, ["UpgradeUnit"]=true, ["UnitAbility"]=true, ["ChangeUnitModeFunction"]=true, ["BuyMeat"]=true, ["FeedAll"]=true, ["SkipEvent"]=true, ["x2Event"]=true }
if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

local PlacedUnitsRegistry = {}

local function SmartFire(remote, args, maxRetries)
    if not remote then return false end
    args = args or {}
    maxRetries = maxRetries or 3
    for attempt = 1, maxRetries do
        local ok = pcall(function()
            if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                remote:FireServer(unpack(args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(args))
            end
        end)
        if ok then return true end
        if attempt < maxRetries then task.wait(0.1) end
    end
    return false
end

local function CFrameToTable(cf) return {cf:GetComponents()} end
local function TableToCFrame(tab) return CFrame.new(unpack(tab)) end
local function getCash() local ls=LocalPlayer:FindFirstChild("leaderstats"); return (ls and ls:FindFirstChild("Cash")) and ls.Cash.Value or 0 end

local function findUnitByCFrame(tCF, ignorePlaced) 
    if not Workspace:FindFirstChild("Units") then return nil end
    local closestUnit = nil
    local minDist = 1.0 
    for _, u in pairs(Workspace.Units:GetChildren()) do 
        if not (ignorePlaced and PlacedUnitsRegistry[u]) then
            local r = u:FindFirstChild("HumanoidRootPart") or u.PrimaryPart
            if r then
                local dist = (r.Position - tCF.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestUnit = u
                end
            end 
        end
    end 
    return closestUnit 
end

local function getUiButton(name) 
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local path = pg:FindFirstChild("EndUI")
    if path then path = path:FindFirstChild("UI") end
    if path then path = path:FindFirstChild("Stage_Grid") end
    if path then path = path:FindFirstChild("Frame") end
    if path then path = path:FindFirstChild(name) end
    if path then return path:FindFirstChild("Button") end
    return nil 
end

local function firebutton(btn) 
    if not btn then return end
    local oldNav = GuiService.GuiNavigationEnabled
    local oldSel = GuiService.SelectedObject
    GuiService.GuiNavigationEnabled = true
    GuiService.SelectedObject = btn
    VirtualInputManager:SendKeyEvent(true, "Return", false, nil)
    VirtualInputManager:SendKeyEvent(false, "Return", false, nil)
    task.wait(0.1)
    GuiService.GuiNavigationEnabled = oldNav
    GuiService.SelectedObject = oldSel
end

local function getWave() if Workspace:FindFirstChild("Info") and Workspace.Info:FindFirstChild("Wave") then return Workspace.Info.Wave.Value end return 0 end
local function SaveCurrentMacro() if currentMacroName=="" then return end; local e={}; for _,a in ipairs(currentMacroData) do local n=table.clone(a); if n.CFrame then n.CFrame=CFrameToTable(n.CFrame) end; table.insert(e,n) end; writefile(MACRO_FOLDER.."/"..currentMacroName..".json", HttpService:JSONEncode(e)); end

local function LoadMacro(n) 
    if not isfile(MACRO_FOLDER.."/"..n..".json") then return end; 
    local c=readfile(MACRO_FOLDER.."/"..n..".json"); 
    local d=HttpService:JSONDecode(c); 
    currentMacroData={}; 
    for _,a in ipairs(d) do 
        if a.CFrame then a.CFrame=TableToCFrame(a.CFrame) end; 
        table.insert(currentMacroData,a) 
    end; 
    currentMacroName=n 
end

local function GetMacroFiles() local f=listfiles(MACRO_FOLDER); local n={}; for _,v in ipairs(f) do local nm=v:match("([^/]+)%.json$"); if nm then table.insert(n,nm) end end; table.sort(n); return n end

local function getUnitUpgradeCost(unit)
    if unit and unit:FindFirstChild("Info") and unit.Info:FindFirstChild("UpgradeCost") then return unit.Info.UpgradeCost.Value end
    return 0 
end

local function MonitorUnitAutoSkill(unit)
    if not unit then return end
    task.spawn(function()
        local info = unit:WaitForChild("Info", 5)
        if info then
            local autoVal = info:WaitForChild("AutoAbility", 5)
            if autoVal and autoVal:IsA("BoolValue") then
                local conn = autoVal.Changed:Connect(function(newVal)
                    if isRecording then
                        local currentTime = tick() - startTime
                        local currentWave = getWave()
                        if unit.PrimaryPart then
                            table.insert(currentMacroData, { Action = "AutoSkill", Time = currentTime, Wave = currentWave, Cost = 0, CFrame = unit.PrimaryPart.CFrame, State = newVal })
                        end
                    end
                end)
                table.insert(AutoSkillConnections, conn)
            end
        end
    end)
end

local function CleanupAutoSkillConnections() for _, conn in pairs(AutoSkillConnections) do if conn then conn:Disconnect() end end AutoSkillConnections = {} end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    if checkcaller() then return oldNamecall(self, ...) end
    if not isRecording then return oldNamecall(self, ...) end
    local method = getnamecallmethod()
    if (method == "InvokeServer" or method == "FireServer") and AllowedRemotes[self.Name] then
        local rName, args = self.Name, {...}
        task.spawn(function() pcall(function()
            local currentTime = tick() - startTime
            local currentWave = getWave()
            local preCash = getCash()
            if rName == "SpawnUnit" then 
                task.wait(0.5)
                table.insert(currentMacroData, {Action="Place", Time=currentTime, Wave=currentWave, Cost=math.max(0, preCash - getCash()), UnitName=args[1], CFrame=args[2], Slot=args[3], Data=args[4]})
            elseif rName == "SellUnit" then local u=args[1]; if u and u.PrimaryPart then table.insert(currentMacroData, {Action="Sell", Time=currentTime, Wave=currentWave, Cost=0, CFrame=u.PrimaryPart.CFrame}) end
            elseif rName == "UpgradeUnit" then task.wait(0.5); local u=args[1]; if u and u.PrimaryPart then table.insert(currentMacroData, {Action="Upgrade", Time=currentTime, Wave=currentWave, Cost=math.max(0, preCash - getCash()), CFrame=u.PrimaryPart.CFrame}) end
            elseif rName == "UnitAbility" then 
                local u = args[2]
                if u and u.PrimaryPart then table.insert(currentMacroData, { Action="Ability", Time=currentTime, Wave=currentWave, Cost=0, SkillName=args[1], CFrame=u.PrimaryPart.CFrame, AbilityData=args[3] }) end
            elseif rName == "ChangeUnitModeFunction" then
                local u = args[1]
                if u and u.PrimaryPart then table.insert(currentMacroData, {Action="TargetMode", Time=currentTime, Wave=currentWave, Cost=0, CFrame=u.PrimaryPart.CFrame}) end
            elseif rName == "BuyMeat" then task.wait(0.5); table.insert(currentMacroData, {Action="BuyMeat", Time=currentTime, Wave=currentWave, Cost=math.max(0, preCash - getCash()), Args=args})
            elseif rName == "FeedAll" then table.insert(currentMacroData, {Action="FeedAll", Time=currentTime, Wave=currentWave, Cost=0})
            elseif rName == "SkipEvent" then table.insert(currentMacroData, {Action="SkipWave", Time=currentTime, Wave=currentWave, Cost=0})
            elseif rName == "x2Event" then table.insert(currentMacroData, {Action="AutoSpeed", Time=currentTime, Wave=currentWave, Cost=0})
            end
        end) end)
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

local Tabs = {
    Macro = Window:AddTab({ Title = "Macro Manager", Icon = "file-cog" }),
    Ability = Window:AddTab({ Title = "Ability Manager", Icon = "star" }),
    Lobby = Window:AddTab({ Title = "Lobby Manager", Icon = "home" }),
    Webhook = Window:AddTab({ Title = "Webhook Manager", Icon = "bell" }), 
    Misc = Window:AddTab({ Title = "Misc", Icon = "components" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options

local StatusParagraph = Tabs.Macro:AddParagraph({ Title = "Status: Idle", Content = "Waiting..." })
local function UpdateStatus(status, details) if StatusParagraph then StatusParagraph:SetTitle("Status: " .. status) StatusParagraph:SetDesc(details or "") end end
Tabs.Macro:AddInput("InputMacroName", {Title = "New Macro Name", Placeholder = "MapName_Diff"})
Tabs.Macro:AddButton({Title = "Create New File", Callback = function() local n=Options.InputMacroName.Value; if n~="" then currentMacroName=n; currentMacroData={}; SaveCurrentMacro(); Options.FileSelect:SetValues(GetMacroFiles()); Options.FileSelect:SetValue(n) end end})
Tabs.Macro:AddDropdown("FileSelect", {Title = "Select File", Values = GetMacroFiles(), Default = 1, Callback = function(v) if v then LoadMacro(v) end end})
task.delay(1, function() local f=GetMacroFiles(); if #f>0 then LoadMacro(f[1]); Options.FileSelect:SetValue(f[1]) end end)
Tabs.Macro:AddButton({Title = "Refresh / Delete", Callback = function() if currentMacroName~="" and isfile(MACRO_FOLDER.."/"..currentMacroName..".json") then delfile(MACRO_FOLDER.."/"..currentMacroName..".json"); currentMacroName=""; currentMacroData={}; Options.FileSelect:SetValues(GetMacroFiles()); Options.FileSelect:SetValue(nil) else Options.FileSelect:SetValues(GetMacroFiles()) end end})

Tabs.Macro:AddToggle("RecordToggle", {Title = "Record", Default = false }):OnChanged(function(v) 
    if v then 
        isPlaying=false; isRecording=true; currentMacroData={}; startTime=tick(); 
        UpdateStatus("Recording", "Started...") 
        CleanupAutoSkillConnections()
        if Workspace:FindFirstChild("Units") then
            for _, u in pairs(Workspace.Units:GetChildren()) do MonitorUnitAutoSkill(u) end
            local spawnConn = Workspace.Units.ChildAdded:Connect(MonitorUnitAutoSkill)
            table.insert(AutoSkillConnections, spawnConn)
        end
    else 
        isRecording=false; CleanupAutoSkillConnections(); SaveCurrentMacro(); UpdateStatus("Stopped", "Saved.") 
    end 
end)

Tabs.Macro:AddDropdown("ModeSelect", {Title = "Mode", Values = {"Time", "Money", "Hybrid"}, Default = "Hybrid", Callback = function(v) playbackMode = v end})
Tabs.Macro:AddToggle("PlayToggle", {Title = "Play", Default = getgenv().AutoResumeState}):OnChanged(function(v) getgenv().AutoResumeState = v; if v then isRecording=false; playMacro() else isPlaying=false; UpdateStatus("Stopped", "User Cancelled") end end)

Tabs.Ability:AddToggle("AutoUraraToggle", {Title = "Auto Urara Ability", Default = false }):OnChanged(function(Value)
    getgenv().AutoUrara = Value
    if Value then
        task.spawn(function()
            while getgenv().AutoUrara do
                pcall(function()
                    local unitsFolder = Workspace:FindFirstChild("Units")
                    if unitsFolder then
                        for _, unit in pairs(unitsFolder:GetChildren()) do
                            if string.find(unit.Name, "Urara") then 
                                local isMine = false
                                local ownerTag = unit:FindFirstChild("Owner") or (unit:FindFirstChild("Info") and unit.Info:FindFirstChild("Owner"))
                                if ownerTag then
                                    if ownerTag.Value == LocalPlayer then isMine = true
                                    elseif tostring(ownerTag.Value) == LocalPlayer.Name then isMine = true
                                    elseif tonumber(ownerTag.Value) == LocalPlayer.UserId then isMine = true
                                    end
                                end
                                if isMine then
                                    local args = { [1] = "Kannonbiraki Benihime Aratame", [2] = unit }
                                    ReplicatedStorage:WaitForChild("Remote"):WaitForChild("UnitAbility"):FireServer(unpack(args))
                                end
                            end
                        end
                    end
                end)
                task.wait(1) 
            end
        end)
    end
end)

Tabs.Lobby:AddSection("Auto Game Functions")
Tabs.Lobby:AddToggle("AutoRestart", {Title = "Auto Restart", Default = false })
Tabs.Lobby:AddToggle("AutoNext", {Title = "Auto Next", Default = false })
Tabs.Lobby:AddToggle("AutoLeave", {Title = "Auto Leave", Default = false })

Tabs.Lobby:AddSection("Event")
Tabs.Lobby:AddDropdown("EventTimeSelect", { Title = "Select Time", Values = {"Day", "Night", "Cycle"}, Default = "Cycle" })
Tabs.Lobby:AddToggle("AutoPickTime", {Title = "Auto Pick Time", Default = false }):OnChanged(function(v)
    getgenv().AutoEventTimeLoop = v
    if v then
        task.spawn(function()
            while getgenv().AutoEventTimeLoop do
                local val = Options.EventTimeSelect.Value
                if val then
                    local args = { [1] = val }
                    local remote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("Update")
                    if remote then remote:FireServer(unpack(args)) end
                end
                task.wait(2)
            end
        end)
    end
end)

Tabs.Lobby:AddToggle("AutoGrave", {Title = "Auto Reveal Graves", Default = false }):OnChanged(function(v)
    getgenv().AutoGraveLoop = v
    if v then
        task.spawn(function()
            while getgenv().AutoGraveLoop do
                pcall(function()
                    local map = Workspace:FindFirstChild("Map")
                    if map and map:FindFirstChild("Graves") then
                        for _, grave in pairs(map.Graves:GetChildren()) do
                            if not getgenv().AutoGraveLoop then break end
                            local part = grave:FindFirstChild("Part")
                            if part then
                                local event = part:FindFirstChild("GraveEvent")
                                if event then
                                    local remote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("GraveEvent")
                                    if remote then SmartFire(remote, {event}, 1) end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
end)

Tabs.Lobby:AddSection("Abyss Bypass")
Tabs.Lobby:AddInput("AbyssFloorInput", {Title = "Bypass Abyss Floor", Default = "40", Numeric = true, Callback = function(v) end})
Tabs.Lobby:AddToggle("AutoJoinAbyss", {Title = "Auto Join Abyss", Default = false }):OnChanged(function(v)
    getgenv().AutoJoinAbyssLoop = v
    if v then 
        task.spawn(function() 
            while getgenv().AutoJoinAbyssLoop do 
                local currentFloor = Options.AbyssFloorInput.Value
                if currentFloor == nil or currentFloor == "" then currentFloor = "40" end
                local r = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("TeleportToStage")
                if r then r:FireServer("Abyss_" .. tostring(currentFloor)) end
                task.wait(2) 
            end 
        end) 
    end
end)
Tabs.Lobby:AddSection("Create/Join Room")
local MapData = {
    ["Event Stage"] = {"Boss Rush", "Random Unit", "Forbidden Graveyard", "Training Field", "Work Field"},
    ["Resource Mode"] = {"Metal Rush", "Blue Element", "Red Element", "Green Element", "Purple Element", "Yellow Element"},
    ["Raid Mode"] = {"The Rumbling", "Esper City", "String Kingdom", "Ruin Society", "Soul Hall", "Katana Revenge", "Pillar Cave", "Spider MT.Raid", "Katamura City Raid", "Kujaku House", "Hero City Raid", "MarineFord Raid", "Idol Concert", "Evil Pink Dungeon", "Exploding Planet", "Charuto Bridge"},
    ["Legend Stages"] = {"Fairy Camelot", "Z Game", "Android Future", "Paradox Invasion", "Victory Valley", "Shinobi Battleground", "Dream Island", "Tomb of the Star", "Shadow Realm", "Chaos Return"},
    ["Quest Stages"] = {"The Eclipse"},
    ["Special Event"] = {"Reaper Town"}
}
local ModeList = {"Event Stage", "Resource Mode", "Raid Mode", "Legend Stages", "Quest Stages", "Special Event"}
local DiffList = {"Normal", "Insane", "Nightmare", "Master", "Challenger", "Unique"}
Tabs.Lobby:AddDropdown("RoomMode", { Title = "Select Mode", Values = ModeList, Default = "Special Event", Callback = function(Value) if Options.RoomStage then Options.RoomStage:SetValues(MapData[Value] or {}); Options.RoomStage:SetValue(MapData[Value][1]) end end })
Tabs.Lobby:AddDropdown("RoomStage", {Title = "Select Stage", Values = MapData["Special Event"], Default = "Reaper Town"})
Tabs.Lobby:AddDropdown("RoomDiff", {Title = "Select Difficulty", Values = DiffList, Default = "Unique"})
Tabs.Lobby:AddToggle("RoomFriendOnly", {Title = "Friend Only", Default = false })
Tabs.Lobby:AddToggle("AutoCreateRoom", {Title = "Auto Join/Create", Default = false }):OnChanged(function(v)
    getgenv().AutoCreateLoop = v
    if v then
        task.spawn(function()
            while getgenv().AutoCreateLoop do
                local args = { [1] = { ["StageSelect"] = Options.RoomStage.Value, ["Image"] = "", ["FriendOnly"] = Options.RoomFriendOnly.Value, ["Difficult"] = Options.RoomDiff.Value } }
                local remote = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("CreateRoom")
                if remote then remote:FireServer(unpack(args)) end
                task.wait(1.5) 
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    local qsBtn = pg:FindFirstChild("InRoomUi") and pg.InRoomUi:FindFirstChild("RoomUI") and pg.InRoomUi.RoomUI:FindFirstChild("QuickStart") and pg.InRoomUi.RoomUI.QuickStart:FindFirstChild("TextButton")
                    if qsBtn and qsBtn.Visible then firebutton(qsBtn) end
                end
                task.wait(1) 
            end
        end)
    end
end)

Tabs.Webhook:AddSection("Discord Configuration")
Tabs.Webhook:AddInput("WebhookURL", { Title = "Webhook URL", Default = "", Placeholder = "Paste Discord Webhook Here", Callback = function(Value) end })
Tabs.Webhook:AddToggle("WebhookToggle", { Title = "Send Webhook on Game End", Default = false }):OnChanged(function(Value) getgenv().WebhookEnabled = Value end)

local function SendGameWebhook(status)
    local url = Options.WebhookURL.Value
    if url == "" then return end
    task.wait(4)
    local requestFunc = (http_request or request or syn.request or fluxus.request)
    if not requestFunc then return end
    local Data = LocalPlayer:WaitForChild("Data")
    local gold = Data:WaitForChild("Gold").Value
    local level = Data:WaitForChild("Level").Value
    local puzzles = Data:WaitForChild("Puzzles").Value
    local stageName = "Unknown Stage"
    local stageSelect = Workspace:FindFirstChild("StageSelect")
    if stageSelect then stageName = stageSelect.Value end
    local timeStr = "00:00"
    pcall(function() timeStr = LocalPlayer.PlayerGui.EndUI.UI.Stats_Grid.TotalTime.Frame.Val.Text end)
    timeStr = ParseTime(timeStr)
    local itemsCollected = {}
    local EndUI = LocalPlayer.PlayerGui:FindFirstChild("EndUI")
    if EndUI then
        local itemContainer = EndUI:WaitForChild("UI"):WaitForChild("ItemYouGot")
        for _, child in pairs(itemContainer:GetChildren()) do
            if child:IsA("Frame") then 
                local countLabel = child:FindFirstChild("Count")
                if countLabel then table.insert(itemsCollected, string.format("- %s [%s]", child.Name, countLabel.Text)) end
            end
        end
    end
    local collectedString = #itemsCollected > 0 and table.concat(itemsCollected, "\n") or "None"
    local embedColor = (status == "Victory") and 65280 or 16711680
    local headerIcon = "https://i.postimg.cc/1RYRdwrS/Bo-suu-tap.jpg"
    local mainImage = "https://i.postimg.cc/TwNxZvmw/no-Filter.webp"
    local footerIcon = "https://i.postimg.cc/HWKcyfKJ/download-(2).jpg"
    local Payload = {
        ["embeds"] = {{
            ["title"] = "AWTD", 
            ["description"] = string.format("**Stage:** %s\n**Result:** %s", stageName, status),
            ["color"] = embedColor,
            ["thumbnail"] = { ["url"] = headerIcon },
            ["image"] = { ["url"] = mainImage },
            ["fields"] = {
                { ["name"] = "Player Info", ["value"] = string.format("👤 Name: ||%s||\n⭐ Level: %s\n💰 Gold: %s\n🧩 Puzzles: %s", LocalPlayer.Name, level, gold, puzzles), ["inline"] = false },
                { ["name"] = "Resources Collected", ["value"] = collectedString, ["inline"] = false },
                { ["name"] = "Match Details", ["value"] = string.format("⏱️ Time: %s", timeStr), ["inline"] = false }
            },
            ["footer"] = { ["text"] = "Made By Kero:333", ["icon_url"] = footerIcon },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }
    requestFunc({ Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(Payload) })
end

Tabs.Webhook:AddButton({ Title = "Test Send Webhook", Description = "Send a test webhook", Callback = function() SendGameWebhook("Test Victory") end })

Tabs.Misc:AddSection("Auto Execute")
Tabs.Misc:AddToggle("AutoExec", {Title = "Auto Execute", Default = false }):OnChanged(function(v)
    getgenv().AutoExec = v
    if v then
        local queue_on_teleport = queue_on_teleport or syn.queue_on_teleport or fluxus.queue_on_teleport
        if queue_on_teleport then
            queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/KeroTwT/Kero-Hub/main/AWTD"))()')
        end
    end
end)

Tabs.Misc:AddSection("FPS Boost")
Tabs.Misc:AddButton({Title = "Boost FPS", Callback = function()
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 9e9
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            v.Color = Color3.new(1, 1, 1)
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end})

Tabs.Misc:AddSection("Privacy")
Tabs.Misc:AddToggle("HideUser", {Title = "Hide User", Default = false }):OnChanged(function(v)
    getgenv().HideUserLoop = v
    if v then
        task.spawn(function()
            while getgenv().HideUserLoop do
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char and LocalPlayer.Name then char = workspace:FindFirstChild(LocalPlayer.Name) end
                    
                    if char then
                        -- Hide Name
                        if char:FindFirstChild("Head") then
                            local pt = char.Head:FindFirstChild("PlayerTag")
                            if pt and pt:FindFirstChild("Info") and pt.Info:FindFirstChild("PlayerName") then
                                pt.Info.PlayerName:Destroy()
                            end
                        end
                        
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        end
                        
                        -- Aggressive Loop
                        for _, child in pairs(char:GetChildren()) do
                            if child:IsA("Accessory") or child:IsA("Accoutrement") or child:IsA("Clothing") or child:IsA("CharacterMesh") or child:IsA("BodyColors") then
                                child:Destroy()
                            elseif child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                                child.Color = Color3.fromRGB(255, 0, 0)
                                child.Material = Enum.Material.SmoothPlastic
                                child.Transparency = 0
                            end
                        end
                    end
                end)
                task.wait(0.1)
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

task.spawn(function()
    task.wait(1) 
    pcall(function() SaveManager:Load(AutoConfigName) end)
end)

task.spawn(function()
    while true do task.wait(5); pcall(function() SaveManager:Save(AutoConfigName) end) end
end)

function playMacro()
    if #currentMacroData == 0 then return end
    isPlaying = true
    PlacedUnitsRegistry = {} 

    task.spawn(function()
        UpdateStatus("Starting...", "Match Start")
        local startT = tick()
        local step = 1
        local R = ReplicatedStorage:WaitForChild("Remote")
        local Rem = { Spawn=R:FindFirstChild("SpawnUnit"), Sell=R:FindFirstChild("SellUnit"), Upgrade=R:FindFirstChild("UpgradeUnit"), Ability=R:FindFirstChild("UnitAbility"), TargetMode=R:FindFirstChild("ChangeUnitModeFunction"), BuyMeat=R:FindFirstChild("BuyMeat"), FeedAll=R:FindFirstChild("FeedAll"), Skip=R:FindFirstChild("SkipEvent"), Speed=R:FindFirstChild("x2Event") }

        while isPlaying do
            if getgenv().StopAllMacros then break end
            local eff = Workspace:FindFirstChild("Effect")
            if eff and (eff:FindFirstChild("Gameover") or eff:FindFirstChild("Victory")) then isPlaying = false; UpdateStatus("Stopped", "Game Ended"); break end

            if step <= #currentMacroData then
                local act = currentMacroData[step]
                local passed = tick() - startT
                local cash = getCash()
                local cost = act.Cost or 0
                local readyT = passed >= act.Time
                local readyM = true
                if playbackMode ~= "Time" and cost > 0 then readyM = cash >= cost end
                
                if (playbackMode == "Time" and readyT) or (playbackMode == "Money" and readyM) or (readyT and readyM) then
                    local stepDone = false
                    UpdateStatus("Executing", "Step: "..step.." | "..act.Action)

                    if act.Action == "Place" and Rem.Spawn then
                        local attempts = 0
                        repeat
                            if getgenv().StopAllMacros or not isPlaying then break end
                            local u = findUnitByCFrame(act.CFrame, true) 
                            if u then 
                                stepDone = true
                                PlacedUnitsRegistry[u] = true
                            else
                                attempts = attempts + 1
                                if attempts > 200 then
                                    stepDone = true 
                                else
                                    if getCash() >= cost then
                                        SmartFire(Rem.Spawn, {act.UnitName, act.CFrame, act.Slot, act.Data}, 3)
                                    end
                                    task.wait(0.1)
                                end
                            end
                        until stepDone

                    elseif act.Action == "Upgrade" and Rem.Upgrade then
                        local u = findUnitByCFrame(act.CFrame, false)
                        if u then
                            if getUnitUpgradeCost(u) <= 0 then stepDone = true else
                                if getCash() >= cost then
                                    SmartFire(Rem.Upgrade, {u}, 3)
                                    stepDone = true
                                else
                                    UpdateStatus("Waiting Cash", "Needed: "..cost)
                                end
                            end
                        else stepDone = true end

                    elseif act.Action == "Sell" and Rem.Sell then
                        local u = findUnitByCFrame(act.CFrame, false)
                        if u then SmartFire(Rem.Sell, {u}, 3) end
                        stepDone = true

                    elseif act.Action == "TargetMode" and Rem.TargetMode then
                        local u = findUnitByCFrame(act.CFrame, false)
                        if u then SmartFire(Rem.TargetMode, {u}, 3) end
                        stepDone = true

                    elseif act.Action == "AutoSkill" then
                        local u = findUnitByCFrame(act.CFrame, false)
                        if u and u:FindFirstChild("Info") then local autoVal = u.Info:FindFirstChild("AutoAbility") if autoVal and autoVal:IsA("BoolValue") then autoVal.Value = act.State end end
                        stepDone = true

                    elseif act.Action == "Ability" and Rem.Ability then 
                        local u = findUnitByCFrame(act.CFrame, false)
                        if u then 
                            if act.AbilityData then SmartFire(Rem.Ability, {act.SkillName, u, act.AbilityData}, 3) else SmartFire(Rem.Ability, {act.SkillName, u}, 3) end 
                        end
                        stepDone = true 

                    elseif act.Action == "BuyMeat" and Rem.BuyMeat then SmartFire(Rem.BuyMeat, act.Args or {}, 3); stepDone = true 
                    elseif act.Action == "FeedAll" and Rem.FeedAll then SmartFire(Rem.FeedAll, {}, 3); stepDone = true
                    elseif act.Action == "SkipEvent" and Rem.Skip then SmartFire(Rem.Skip, {}, 3); stepDone = true
                    elseif act.Action == "SkipWave" and Rem.Skip then SmartFire(Rem.Skip, {}, 3); stepDone = true
                    elseif act.Action == "AutoSpeed" and Rem.Speed then SmartFire(Rem.Speed, {}, 3); stepDone = true
                    else stepDone = true end
                    
                    if stepDone then step = step + 1 end
                else
                    local stepName = act.Action
                    if act.UnitName then stepName = stepName .. " [" .. act.UnitName .. "]" end
                    if act.SkillName then stepName = stepName .. " [" .. act.SkillName .. "]" end
                    local waitInfo = ""
                    if not readyT then waitInfo = string.format("Wait Time: %.1fs", act.Time - passed)
                    elseif not readyM then waitInfo = string.format("Wait Cash: %d/%d", cash, cost) end
                    UpdateStatus("Waiting", string.format("Next: %s\nCost: %d$\n%s", stepName, cost, waitInfo))
                end
            else UpdateStatus("Waiting", "Macro Done") end
            task.wait(0.05)
        end
    end)
end

if getgenv().AutoResumeState then
    task.delay(2, function() if currentMacroName == "" then local f=GetMacroFiles(); if #f>0 then LoadMacro(f[1]) end end; end)
end

task.spawn(function()
    local wasEnded = false
    while task.wait(0.5) do
        if getgenv().StopAllMacros then break end
        local eff = Workspace:FindFirstChild("Effect")
        if eff and (eff:FindFirstChild("Gameover") or eff:FindFirstChild("Victory")) then
            local status = eff:FindFirstChild("Victory") and "Victory" or "Lose"
            if not wasEnded then 
                wasEnded = true
                isPlaying = false
                task.wait(2) 
                if getgenv().WebhookEnabled then SendGameWebhook(status) end
                if Options.AutoRestart.Value then 
                    local btn = getUiButton("Restart")
                    if btn and btn.Visible then firebutton(btn) end
                elseif Options.AutoNext.Value then 
                    local btn = getUiButton("Next")
                    if btn and btn.Visible then firebutton(btn) end
                elseif Options.AutoLeave.Value then 
                    local btn = getUiButton("Back")
                    if btn and btn.Visible then firebutton(btn) end
                end
            end
        elseif wasEnded then
            wasEnded = false
            if Options.PlayToggle.Value then playMacro() end
        end
    end
end)
