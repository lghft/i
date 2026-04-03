local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerScripts = player:WaitForChild("PlayerScripts")
local cashStat = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local currentCash = cashStat.Value  -- seed từ leaderstats, sau đó update qua event
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerGui = player:WaitForChild("PlayerGui")
local function setThreadIdentity(identity)
    if setthreadidentity then setthreadidentity(identity)
    elseif syn and syn.set_thread_identity then syn.set_thread_identity(identity) end
end

local function SmartWait(seconds)
    if not seconds or seconds <= 0 then RunService.RenderStepped:Wait(); return end
    local start = tick()
    while tick() - start < seconds do RunService.RenderStepped:Wait() end
end

local function SafeRemoteCall(remoteType, remote, ...)
    local args = {...}
    task.spawn(function()
        setThreadIdentity(2)
        if remoteType == "FireServer" then pcall(function() remote:FireServer(unpack(args)) end)
        elseif remoteType == "InvokeServer" then pcall(function() remote:InvokeServer(unpack(args)) end) end
    end)
end

local function getGlobalEnv() return (getgenv and getgenv()) or _G end
local globalEnv = getGlobalEnv()

local defaultConfig = {
    ["Macro Name"] = "endless",
    ["PlaceMode"] = "Rewrite",
    ["ForceRebuildEvenIfSold"] = false,
    ["MaxRebuildRetry"] = nil,
    ["SellAllDelay"] = 0.1,
    ["PriorityRebuildOrder"] = {"EDJ", "Medic", "Commander", "Mobster", "Golden Mobster", "Combat Drone", "Shield Tower"},
    ["TargetChangeCheckDelay"] = 0.05,
    ["RebuildPriority"] = true,
    ["RebuildCheckInterval"] = 0,
    ["MacroStepDelay"] = 0.1,
    ["MaxConcurrentRebuilds"] = 120,
    ["MonitorCheckDelay"] = 0.05,
    ["AllowParallelTargets"] = false,
    ["AllowParallelSkips"] = true,
    ["UseThreadedRemotes"] = true,
    ["ShopInstantMode"] = true,
    -- Timing-based execution (wait for recorded wave/time before acting)
    ["PlaceByTiming"] = false,
    ["UpgradeByTiming"] = false,
    ["SellByTiming"] = false,
    ["MovePlayer"] = true,
}

globalEnv.TDX_Config = globalEnv.TDX_Config or {}
for key, value in pairs(defaultConfig) do
    if globalEnv.TDX_Config[key] == nil then globalEnv.TDX_Config[key] = value end
end

local function safeReadFile(path) return (isfile and readfile and pcall(readfile, path)) and readfile(path) or nil end
local function safeIsFile(path) return (isfile and pcall(isfile, path)) and isfile(path) or false end
local GameModules = { Networking = nil, LevelUtils = nil, TowerClass = nil, ShopUtils = nil, PowerUpsConfig = nil, GameClass = nil }

local function InitializeModules()
    local Common = ReplicatedStorage:WaitForChild("TDX_Shared"):WaitForChild("Common")
    local function RequireSafe(mod)
        local t0 = tick()
        while tick() - t0 < 5 do
            local ok, m = pcall(require, mod)
            if ok and m then return m end
            RunService.RenderStepped:Wait()
        end
        return nil
    end

    GameModules.Networking = RequireSafe(Common:WaitForChild("NetworkingHandler"))
    GameModules.LevelUtils = RequireSafe(Common:WaitForChild("LevelHandlerUtilities"))
    GameModules.ShopUtils = RequireSafe(Common:WaitForChild("TowerUpgradeShopUtilities"))
    pcall(function()
        GameModules.PowerUpsConfig = require(Common.Resources.Misc.PowerUpsConfigHandler)
    end)

    local Client = PlayerScripts:WaitForChild("Client")
    local GameClassMod = Client:FindFirstChild("GameClass")
    if GameClassMod then
        GameModules.GameClass = RequireSafe(GameClassMod)
        local TowerMod = GameClassMod:FindFirstChild("TowerClass")
        if TowerMod then GameModules.TowerClass = RequireSafe(TowerMod) end
    end
    if not GameModules.TowerClass then error("Failed to load TowerClass") end
end
InitializeModules()

-- Đọc tiền trực tiếp từ UpdateCash (StatsHandlerClass) thay vì leaderstats.Value
-- UpdateCash fire ngay khi server replicate, nhanh và chính xác hơn IntValue replication
GameModules.Networking.GetEvent("UpdateCash"):AttachCallback(function(cash)
    currentCash = cash
end)
cashStat.Changed:Connect(function(v) if currentCash < v then currentCash = v end end)

-- Hash → SpawnPosition cache (O(1) lookup, replaces per-call GetTowers() scan)
local HashToPosCache = {}  -- [tostring(hash)] = {x, y, z}

-- Reverse map: axis X → hashStr, để FindTower O(1) thay vì duyệt toàn bộ cache
local axisToHash = {}

do
    -- Seed cache from towers already in game at inject time
    local existing = GameModules.TowerClass.GetTowers and GameModules.TowerClass.GetTowers()
    if existing then
        for hash, tower in pairs(existing) do
            if tower.SpawnCFrame and typeof(tower.SpawnCFrame) == "CFrame" then
                local p = tower.SpawnCFrame.Position
                local hs = tostring(hash)
                HashToPosCache[hs] = {x = p.X, y = p.Y, z = p.Z}
                axisToHash[p.X] = hs
            end
        end
    end
