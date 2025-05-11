local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ====== CONFIGURATION ======
local ATTACK_RANGE = 30
local REFRESH_RATE = 1
local STUCK_CHECK_INTERVAL = 60
local STUCK_DISTANCE_THRESHOLD = 5
local GRID_SIZE = 5 -- Size of grid cells for Q-learning (studs)
local DEBUG_MODE = true -- Toggle visual debugging

-- ====== MACHINE LEARNING SETUP ======
local QLearning = {
    QTable = {}, -- Format: ["x,y,z->x,y,z"] = reward
    LearningRate = 0.1,
    DiscountFactor = 0.9,
    ExplorationRate = 0.3,
    MaxReward = 1,
    MinReward = -1
}

-- Convert position to grid key
function QLearning:GetStateKey(position)
    local x = math.floor(position.X / GRID_SIZE) * GRID_SIZE
    local y = math.floor(position.Y / GRID_SIZE) * GRID_SIZE
    local z = math.floor(position.Z / GRID_SIZE) * GRID_SIZE
    return string.format("%d,%d,%d", x, y, z)
end

-- Get best action from Q-table
function QLearning:GetBestAction(currentState, possibleActions)
    local bestAction = possibleActions[1]
    local bestReward = -math.huge

    for _, action in ipairs(possibleActions) do
        local actionKey = self:GetStateKey(action.Position)
        local qKey = currentState .. "->" .. actionKey
        local reward = self.QTable[qKey] or 0

        if reward > bestReward then
            bestReward = reward
            bestAction = action
        end
    end

    return bestAction
end

-- Update Q-values based on experience
function QLearning:UpdateQValue(oldState, action, newState, reward)
    local qKey = oldState .. "->" .. action
    local maxFutureReward = -math.huge

    -- Find best future reward
    for key, val in pairs(self.QTable) do
        if key:find("^" .. newState .. "->") and val > maxFutureReward then
            maxFutureReward = val
        end
    end

    -- Q-learning formula
    local currentQ = self.QTable[qKey] or 0
    local newQ = currentQ + self.LearningRate * 
        (reward + self.DiscountFactor * (maxFutureReward or 0) - currentQ)
    
    -- Clamp rewards
    self.QTable[qKey] = math.clamp(newQ, self.MinReward, self.MaxReward)
end

-- ====== DEBUG VISUALIZATION ======
local debugParts = {}
local debugGui = Instance.new("ScreenGui")
debugGui.Name = "QLearningDebug"
debugGui.Parent = player.PlayerGui

local function clearDebugVisuals()
    for _, part in pairs(debugParts) do
        part:Destroy()
    end
    debugParts = {}
end

local function createDebugLabel(position, text, color)
    local part = Instance.new("Part")
    part.Size = Vector3.new(GRID_SIZE, 0.1, GRID_SIZE)
    part.Position = position + Vector3.new(0, 2, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Color = color
    part.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(4, 0, 2, 0)
    billboard.StudsOffset = Vector3.new(0, 1, 0)
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Text = text
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = billboard

    table.insert(debugParts, part)
    return part
end

local function visualizeQTable()
    clearDebugVisuals()
    
    local characterPos = character:GetPivot().Position
    local charKey = QLearning:GetStateKey(characterPos)
    
    for qKey, reward in pairs(QLearning.QTable) do
        if qKey:find("^" .. charKey .. "->") then
            local _, endPosStr = qKey:match("(.+)%->(.+)")
            local x, y, z = endPosStr:match("([^,]+),([^,]+),([^,]+)")
            local position = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
            
            local color = if reward > 0 
                then Color3.new(0, reward, 0) 
                else Color3.new(-reward, 0, 0)
            
            createDebugLabel(
                position,
                string.format("%.2f", reward),
                color
            )
        end
    end
end

-- Toggle debug with F3
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F3 then
        DEBUG_MODE = not DEBUG_MODE
        if not DEBUG_MODE then
            clearDebugVisuals()
        else
            visualizeQTable()
        end
    end
end)

-- ====== ENHANCED PATHFINDING ======
local function moveToTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })

    path:ComputeAsync(character:GetPivot().Position, target:GetPivot().Position)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local currentState = QLearning:GetStateKey(character:GetPivot().Position)

        for i = 1, #waypoints do
            -- Choose action (explore or exploit)
            local chosenWaypoint
            if math.random() < QLearning.ExplorationRate then
                chosenWaypoint = waypoints[math.random(math.max(1, i-2), math.min(#waypoints, i+2))]
            else
                chosenWaypoint = QLearning:GetBestAction(currentState, {waypoints[i]})
            end

            -- Move to waypoint
            humanoid:MoveTo(chosenWaypoint.Position)
            local success = humanoid.MoveToFinished:Wait(5)

            -- Update Q-learning
            local newState = QLearning:GetStateKey(character:GetPivot().Position)
            local reward = success and 0.1 or -0.5 -- Small positive reward for progress, larger penalty for failure
            QLearning:UpdateQValue(currentState, QLearning:GetStateKey(chosenWaypoint.Position), newState, reward)

            currentState = newState
            
            if DEBUG_MODE then
                visualizeQTable()
            end

            -- Check if reached target
            if (target:GetPivot().Position - character:GetPivot().Position).Magnitude <= ATTACK_RANGE then
                QLearning:UpdateQValue(currentState, QLearning:GetStateKey(target:GetPivot().Position), currentState, 1)
                break
            end
        end
    end
end

-- ====== MAIN LOOP ======
while true do
    local target = findClosestAliveEnemy() -- Your existing target finding function
    
    if target then
        moveToTarget(target)
    end
    
    task.wait(REFRESH_RATE)
end
