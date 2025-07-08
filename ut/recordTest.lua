-- Universal Macro Recorder Module (No TowerClass, Uses Hotbar Index, GUI Cash Tracking)
local MacroRecorder = {}

local macroLog = {}
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local outJson = nil
local recording = false
local recordTask = nil

-- Utility: serialize vector to string
local function vectorToString(vec)
    if typeof(vec) == "Vector3" then
        return string.format("%.8g, %.8g, %.8g", vec.X, vec.Y, vec.Z)
    elseif type(vec) == "table" and vec.X and vec.Y and vec.Z then
        return string.format("%.8g, %.8g, %.8g", vec.X, vec.Y, vec.Z)
    else
        return tostring(vec)
    end
end

-- Get Hotbar Index from tower name/hash
local function getHotbarIndexFromName(name)
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return nil end
    local mainGui = gui:FindFirstChild("MainGui")
    if not mainGui then return nil end
    local hud = mainGui:FindFirstChild("HUD")
    if not hud then return nil end
    local toolbox = hud:FindFirstChild("Toolbox")
    if not toolbox then return nil end
    local hotbar = toolbox:FindFirstChild("Hotbar")
    if not hotbar then return nil end
    local slot = hotbar:FindFirstChild(name)
    if slot and slot:FindFirstChild("HotbarIndex") then
        return tonumber(slot.HotbarIndex.Text)
    end
    return nil
end

-- Get current money from GUI, formatted as number
local function getTotalMoney()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return 0 end
    local mainGui = gui:FindFirstChild("MainGui")
    if not mainGui then return 0 end
    local mainFrames = mainGui:FindFirstChild("MainFrames")
    if not mainFrames then return 0 end
    local cash = mainFrames:FindFirstChild("Cash")
    if not cash then return 0 end
    local amount = cash:FindFirstChild("Amount")
    if not amount or not amount:IsA("TextLabel") then return 0 end
    local text = tostring(amount.Text)
    local num = text:gsub("%$", ""):gsub(",", ""):gsub("%s+", "")
    return tonumber(num) or 0
end

-- Get current time (stub, replace with your method if needed)
local function getCurrentTime()
    return tick()
end

-- Track last cash for cost calculation
local lastCash = getTotalMoney()

-- Log PlaceTower event (only if money decreases)
local function logPlaceTower(args)
    local nameOrHash = tostring(args[1])
    local pos = args[2]
    local rot = args[3]
    local hotbarIndex = getHotbarIndexFromName(nameOrHash)
    local beforeCash = lastCash
    local afterCash = getTotalMoney()
    local placeCost = beforeCash - afterCash

    if afterCash < beforeCash then
        table.insert(macroLog, {
            TowerPlaced = hotbarIndex and tostring(hotbarIndex) or nameOrHash,
            Time = getCurrentTime(),
            TotalMoney = afterCash,
            PlaceCost = placeCost,
            TowerPosition = vectorToString(pos),
            Rotation = rot
        })
        lastCash = afterCash
    end
end

-- Helper: Get X position of tower model by id (as string)
local function getTowerModelXById(id)
    local towersFolder = workspace:FindFirstChild("EntityModels") and workspace.EntityModels:FindFirstChild("Towers")
    if not towersFolder then return nil end
    local model = towersFolder:FindFirstChild(tostring(id))
    if model and model.PrimaryPart then
        return model.PrimaryPart.Position.X
    end
    return nil
end

-- Log UpgradeTower event (only if money decreases)
local function logUpgradeTower(args)
    local xValue = args[1]
    local towerX = getTowerModelXById(xValue)
    local beforeCash = lastCash
    local afterCash = getTotalMoney()
    local upgradeCost = beforeCash - afterCash

    if afterCash < beforeCash then
        table.insert(macroLog, {
            Time = getCurrentTime(),
            TotalMoney = afterCash,
            UpgradeCost = upgradeCost,
            TowerUpgradedX = towerX
        })
        lastCash = afterCash
    end
end