end

do
    -- Hook TowerClass.New to register new towers
    local origNew = rawget(GameModules.TowerClass, "New") or GameModules.TowerClass.New
    if origNew then
        GameModules.TowerClass.New = newcclosure(function(...)
            local tower = origNew(...)
            if tower and tower.Hash and tower.SpawnCFrame and typeof(tower.SpawnCFrame) == "CFrame" then
                local p = tower.SpawnCFrame.Position
                local hs = tostring(tower.Hash)
                HashToPosCache[hs] = {x = p.X, y = p.Y, z = p.Z}
                axisToHash[p.X] = hs
            end
            return tower
        end)
    end

    -- Hook TowerClass.Destroy to evict removed towers
    local origDestroy = rawget(GameModules.TowerClass, "Destroy") or GameModules.TowerClass.Destroy
    if origDestroy then
        GameModules.TowerClass.Destroy = newcclosure(function(tower, ...)
            if tower and tower.Hash then
                local hs = tostring(tower.Hash)
                local pos = HashToPosCache[hs]
                if pos then axisToHash[pos.x] = nil end
                HashToPosCache[hs] = nil
            end
            return origDestroy(tower, ...)
        end)
    end
end

-- PowerUp state tracking
local PowerUpState = {
    Inventory  = {},  -- { [puName] = count }
    UsageStats = {},  -- { [puName] = NumUsed } — for MaxUses check
}

pcall(function()
    local Common = ReplicatedStorage:WaitForChild("TDX_Shared"):WaitForChild("Common")
    local bh = require(Common:WaitForChild("BindableHandler"))
    bh.GetEvent("PowerUpStatsChanged"):AttachCallback(function(stats)
        for name, data in pairs(stats) do
            PowerUpState.UsageStats[name] = data.NumUsed or 0
        end
    end)
end)

pcall(function()
    local Data = require(ReplicatedStorage:WaitForChild("TDX_Shared").Client.Services.Data)
    local function applyInventory(inv)
        if inv and inv.PowerUps then
            for name, count in pairs(inv.PowerUps) do
                PowerUpState.Inventory[name] = count
            end
        end
    end
    applyInventory(Data.Get("Inventory"))
    Data.Updated:Connect(function(key)
        if key == "Inventory" then applyInventory(Data.Get("Inventory")) end
    end)
end)

local function CanUsePowerUp(puName)
    -- Inventory = 0: bail, không thể dùng
    if (PowerUpState.Inventory[puName] or 0) <= 0 then return false, "NoCount" end
    if GameModules.PowerUpsConfig then
        local ok, cfg = pcall(function() return GameModules.PowerUpsConfig.GetConfig(puName) end)
        if ok and cfg then
            if cfg.Disabled == true then return false, "Disabled" end
            if cfg.MinWave and PowerUpState.CurrentWave < cfg.MinWave then return false, "WaveRequirementNotReached" end
            if cfg.BossOnly == true and PowerUpState.BossCount == 0 then return false, "NoBosses" end
            if cfg.MaxUses and (PowerUpState.UsageStats[puName] or 0) >= cfg.MaxUses then return false, "NoUsesRemaining" end
        end
    end
    return true
end

local function WaitUntilPowerUpReady(puName, timeout)
    timeout = timeout or 30
    local t0 = tick()
    while tick() - t0 < timeout do
        local ok, reason = CanUsePowerUp(puName)
        if ok then return true end
        -- Chỉ bail khi inventory = 0 hoặc đã hết lượt dùng tối đa
        if reason == "NoCount" or reason == "NoUsesRemaining" then return false, reason end
        RunService.RenderStepped:Wait()
    end
    return false, "Timeout"
end

local NetEvents = {}
local RequiredEvents = {"NewCoinDropEvent", "ClientsideCoinCollectedStartedEvent", "ClientsideCoinCollectedEvent"}
for _, name in ipairs(RequiredEvents) do NetEvents[name] = GameModules.Networking.GetEvent(name) end

local collectedCoins = {}  -- serverHash đã confirmed bởi server
NetEvents.NewCoinDropEvent:AttachCallback(function(args)
    local serverHash = args[1]
    local walkNear = args[10]
    if not serverHash or collectedCoins[serverHash] then return end
    task.spawn(function()
        local deadline = tick() + 10  -- timeout 10s
        local interval = 0.3
        while tick() < deadline and not collectedCoins[serverHash] do
            if walkNear then NetEvents.ClientsideCoinCollectedStartedEvent:FireServer(serverHash) end
            NetEvents.ClientsideCoinCollectedEvent:FireServer(serverHash)
            task.wait(interval)
            interval = math.min(interval * 1.5, 2)  -- backoff: 0.3 → 0.45 → ... → 2s max
        end
    end)
end)
GameModules.Networking.GetEvent("ClientsideCoinUpdate"):AttachCallback(function(_, serverHash)
    if serverHash then collectedCoins[serverHash] = true end
end)
local function FindTower(mode, value)
    if mode == "Axis" then
        local hs = axisToHash[value]
        if hs then
            local hash = tonumber(hs)
            if hash then
                local tower = GameModules.TowerClass.GetTowers()[hash]
                if tower then return hash, tower end
                -- stale, evict
                HashToPosCache[hs] = nil
                axisToHash[value] = nil
            end
        end
    end
    return nil, nil
