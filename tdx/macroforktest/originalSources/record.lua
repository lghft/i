local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerScripts = player:WaitForChild("PlayerScripts")
local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local currentCash = cash.Value
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function setThreadIdentity(identity)
    if setthreadidentity then setthreadidentity(identity)
    elseif syn and syn.set_thread_identity then syn.set_thread_identity(identity) end
end

local function SmartWait(seconds)
    if not seconds or seconds <= 0 then RunService.RenderStepped:Wait(); return end
    local start = tick()
    while tick() - start < seconds do RunService.RenderStepped:Wait() end
end

local function getGlobalEnv() return (getgenv and getgenv()) or _G end
local globalEnv = getGlobalEnv()

local defaultConfig = {
    ["MacroPath"] = "tdx/macros/recorder_output.json",
    ["MaxConcurrentRebuilds"] = 120,
    ["PriorityRebuildOrder"] = {"EDJ", "Medic", "Commander", "Mobster", "Golden Mobster"},
    ["MaxRebuildRetry"] = nil,
    ["AutoSellConvertDelay"] = 0.2,
    ["PlaceMode"] = "Rewrite",
    ["UseThreadedRemotes"] = true,
    ["UpgradeDelay"] = 0.5,
    ["SkipTowersAtAxis"] = {},
    ["SkipTowersByName"] = {},
    ["SkipTowersByLine"] = {},
    ["ReliveTowers"] = {},
    ["AutoReshield"] = true,
    ["ShieldTowerName"] = "Shield Tower",
    ["ReshieldThreshold"] = 0,
    ["RecordPlayerPosition"] = true,
    ["PlayerIdleThreshold"] = 0.5,
    ["PlayerIdleMoveTolerance"] = 0.1,   
}

if makefolder then pcall(makefolder, "tdx"); pcall(makefolder, "tdx/macros") end


if writefile then pcall(writefile, defaultConfig.MacroPath, "[]") end

if not globalEnv.TDX_Recorder_Context then
    globalEnv.TDX_Recorder_Context = {
        Config = defaultConfig,
        RebuildingCache = {},
        HashToPosCache = {}
    }
else
    for k, v in pairs(defaultConfig) do globalEnv.TDX_Recorder_Context.Config[k] = v end
end

local CurrentConfig = globalEnv.TDX_Recorder_Context.Config
local RebuildingCache = globalEnv.TDX_Recorder_Context.RebuildingCache
local HashToPosCache = globalEnv.TDX_Recorder_Context.HashToPosCache

local function safeWriteFile(path, content) if writefile then pcall(writefile, path, content) end end
local function safeReadFile(path)
    if isfile and isfile(path) and readfile then
        local s, c = pcall(readfile, path)
        return s and c or ""
    end
    return ""
end

local GameModules = { Networking = nil, LevelUtils = nil, TowerClass = nil, GameClass = nil }
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
    local Client = PlayerScripts:WaitForChild("Client")
    local GameClassMod = Client:FindFirstChild("GameClass")
    if GameClassMod then
        GameModules.GameClass = RequireSafe(GameClassMod)
        local TowerMod = GameClassMod:FindFirstChild("TowerClass")
        if TowerMod then GameModules.TowerClass = RequireSafe(TowerMod) end
    end
end
InitializeModules()
if not GameModules.TowerClass then return end

GameModules.Networking.GetEvent("UpdateCash"):AttachCallback(function(cash)
    currentCash = cash
end)
cash.Changed:Connect(function(v) if currentCash < v then currentCash = v end end)

local NetEvents = {}
local RequiredEvents = { "NewCoinDropEvent", "ClientsideCoinCollectedStartedEvent", "ClientsideCoinCollectedEvent" }
for _, name in ipairs(RequiredEvents) do NetEvents[name] = GameModules.Networking.GetEvent(name) end

local collectedCoins = {}
NetEvents.NewCoinDropEvent:AttachCallback(function(args)
    local serverHash = args[1]
    local walkNear = args[10]
    if not serverHash or collectedCoins[serverHash] then return end
    task.spawn(function()
        local deadline = tick() + 10
        local interval = 0.3
        while tick() < deadline and not collectedCoins[serverHash] do
            if walkNear then NetEvents.ClientsideCoinCollectedStartedEvent:FireServer(serverHash) end
            NetEvents.ClientsideCoinCollectedEvent:FireServer(serverHash)
            task.wait(interval)
            interval = math.min(interval * 1.5, 2)
        end
    end)
end)
GameModules.Networking.GetEvent("ClientsideCoinUpdate"):AttachCallback(function(_, serverHash)
    if serverHash then collectedCoins[serverHash] = true end
end)

local pendingQueue = {}


local towersByAxis, soldAxis, rebuildAttempts = {}, {}, {}
local macroLineCount = 0
local jsonBuffer = {}

local function flushBuffer()
    if #jsonBuffer == 0 then return end
    safeWriteFile(CurrentConfig.MacroPath, "[" .. table.concat(jsonBuffer, ",") .. "]")
end

