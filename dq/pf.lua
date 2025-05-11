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
local POSITION_CHECK_INTERVAL = 0.5 -- How often to verify position
local TELEPORT_DISTANCE_THRESHOLD = 50 -- Distance to consider as teleport

-- ====== TELEPORT DETECTION ======
local lastValidPosition = character:GetPivot().Position
local function checkForTeleport()
    while true do
        local currentPosition = character:GetPivot().Position
        local distanceMoved = (currentPosition - lastValidPosition).Magnitude
        
        if distanceMoved > TELEPORT_DISTANCE_THRESHOLD then
            -- Character was likely teleported
            return true
        end
        
        lastValidPosition = currentPosition
        wait(POSITION_CHECK_INTERVAL)
    end
end

-- ====== MOVEMENT CONTROL ======
local activePath = nil
local function cancelCurrentPath()
    if activePath then
        activePath.Cancel()
        activePath = nil
    end
    humanoid:MoveTo(character:GetPivot().Position) -- Stop movement
end

-- ====== PATH EXECUTION ======
local function executePathToTarget(target)
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
        
        for i, waypoint in ipairs(waypoints) do
            -- Check for teleportation
            if checkForTeleport() then
                cancelCurrentPath()
                return false, "teleported"
            end
            
            humanoid:MoveTo(waypoint.Position)
            
            local startTime = os.clock()
            while not humanoid.MoveToFinished:Wait(0.1) do
                if os.clock() - startTime > MAX_WAYPOINT_TIME then
                    cancelCurrentPath()
                    return false, "timeout"
                end
                
                -- Continuous position validation
                if checkForTeleport() then
                    cancelCurrentPath()
                    return false, "teleported"
                end
            end
        end
        return true
    end
    return false
end

-- ====== MAIN PATHFINDING FUNCTION ======
local function moveToTarget(target)
    local attempts = 0
    local lastPosition = character:GetPivot().Position
    
    while attempts < RECALCULATE_ATTEMPTS do
        local success, reason = executePathToTarget(target)
        
        if success then
            return true
        elseif reason == "teleported" then
            -- Immediate recalculation from new position
            attempts = 0
        else
            attempts = attempts + 1
        end
        
        -- Verify target is still valid
        if not isEnemyAlive(target) then
            return false
        end
        
        wait(0.5) -- Brief pause between attempts
    end
    return false
end

-- ====== MAIN LOOP ======
local function mainLoop()
    while true do
        local enemy = findClosestAliveEnemy()
        if enemy then
            local distance = (character:GetPivot().Position - enemy:GetPivot().Position).Magnitude
            if distance > ATTACK_RANGE then
                moveToTarget(enemy)
            end
        end
        wait(REFRESH_RATE)
    end
end

-- Initialize
spawn(mainLoop)
spawn(checkForTeleport)
