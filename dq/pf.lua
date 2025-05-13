-- ====== SERVICES ======
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

-- ====== CONFIGURATION ======
local Config = {
    ATTACK_RANGE = 30,
    REFRESH_RATE = 0,
    STUCK_CHECK_INTERVAL = 60,
    STUCK_DISTANCE_THRESHOLD = 5,
    PREDICTION_FRAMES = 10,
    TELEPORT_DELAY = 0.25
}

-- ====== PLAYER INITIALIZATION ======
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Check player count before proceeding
local function checkPlayerCount()
    return #Players:GetPlayers() <= 1
end

if not checkPlayerCount() then
    warn("Script disabled - More than 1 player in game")
    return
end

-- ====== MINIMAL STATS GUI ======
local statsGui = Instance.new("ScreenGui")
statsGui.Name = "PathfinderStats"
statsGui.Parent = player.PlayerGui

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0.25, 0, 0.15, 0)
statsFrame.Position = UDim2.new(0.73, 0, 0.8, 0)
statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
statsFrame.BackgroundTransparency = 0.7
statsFrame.BorderSizePixel = 0
statsFrame.Parent = statsGui

local statsText = Instance.new("TextLabel")
statsText.Name = "StatsText"
statsText.Text = "Initializing pathfinder..."
statsText.Size = UDim2.new(1, -10, 1, -10)
statsText.Position = UDim2.new(0, 5, 0, 5)
statsText.BackgroundTransparency = 1
statsText.TextColor3 = Color3.fromRGB(200, 255, 200)
statsText.Font = Enum.Font.Code
statsText.TextSize = 14
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.TextYAlignment = Enum.TextYAlignment.Top
statsText.TextWrapped = true
statsText.Parent = statsFrame

local function UpdateStats(info)
    statsText.Text = string.format(
        "TARGET: %s\nDISTANCE: %.1f\nWAYPOINT: %d/%d\nSTATUS: %s\nPREDICTION: %s",
        info.targetName or "NONE",
        info.distance or 0,
        info.currentWaypoint or 0,
        info.totalWaypoints or 0,
        info.status or "IDLE",
        info.prediction or "OFF"
    )
end

-- ====== ENEMY PREDICTION SYSTEM ======
local Prediction = {
    History = {},
    SampleRate = 0.1
}

function PredictPosition(enemy, frames)
    if not Prediction.History[enemy] then return enemy:GetPivot().Position end
    
    local velocity = Vector3.new()
    local samples = math.min(#Prediction.History[enemy], 5)
    
    for i = 1, samples-1 do
        local delta = Prediction.History[enemy][i] - Prediction.History[enemy][i+1]
        velocity = velocity + (delta / Prediction.SampleRate)
    end
    velocity = velocity / samples
    
    return enemy:GetPivot().Position + (velocity * frames * Prediction.SampleRate)
end

-- ====== PATHFINDING FUNCTIONS ======
local function isEnemyAlive(enemy)
    if not enemy:FindFirstChild("HumanoidRootPart") then return false end
    local enemyHumanoid = enemy:FindFirstChild("Humanoid")
    if enemyHumanoid and enemyHumanoid.Health <= 0 then return false end
    return true
end

local function findClosestAliveEnemy()
    local closestEnemy = nil
    local closestDistance = math.huge
    
    for _, folder in pairs(game.Workspace.dungeon:GetDescendants()) do
        if folder.Name == "enemyFolder" then
            for _, enemy in pairs(folder:GetChildren()) do
                if enemy:IsA("Model") and isEnemyAlive(enemy) and enemy:FindFirstChild("HumanoidRootPart") then
                    local distance = (character:GetPivot().Position - enemy:GetPivot().Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestEnemy = enemy
                    end
                end
            end
        end
    end
    
    UpdateStats({
        targetName = closestEnemy and closestEnemy.Name or "NONE",
        distance = closestDistance ~= math.huge and closestDistance or 0,
        status = closestEnemy and "TARGET FOUND" or "NO TARGETS",
        prediction = Config.PREDICTION_FRAMES > 0 and "ON" or "OFF"
    })
    
    return closestEnemy, closestDistance
end

local function SafeTeleport(position)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(position)
        return true
    end
    return false
end

local function ComputePath(target)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })
    
    local targetPos = Config.PREDICTION_FRAMES > 0 and PredictPosition(target, Config.PREDICTION_FRAMES) or target:GetPivot().Position
    path:ComputeAsync(character:GetPivot().Position, targetPos)
    
    return path
end

local function EnhancedMoveToTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    
    local path = ComputePath(target)
    if not path or path.Status ~= Enum.PathStatus.Success then
        UpdateStats({
            status = "PATH FAILED: "..tostring(path and path.Status or "NO PATH"),
            targetName = target.Name
        })
        return
    end

    local waypoints = path:GetWaypoints()
    local lastPosition = character:GetPivot().Position
    local lastMovementCheck = os.clock()
    
    for i, waypoint in ipairs(waypoints) do
        -- Check player count before each move
        if not checkPlayerCount() then
            UpdateStats({status = "DISABLED - MULTIPLAYER DETECTED"})
            return
        end
        
        -- Update stats
        UpdateStats({
            targetName = target.Name,
            distance = (target:GetPivot().Position - character:GetPivot().Position).Magnitude,
            currentWaypoint = i,
            totalWaypoints = #waypoints,
            status = "MOVING"
        })
        
        -- Check if stuck
        if os.clock() - lastMovementCheck >= Config.STUCK_CHECK_INTERVAL then
            local currentPosition = character:GetPivot().Position
            if (currentPosition - lastPosition).Magnitude < Config.STUCK_DISTANCE_THRESHOLD then
                UpdateStats({status = "STUCK - RECALCULATING"})
                return
            end
            lastPosition = currentPosition
            lastMovementCheck = os.clock()
        end
        
        -- Check attack range
        if (target:GetPivot().Position - character:GetPivot().Position).Magnitude <= Config.ATTACK_RANGE then
            UpdateStats({status = "IN ATTACK RANGE"})
            break
        end
        
        -- Teleport to waypoint
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            SafeTeleport(waypoint.Position + Vector3.new(0, 5, 0))
        else
            SafeTeleport(waypoint.Position)
        end
        
        -- Update prediction history
        if Config.PREDICTION_FRAMES > 0 then
            if not Prediction.History[target] then
                Prediction.History[target] = {}
            end
            table.insert(Prediction.History[target], 1, target:GetPivot().Position)
            if #Prediction.History[target] > 10 then
                table.remove(Prediction.History[target])
            end
        end
        
        task.wait(Config.TELEPORT_DELAY)
    end
end

-- ====== MAIN LOOP ======
while checkPlayerCount() do
    local enemy, distance = findClosestAliveEnemy()
    
    if enemy then
        if distance > Config.ATTACK_RANGE then
            EnhancedMoveToTarget(enemy)
        else
            UpdateStats({
                status = "IN ATTACK RANGE",
                targetName = enemy.Name,
                distance = distance
            })
        end
    else
        UpdateStats({
            status = "SEARCHING",
            targetName = "NONE",
            distance = 0
        })
    end
    
    task.wait(Config.REFRESH_RATE)
end

-- If we exit the loop due to player count
UpdateStats({status = "DISABLED - MULTIPLAYER DETECTED"})