local function appendToJsonFile(entry)
    if not HttpService then return end
    local ok, jsonStr = pcall(HttpService.JSONEncode, HttpService, entry)
    if not ok then return end
    table.insert(jsonBuffer, jsonStr)
    flushBuffer()

    macroLineCount = macroLineCount + 1
    local lineIndex = macroLineCount
    local x
    if entry.SellTower then
        x = tonumber(entry.SellTower)
        if x then soldAxis[x] = true end
    elseif entry.TowerPlaced then
        x = entry.TowerVector and tonumber(entry.TowerVector:match("^([%d%-%.]+),"))
    elseif entry.TowerUpgraded then
        x = tonumber(entry.TowerUpgraded)
    elseif entry.TowerTargetChange then
        x = tonumber(entry.TowerTargetChange)
    elseif entry.towermoving then
        x = entry.towermoving
    end
    if x then
        towersByAxis[x] = towersByAxis[x] or {}
        table.insert(towersByAxis[x], { line = lineIndex, entry = entry })
    end
end

local function GetTowerSpawnPosition(tower)
    if not tower then return nil end
    local spawnCFrame = tower.SpawnCFrame
    if spawnCFrame and typeof(spawnCFrame) == "CFrame" then return spawnCFrame.Position end
    return nil
end

local function GetTowerPlaceCostByName(name)
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return 0 end
    local interface = playerGui:FindFirstChild("Interface") or playerGui:WaitForChild("Interface", 1)
    if not interface then return 0 end
    local bottomBar = interface:FindFirstChild("BottomBar")
    if not bottomBar then return 0 end
    local towersBar = bottomBar:FindFirstChild("TowersBar")
    if not towersBar then return 0 end
    for _, towerButton in ipairs(towersBar:GetChildren()) do
        if towerButton.Name == name then
            local costFrame = towerButton:FindFirstChild("CostFrame")
            if costFrame then
                local costText = costFrame:FindFirstChild("CostText")
                if costText and costText:IsA("TextLabel") then
                    local raw = tostring(costText.Text):gsub("%D", "")
                    return tonumber(raw) or 0
                end
            end
        end
    end
    return 0
end

local function getCurrentWaveAndTime()
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil, nil end
    local interface = playerGui:FindFirstChild("Interface")
    if not interface then return nil, nil end
    local gameInfoBar = interface:FindFirstChild("GameInfoBar")
    if not gameInfoBar then return nil, nil end
    local default = gameInfoBar:FindFirstChild("Default")
    if not default then return nil, nil end
    local waveFrame = default:FindFirstChild("Wave")
    local timerFrame = default:FindFirstChild("TimeLeft")
    local waveText = waveFrame and waveFrame:FindFirstChild("WaveText")
    local timerText = timerFrame and timerFrame:FindFirstChild("TimeLeftText")
    local waveNum = nil
    local timeStr = nil
    if waveText and waveText:IsA("TextLabel") then waveNum = tostring(waveText.Text) end
    if timerText and timerText:IsA("TextLabel") then timeStr = tostring(timerText.Text) end
    return waveNum, timeStr
end

local function convertTimeToNumber(timeStr)
    if not timeStr then return nil end
    local mins, secs = timeStr:match("(%d+):(%d+)")
    if mins and secs then return tonumber(mins) * 100 + tonumber(secs) end
    return nil
end

local FindTower -- forward declaration; defined below

local MovingSkillTowers = {
    ["Helicopter"] = true,
    ["Cryo Helicopter"] = true,
    ["Jet Trooper"] = true,
    ["Psycho Slayer"] = true,
}

local function IsMovingSkillTower(towerName)
    return towerName ~= nil and MovingSkillTowers[towerName] == true
end

local function GetTowerNameByHash(hash)
    local towers = GameModules.TowerClass.GetTowers()
    local tower = towers[hash]
    return tower and tower.Type or nil
end