end

local function WaitForTower(mode, value, timeout)
    timeout = timeout or 5
    local t0 = tick()
    while tick() - t0 < timeout do
        local h, t = FindTower(mode, value)
        if h and t and t.LevelHandler then return h, t end
        RunService.RenderStepped:Wait()
    end
    return nil, nil
end

local function CreateTowerContext(axisX) return { axisX = axisX, hash = nil, tower = nil, levelHandler = nil } end
local function UpdateContext(ctx)
    local h, t = FindTower("Axis", ctx.axisX)
    if h and t and t.LevelHandler then ctx.hash = h; ctx.tower = t; ctx.levelHandler = t.LevelHandler; return true end
    return false
end

local function getGameUI()
    local t0 = tick()
    while tick() - t0 < 30 do
        local interface = PlayerGui:FindFirstChild("Interface")
        if interface then
            local gameInfoBar = interface:FindFirstChild("GameInfoBar")
            if gameInfoBar then
                local default = gameInfoBar:FindFirstChild("Default")
                if default then
                    local wave = default:FindFirstChild("Wave")
                    local time = default:FindFirstChild("TimeLeft")
                    if wave and time then
                        return { waveText = wave:FindFirstChild("WaveText"), timeText = time:FindFirstChild("TimeLeftText") } 
                    end
                end
            end
        end
        SmartWait(1)
    end
    error("Game UI Not Found")
end

local function convertToTimeFormat(num) return string.format("%02d:%02d", math.floor(num / 100), num % 100) end
local function parseTimeToNumber(s) local m,sec = s:match("(%d+):(%d+)"); return m and (tonumber(m)*100 + tonumber(sec)) or nil end

-- waveIndex: waveStr → thứ tự, dùng để detect wave đã qua thay vì string match
local function WaitForTiming(entry, gameUI, waveIndex)
    if not entry.Wave and not entry.Time then return end
    local targetWave = entry.Wave and tostring(entry.Wave) or nil
    local targetWaveIdx = targetWave and waveIndex[targetWave] or nil
    while true do
        local ok, waveText, timeText = pcall(function()
            return gameUI.waveText.Text, gameUI.timeText.Text
        end)
        if ok then
            local currentIdx = waveIndex[waveText] or 0
            -- wave đã qua (idx lớn hơn) hoặc không có ràng buộc wave → bỏ qua check wave
            local waveMatch = (not targetWaveIdx) or (currentIdx >= targetWaveIdx)
            if waveMatch then
                if entry.Time then
                    local current = parseTimeToNumber(timeText)
                    -- nếu đúng wave thì chờ time; nếu wave đã qua thì trigger ngay
                    if (not targetWaveIdx or currentIdx > targetWaveIdx) or (current and current <= entry.Time) then return end
                else
                    return
                end
            end
        end
        RunService.RenderStepped:Wait()
    end
end

local function CalculateUpgradeCost(tower, path, count)
    if not tower or not tower.LevelHandler or count <= 0 then return nil end
    local lh = tower.LevelHandler
    local discount = 0; if tower.BuffHandler then pcall(function() discount = tower.BuffHandler:GetDiscount() or 0 end) end
    local dynamic = {}; if lh.HasDynamicPriceScaling then dynamic = GameModules.TowerClass.GetDynamicPriceScalingData(tower) or {} end
    local multiplier = 1
    if GameModules.GameClass then
        local game = GameModules.GameClass.GetCurrentGame()
        if game then pcall(function() multiplier = game:GetTowerCostMultiplier(tower.Type) or 1 end) end
    end
    local s, r = pcall(function() return lh:GetLevelUpgradeCost(path, count, discount, multiplier, dynamic) end)
    return s and r or nil
end

local function WaitForCash(amount) while currentCash < amount do RunService.RenderStepped:Wait() end end
local function PlaceTowerRetry(args, axisValue)
    for i = 1, 1 do
        if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("InvokeServer", Remotes.PlaceTower, unpack(args))
        else pcall(function() Remotes.PlaceTower:InvokeServer(unpack(args)) end) end
        SmartWait(globalEnv.TDX_Config.MacroStepDelay)
        if WaitForTower("Axis", axisValue, 3) then
            -- Wait an extra frame so SetTower completes on all abilities
            -- before AbilityHotbarHandler refreshes (avoids Tower=nil crash)
            RunService.RenderStepped:Wait()
            return true
        end
    end
    return false
end

