local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ====== CONFIGURATION ======
local ATTACK_RANGE = 30
local REFRESH_RATE = 1
local STUCK_THRESHOLD = 5
local MAX_WAYPOINT_TIME = 10
local RECALCULATE_ATTEMPTS = 3
local LONG_PATH_THRESHOLD = 100
local WAYPOINT_SKIP_DISTANCE = 5
local CONSECUTIVE_STUCK_LIMIT = 3
local STUCK_MOVE_THRESHOLD = 1.5
local INPUT_RESET_DELAY = 0.2
local POSITION_CHECK_INTERVAL = 0.5
local TELEPORT_DISTANCE_THRESHOLD = 50
local DEBUG_MODE = true

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

-- ====== CORE FUNCTIONS ======
local function updateDebugInfo(info)
    if not DEBUG_MODE then return end
    content.Text = string.format(
        "STATUS: %s\nTARGET: %s\nDISTANCE: %.1f/%.1f\nPATH: %s\nUPDATED: %s\n%s",
        info.status or "WAITING",
        info.targetName or "NONE",
        info.distance or 0,
        ATTACK_RANGE,
        info.pathStatus or "READY",
        os.date("%X"),
        info.extra or ""
    )
end

local function isEnemyAlive(enemy)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then return false end
    local enemyHumanoid = enemy:FindFirstChild("Humanoid")
    return enemyHumanoid and enemyHumanoid.Health > 0
end

local function findClosestAliveEnemy()
    local closestEnemy, closestDistance = nil, math.huge
    
    for _, folder in pairs(workspace.dungeon:GetDescendants()) do
        if folder.Name == "enemyFolder" then
            for _, enemy in pairs(folder:GetChildren()) do
                if isEnemyAlive(enemy) then
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
        distance = closestDistance
    })
    
    return closestEnemy, closestDistance
end

-- ====== MOVEMENT CONTROL ======
local activePath = nil
local lastValidPosition = character:GetPivot().Position

local function clearPlayerInput()
    humanoid:Move(Vector3.new(0, 0, 0))
    task.wait(INPUT_RESET_DELAY)
end

local function cancelCurrentPath()
    if activePath then
        pcall(function() activePath:Destroy() end)
        activePath = nil
    end
    humanoid:MoveTo(character:GetPivot().Position)
end

local function checkForTeleport()
    local currentPos = character:GetPivot().Position
    local distance = (currentPos - lastValidPosition).Magnitude
    lastValidPosition = currentPos
    return distance > TELEPORT_DISTANCE_THRESHOLD
end

-- ====== PATH EXECUTION ======
local function executeWaypoint(waypoint, target, pathIndex, totalWaypoints)
    clearPlayerInput()
    
    if waypoint.Action == Enum.PathWaypointAction.Jump then
        humanoid.Jump = true
    end
    
    humanoid:MoveTo(waypoint.Position)
    
    local startTime = os.clock()
    local lastPosition = character:GetPivot().Position
    local stuckTime = nil
    
    while not humanoid.MoveToFinished:Wait(0.1) do
        local currentTime = os.clock()
        local currentPos = character:GetPivot().Position
        
        -- Check for teleport
        if checkForTeleport() then
            updateDebugInfo({status = "TELEPORT DETECTED", extra = "Recalculating path..."})
            return false, "teleport"
        end
        
        -- Stuck detection
        if (currentPos - lastPosition).Magnitude < STUCK_MOVE_THRESHOLD then
            stuckTime = stuckTime or currentTime
            if currentTime - stuckTime > STUCK_THRESHOLD then
                updateDebugInfo({status = "STUCK", extra = "Attempting recovery..."})
                humanoid.Jump = true
                task.wait(0.2)
                humanoid:MoveTo(waypoint.Position)
                stuckTime = nil
            end
        else
            stuckTime = nil
            lastPosition = currentPos
        end
        
        -- Timeout check
        if currentTime - startTime > MAX_WAYPOINT_TIME then
            return false, "timeout"
        end
        
        -- Target validity check
        if not isEnemyAlive(target) then
            return false, "target_dead"
        end
    end
    
    return true
end

local function moveToTarget(target)
    local attempts = 0
    local success = false
    
    while attempts < RECALCULATE_ATTEMPTS and not success do
        cancelCurrentPath()
        
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 2
        })
        
        path:ComputeAsync(character:GetPivot().Position, target:GetPivot().Position)
        activePath = path
        
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            
            updateDebugInfo({
                status = "PATHFINDING",
                pathStatus = string.format("Waypoints: %d", #waypoints)
            })
            
            for i, waypoint in ipairs(waypoints) do
                local result, reason = executeWaypoint(waypoint, target, i, #waypoints)
                
                if not result then
                    if reason == "teleport" then
                        attempts = 0 -- Reset attempts on teleport
                        break
                    elseif reason == "target_dead" then
                        return false
                    end
                    break
                end
                
                -- Check if we reached attack range
                local distance = (character:GetPivot().Position - target:GetPivot().Position).Magnitude
                if distance <= ATTACK_RANGE then
                    updateDebugInfo({status = "IN RANGE"})
                    return true
                end
            end
        end
        
        attempts = attempts + 1
        task.wait(0.5)
    end
    
    return false
end

-- ====== INPUT HANDLING ======
local function handlePlayerInput()
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            cancelCurrentPath()
        end
    end)
end

-- ====== MAIN LOOP ======
local function main()
    handlePlayerInput()
    
    while true do
        local enemy, distance = findClosestAliveEnemy()
        
        if enemy and distance > ATTACK_RANGE then
            moveToTarget(enemy)
        elseif enemy then
            updateDebugInfo({status = "IN RANGE"})
        else
            updateDebugInfo({status = "SEARCHING"})
        end
        
        task.wait(REFRESH_RATE)
    end
end

-- Start execution
if #game.Players:GetPlayers() == 1 then
    main()
else
    updateDebugInfo({status = "MULTIPLAYER - DISABLED"})
end
