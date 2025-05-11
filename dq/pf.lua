local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ====== CONFIGURATION ======
local ATTACK_RANGE = 30 -- Stops moving when within this distance (studs)
local REFRESH_RATE = 1 -- How often to check for new targets (seconds)
local STUCK_THRESHOLD = 10 -- Time in seconds before considering stuck (increased to 10)
local MAX_WAYPOINT_TIME = 10 -- Maximum time to spend on a single waypoint
local RECALCULATE_ATTEMPTS = 3 -- How many times to try recalculating path when stuck
local LONG_PATH_THRESHOLD = 100 -- Considered a long path
local WAYPOINT_SKIP_DISTANCE = 5 -- How many waypoints to skip when stuck
local CONSECUTIVE_STUCK_LIMIT = 3 -- How many stuck checks before taking action
local STUCK_MOVE_THRESHOLD = 1.5 -- Distance to consider as not moving (studs)
local INPUT_RESET_DELAY = 0.2 -- Time to wait after clearing player input
local STUCK_CHECK_INTERVAL = 10 -- Check for stuck conditions every 10 seconds

-- ====== DEBUG GUI SETUP ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PathfindingDebug"
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.25, 0, 0.35, 0)
frame.Position = UDim2.new(0.73, 0, 0.6, 0)
frame.BackgroundTransparency = 0.7
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Text = "PATHFINDING STATS"
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SciFi
title.TextSize = 22
title.TextScaled = false
title.Parent = frame

local content = Instance.new("TextLabel")
content.Name = "Content"
content.Text = "Initializing..."
content.Size = UDim2.new(1, -10, 0.85, -10)
content.Position = UDim2.new(0, 5, 0.15, 5)
content.BackgroundTransparency = 1
content.TextColor3 = Color3.fromRGB(200, 255, 200)
content.Font = Enum.Font.Code
content.TextSize = 18
content.TextXAlignment = Enum.TextXAlignment.Left
content.TextYAlignment = Enum.TextYAlignment.Top
content.TextWrapped = true
content.Parent = frame

local textStroke = Instance.new("UIStroke")
textStroke.Thickness = 1.5
textStroke.Color = Color3.fromRGB(0, 0, 0)
textStroke.Parent = content

-- ====== MOVEMENT TRACKING ======
local lastPosition = character:GetPivot().Position
local lastMovementCheck = os.clock()
local currentWaypointIndex = 0
local lastWaypointChangeTime = os.clock()

-- ====== INPUT CONTROL ======
local function clearPlayerInput()
    -- Cancel all current movement input
    humanoid:Move(Vector3.new(0, 0, 0))
    
    -- Disconnect any existing connections to prevent memory leaks
    if humanoid.MoveToFinished then
        humanoid.MoveToFinished:Disconnect()
    end
    
    task.wait(INPUT_RESET_DELAY) -- Small delay to ensure input is cleared
end

-- ====== PATHFINDING FUNCTIONS ======
local function updateDebugInfo(info)
    content.Text = string.format(
        "STATUS: %s\n\nTARGET: %s\n\nDISTANCE: %.1f/%.1f\n\nPATH: %s\n\nWAYPOINT: %d\n\nLAST CHECK: %s\n\nUPDATED: %s",
        info.status or "WAITING",
        info.targetName or "NONE",
        info.distance or 0,
        ATTACK_RANGE,
        info.pathStatus or "READY",
        currentWaypointIndex,
        os.date("%X", lastMovementCheck),
        os.date("%X")
    )
end

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
    
    updateDebugInfo({
        status = closestEnemy and "TARGET FOUND" or "NO TARGETS",
        targetName = closestEnemy and closestEnemy.Name or "NONE",
        distance = closestDistance ~= math.huge and closestDistance or 0
    })
    
    return closestEnemy, closestDistance
end

local function checkStuckCondition()
    local currentTime = os.clock()
    local currentPosition = character:GetPivot().Position
    local distanceMoved = (currentPosition - lastPosition).Magnitude
    
    -- Update last check time
    lastMovementCheck = currentTime
    
    -- Check if we're not moving
    if distanceMoved < STUCK_MOVE_THRESHOLD then
        -- Check if we've been stuck for the threshold time
        if (currentTime - lastWaypointChangeTime) >= STUCK_THRESHOLD then
            return true
        end
    else
        -- Update position if we're moving
        lastPosition = currentPosition
    end
    
    return false
end

