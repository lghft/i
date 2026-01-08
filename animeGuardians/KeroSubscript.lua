local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Anime Guardian Sub-Script | Kero:33",
   LoadingTitle = "MOEWTIE",
   LoadingSubtitle = "Made by Kero :333",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AnimeGuardianSub_V4",
      FileName = "KeroConfig"
   },
   KeySystem = false,
})

-- =============================================
-- VARIABLES & SERVICES
-- =============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Lobby Variables
local defaultStages = {"City of Shattered Frost", "Priestella", "Roswaal Mansion"}
local selectedStage = defaultStages[1]
local isFriendOnly = true
local isAutoHosting = false
local hostDelay = 0

-- Ancient Floor Variables
local isAutoAncientMax = false
local isAutoAncientCustom = false
local customAncientFloor = 1

-- Restart Variables
local targetCoins = 0
local targetWave = 0
local isAutoRestart = false

-- Teleport Variables
local isAutoBeherit = false
local targetBeherit = 0
local isAutoAncient = false
local targetAncient = 0

-- Shop Variables
local isAutoBuyCapsule = false
local buyCapsuleAmount = 1
local isAutoOpenCapsule = false
local openCapsuleAmount = 1
local isAutoBuyChristmas = false
local buyChristmasAmount = 1
local isAutoOpenChristmas = false
local openChristmasAmount = 1

-- Banner Variables
local selectedBanner = "OPMBanner"
local summonAmount = 1
local isAutoSummon = false

-- Modifier Variables
local isAutoBuy = false
local targetBuyWave = 0
local prioritySlot1 = "Golden Tribute"
local prioritySlot2 = "Power Surge"
local prioritySlot3 = "Saiya"
local prioritySlot4 = "Time Snare"
local modifierList = {"None", "Golden Tribute", "Power Surge", "Saiya", "Time Snare"}

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function getAvailableStages()
    local list = {}
    local stagesFolder = LocalPlayer:WaitForChild("Stages", 3) 
    if stagesFolder then
        for _, stageObj in ipairs(stagesFolder:GetChildren()) do
            table.insert(list, stageObj.Name)
        end
    end
    if #list == 0 then return defaultStages end
    table.sort(list)
    return list
end

local function cleanNumber(str)
    if not str then return 0 end
    local cleanStr = string.gsub(str, "%D", "") 
    return tonumber(cleanStr) or 0
end

local function getMyMoney()
    local mainGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
    if mainGui then
        local unitBar = mainGui:FindFirstChild("UnitBar")
        if unitBar then
            local dataFrame = unitBar:FindFirstChild("DataFrame")
            if dataFrame then
                local coinsLabel = dataFrame:FindFirstChild("Coins")
                if coinsLabel then return cleanNumber(coinsLabel.Text) end
            end
        end
    end
    return 0
end

local function getModifierPrice(modName)
    local npcShop = LocalPlayer.PlayerGui:FindFirstChild("Npc_Shop")
    if npcShop then
        local modShop = npcShop:FindFirstChild("ModifierShop")
        if modShop then
            local inset = modShop:FindFirstChild("Inset")
            if inset then
                local scroll = inset:FindFirstChild("ScrollingFrame")
                if scroll then
                    local item = scroll:FindFirstChild(modName)
                    if item then
                        local priceLabel = item:FindFirstChild("PriceText")
                        if priceLabel then return cleanNumber(priceLabel.Text) end
                    end
                end
            end
        end
    end
    return 999999999 
end

local function getCurrentWave()
    if LocalPlayer.PlayerGui:FindFirstChild("GUI") 
       and LocalPlayer.PlayerGui.GUI:FindFirstChild("BaseFrame") 
       and LocalPlayer.PlayerGui.GUI.BaseFrame:FindFirstChild("Wave") then
        local waveText = LocalPlayer.PlayerGui.GUI.BaseFrame.Wave.Text
        return cleanNumber(waveText)
    end
    return 0