local function UpgradeTowerRetry(axisValue, path, count)
    local ctx = CreateTowerContext(axisValue)
    count = count or 1

    local t0 = tick()
    while tick() - t0 < 5 do if UpdateContext(ctx) then break end; RunService.RenderStepped:Wait() end
    if not ctx.hash then return false end

    local startLevel = ctx.levelHandler:GetLevelOnPath(path) or 0
    local maxPossible = ctx.levelHandler:GetMaxPossibleLevel(path)
    local targetLevel = math.min(startLevel + count, maxPossible)

    while true do
        if not UpdateContext(ctx) then return false end
        local currentLevel = ctx.levelHandler:GetLevelOnPath(path) or 0
        if currentLevel >= targetLevel then return true end

        local upgradesNeeded = targetLevel - currentLevel
        local amountToBuy = 0

        for k = upgradesNeeded, 1, -1 do
            local cost = CalculateUpgradeCost(ctx.tower, path, k)
            if cost and currentCash >= cost then amountToBuy = k; break end
        end

        if amountToBuy == 0 then
            local costOne = CalculateUpgradeCost(ctx.tower, path, 1)
            if costOne then WaitForCash(costOne); amountToBuy = 1 end
        end

        if amountToBuy > 0 then
            if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.TowerUpgradeRequest, ctx.hash, path, amountToBuy)  
            else pcall(function() Remotes.TowerUpgradeRequest:FireServer(ctx.hash, path, amountToBuy) end) end 

            local t0 = tick()
            local expected = currentLevel + amountToBuy
            while tick() - t0 < 2 do
                local lvl = ctx.levelHandler:GetLevelOnPath(path) or 0
                if lvl >= expected then break end
                RunService.RenderStepped:Wait()
            end
        else
            SmartWait(globalEnv.TDX_Config.MacroStepDelay)
        end
    end
end

local function UseMovingSkillRetry(axisValue, skillIndex, location)
    local Remote = Remotes:FindFirstChild("TowerUseAbilityRequest")
    if not Remote then return false end
    local isEvent = Remote:IsA("RemoteEvent")
    location = location or "no_pos"
    for i = 1, 1 do  
        local hash, tower = WaitForTower("Axis", axisValue)
        if hash and tower and tower.AbilityHandler then  
            local ability = tower.AbilityHandler:GetAbilityFromIndex(skillIndex)  
            if ability then  
                local cd = ability.CooldownRemaining or 0  
                if cd > 0 then SmartWait(cd + 0.1) end  
                local args = {hash, skillIndex}
                if location ~= "no_pos" then
                    local x, y, z = location:match("([^,%s]+),%s*([^,%s]+),%s*([^,%s]+)")
                    if x then table.insert(args, Vector3.new(tonumber(x), tonumber(y), tonumber(z))) end
                end
                if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall(isEvent and "FireServer" or "InvokeServer", Remote, unpack(args))
                else pcall(function() if isEvent then Remote:FireServer(unpack(args)) else Remote:InvokeServer(unpack(args)) end end) end
                return true   
            end  
        end  
        SmartWait(globalEnv.TDX_Config.MacroStepDelay)  
    end  
    return false
end

local function ChangeTargetRetry(axisValue, targetType)
    local hash = FindTower("Axis", axisValue)
    if hash then
        if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.ChangeQueryType, hash, targetType)
        else pcall(function() Remotes.ChangeQueryType:FireServer(hash, targetType) end) end
        return true
    end
    return false
end

local function SellTowerRetry(axisValue)
    local hash = FindTower("Axis", axisValue)
    if hash then
        if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SellTower, hash)
        else pcall(function() Remotes.SellTower:FireServer(hash) end) end
        return true
    end
    return false
end

local function SellAllTowers(skipList)
    local skipMap = {}
    if skipList then for _, name in ipairs(skipList) do skipMap[name] = true end end
    for hash, tower in pairs(GameModules.TowerClass.GetTowers()) do
        if not skipMap[tower.Type] then
            if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SellTower, hash)
            else pcall(function() Remotes.SellTower:FireServer(hash) end) end
            SmartWait(globalEnv.TDX_Config.MacroStepDelay)
        end
    end
end
local function MovePlayerTo(posStr)
    local v = {}; for c in posStr:gmatch("[^,%s]+") do table.insert(v, tonumber(c)) end
    if #v ~= 3 then return false end
    local target = Vector3.new(v[1], v[2], v[3])
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end

    local walkSpeed = humanoid.WalkSpeed > 0 and humanoid.WalkSpeed or 16
    local startPos = hrp.Position
    local endPos = target
    local distance = (endPos - startPos).Magnitude
    local duration = distance / walkSpeed

    local lookCF = distance > 0.01 and CFrame.lookAt(startPos, endPos) or hrp.CFrame
    local rotOnly = lookCF - lookCF.Position

    local savedSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0

    local elapsed = 0
    local stuck = false
    local lastCheckPos = startPos
    local lastCheckTime = tick()

    local conn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        local alpha = math.min(elapsed / math.max(duration, 0.001), 1)
        hrp.CFrame = CFrame.new(startPos:Lerp(endPos, alpha)) * rotOnly

        local now = tick()
        if now - lastCheckTime >= 0.5 then
            local moved = (hrp.Position - lastCheckPos).Magnitude
            if moved < 0.5 and alpha < 1 then stuck = true end
            lastCheckPos = hrp.Position
            lastCheckTime = now
        end
    end)

    while elapsed < duration and not stuck do RunService.RenderStepped:Wait() end
    conn:Disconnect()

    hrp.CFrame = CFrame.new(endPos) * rotOnly
    humanoid.WalkSpeed = savedSpeed
    return true
end