local function moveToTarget(target, recalculateAttempts)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return false end
    recalculateAttempts = recalculateAttempts or 0
    
    local stopMoving = false
    local _, currentDistance = findClosestAliveEnemy()
    
    -- Skip if we've tried too many times
    if recalculateAttempts >= RECALCULATE_ATTEMPTS then
        updateDebugInfo({
            status = "GIVING UP - TOO MANY ATTEMPTS",
            targetName = target.Name,
            distance = currentDistance,
            pathStatus = "FAILED"
        })
        return false
    end
    
    -- Stop if already in attack range
    if currentDistance <= ATTACK_RANGE then
        updateDebugInfo({
            status = "IN RANGE",
            targetName = target.Name,
            distance = currentDistance,
            pathStatus = "READY TO ATTACK"
        })
        return true
    end
    
    updateDebugInfo({
        status = "CALCULATING PATH",
        targetName = target.Name,
        distance = currentDistance
    })
    
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })
    
    local deathCheckConnection
    if target:FindFirstChild("Humanoid") then
        deathCheckConnection = target.Humanoid.Died:Connect(function()
            stopMoving = true
        end)
    end
    
    local success, errorMessage = pcall(function()
        path:ComputeAsync(character:GetPivot().Position, target:GetPivot().Position)
    end)
    
    if not success then
        warn("Path error:", errorMessage)
        if deathCheckConnection then deathCheckConnection:Disconnect() end
        return false
    end
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local stuckCheckTimer = os.clock()
        
        for i, waypoint in ipairs(waypoints) do
            if stopMoving then break end
            
            currentWaypointIndex = i
            lastWaypointChangeTime = os.clock()
            
            -- Skip waypoints if we're far along in a long path
            if #waypoints > LONG_PATH_THRESHOLD and i > 50 then
                local skipAmount = math.min(WAYPOINT_SKIP_DISTANCE, #waypoints - i)
                updateDebugInfo({
                    status = "LONG PATH - SKIPPING",
                    targetName = target.Name,
                    distance = currentDistance,
                    pathStatus = string.format("SKIPPING %d WAYPOINTS (%d/%d)", skipAmount, i, #waypoints)
                })
                i = i + skipAmount - 1 -- -1 because loop will increment
                continue
            end

            -- Check distance every step
            local _, currentDistance = findClosestAliveEnemy()
            if currentDistance <= ATTACK_RANGE then
                updateDebugInfo({
                    status = "IN RANGE",
                    targetName = target.Name,
                    distance = currentDistance,
                    pathStatus = "ATTACKING"
                })
                if deathCheckConnection then deathCheckConnection:Disconnect() end
                return true
            end
            
            updateDebugInfo({
                status = "MOVING",
                targetName = target.Name,
                distance = currentDistance,
                pathStatus = string.format("%s (%d/%d)", path.Status.Name, i, #waypoints)
            })
            
            -- Clear any player input before moving
            clearPlayerInput()
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startTime = os.clock()
            
            while not humanoid.MoveToFinished:Wait(0.1) do
                -- Check for stuck condition every 10 seconds
                if os.clock() - stuckCheckTimer >= STUCK_CHECK_INTERVAL then
                    stuckCheckTimer = os.clock()
                    
                    if checkStuckCondition() then
                        updateDebugInfo({
                            status = "STUCK - RECALCULATING",
                            targetName = target.Name,
                            distance = currentDistance,
                            pathStatus = string.format("PATH RECALCULATION (attempt %d/%d)", recalculateAttempts + 1, RECALCULATE_ATTEMPTS)
                        })
                        
                        if deathCheckConnection then deathCheckConnection:Disconnect() end
                        return moveToTarget(target, recalculateAttempts + 1)
                    end
                end

                -- Timeout for this waypoint
                if os.clock() - startTime > MAX_WAYPOINT_TIME then
                    updateDebugInfo({
                        status = "WAYPOINT TIMEOUT",
                        targetName = target.Name,
                        distance = currentDistance,
                        pathStatus = string.format("TIMEOUT (%d/%d)", i, #waypoints)
                    })
                    stopMoving = true
                    break
                end
                
                if not isEnemyAlive(target) then
                    stopMoving = true
                    break
                end
            end
        end
    else
        warn("Path failed:", path.Status)
        updateDebugInfo({
            status = "PATH FAILED",
            targetName = target.Name,
            distance = currentDistance,
            pathStatus = path.Status.Name
        })
    end
    
    if deathCheckConnection then deathCheckConnection:Disconnect() end
    return false
end

-- ====== INPUT MONITORING ======
local function monitorPlayerInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and (input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or 
                                 input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D) then
            -- Player pressed a movement key - clear any existing path movement
            clearPlayerInput()
        end
    end)
end

-- ====== MAIN LOOP ======
local plrs = game.Players:GetChildren()
if #plrs == 1 then
    -- Start monitoring player input
    monitorPlayerInput()
    
    while true do
        local enemy, distance = findClosestAliveEnemy()
        
        if enemy then
            if distance > ATTACK_RANGE then
                local success = moveToTarget(enemy)
                if not success then
                    -- Wait a bit before trying again after failure
                    task.wait(1)
                end
            else
                updateDebugInfo({
                    status = "IN RANGE",
                    targetName = enemy.Name,
                    distance = distance,
                    pathStatus = "READY TO ATTACK"
                })
            end
        else
            updateDebugInfo({
                status = "SEARCHING",
                targetName = "NONE",
                distance = 0
            })
        end
        
        task.wait(REFRESH_RATE)
    end
end