local function parseMacroLine(line)
    if line:match('TDX:skipWave%(%)') then
        local w, t = getCurrentWaveAndTime()
        return {{ SkipWave = w, SkipWhen = convertTimeToNumber(t) }}
    end
    local sName, sStat, sBool = line:match('TDX:shopUpgrade%("([^"]+)",%s*"([^"]+)",%s*([^%)]+)%)')
    if not sName then sName, sStat = line:match('TDX:shopUpgrade%("([^"]+)",%s*"([^"]+)"%)') end
    if sName and sStat then
        local w, t = getCurrentWaveAndTime()
        return {{ ShopUpgrade = sName, Stat = sStat, Extra = (sBool == "true"), Wave = w, Time = convertTimeToNumber(t) }}
    end
    local rName = line:match('TDX:shopRefund%("([^"]+)"%)')
    if rName then
        local w, t = getCurrentWaveAndTime()
        return {{ ShopRefund = rName, Wave = w, Time = convertTimeToNumber(t) }}
    end
    local hash, skillIndex, x, y, z = line:match('TDX:useMovingSkill%(([^,]+),%s*([^,]+),%s*Vector3%.new%(([^,]+),%s*([^,]+),%s*([^%)]+)%)%)')
    if hash and skillIndex and x and y and z then
        local pos = HashToPosCache[tostring(hash)]
        if pos then
            local w, t = getCurrentWaveAndTime()
            return {{ towermoving = pos.x, skillindex = tonumber(skillIndex), location = string.format("%s, %s, %s", x, y, z), wave = w, time = convertTimeToNumber(t) }}
        end
    end
    local hash, skillIndex = line:match('TDX:useSkill%(([^,]+),%s*([^%)]+)%)')
    if hash and skillIndex then
        local pos = HashToPosCache[tostring(hash)]
        if pos then
            local w, t = getCurrentWaveAndTime()
            return {{ towermoving = pos.x, skillindex = tonumber(skillIndex), wave = w, time = convertTimeToNumber(t) }}
        end
    end
    local a1, name, x, y, z, rot = line:match('TDX:placeTower%(([^,]+),%s*([^,]+),%s*Vector3%.new%(([^,]+),%s*([^,]+),%s*([^%)]+)%)%s*,%s*([^%)]+)%)')
    if a1 and name and x and y and z and rot then
        name = tostring(name):gsub('^%s*"(.-)"%s*$', '%1')
        local w, t = getCurrentWaveAndTime()
        return {{ TowerPlaceCost = GetTowerPlaceCostByName(name), TowerPlaced = name, TowerVector = string.format("%s, %s, %s", x, y, z), Rotation = rot, TowerA1 = a1, Wave = w, Time = convertTimeToNumber(t) }}
    end
    local hash, path, upgradeCount = line:match('TDX:upgradeTower%(([^,]+),%s*([^,]+),%s*([^%)]+)%)')
    if hash and path and upgradeCount then
        local pos = HashToPosCache[tostring(hash)]
        local pathNum, count = tonumber(path), tonumber(upgradeCount)
        if pos and pathNum and count and count > 0 then
            local entries = {}
            local w, t = getCurrentWaveAndTime()
            for _ = 1, count do table.insert(entries, { UpgradeCost = 0, UpgradePath = pathNum, TowerUpgraded = pos.x, Wave = w, Time = convertTimeToNumber(t) }) end
            return entries
        end
    end
    local hash, targetType = line:match('TDX:changeQueryType%(([^,]+),%s*([^%)]+)%)')
    if hash and targetType then
        local pos = HashToPosCache[tostring(hash)]
        if pos then
            local w, t = getCurrentWaveAndTime()
            return {{ TowerTargetChange = pos.x, TargetWanted = tonumber(targetType), Wave = w, Time = convertTimeToNumber(t) }}
        end
    end
    local puName, px, py, pz = line:match('TDX:usePowerUp%("([^"]+)",%s*Vector3%.new%(([^,]+),%s*([^,]+),%s*([^%)]+)%)%)')
    if puName and px and py and pz then
        local w, t = getCurrentWaveAndTime()
        return {{ PowerUp = puName, PowerUpVector = string.format("%s, %s, %s", px, py, pz), Wave = w, Time = convertTimeToNumber(t) }}
    end
    local puNameOnly = line:match('TDX:usePowerUp%("([^"]+)"%)') 
    if puNameOnly then
        local w, t = getCurrentWaveAndTime()
        return {{ PowerUp = puNameOnly, Wave = w, Time = convertTimeToNumber(t) }}
    end
    local hash = line:match('TDX:sellTower%(([^%)]+)%)')
    if hash then
        local hashStr = tostring(hash)
        local pos = HashToPosCache[hashStr]
        if pos then
            local w, t = getCurrentWaveAndTime()
            local entry = { SellTower = pos.x, Wave = w, Time = convertTimeToNumber(t) }
            HashToPosCache[hashStr] = nil
            return {entry}
        end
    end
    return nil
end

local function processAndWriteAction(commandString)
    local axisX = nil
    local _, _, vec = commandString:match('TDX:placeTower%(([^,]+),%s*([^,]+),%s*Vector3%.new%(([^,]+)')
    if vec then axisX = tonumber(vec) end
    if not axisX then
        local hash = commandString:match('TDX:upgradeTower%(([^,]+),')
                  or commandString:match('TDX:changeQueryType%(([^,]+),')
                  or commandString:match('TDX:sellTower%(([^%)]+)%)')
                  or commandString:match('TDX:useMovingSkill%(([^,]+),')
                  or commandString:match('TDX:useSkill%(([^,]+),')
        if hash then
            local pos = HashToPosCache[tostring(hash)]
            if pos then axisX = pos.x end
        end
    end
    if axisX and RebuildingCache[axisX] then return end
    local entries = parseMacroLine(commandString)
    if entries then for _, entry in ipairs(entries) do appendToJsonFile(entry) end end
end

local function setPending(typeStr, code, hash, extra)
    table.insert(pendingQueue, { type = typeStr, code = code, created = tick(), hash = hash, extra = extra })
end

local function tryConfirm(typeStr, specificHash)
    for i = #pendingQueue, 1, -1 do
        local item = pendingQueue[i]
        if item.type == typeStr then
            if not specificHash or string.find(item.code, tostring(specificHash)) then
                processAndWriteAction(item.code)
                table.remove(pendingQueue, i)
                return
            end
        end
    end