end

local function getAncientMaxFloor()
    local stages = LocalPlayer:FindFirstChild("Stages")
    if stages then
        local ancientFolder = stages:FindFirstChild("The Lost Ancient World")
        if ancientFolder then
            local floorVal = ancientFolder:FindFirstChild("Floor")
            if floorVal then
                return tonumber(floorVal.Value) or 1
            end
        end
    end
    return 1
end

local function getBannerList()
    local list = {}
    local profileData = LocalPlayer:FindFirstChild("ProfileData")
    if profileData then
        local summonPity = profileData:FindFirstChild("SummonPity")
        if summonPity then
            for _, item in pairs(summonPity:GetChildren()) do
                table.insert(list, item.Name)
            end
        end
    end
    if #list == 0 then return {"OPMBanner"} end
    table.sort(list)
    return list
end

-- =============================================
-- TAB 1: LOBBY MANAGER
-- =============================================
local LobbyTab = Window:CreateTab("Lobby Manager", 4483362458)

LobbyTab:CreateSection("Normal Room Settings")
local StageDropdown = LobbyTab:CreateDropdown({
   Name = "Select Stage",
   Options = getAvailableStages(),
   CurrentOption = {selectedStage},
   Flag = "Lobby_Stage",
   Callback = function(Option) selectedStage = Option[1] end,
})
LobbyTab:CreateButton({
   Name = "Refresh List",
   Callback = function()
       local newStages = getAvailableStages()
       StageDropdown:Refresh(newStages, true)
       Rayfield:Notify({Title="Updated", Content="Found "..#newStages.." stages.", Duration=2})
   end,
})
LobbyTab:CreateToggle({Name="Friend Only", CurrentValue=true, Flag="Lobby_FriendOnly", Callback=function(V) isFriendOnly=V end})

LobbyTab:CreateSection("Automation (Normal)")
LobbyTab:CreateToggle({Name="Auto Host", CurrentValue=false, Flag="Lobby_AutoHost", Callback=function(V) isAutoHosting=V end})
LobbyTab:CreateSlider({Name="Start Delay (Seconds)", Range={0, 30}, Increment=1, Suffix="s", CurrentValue=0, Flag="Lobby_StartDelay", Callback=function(V) hostDelay=V end})

LobbyTab:CreateSection("Ancient Floor")
LobbyTab:CreateToggle({Name="Auto Host Ancient (Max Floor)", CurrentValue=false, Flag="Lobby_AutoAncientMax", Callback=function(V) isAutoAncientMax=V end})
LobbyTab:CreateLabel("Custom Ancient Floor | USE AT YOUR OWN RISK")
LobbyTab:CreateInput({Name="Put Ur Floor Number", PlaceholderText="e.g. 4000", Flag="Lobby_CustomFloorNum", Callback=function(T) customAncientFloor=tonumber(T) or 1 end})
LobbyTab:CreateToggle({Name="Auto Host Custom Floor", CurrentValue=false, Flag="Lobby_AutoAncientCustom", Callback=function(V) isAutoAncientCustom=V end})

-- =============================================
-- TAB 2: IN-GAME MANAGER
-- =============================================
local GameTab = Window:CreateTab("In-Game Manager", 4483362458)

GameTab:CreateSection("Modifier Shop")
GameTab:CreateToggle({Name="Auto Buy Modifiers", CurrentValue=false, Flag="Shop_AutoBuy", Callback=function(V) isAutoBuy=V end})
GameTab:CreateInput({Name="Min Wave to Buy", PlaceholderText="0", Flag="Shop_MinWave", Callback=function(T) targetBuyWave=tonumber(T) or 0 end})
GameTab:CreateLabel("Priority Order:")
GameTab:CreateDropdown({Name="Priority 1", Options=modifierList, CurrentOption={"Golden Tribute"}, Flag="P1", Callback=function(O) prioritySlot1=O[1] end})
GameTab:CreateDropdown({Name="Priority 2", Options=modifierList, CurrentOption={"Power Surge"}, Flag="P2", Callback=function(O) prioritySlot2=O[1] end})
GameTab:CreateDropdown({Name="Priority 3", Options=modifierList, CurrentOption={"Saiya"}, Flag="P3", Callback=function(O) prioritySlot3=O[1] end})
GameTab:CreateDropdown({Name="Priority 4", Options=modifierList, CurrentOption={"Time Snare"}, Flag="P4", Callback=function(O) prioritySlot4=O[1] end})

GameTab:CreateSection("Auto Restart")
GameTab:CreateToggle({Name="Auto Restart", CurrentValue=false, Flag="Restart_Master", Callback=function(V) isAutoRestart=V end})
GameTab:CreateInput({Name="Target Coins", PlaceholderText="0", Flag="Restart_Coins", Callback=function(T) targetCoins=tonumber(T) or 0 end})
GameTab:CreateInput({Name="Target Wave", PlaceholderText="0", Flag="Restart_Wave", Callback=function(T) targetWave=tonumber(T) or 0 end})
local StatusLabel = GameTab:CreateLabel("Status: Waiting...")

GameTab:CreateSection("Auto Teleport (Return to Lobby)")
GameTab:CreateToggle({Name="TP on Beherit", CurrentValue=false, Flag="TP_Beherit", Callback=function(V) isAutoBeherit=V end})
GameTab:CreateInput({Name="Target Beherit", PlaceholderText="Amount", Flag="TP_Beherit_Num", Callback=function(T) targetBeherit=tonumber(T) or 0 end})
GameTab:CreateToggle({Name="TP on Ancient", CurrentValue=false, Flag="TP_Ancient", Callback=function(V) isAutoAncient=V end})
GameTab:CreateInput({Name="Target Ancient", PlaceholderText="Amount", Flag="TP_Ancient_Num", Callback=function(T) targetAncient=tonumber(T) or 0 end})
local TeleportLabel = GameTab:CreateLabel("Inventory: Waiting...")

-- =============================================
-- TAB 3: SHOP MANAGER
-- =============================================
local ShopTab = Window:CreateTab("Shop Manager", 4483362458)

ShopTab:CreateSection("Ragna Capsule")
ShopTab:CreateInput({Name="Buy Amount", PlaceholderText="1", Flag="Ragna_BuyNum", Callback=function(T) buyCapsuleAmount=tonumber(T) or 1 end})
ShopTab:CreateToggle({Name="Auto Buy (Loop 1s)", CurrentValue=false, Flag="Ragna_AutoBuy", Callback=function(V) isAutoBuyCapsule=V end})
ShopTab:CreateInput({Name="Open Amount", PlaceholderText="1", Flag="Ragna_OpenNum", Callback=function(T) openCapsuleAmount=tonumber(T) or 1 end})
ShopTab:CreateToggle({Name="Auto Open (Loop 1s)", CurrentValue=false, Flag="Ragna_AutoOpen", Callback=function(V) isAutoOpenCapsule=V end})

ShopTab:CreateSection("Christmas Capsule")
ShopTab:CreateInput({Name="Buy Amount", PlaceholderText="1", Flag="Chris_BuyNum", Callback=function(T) buyChristmasAmount=tonumber(T) or 1 end})
ShopTab:CreateToggle({Name="Auto Buy (Loop 1s)", CurrentValue=false, Flag="Chris_AutoBuy", Callback=function(V) isAutoBuyChristmas=V end})
ShopTab:CreateInput({Name="Open Amount", PlaceholderText="1", Flag="Chris_OpenNum", Callback=function(T) openChristmasAmount=tonumber(T) or 1 end})
ShopTab:CreateToggle({Name="Auto Open (Loop 1s)", CurrentValue=false, Flag="Chris_AutoOpen", Callback=function(V) isAutoOpenChristmas=V end})

-- =============================================
-- TAB 4: BANNER MANAGER
-- =============================================
local BannerTab = Window:CreateTab("Banner Manager", 4483362458)
BannerTab:CreateSection("Summon Settings")
local BannerDropdown = BannerTab:CreateDropdown({
   Name = "Select Banner",
   Options = getBannerList(),
   CurrentOption = {selectedBanner},
   Flag = "Banner_Select",
   Callback = function(Option) selectedBanner = Option[1] end,
})
BannerTab:CreateButton({
   Name = "Refresh Banner List",
   Callback = function()
       local newBanners = getBannerList()
       BannerDropdown:Refresh(newBanners, true)
       Rayfield:Notify({Title="Updated", Content="Found "..#newBanners.." banners.", Duration=2})
   end,
})
BannerTab:CreateInput({Name="Summon Amount", PlaceholderText="1", Flag="Banner_Amount", Callback=function(T) summonAmount=tonumber(T) or 1 end})
BannerTab:CreateToggle({Name="Auto Summon (0.1s)", CurrentValue=false, Flag="Banner_AutoSummon", Callback=function(V) isAutoSummon=V end})

-- =============================================
-- TAB 5: SETTINGS
-- =============================================
local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateSection("Performance & UI")
SettingsTab:CreateToggle({
   Name = "White Screen (AFK Mode)",
   CurrentValue = false,
   Flag = "Set_WhiteScreen",
   Callback = function(Value)
      RunService:Set3dRenderingEnabled(not Value)
      if Value then Rayfield:Notify({Title="AFK Mode", Content="3D Rendering Disabled", Duration=3}) else Rayfield:Notify({Title="Active Mode", Content="3D Rendering Enabled", Duration=3}) end
   end,
})
SettingsTab:CreateToggle({
   Name = "Hide Game UI",
   CurrentValue = false,
   Flag = "Set_HideGameUI",
   Callback = function(Value)
      local gui = LocalPlayer.PlayerGui:FindFirstChild("GUI") or LocalPlayer.PlayerGui:FindFirstChild("Main")
      if gui then gui.Enabled = not Value end
      local hotbar = LocalPlayer.PlayerGui:FindFirstChild("Hotbar")
      if hotbar then hotbar.Enabled = not Value end
   end,
})
SettingsTab:CreateSection("Hub Settings")
SettingsTab:CreateKeybind({Name = "Toggle Hub Keybind", CurrentKeybind = "RightControl", HoldToInteract = false, Flag = "Set_Keybind", Callback = function(Keybind) end})
SettingsTab:CreateButton({Name = "Destroy UI (Unload)", Callback = function() Rayfield:Destroy() end})

-- =============================================
-- LOGIC LOOPS
-- =============================================

-- 1. Auto Host
task.spawn(function()
    while true do
        if isAutoHosting then
            local RoomFunction = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RoomFunction")
            if RoomFunction then
                pcall(function()
                    local args = { [1] = "host", [2] = { ["stage"] = selectedStage, ["friendOnly"] = isFriendOnly } }
                    RoomFunction:InvokeServer(unpack(args))
                    task.wait(1.5 + hostDelay)
                    RoomFunction:InvokeServer("start")
                end)
                task.wait(3)
            end
        end
        task.wait(1)
    end
end)

-- 2. Auto Host Ancient (UPDATED LOGIC)
task.spawn(function()
    while true do
        -- A. Auto Max Floor (Host -> Wait -> Start)
        if isAutoAncientMax then
            local CreatePortal = ReplicatedStorage:FindFirstChild("PlayMode") 
                                 and ReplicatedStorage.PlayMode:FindFirstChild("Events") 
                                 and ReplicatedStorage.PlayMode.Events:FindFirstChild("CreatingPortal")

            if CreatePortal then
                pcall(function()
                    local maxF = getAncientMaxFloor()
                    
                    -- STEP 1: HOST (Dùng code cũ như bạn yêu cầu)
                    local hostArgs = {
                        [1] = "Tower Adventures",
                        [2] = {
                            [1] = "The Lost Ancient World",
                            [2] = tostring(maxF),
                            [3] = "Tower Adventures"
                        }
                    }
                    CreatePortal:InvokeServer(unpack(hostArgs))
                    
                    task.wait(1.5 + hostDelay)
                    
                    -- STEP 2: START (Dùng remote "Create" mới, thay thế cho RoomFunction:Start)
                    local startArgs = {
                        [1] = "Create",
                        [2] = {
                            [1] = "The Lost Ancient World",
                            [2] = tostring(maxF), -- Tự động điền tầng cao nhất
                            [3] = "Tower Adventures"
                        }
                    }
                    CreatePortal:InvokeServer(unpack(startArgs))
                end)
                task.wait(3)
            end
            
        -- B. Custom Floor (Logic Riêng)
        elseif isAutoAncientCustom then
            local CreatePortal = ReplicatedStorage:FindFirstChild("PlayMode") and ReplicatedStorage.PlayMode:FindFirstChild("Events") and ReplicatedStorage.PlayMode.Events:FindFirstChild("CreatingPortal")
            local RoomFunction = ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RoomFunction")
            if CreatePortal and RoomFunction then
                pcall(function()
                    local args = {
                        "Create_Solo",
                        {
                            "The Lost Ancient World",
                            tostring(customAncientFloor),
                            "Tower Adventures"
                        }
                    }
                    CreatePortal:InvokeServer(unpack(args))
                    task.wait(1.5 + hostDelay)
                    RoomFunction:InvokeServer("start")
                end)
                task.wait(3)
            end
        end
        task.wait(1)
    end
end)

-- 3. Auto Restart
task.spawn(function()
    while true do
        local currentCoin = 0
        if LocalPlayer.PlayerGui:FindFirstChild("GUI") 
           and LocalPlayer.PlayerGui.GUI:FindFirstChild("BaseFrame") 
           and LocalPlayer.PlayerGui.GUI.BaseFrame:FindFirstChild("RewardFrame") 
           and LocalPlayer.PlayerGui.GUI.BaseFrame.RewardFrame:FindFirstChild("ChristmasCoin") then
            currentCoin = cleanNumber(LocalPlayer.PlayerGui.GUI.BaseFrame.RewardFrame.ChristmasCoin.Text)
        end
        local currentWave = getCurrentWave()
        StatusLabel:Set("Coin: " .. currentCoin .. " / " .. targetCoins .. " | Wave: " .. currentWave .. " / " .. targetWave)

        if isAutoRestart then
            local MiscAction = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Misc") and ReplicatedStorage.Remotes.Misc:FindFirstChild("Action")
            if MiscAction then
                local shouldRestart = false
                if targetCoins > 0 and currentCoin >= targetCoins then
                    Rayfield:Notify({Title = "Restarting", Content = "Target Coins Reached!", Duration = 3})
                    shouldRestart = true
                end
                if targetWave > 0 and currentWave >= targetWave then
                    Rayfield:Notify({Title = "Restarting", Content = "Target Wave Reached!", Duration = 3})
                    shouldRestart = true
                end
                if shouldRestart then
                    pcall(function() MiscAction:FireServer("Restart") end)
                    task.wait(10)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- 4. Auto Modifier
task.spawn(function()
    while true do
        if isAutoBuy then
            local currentWave = getCurrentWave()
            if currentWave >= targetBuyWave then
                local myMoney = getMyMoney()
                local ModifierShop = ReplicatedStorage:FindFirstChild("ModifierShop")
                local currentQueue = {prioritySlot1, prioritySlot2, prioritySlot3, prioritySlot4}
                if ModifierShop then
                    for _, modName in ipairs(currentQueue) do
                        if modName and modName ~= "None" then
                            local price = getModifierPrice(modName)
                            if myMoney >= price then
                                pcall(function() ModifierShop:InvokeServer(modName); myMoney = myMoney - price end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- 5. Auto Teleport (Lobby)
task.spawn(function()
    while true do
        local inv = LocalPlayer:FindFirstChild("ItemsInventory")
        local curBeherit = inv and inv:FindFirstChild("Beherit") and inv.Beherit:FindFirstChild("Amount") and inv.Beherit.Amount.Value or 0
        local curAncient = inv and inv:FindFirstChild("Dragonpoints") and inv.Dragonpoints:FindFirstChild("Amount") and inv.Dragonpoints.Amount.Value or 0
        TeleportLabel:Set("Beherit: " .. curBeherit .. " | Ancient: " .. curAncient)
        
        local TeleportRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Misc") and ReplicatedStorage.Remotes.Misc:FindFirstChild("Teleport")
        
        if TeleportRemote then
            if isAutoBeherit and targetBeherit > 0 and curBeherit >= targetBeherit then
                Rayfield:Notify({Title = "Teleporting", Content = "Beherit Target Reached!", Duration = 3})
                TeleportRemote:FireServer("Lobby")
                break
            end
            if isAutoAncient and targetAncient > 0 and curAncient >= targetAncient then
                Rayfield:Notify({Title = "Teleporting", Content = "Ancient Points Target Reached!", Duration = 3})
                TeleportRemote:FireServer("Lobby")
                break
            end
        end
        task.wait(5)
    end
end)

-- 6. Shop Loops
task.spawn(function()
    while true do
        if isAutoBuyCapsule and buyCapsuleAmount > 0 then
            local EventShop = ReplicatedStorage:FindFirstChild("PlayMode") and ReplicatedStorage.PlayMode:FindFirstChild("Events") and ReplicatedStorage.PlayMode.Events:FindFirstChild("EventShop")
            if EventShop then pcall(function() EventShop:InvokeServer(buyCapsuleAmount, "Ragna Capsule", "RagnaShop") end) end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if isAutoOpenCapsule and openCapsuleAmount > 0 then
            local UseEvent = ReplicatedStorage:FindFirstChild("PlayMode") and ReplicatedStorage.PlayMode:FindFirstChild("Events") and ReplicatedStorage.PlayMode.Events:FindFirstChild("Use")
            if UseEvent then pcall(function() UseEvent:InvokeServer("Ragna Capsule", openCapsuleAmount) end) end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if isAutoBuyChristmas and buyChristmasAmount > 0 then
            local remote = ReplicatedStorage:FindFirstChild("BLINK_RELIABLE_REMOTE")
            if remote then
                pcall(function()
                    local buf = buffer.fromstring("\014\r\000\017\002\000\000\000CHRISTMASSHOPChristmas Capsule")
                    buffer.writeu32(buf, 4, buyChristmasAmount)
                    remote:FireServer(buf, {})
                end)
            end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while true do
        if isAutoOpenChristmas and openChristmasAmount > 0 then
            local UseEvent = ReplicatedStorage:FindFirstChild("PlayMode") and ReplicatedStorage.PlayMode:FindFirstChild("Events") and ReplicatedStorage.PlayMode.Events:FindFirstChild("Use")
            if UseEvent then pcall(function() UseEvent:InvokeServer("Christmas Capsule", openChristmasAmount) end) end
        end
        task.wait(1)
    end
end)

-- 7. Banner Summon
task.spawn(function()
    while true do
        if isAutoSummon and summonAmount > 0 and selectedBanner then
            local SummonEvent = ReplicatedStorage:FindFirstChild("PlayMode") and ReplicatedStorage.PlayMode:FindFirstChild("Events") and ReplicatedStorage.PlayMode.Events:FindFirstChild("Summon")
            if SummonEvent then
                pcall(function() SummonEvent:InvokeServer(selectedBanner, summonAmount) end)
            end
        end
        task.wait(0.1)
    end
end)

Rayfield:LoadConfiguration()