local function StartRebuildSystem(rebuildEntry, towerRecords, skipTypesMap)
    local config = globalEnv.TDX_Config
    local rebuildAttempts, soldPositions, jobQueue, activeJobs = {}, {}, {}, {}

    local function GetTowerPriority(towerName)
        for priority, name in ipairs(config.PriorityRebuildOrder or {}) do
            if towerName == name then return priority end
        end
        return 999
    end

    task.spawn(function()
        while true do
            RunService.RenderStepped:Wait()
            if #jobQueue > 0 then
                local job = table.remove(jobQueue, 1)
                task.spawn(function()
                    setThreadIdentity(2)
                    local records = job.records
                    local placeRecord = nil
                    local upgradesByPath = {[1] = {}, [2] = {}}
                    local targetRecords, movingRecords = {}, {}

                    for _, record in ipairs(records) do
                        local action = record.entry
                        if action.TowerPlaced then placeRecord = record
                        elseif action.TowerUpgraded then table.insert(upgradesByPath[action.UpgradePath] or {}, record)
                        elseif action.TowerTargetChange then table.insert(targetRecords, record)
                        elseif action.towermoving then table.insert(movingRecords, record) end
                    end

                    -- Tìm entry có location cuối cùng và entry skill cuối cùng
                    local finalPosEntry = nil
                    local skillEntry = nil
                    for _, r in ipairs(movingRecords) do
                        local e = r.entry
                        if e.location and e.location ~= "no_pos" then
                            finalPosEntry = e
                        else
                            skillEntry = e
                        end
                    end
                    if not skillEntry then skillEntry = finalPosEntry end

                    local placePos, newAxisX
                    if finalPosEntry and placeRecord then
                        local lv = {}; for c in finalPosEntry.location:gmatch("[^,%s]+") do table.insert(lv, tonumber(c)) end
                        if #lv == 3 then placePos = Vector3.new(lv[1], lv[2], lv[3]); newAxisX = lv[1] end
                    end
                    if not placePos and placeRecord then
                        local v = {}; for c in placeRecord.entry.TowerVector:gmatch("[^,%s]+") do table.insert(v, tonumber(c)) end
                        if #v == 3 then placePos = Vector3.new(v[1], v[2], v[3]); newAxisX = v[1] end
                    end

                    local rebuildSuccess = true
                    if placeRecord and placePos then
                        local a = placeRecord.entry
                        local args = {tonumber(a.TowerA1), a.TowerPlaced, placePos, tonumber(a.Rotation or 0)}
                        WaitForCash(a.TowerPlaceCost)
                        if not PlaceTowerRetry(args, newAxisX) then rebuildSuccess = false end

                        -- Migrate towerRecords sang axis mới nếu place tại vị trí khác
                        if rebuildSuccess and newAxisX ~= job.x then
                            towerRecords[newAxisX] = towerRecords[job.x]
                            towerRecords[job.x] = nil
                            rebuildAttempts[newAxisX] = rebuildAttempts[job.x]
                            rebuildAttempts[job.x] = nil
                            -- cập nhật reverse map
                            local hs = axisToHash[job.x]
                            if hs then axisToHash[newAxisX] = hs; axisToHash[job.x] = nil end
                        end
                    end

                    if rebuildSuccess and newAxisX then
                        if #upgradesByPath[1] > 0 then if not UpgradeTowerRetry(newAxisX, 1, #upgradesByPath[1]) then rebuildSuccess = false end end
                        if rebuildSuccess and #upgradesByPath[2] > 0 then if not UpgradeTowerRetry(newAxisX, 2, #upgradesByPath[2]) then rebuildSuccess = false end end
                    end

                    if rebuildSuccess then
                        for _, r in ipairs(targetRecords) do ChangeTargetRetry(tonumber(r.entry.TowerTargetChange), r.entry.TargetWanted) end
                        if not finalPosEntry and skillEntry then
                            task.spawn(function()
                                local axisToCheck = newAxisX or skillEntry.towermoving
                                local deadline = tick() + 10
                                while tick() < deadline do
                                    local _, t = FindTower("Axis", axisToCheck)
                                    if t then break end
                                    SmartWait(0.5)
                                end
                                UseMovingSkillRetry(axisToCheck, skillEntry.skillindex, skillEntry.location)
                            end)
                        end
                    end
                    activeJobs[job.x] = nil  
                end)
            end
        end
    end)

    task.spawn(function()
        while true do
            local jobsAdded = false
            for x, records in pairs(towerRecords) do
                if not axisToHash[x] and not activeJobs[x] and not (config.ForceRebuildEvenIfSold == false and soldPositions[x]) then
                    local towerType = nil
                    for _, record in ipairs(records) do
                        if record.entry.TowerPlaced then towerType = record.entry.TowerPlaced; break end
                    end
                    if towerType then
                        local shouldSkip = skipTypesMap[towerType] ~= nil
                        if not shouldSkip then
                            rebuildAttempts[x] = (rebuildAttempts[x] or 0) + 1
                            if not config.MaxRebuildRetry or rebuildAttempts[x] <= config.MaxRebuildRetry then
                                activeJobs[x] = true
                                table.insert(jobQueue, { x = x, records = records, priority = GetTowerPriority(towerType), deathTime = tick() })
                                jobsAdded = true
                            end
                        end
                    end
                end
            end
            if jobsAdded and #jobQueue > 1 then
                table.sort(jobQueue, function(a, b) return (a.priority == b.priority) and (a.deathTime < b.deathTime) or (a.priority < b.priority) end)
            end
            SmartWait(config.RebuildCheckInterval or 0)
        end
    end)