end

ReplicatedStorage.Remotes.TowerFactoryQueueUpdated.OnClientEvent:Connect(function(data)
    local d = data and data[1]
    if not d then return end
    if d.Creation then tryConfirm("Place") else tryConfirm("Sell") end
end)

local origTCUpgrade = rawget(GameModules.TowerClass, "Upgrade") or GameModules.TowerClass.Upgrade
if origTCUpgrade then
    GameModules.TowerClass.Upgrade = function(tower, ...)
        if not tower then return origTCUpgrade(tower, ...) end
        local lh = tower.LevelHandler
        local oldP1 = lh and (lh.Path1Level or 0) or 0
        local oldP2 = lh and (lh.Path2Level or 0) or 0
        origTCUpgrade(tower, ...)
        local hash = tower.Hash
        if not hash then return end
        local pos = HashToPosCache[tostring(hash)]
        if not pos or RebuildingCache[pos.x] then return end
        lh = tower.LevelHandler
        if not lh then return end
        local newP1 = lh.Path1Level or 0
        local newP2 = lh.Path2Level or 0
        local c1 = (newP1 > oldP1) and (newP1 - oldP1) or 0
        local c2 = (newP2 > oldP2) and (newP2 - oldP2) or 0
        local paths = {}
        if c1 >= c2 then
            if c1 > 0 then table.insert(paths, {p=1, c=c1}) end
            if c2 > 0 then table.insert(paths, {p=2, c=c2}) end
        else
            if c2 > 0 then table.insert(paths, {p=2, c=c2}) end
            if c1 > 0 then table.insert(paths, {p=1, c=c1}) end
        end
        local w, t = getCurrentWaveAndTime()
        for _, pd in ipairs(paths) do
            for _ = 1, pd.c do
                appendToJsonFile({UpgradeCost=0, UpgradePath=pd.p, TowerUpgraded=pos.x, Wave=w, Time=convertTimeToNumber(t)})
            end
        end
    end
end

ReplicatedStorage.Remotes.TowerUpgradeQueueUpdated.OnClientEvent:Connect(function() end)

ReplicatedStorage.Remotes.TowerQueryTypeIndexChanged.OnClientEvent:Connect(function(data)
    if data and data[1] then tryConfirm("Target") end
end)

local UpgradeShopDataUpdate = ReplicatedStorage.Remotes:FindFirstChild("UpgradeShopDataUpdate")
if UpgradeShopDataUpdate then UpgradeShopDataUpdate.OnClientEvent:Connect(function() tryConfirm("ShopUpgrade") end) end

local UpgradeShopTowerReset = ReplicatedStorage.Remotes:FindFirstChild("UpgradeShopTowerReset")
if UpgradeShopTowerReset then UpgradeShopTowerReset.OnClientEvent:Connect(function(uid) if tostring(uid) == tostring(player.UserId) then tryConfirm("ShopRefund") end end) end

local UpdatePowerUpStats = ReplicatedStorage.Remotes:FindFirstChild("UpdatePowerUpStats")
if UpdatePowerUpStats then
    UpdatePowerUpStats.OnClientEvent:Connect(function()
        tryConfirm("PowerUp")
    end)
end

local function handleRemote(name, args)
    if name == "SkipWaveVoteCast" then
        if args and args[1] == true then setPending("SkipWave", "TDX:skipWave()") end
    elseif name == "UpgradeShopOperationRequest" then
        local tName, stat, isTrue = args[1], args[2], args[3]
        local code
        if isTrue ~= nil then code = string.format('TDX:shopUpgrade("%s", "%s", %s)', tostring(tName), tostring(stat), tostring(isTrue))
        else code = string.format('TDX:shopUpgrade("%s", "%s")', tostring(tName), tostring(stat)) end
        setPending("ShopUpgrade", code)
    elseif name == "UpgradeShopRefundAllRequest" then
        local tName = args[1]
        local code = string.format('TDX:shopRefund("%s")', tostring(tName))
        setPending("ShopRefund", code, nil, tName)
    elseif name == "TowerUseAbilityRequest" then
        local h, idx, vec = args[1], args[2], args[3]
        if type(h) == "number" and type(idx) == "number" then
            local tName = GetTowerNameByHash(h)
            if IsMovingSkillTower(tName) then
                local code
                if typeof(vec) == "Vector3" then
                    code = string.format("TDX:useMovingSkill(%s, %d, Vector3.new(%s, %s, %s))", tostring(h), idx, tostring(vec.X), tostring(vec.Y), tostring(vec.Z))
                else
                    code = string.format("TDX:useSkill(%s, %d)", tostring(h), idx)
                end
                setPending("MovingSkill", code, h)
            end
        end
    elseif name == "PlaceTower" then
        local a1, n, v, r = args[1], args[2], args[3], args[4]
        if type(a1)=="number" and type(n)=="string" and typeof(v)=="Vector3" and type(r)=="number" then
            setPending("Place", string.format('TDX:placeTower(%s, "%s", Vector3.new(%s, %s, %s), %s)', tostring(a1), n, tostring(v.X), tostring(v.Y), tostring(v.Z), tostring(r)))
        end
    elseif name == "SellTower" then
        setPending("Sell", "TDX:sellTower("..tostring(args[1])..")")
    elseif name == "ChangeQueryType" then
        setPending("Target", string.format("TDX:changeQueryType(%s, %s)", tostring(args[1]), tostring(args[2])))
    elseif name == "RequestUsePowerUp" then
        local puName = args[1]
        local puVec  = args[2]
        if type(puName) == "string" then
            local code
            if typeof(puVec) == "Vector3" then
                code = string.format('TDX:usePowerUp("%s", Vector3.new(%s, %s, %s))',
                    puName, tostring(puVec.X), tostring(puVec.Y), tostring(puVec.Z))
            else
                code = string.format('TDX:usePowerUp("%s")', puName)
            end
            setPending("PowerUp", code)
        end
    end