-- Log SellTower event (only if money increases)
local function logSellTower(args)
    local xValue = args[1]
    local towerX = getTowerModelXById(xValue)
    local beforeCash = lastCash
    local afterCash = getTotalMoney()
    local sellGain = afterCash - beforeCash

    if afterCash > beforeCash then
        table.insert(macroLog, {
            Time = getCurrentTime(),
            TotalMoney = afterCash,
            SellTowerX = towerX,
            SellGain = sellGain
        })
        lastCash = afterCash
    end
end

-- Improved remote hooking system based on SimpleSpy's robust method
local originalNamecall
local originalEvent
local originalFunction
local hooked = false

local function hookRemotes()
    if hooked then return end
    hooked = true

    -- Only hook if not already hooked
    if not originalNamecall then
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if recording and method == "FireServer" then
                if self.Name == "PlayerPlaceTower" then
                    logPlaceTower(args)
                elseif self.Name == "PlayerUpgradeTower" then
                    logUpgradeTower(args)
                elseif self.Name == "PlayerSellTower" then
                    logSellTower(args)
                end
            end

            -- Always call the original function
            return originalNamecall(self, ...)
        end)
    end

    if not originalEvent then
        local remoteEvent = Instance.new("RemoteEvent")
        originalEvent = hookfunction(remoteEvent.FireServer, function(self, ...)
            local args = {...}

            if recording and self.Name == "PlayerPlaceTower" then
                logPlaceTower(args)
            elseif recording and self.Name == "PlayerUpgradeTower" then
                logUpgradeTower(args)
            elseif recording and self.Name == "PlayerSellTower" then
                logSellTower(args)
            end

            -- Always call the original function
            return originalEvent(self, ...)
        end)
    end

    if not originalFunction then
        local remoteFunction = Instance.new("RemoteFunction")
        originalFunction = hookfunction(remoteFunction.InvokeServer, function(self, ...)
            local args = {...}

            if recording and self.Name == "PlayerPlaceTower" then
                logPlaceTower(args)
            elseif recording and self.Name == "PlayerUpgradeTower" then
                logUpgradeTower(args)
            elseif recording and self.Name == "PlayerSellTower" then
                logSellTower(args)
            end

            -- Always call the original function
            return originalFunction(self, ...)
        end)
    end
end

local function unhookRemotes()
    if not hooked then return end
    
    -- Restore original functions
    if originalNamecall then
        hookmetamethod(game, "__namecall", originalNamecall)
    end
    
    if originalEvent then
        hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
    end
    
    if originalFunction then
        hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
    end
    
    hooked = false
end

function MacroRecorder.startRecording(outputFile)
    if recording then return end
    recording = true
    outJson = outputFile
    macroLog = {}
    lastCash = getTotalMoney()
    hookRemotes()
    
    if recordTask then recordTask:Disconnect() end
    recordTask = game:GetService("RunService").Heartbeat:Connect(function()
        if outJson and recording then
            writefile(outJson, HttpService:JSONEncode(macroLog))
        end
    end)
    
    print("✅ Macro recording started: " .. tostring(outJson))
end

function MacroRecorder.stopRecording()
    if not recording then return end
    recording = false
    
    if recordTask then recordTask:Disconnect() end
    recordTask = nil
    
    if outJson then
        writefile(outJson, HttpService:JSONEncode(macroLog))
    end
    
    unhookRemotes()
    print("⏹️ Macro recording stopped: " .. tostring(outJson))
end

-- Utility to check if RoundOver is visible
function MacroRecorder.isRoundOverVisible()
    local gui = player:FindFirstChild("PlayerGui")
    if gui then
        local mainGui = gui:FindFirstChild("MainGui")
        if mainGui then
            local mainFrames = mainGui:FindFirstChild("MainFrames")
            if mainFrames then
                local roundOver = mainFrames:FindFirstChild("RoundOver")
                if roundOver and roundOver.Visible then
                    return true
                end
            end
        end
    end
    return false
end

return MacroRecorder