end
local ShopSystem = { Queue = {}, Credits = 0 }
local CreditsRemote = Remotes:FindFirstChild("UpgradeShopCreditsUpdate")
if CreditsRemote then 
    CreditsRemote.OnClientEvent:Connect(function(n) 
        ShopSystem.Credits = n 
    end) 
end

local _cachedShopDataHandler = nil
local function GetShopDataHandler()
    if _cachedShopDataHandler then return _cachedShopDataHandler end
    local ok, result = pcall(function()
        local Client = PlayerScripts:WaitForChild("Client", 5)
        if not Client then return nil end
        local PlayerClassModule = Client:FindFirstChild("PlayerClass")
        if not PlayerClassModule then return nil end
        local PlayerClass = require(PlayerClassModule)
        local playerWrapper = PlayerClass.GetLocalPlayerWrapper()
        if playerWrapper then return playerWrapper:GetUpgradeShopDataHandler() end
    end)
    local h = ok and result or nil
    if h then _cachedShopDataHandler = h end
    return h
end

local function GetCurrentCredits()
    local handler = GetShopDataHandler()
    if handler and handler.GetCredits then
        return handler:GetCredits()
    end
    return ShopSystem.Credits
end

local function CalculateShopUpgradeCost(towerType, statType)
    if not GameModules.ShopUtils then return nil end

    local itemData = GameModules.ShopUtils.GetUpgradeShopItemDataForTower(towerType, statType)
    if not itemData then return nil end

    local handler = GetShopDataHandler()
    if handler then
        local activeData = GameModules.ShopUtils.GetActiveUpgradeShopData(
            handler.TowerToUpgradeTypeToActiveUpgradeData,
            towerType,
            statType
        )

        if activeData and itemData then
            return GameModules.ShopUtils.GetOperationCost(activeData, itemData)
        end
    end

    return nil
end

local function WaitForCredits(amount)
    while GetCurrentCredits() < amount do 
        RunService.RenderStepped:Wait() 
    end
end

local function ExecuteShopItem(item, gameUI)
    local forceInstant = globalEnv.TDX_Config.ShopInstantMode
    local hasTimingInfo = (item.Wave ~= nil or item.Time ~= nil)
    local shouldWaitForTiming = (not forceInstant) and hasTimingInfo
    local isExtra = (item.Extra == true)

    if item.ShopUpgrade and not isExtra then
        local cost = CalculateShopUpgradeCost(item.ShopUpgrade, item.Stat)

        if cost then
            if forceInstant then
                WaitForCredits(cost)
            else
                if GetCurrentCredits() < cost then
                    WaitForCredits(cost)
                end
            end
        end
    end

    if shouldWaitForTiming then
        while true do
            local s, waveText, timeText = pcall(function() 
                return gameUI.waveText.Text, gameUI.timeText.Text 
            end)

            if s then
                local waveMatch = (not item.Wave or item.Wave == waveText)
                local timeMatch = (not item.Time or timeText == convertToTimeFormat(item.Time))

                if waveMatch and timeMatch then 
                    if item.ShopUpgrade and not isExtra then
                        local cost = CalculateShopUpgradeCost(item.ShopUpgrade, item.Stat)
                        if cost and GetCurrentCredits() < cost then
                            WaitForCredits(cost)
                        end
                    end
                    break 
                end
            end
            SmartWait(0.1)
        end
    end

    local confirmed = false
    local connection

    if item.ShopUpgrade then
        connection = Remotes:WaitForChild("UpgradeShopDataUpdate").OnClientEvent:Connect(function() 
            confirmed = true 
        end)
    elseif item.ShopRefund then
        connection = Remotes:WaitForChild("UpgradeShopTowerReset").OnClientEvent:Connect(function() 
            confirmed = true 
        end)
    end

    while not confirmed do
        if item.ShopUpgrade then
            local t = Remotes:WaitForChild("UpgradeShopOperationRequest")
            if globalEnv.TDX_Config.UseThreadedRemotes then 
                SafeRemoteCall("InvokeServer", t, item.ShopUpgrade, item.Stat, item.Extra)
            else 
                pcall(function() t:InvokeServer(item.ShopUpgrade, item.Stat, item.Extra) end) 
            end
        elseif item.ShopRefund then
            local t = Remotes:WaitForChild("UpgradeShopRefundAllRequest")
            if globalEnv.TDX_Config.UseThreadedRemotes then 
                SafeRemoteCall("FireServer", t, item.ShopRefund)
            else 
                pcall(function() t:FireServer(item.ShopRefund) end) 
            end
        end

        local t0 = tick()
        while tick() - t0 < 5 do
            if confirmed then break end
            RunService.RenderStepped:Wait()
        end

        if not confirmed then break end
    end

    if connection then connection:Disconnect() end
end

local function StartShopRunner(gameUI)
    task.spawn(function()
        setThreadIdentity(2)
        for _, item in ipairs(ShopSystem.Queue) do
            ExecuteShopItem(item, gameUI)
            SmartWait(globalEnv.TDX_Config.MacroStepDelay)
        end
    end)