end

local function setupHooks()
    if not hookfunction or not hookmetamethod or not checkcaller then return end
    local oldFireServer, oldInvokeServer
    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
        handleRemote(self.Name, {...})
        return oldFireServer(self, ...)
    end)
    oldInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(self, ...)
        handleRemote(self.Name, {...})
        return oldInvokeServer(self, ...)
    end)
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if checkcaller() then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then handleRemote(self.Name, {...}) end
        return oldNamecall(self, ...)
    end)
end
setupHooks()

local function SafeRemoteCall(remoteType, remote, ...)
    local args = {...}
    task.spawn(function()
        setThreadIdentity(2)
        if remoteType == "FireServer" then pcall(function() remote:FireServer(unpack(args)) end)
        elseif remoteType == "InvokeServer" then pcall(function() remote:InvokeServer(unpack(args)) end) end
    end)
end

local function ForceSellTower(hash)
    if CurrentConfig.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.SellTower, hash)
    else pcall(function() Remotes.SellTower:FireServer(hash) end) end
end

FindTower = function(mode, value)
    local towers = GameModules.TowerClass.GetTowers()
    if mode == "Axis" then
        for hash, tower in pairs(towers) do
            if tower.SpawnCFrame and typeof(tower.SpawnCFrame) == "CFrame" and tower.SpawnCFrame.Position.X == value then
                return hash, tower
            end
        end
    end
    return nil, nil
end

local function CreateTowerContext(axisX) return { axisX = axisX, hash = nil, tower = nil, levelHandler = nil } end
local function UpdateContext(ctx)
    local h, t = FindTower("Axis", ctx.axisX)
    if h and t and t.LevelHandler then ctx.hash = h; ctx.tower = t; ctx.levelHandler = t.LevelHandler; return true end
    return false
end

local function WaitForCash(amount) while currentCash < amount do RunService.RenderStepped:Wait() end end

local function GetTowerDiscount(tower)
    local discount = 0
    if tower and tower.BuffHandler then pcall(function() discount = tower.BuffHandler:GetDiscount() or 0 end) end
    return discount
end

local function GetTowerCostMultiplier(tower)
    local multiplier = 1
    if tower and tower.Type and GameModules.GameClass and GameModules.GameClass.GetTowerCostMultiplier then
        pcall(function() multiplier = GameModules.GameClass.GetTowerCostMultiplier(tower.Type) or 1 end)
    end
    return multiplier
end

local function GetTowerDynamicScalingData(tower)
    local dynamic = {}
    if not tower then return dynamic end
    pcall(function()
        if tower.GetDynamicPriceScalingData then dynamic = tower:GetDynamicPriceScalingData() or {}
        elseif GameModules.TowerClass and GameModules.TowerClass.GetDynamicPriceScalingData then dynamic = GameModules.TowerClass.GetDynamicPriceScalingData(tower) or {} end
    end)
    return dynamic
end

local function CalculateUpgradeCost(tower, path, count)
    if not tower or not tower.LevelHandler or count <= 0 then return nil end
    local lh = tower.LevelHandler
    local discount = GetTowerDiscount(tower)
    local multiplier = GetTowerCostMultiplier(tower)
    local dynamic = GetTowerDynamicScalingData(tower)
    local ok, result = pcall(function()
        if lh.GetLevelUpgradeCost then return lh:GetLevelUpgradeCost(path, count, discount, multiplier, dynamic)
        else return GameModules.LevelUtils.GetLevelUpgradeCost(lh, tower.Type, path, count, discount, multiplier, dynamic) end
    end)
    return ok and result or nil
end

local function PlaceTowerRetry(args, axisValue, towerName)
    local attempts = 0
    while attempts < 10 do
        if CurrentConfig.UseThreadedRemotes then SafeRemoteCall("InvokeServer", Remotes.PlaceTower, unpack(args))
        else pcall(function() Remotes.PlaceTower:InvokeServer(unpack(args)) end) end
        local t0 = tick()
        while tick() - t0 < 3 do if FindTower("Axis", axisValue) then return true end; RunService.RenderStepped:Wait() end
        attempts = attempts + 1
    end
    return false
end

