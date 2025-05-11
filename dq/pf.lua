local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ====== CONFIGURATION ======
local ATTACK_RANGE = 30 -- Stops moving when within this distance (studs)
local REFRESH_RATE = 1 -- How often to check for new targets (seconds)
local STUCK_THRESHOLD = 5 -- Time in seconds before considering stuck
local MAX_WAYPOINT_TIME = 10 -- Maximum time to spend on a single waypoint
local RECALCULATE_ATTEMPTS = 3 -- How many times to try recalculating path when stuck

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

-- ====== PATHFINDING FUNCTIONS ======
local function updateDebugInfo(info)
    content.Text = string.format(
        "STATUS: %s\n\nTARGET: %s\n\nDISTANCE: %.1f/%.1f\n\nPATH: %s\n\nUPDATED: %s",
        info.status or "WAITING",
        info.targetName or "NONE",
        info.distance or 0,
        ATTACK_RANGE,
        info.pathStatus or "READY",
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

local function moveToTarget(target, recalculateAttempts)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return false end
    recalculateAttempts = recalculateAttempts or 0
    
    local stopMoving = false
    local _, currentDistance = findClosestAliveEnemy()
    
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
        local lastWaypointPosition = nil
        local stuckStartTime = nil
        
        for i, waypoint in ipairs(waypoints) do
            if stopMoving then break end
            
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
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startTime = os.clock()
            local lastPosition = character:GetPivot().Position
            local stuckCheckInterval = 0.5 -- Check for stuck every 0.5 seconds
            local lastCheckTime = os.clock()
            
            while not humanoid.MoveToFinished:Wait(0.1) do
                local currentTime = os.clock()
                
                -- Check if character is stuck (not moving for STUCK_THRESHOLD seconds)
                if (currentTime - lastCheckTime) >= stuckCheckInterval then
                    lastCheckTime = currentTime
                    local currentPosition = character:GetPivot().Position
                    local distanceMoved = (currentPosition - lastPosition).Magnitude
                    
                    if distanceMoved < 1 then -- If moved less than 1 stud
                        if not stuckStartTime then
                            stuckStartTime = currentTime
                        elseif (currentTime - stuckStartTime) >= STUCK_THRESHOLD then
                            -- We're stuck, try to recover
                            updateDebugInfo({
                                status = "STUCK - RECOVERING",
                                targetName = target.Name,
                                distance = currentDistance,
                                pathStatus = string.format("JUMPING (%d/%d)", i, #waypoints)
                            })
                            
                            -- Try jumping to unstick
                            humanoid.Jump = true
                            wait(0.2)
                            humanoid:MoveTo(waypoint.Position)
                            
                            -- If still stuck after jumping, break and recalculate path
                            if (character:GetPivot().Position - lastPosition).Magnitude < 1 then
                                updateDebugInfo({
                                    status = "STUCK - RECALCULATING",
                                    targetName = target.Name,
                                    distance = currentDistance,
                                    pathStatus = string.format("PATH RECALCULATION (attempt %d/%d)", recalculateAttempts + 1, RECALCULATE_ATTEMPTS)
                                })
                                
                                if recalculateAttempts < RECALCULATE_ATTEMPTS then
                                    if deathCheckConnection then deathCheckConnection:Disconnect() end
                                    return moveToTarget(target, recalculateAttempts + 1)
                                else
                                    updateDebugInfo({
                                        status = "GIVING UP - TOO MANY ATTEMPTS",
                                        targetName = target.Name,
                                        distance = currentDistance,
                                        pathStatus = "FAILED"
                                    })
                                    if deathCheckConnection then deathCheckConnection:Disconnect() end
                                    return false
                                end
                            else
                                stuckStartTime = nil -- Reset if we moved
                            end
                        end
                    else
                        stuckStartTime = nil -- Reset if we moved
                        lastPosition = currentPosition
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

-- ====== MAIN LOOP ======
local plrs = game.Players:GetChildren()
if #plrs == 1 then
    while true do
        local enemy, distance = findClosestAliveEnemy()
        
        if enemy then
            if distance > ATTACK_RANGE then
                local success = moveToTarget(enemy)
                if not success then
                    -- Wait a bit before trying again after failure
                    wait(1)
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
        
        wait(REFRESH_RATE)
    end
end