end
local function StartUnifiedMonitor(monitorEntries, gameUI, waveIndex)
    local processed, attemptedSkips = {}, {}
    local cachedWaveStr = ""
    local cachedWaveIdx = 0
    local cachedTimeNum = nil

    local function shouldRun(entry, waveStr, waveIdx, timeNum)
        if entry.SkipWave then
            return not attemptedSkips[entry.SkipWave] and tostring(entry.SkipWave) == waveStr
                   and (not entry.SkipWhen or (timeNum or 9999) <= entry.SkipWhen)
        elseif entry.TowerTargetChange or entry.towermoving then
            local targetWave = tostring(entry.Wave or entry.wave or "")
            local targetTime = entry.Time or entry.time
            local targetIdx = waveIndex[targetWave]
            if targetIdx and waveIdx < targetIdx then return false end  -- chưa tới wave
            if targetTime and targetIdx and waveIdx == targetIdx then
                return timeNum and (timeNum <= targetTime)
            end
            return true  -- wave đã qua hoặc không ràng buộc
        end
        return false
    end

    task.spawn(function()
        setThreadIdentity(2)
        while true do
            local s, wave, time = pcall(function() return gameUI.waveText.Text, gameUI.timeText.Text end)
            if s then
                local idx = waveIndex[wave] or cachedWaveIdx
                if wave ~= cachedWaveStr then cachedTimeNum = nil end  -- sang wave mới, reset time
                cachedWaveStr = wave
                cachedWaveIdx = idx
                cachedTimeNum = parseTimeToNumber(time) or cachedTimeNum
                for i, entry in ipairs(monitorEntries) do
                    if not processed[i] and shouldRun(entry, cachedWaveStr, cachedWaveIdx, cachedTimeNum) then
                        local done = false
                        if entry.SkipWave then
                            attemptedSkips[entry.SkipWave] = true
                            if globalEnv.TDX_Config.AllowParallelSkips then task.spawn(function()
                                if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SkipWaveVoteCast, true) else Remotes.SkipWaveVoteCast:FireServer(true) end
                            end) else
                                if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SkipWaveVoteCast, true) else Remotes.SkipWaveVoteCast:FireServer(true) end
                            end
                            done = true
                        elseif entry.towermoving then
                            done = UseMovingSkillRetry(entry.towermoving, entry.skillindex, entry.location)
                        elseif entry.TowerTargetChange then
                            if globalEnv.TDX_Config.AllowParallelTargets then task.spawn(function() ChangeTargetRetry(entry.TowerTargetChange, entry.TargetWanted) end)
                            else done = ChangeTargetRetry(entry.TowerTargetChange, entry.TargetWanted) end
                            done = true
                        end
                        if done then processed[i] = true end
                    end
                end
            end
            SmartWait(globalEnv.TDX_Config.MonitorCheckDelay)
        end
    end)