local function UpgradeTowerToLevel(axisValue, targetPath1, targetPath2)
    local ctx = CreateTowerContext(axisValue)
    if not UpdateContext(ctx) then return false end
    local curP1 = ctx.levelHandler:GetLevelOnPath(1) or 0
    local curP2 = ctx.levelHandler:GetLevelOnPath(2) or 0
    local maxP1 = ctx.levelHandler:GetMaxPossibleLevel(1)
    local maxP2 = ctx.levelHandler:GetMaxPossibleLevel(2)
    local actualTarget1 = math.min(targetPath1, maxP1)
    local actualTarget2 = math.min(targetPath2, maxP2)
    if curP1 > actualTarget1 or curP2 > actualTarget2 then ForceSellTower(ctx.hash); return false end
    local function HandlePathSmart(pathIndex, targetLevel)
        while true do
            if not UpdateContext(ctx) then return false end
            local currentLevel = ctx.levelHandler:GetLevelOnPath(pathIndex) or 0
            if currentLevel >= targetLevel then
                if currentLevel > targetLevel then ForceSellTower(ctx.hash); return false end
                return true
            end
            local upgradesNeeded = targetLevel - currentLevel
            local amountToBuy = 0
            for k = upgradesNeeded, 1, -1 do
                local costK = CalculateUpgradeCost(ctx.tower, pathIndex, k)
                if costK and currentCash >= costK then amountToBuy = k; break end
            end
            if amountToBuy == 0 then
                local costOne = CalculateUpgradeCost(ctx.tower, pathIndex, 1)
                if costOne then WaitForCash(costOne); amountToBuy = 1 else return false end
            end
            if amountToBuy > 0 then
                if CurrentConfig.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.TowerUpgradeRequest, ctx.hash, pathIndex, amountToBuy)
                else pcall(function() Remotes.TowerUpgradeRequest:FireServer(ctx.hash, pathIndex, amountToBuy) end) end
                local start = tick()
                local expected = currentLevel + amountToBuy
                while tick() - start < 2 do
                    local lvl = ctx.levelHandler:GetLevelOnPath(pathIndex) or 0
                    if lvl >= expected then break end
                    RunService.RenderStepped:Wait()
                end
            else
                RunService.RenderStepped:Wait()
            end
        end
    end
    if not HandlePathSmart(1, actualTarget1) then return false end
    if not HandlePathSmart(2, actualTarget2) then return false end
    return true
end

local function ChangeTargetRetry(axisValue, targetType)
    local attempts = 0
    while attempts < 3 do
        local hash = FindTower("Axis", axisValue)
        if hash then
            if CurrentConfig.UseThreadedRemotes then SafeRemoteCall("FireServer", Remotes.ChangeQueryType, hash, targetType)
            else pcall(function() Remotes.ChangeQueryType:FireServer(hash, targetType) end) end
            return true
        end
        attempts = attempts + 1
        SmartWait(0.2)
    end
    return false
end

local function UseMovingSkillRetry(axisValue, skillIndex, location)
    local Remote = Remotes:FindFirstChild("TowerUseAbilityRequest")
    if not Remote then return false end
    local isEvent = Remote:IsA("RemoteEvent")
    location = location or "no_pos"
    local attempts = 0
    while attempts < 5 do
        local h, t = FindTower("Axis", axisValue)
        if h and t and t.AbilityHandler then
            local ability = t.AbilityHandler:GetAbilityFromIndex(skillIndex)
            if ability then
                if ability.CooldownRemaining > 0 then SmartWait(ability.CooldownRemaining + 0.1) end
                local args = {h, skillIndex}
                if location ~= "no_pos" then
                    local x, y, z = location:match("([^,%s]+),%s*([^,%s]+),%s*([^,%s]+)")
                    if x then table.insert(args, Vector3.new(tonumber(x), tonumber(y), tonumber(z))) end
                end
                if CurrentConfig.UseThreadedRemotes then SafeRemoteCall(isEvent and "FireServer" or "InvokeServer", Remote, unpack(args))
                else pcall(function() if isEvent then Remote:FireServer(unpack(args)) else Remote:InvokeServer(unpack(args)) end end) end
                return true
            end
        end
        attempts = attempts + 1
        SmartWait(0.2)
    end
    return false
end