end
local function RunMacroRunner()
    local config = globalEnv.TDX_Config
    local macroName = config["Macro Name"] or "event"
    local macroPath = "tdx/macros/" .. macroName .. ".json"

    if not safeIsFile(macroPath) then error("Macro file not found: " .. macroPath) end  
    local macro = HttpService:JSONDecode(safeReadFile(macroPath))
    local gameUI = getGameUI()
    local towerRecords, monitorEntries = {}, {}

    local activeReliveConfig, activeReshieldConfig = nil, nil  
    local rebuildSystemActive, skipTypesMap = false, {}

    task.spawn(function()  
        while true do  
            for hash, tower in pairs(GameModules.TowerClass.GetTowers()) do  
                local shouldSell = false  
                -- Auto sell converted towers (from recorder: tower.Converted check)
                if tower.Converted then  
                    shouldSell = true  
                end  
                -- ReliveTowers logic
                if not shouldSell and activeReliveConfig then  
                    local reliveMap = activeReliveConfig.ReliveTowers or {}  
                    local limit = reliveMap[tower.Type]  
                    if limit then  
                        shouldSell = (limit == -1 and tower.IsRebuilding and tower:IsRebuilding()) or (limit ~= -1 and tower.RebuildsLeft and tower.RebuildsLeft <= limit)
                    end  
                end  
                if shouldSell then  
                    if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SellTower, hash)  
                    else pcall(function() Remotes.SellTower:FireServer(hash) end) end  
                end  
            end  
            SmartWait(0.2)  
        end  
    end)  

    task.spawn(function()  
        while true do  
            if activeReshieldConfig and activeReshieldConfig.AutoReshield then  
                local threshold = activeReshieldConfig.ShieldCount or 0  
                for hash, tower in pairs(GameModules.TowerClass.GetTowers()) do  
                    if tower.Type == "Shield Tower" and tower.LevelHandler and tower.LevelHandler.Path1Level >= 5 then  
                        if tower.HealthHandler and (tower.HealthHandler:GetShield() or 0) <= threshold then  
                            if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SellTower, hash)  
                            else pcall(function() Remotes.SellTower:FireServer(hash) end) end  
                        end  
                    end  
                end  
            end  
            SmartWait(0.5)  
        end  
    end)  

    local mainMacro = {}

    -- Build waveIndex từ toàn bộ macro (dùng chung cho WaitForTiming và monitor)
    local waveIndex = {}
    do
        local seen, order = {}, {}
        local sorted = {table.unpack(macro)}
        table.sort(sorted, function(a, b)
            local wa = tonumber(tostring(a.Wave or a.wave or a.SkipWave or ""):match("(%d+)")) or math.huge
            local wb = tonumber(tostring(b.Wave or b.wave or b.SkipWave or ""):match("(%d+)")) or math.huge
            return wa < wb
        end)
        for _, e in ipairs(sorted) do
            local w = tostring(e.Wave or e.wave or e.SkipWave or "")
            if w ~= "" and not seen[w] then seen[w] = true; table.insert(order, w) end
        end
        for i, w in ipairs(order) do waveIndex[w] = i end
    end
    for i, entry in ipairs(macro) do
        if entry.ShopUpgrade or entry.ShopRefund then
            table.insert(ShopSystem.Queue, entry)
        else
            table.insert(mainMacro, entry)
        end
        if entry.TowerTargetChange or entry.towermoving or entry.SkipWave then 
            table.insert(monitorEntries, entry) 
        end
    end

    if #ShopSystem.Queue > 0 then StartShopRunner(gameUI) end
    if #monitorEntries > 0 then
        table.sort(monitorEntries, function(a, b)
            local wa = waveIndex[tostring(a.Wave or a.wave or a.SkipWave or "")] or math.huge
            local wb = waveIndex[tostring(b.Wave or b.wave or b.SkipWave or "")] or math.huge
            return wa < wb
        end)
        StartUnifiedMonitor(monitorEntries, gameUI, waveIndex)
    end

    local i = 1
    while i <= #mainMacro do
        local entry = mainMacro[i]

        if entry.SuperFunction == "sell_all" then SellAllTowers(entry.Skip)
        elseif entry.SuperFunction == "rebuild" then
            if not rebuildSystemActive then
                for _, skip in ipairs(entry.Skip or {}) do skipTypesMap[skip] = { beOnly = entry.Be == true, fromLine = i } end
                StartRebuildSystem(entry, towerRecords, skipTypesMap)
                rebuildSystemActive = true
            end
        elseif entry.SuperFunction == "relive" then activeReliveConfig = entry
        elseif entry.SuperFunction == "reshield" then activeReshieldConfig = entry

        elseif entry.TowerPlaced and entry.TowerVector then
             if globalEnv.TDX_Config.PlaceByTiming then WaitForTiming(entry, gameUI, waveIndex) end
             local v = {}; for c in entry.TowerVector:gmatch("[^,%s]+") do table.insert(v, tonumber(c)) end
             local pos = Vector3.new(v[1], v[2], v[3])
             local args = {tonumber(entry.TowerA1), entry.TowerPlaced, pos, tonumber(entry.Rotation or 0)}
             WaitForCash(entry.TowerPlaceCost)
             PlaceTowerRetry(args, pos.X)
             towerRecords[pos.X] = towerRecords[pos.X] or {}; table.insert(towerRecords[pos.X], { line = i, entry = entry })
        elseif entry.TowerUpgraded then
             if globalEnv.TDX_Config.UpgradeByTiming then WaitForTiming(entry, gameUI, waveIndex) end
             local axis, path = tonumber(entry.TowerUpgraded), entry.UpgradePath
             local batchCount, j = 1, i + 1
             while j <= #mainMacro do
                 local n = mainMacro[j]
                 if n.TowerUpgraded and tonumber(n.TowerUpgraded) == axis and n.UpgradePath == path then
                     batchCount = batchCount + 1; table.insert(towerRecords[axis] or {}, { line = j, entry = n }); j = j + 1
                 else break end
             end
             UpgradeTowerRetry(axis, path, batchCount)
             table.insert(towerRecords[axis] or {}, { line = i, entry = entry })
             i = i + (batchCount - 1)
        elseif entry.TowerTargetChange then
             local axis = tonumber(entry.TowerTargetChange)
             table.insert(towerRecords[axis] or {}, { line = i, entry = entry })
        elseif entry.towermoving then
             local axis = entry.towermoving
             table.insert(towerRecords[axis] or {}, { line = i, entry = entry })
        elseif entry.PlayerPosition then
             if globalEnv.TDX_Config.MovePlayer then MovePlayerTo(entry.PlayerPosition) end
        elseif entry.SellTower then
             if globalEnv.TDX_Config.SellByTiming then WaitForTiming(entry, gameUI, waveIndex) end
             SellTowerRetry(tonumber(entry.SellTower))
             towerRecords[tonumber(entry.SellTower)] = nil
        elseif entry.PowerUp then
             local Remote = Remotes:FindFirstChild("RequestUsePowerUp")
             if Remote then
                 local ready, reason = WaitUntilPowerUpReady(entry.PowerUp)
                 if ready then
                     local args = {entry.PowerUp}
                     if entry.PowerUpVector then
                         local v = {}; for c in entry.PowerUpVector:gmatch("[^,%s]+") do table.insert(v, tonumber(c)) end
                         if #v == 3 then table.insert(args, Vector3.new(v[1], v[2], v[3])) end
                     end
                     if globalEnv.TDX_Config.UseThreadedRemotes then SafeRemoteCall("InvokeServer", Remote, unpack(args))
                     else pcall(function() Remote:InvokeServer(unpack(args)) end) end
                 end
             end
        end
        SmartWait(globalEnv.TDX_Config.MacroStepDelay)
        i = i + 1
    end
end

task.spawn(function() pcall(RunMacroRunner) end)