local function RebuildTowerSequence(records, jobAxisX)
    local placeRecord, upgradesByPath, targetRecords, movingRecords = nil, {[1]={}, [2]={}}, {}, {}
    for _, r in ipairs(records) do
        local e = r.entry
        if e.TowerPlaced then placeRecord = r
        elseif e.TowerUpgraded then table.insert(upgradesByPath[e.UpgradePath] or {}, r)
        elseif e.TowerTargetChange then table.insert(targetRecords, r)
        elseif e.towermoving then table.insert(movingRecords, r) end
    end

    local lastWithPos = nil
    local lastNoPos = nil
    for _, r in ipairs(movingRecords) do
        local e = r.entry
        if e.location and e.location ~= "no_pos" then
            lastWithPos = e
        else
            lastNoPos = e
        end
    end
    local finalPosEntry = lastWithPos  -- entry quyết định vị trí place
    local skillEntry = lastNoPos or lastWithPos  -- entry để fire skill nếu không có pos

    local placePos = nil
    local newAxisX = nil
    if finalPosEntry and placeRecord then
        local lv = {}; for c in finalPosEntry.location:gmatch("[^,%s]+") do table.insert(lv, tonumber(c)) end
        if #lv == 3 then
            placePos = Vector3.new(lv[1], lv[2], lv[3])
            newAxisX = lv[1]
        end
    end
    if not placePos and placeRecord then
        local v = {}; for c in placeRecord.entry.TowerVector:gmatch("[^,%s]+") do table.insert(v, tonumber(c)) end
        placePos = Vector3.new(v[1], v[2], v[3])
        newAxisX = v[1]
    end

    local success = true
    if placeRecord and placePos then
        local e = placeRecord.entry
        local args = {tonumber(e.TowerA1), e.TowerPlaced, placePos, tonumber(e.Rotation or 0)}
        WaitForCash(e.TowerPlaceCost)
        if not PlaceTowerRetry(args, newAxisX, e.TowerPlaced) then success = false end

        -- Nếu axis thay đổi (moving tower placed tại vị trí mới), migrate towersByAxis
        if success and jobAxisX and newAxisX ~= jobAxisX then
            towersByAxis[newAxisX] = towersByAxis[jobAxisX]
            towersByAxis[jobAxisX] = nil
            rebuildAttempts[newAxisX] = rebuildAttempts[jobAxisX]
            rebuildAttempts[jobAxisX] = nil
            RebuildingCache[newAxisX] = true
            markExistCacheDirty()
        end
    end
    if success and newAxisX then
        local max1, max2 = #upgradesByPath[1], #upgradesByPath[2]
        if max1 > 0 or max2 > 0 then
            if not UpgradeTowerToLevel(newAxisX, max1, max2) then success = false end
        end
    end
    if success then
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
    return success, newAxisX
end

local deadTowers, nextDeathId, jobQueue, activeJobs = {}, 1, {}, {}
local loopTimers = { pending = 0, logic = 0 }
local existCache = {}
local existCacheDirty = true
local function markExistCacheDirty() existCacheDirty = true end

local function GetTowerPriority(towerName)
    for priority, name in ipairs(CurrentConfig.PriorityRebuildOrder or {}) do
        if towerName == name then return priority end
    end
    return 999
end

local function ShouldSkipTower(axisX, towerName, lineIndex)
    if CurrentConfig.SkipTowersAtAxis[axisX] then return true end
    if CurrentConfig.SkipTowersByName[towerName] then return true end
    if lineIndex and CurrentConfig.SkipTowersByLine[lineIndex] then return true end
    return false
end

local origTCNew = rawget(GameModules.TowerClass, "New") or GameModules.TowerClass.New
if origTCNew then
    GameModules.TowerClass.New = function(...)
        local tower = origTCNew(...)
        if tower and tower.Hash then
            local pos = GetTowerSpawnPosition(tower)
            if pos then
                HashToPosCache[tostring(tower.Hash)] = {x = pos.X, y = pos.Y, z = pos.Z}
                markExistCacheDirty()
            end
        end
        return tower
    end
end

local origTCDestroy = rawget(GameModules.TowerClass, "Destroy") or GameModules.TowerClass.Destroy
if origTCDestroy then
    GameModules.TowerClass.Destroy = function(tower, ...)
        local hash = tower and tower.Hash
        origTCDestroy(tower, ...)
        if hash then HashToPosCache[tostring(hash)] = nil; markExistCacheDirty() end
    end
end

do
    local existingHashes = {}
    local rawT = GameModules.TowerClass.GetTowers and GameModules.TowerClass.GetTowers()
    if rawT then
        for hash, tower in pairs(rawT) do
            local pos = GetTowerSpawnPosition(tower)
            if pos then
                local hashStr = tostring(hash)
                existingHashes[hashStr] = true
                HashToPosCache[hashStr] = {x = pos.X, y = pos.Y, z = pos.Z}
            end
        end
    end
    for hashStr in pairs(HashToPosCache) do
        if not existingHashes[hashStr] then HashToPosCache[hashStr] = nil end
    end
end

local posTrack = {
    lastPos  = nil,
    idleTime = 0,
    recorded = false,
    hrp      = nil,   -- cached HumanoidRootPart ref
    char     = nil,   -- cached character ref để detect respawn
}

RunService.RenderStepped:Connect(function(dt)

    loopTimers.pending = loopTimers.pending + dt
    if loopTimers.pending >= 0.05 then
        loopTimers.pending = 0
        for i = #pendingQueue, 1, -1 do
            local item = pendingQueue[i]
            local age = tick() - item.created
            local timeout = (item.type == "ShopUpgrade" or item.type == "ShopRefund") and 15 or 3
            if (item.type == "MovingSkill" or item.type == "SkipWave" or item.type == "PowerUp") and age > 0.1 then
                processAndWriteAction(item.code)
                table.remove(pendingQueue, i)
            elseif age > timeout then table.remove(pendingQueue, i) end
        end
    end

    loopTimers.logic = loopTimers.logic + dt
    if loopTimers.logic >= 0.2 then
        loopTimers.logic = 0
        pcall(function()
            for hash, tower in pairs(GameModules.TowerClass.GetTowers()) do
                local tName = tower.Type
                local shouldSell = tower.Converted
                if not shouldSell and CurrentConfig.ReliveTowers[tName] then
                    local val = CurrentConfig.ReliveTowers[tName]
                    if val == -1 and tower.IsRebuilding and tower:IsRebuilding() then shouldSell = true
                    elseif val ~= -1 and (tower.RebuildsLeft or 0) <= val then shouldSell = true end
                end
                if not shouldSell and CurrentConfig.AutoReshield and tName == CurrentConfig.ShieldTowerName then
                    if tower.LevelHandler and tower.LevelHandler.Path1Level >= 5 then
                        if (tower.HealthHandler:GetShield() or 0) <= (CurrentConfig.ReshieldThreshold or 0) then shouldSell = true end
                    end
                end
                if shouldSell then ForceSellTower(hash) end
            end
        end)
    end

    if CurrentConfig.RecordPlayerPosition then
        local char = player.Character
        if char ~= posTrack.char then
            posTrack.char = char
            posTrack.hrp = char and char:FindFirstChild("HumanoidRootPart") or nil
            posTrack.lastPos = nil; posTrack.idleTime = 0; posTrack.recorded = false
        end
        local hrp = posTrack.hrp
        if hrp then
            local curPos = hrp.Position
            if posTrack.lastPos then
                local dx = curPos.X - posTrack.lastPos.X
                local dz = curPos.Z - posTrack.lastPos.Z
                local moved2 = dx*dx + dz*dz
                local tol = CurrentConfig.PlayerIdleMoveTolerance
                if moved2 <= tol*tol then
                    if not posTrack.recorded then
                        posTrack.idleTime = posTrack.idleTime + dt
                        if posTrack.idleTime >= CurrentConfig.PlayerIdleThreshold then
                            local w, t = getCurrentWaveAndTime()
                            if w ~= "-" then
                                appendToJsonFile({
                                    PlayerPosition = string.format("%s, %s, %s",
                                        tostring(curPos.X), tostring(curPos.Y), tostring(curPos.Z)),
                                    Wave = w, Time = convertTimeToNumber(t),
                                })
                            end
                            posTrack.recorded = true
                        end
                    end
                else
                    posTrack.idleTime = 0
                    posTrack.recorded = false
                end
            end
            posTrack.lastPos = curPos
        end
    end

    if existCacheDirty then
        existCache = {}
        for _, pos in pairs(HashToPosCache) do existCache[pos.x] = true end
        existCacheDirty = false
    end

    local added = false
    for x, recs in pairs(towersByAxis) do
        if not soldAxis[x] and not existCache[x] then
            if not activeJobs[x] then
                if not deadTowers[x] then deadTowers[x] = {time=tick(), id=nextDeathId}; nextDeathId=nextDeathId+1 end
                local tType, line
                for _, r in ipairs(recs) do if r.entry.TowerPlaced then tType=r.entry.TowerPlaced; line=r.line; break end end
                if tType then
                    rebuildAttempts[x] = (rebuildAttempts[x] or 0) + 1
                    if not CurrentConfig.MaxRebuildRetry or rebuildAttempts[x] <= CurrentConfig.MaxRebuildRetry then
                        activeJobs[x] = true
                        table.insert(jobQueue, { x=x, records=recs, priority=GetTowerPriority(tType), deathTime=deadTowers[x].time, towerName=tType, firstPlaceLine=line })
                        added = true
                    end
                end
            end
        else
            deadTowers[x] = nil
            if activeJobs[x] then
                activeJobs[x] = nil
                for i=#jobQueue, 1, -1 do if jobQueue[i].x == x then table.remove(jobQueue, i); break end end
            end
        end
    end
    if added and #jobQueue > 1 then table.sort(jobQueue, function(a,b) return (a.priority==b.priority) and (a.deathTime<b.deathTime) or (a.priority<b.priority) end) end
end)

task.spawn(function()
    while true do
        RunService.RenderStepped:Wait()
        if #jobQueue > 0 then
            local job = table.remove(jobQueue, 1)
            task.spawn(function()
                setThreadIdentity(2)
                RebuildingCache[job.x] = true
                local newAxisX
                local s = pcall(function()
                    if not ShouldSkipTower(job.x, job.towerName, job.firstPlaceLine) then
                        local ok, ax = RebuildTowerSequence(job.records, job.x)
                        newAxisX = ax
                        if ok then rebuildAttempts[job.x] = 0; deadTowers[job.x] = nil end
                    else rebuildAttempts[job.x] = 0; deadTowers[job.x] = nil end
                end)
                RebuildingCache[job.x] = nil
                if newAxisX and newAxisX ~= job.x then RebuildingCache[newAxisX] = nil end
                if not s then rebuildAttempts[job.x] = (rebuildAttempts[job.x] or 0) + 1 end
                activeJobs[job.x] = nil
            end)
        end
    end
end)
