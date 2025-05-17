-- Macro Recorder/Player with Enhanced Gregg Detection
repeat wait(6) until game:IsLoaded()
wait(16)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

-- Custom trim function
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Create main folders if they don't exist
if not isfolder("MacroTesting") then
    makefolder("MacroTesting")
end

if not isfolder("MacroTesting/Macros") then
    makefolder("MacroTesting/Macros")
end

-- Load or create config
local config = {
    manualPlayEnabled = false,
    selectedMacro = nil,
    windowPosition = {x = 0, y = 0.5} -- Left side by default
}

local function loadConfig()
    if isfile("MacroTesting/config.json") then
        local success, loaded = pcall(function()
            return HttpService:JSONDecode(readfile("MacroTesting/config.json"))
        end)
        if success then
            config = loaded
            config.manualPlayEnabled = config.manualPlayEnabled or false
            -- Ensure window stays on left side
            config.windowPosition.x = 0
        end
    end
end

local function saveConfig()
    -- Force window to stay on left side when saving
    config.windowPosition.x = 0
    writefile("MacroTesting/config.json", HttpService:JSONEncode(config))
end

loadConfig()

-- Enemy Prediction System
local Prediction = {
    History = {},
    SampleRate = 0.1,
    PREDICTION_FRAMES = 10
}

local function PredictPosition(enemy, frames)
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

local function UpdatePredictionHistory(enemy)
    if not Prediction.History[enemy] then
        Prediction.History[enemy] = {}
    end
    table.insert(Prediction.History[enemy], 1, enemy:GetPivot().Position)
    if #Prediction.History[enemy] > 10 then
        table.remove(Prediction.History[enemy])
    end
end

-- Enhanced Gregg Detection
local function isEnemyAlive(enemy)
    if not enemy:FindFirstChild("HumanoidRootPart") then return false end
    local enemyHumanoid = enemy:FindFirstChild("Humanoid")
    if enemyHumanoid and enemyHumanoid.Health <= 0 then return false end
    return true
end

local function findGregg()
    -- Search through all enemy folders in the dungeon
    for _, folder in pairs(Workspace:GetDescendants()) do
        if folder.Name == "enemyFolder" then
            for _, enemy in pairs(folder:GetChildren()) do
                if enemy:IsA("Model") and enemy.Name == "Gregg" and isEnemyAlive(enemy) then
                    return enemy
                end
            end
        end
    end
    return nil
end

local function SafeTeleport(position)
    local character = LocalPlayer.Character
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
    
    local targetPos = PredictPosition(target, Prediction.PREDICTION_FRAMES)
    path:ComputeAsync(LocalPlayer.Character:GetPivot().Position, targetPos)
    
    return path
end

local function EnhancedMoveToGregg(gregg)
    if not gregg or not gregg:FindFirstChild("HumanoidRootPart") then return false end
    
    local path = ComputePath(gregg)
    if not path or path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()
    
    for _, waypoint in ipairs(waypoints) do
        if not isEnemyAlive(gregg) then
            return false -- Gregg died while we were moving
        end
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            SafeTeleport(waypoint.Position + Vector3.new(0, 5, 0))
        else
            SafeTeleport(waypoint.Position)
        end
        
        UpdatePredictionHistory(gregg)
        task.wait(0.025)
    end
    
    return true
end

-- Enhanced Gregg Handling
local function handleGregg()
    local gregg = findGregg()
    if gregg and isPlaying and not greggDetected then
        -- Pause the macro
        greggDetected = true
        macroPaused = true
        pauseTime = tick() - playbackStartTime
        
        if stopPlaying then
            stopPlaying()
        end
        
        -- Enhanced movement to Gregg with pathfinding
        local success = EnhancedMoveToGregg(gregg)
        
        if success then
            -- Wait until Gregg is defeated
            local greggDefeated = false
            greggConnection = gregg.Humanoid.Died:Connect(function()
                greggDefeated = true
            end)
            
            -- Check every second if Gregg is defeated
            while not greggDefeated and isEnemyAlive(gregg) do
                -- Update our position to follow Gregg if he moves
                UpdatePredictionHistory(gregg)
                local targetPos = PredictPosition(gregg, Prediction.PREDICTION_FRAMES)
                SafeTeleport(targetPos)
                wait(0.5)
            end
            
            -- Clean up
            if greggConnection then
                greggConnection:Disconnect()
                greggConnection = nil
            end
        end
        
        -- Resume macro
        greggDetected = false
        macroPaused = false
        if config.manualPlayEnabled then
            stopPlaying = startPlaying(true, pauseTime)
        end
    end
end

-- GUI Setup (Left Side)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroGui"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0, 10, 0.5, -225) -- Left side position
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Make the window draggable vertically only
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    -- Only update Y position
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    MainFrame.Position = newPos
    config.windowPosition = {x = 0, y = newPos.Y.Scale} -- Keep X at 0 (left side)
    saveConfig()
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Rest of the GUI elements remain the same...

-- Variables
local isRecording = false
local isPlaying = false
local selectedMacro = nil
local currentRecording = {}
local recordingStartTime = 0
local playbackStartTime = 0
local playbackIndex = 1
local humanoid = nil
local stopRecording = nil
local stopPlaying = nil
local greggDetected = false
local macroPaused = false
local pauseTime = 0
local greggConnection = nil
local greggCheckInterval = 1 -- Check for Gregg every second
local lastGreggCheck = 0
local lastMovementTime = tick() -- Track last movement time
local idleThreshold = 60 -- 1 minute idle threshold

-- Idle detection function
local function checkIdle()
    while true do
        wait(5) -- Check every 5 seconds
        
        if not isPlaying and config.manualPlayEnabled and selectedMacro then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character:FindFirstChild("Humanoid")
                -- Check if player is standing still (no movement input)
                if humanoid.MoveDirection.Magnitude < 0.1 then
                    -- If idle for more than threshold, restart macro
                    if tick() - lastMovementTime > idleThreshold then
                        print("Player idle for over 1 minute - restarting macro")
                        if stopPlaying then stopPlaying() end
                        stopPlaying = startPlaying(true)
                    end
                else
                    -- Player moved, update last movement time
                    lastMovementTime = tick()
                end
            end
        end
    end
end

-- Start idle detection
coroutine.wrap(checkIdle)()

-- Wait for character
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

-- Update last movement time when player moves
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if humanoid.MoveDirection.Magnitude > 0.1 then
        lastMovementTime = tick()
    end
end)

-- Rest of your existing functions (createMacroButton, refreshMacroList, startRecording, startPlaying, etc.) go here...
-- ... [Previous code remains the same until the end] ...

-- Initial setup
refreshMacroList()

-- Cleanup on script termination
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    end
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(character)
    humanoid = character:WaitForChild("Humanoid")
    -- Update movement tracking for new character
    humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        if humanoid.MoveDirection.Magnitude > 0.1 then
            lastMovementTime = tick()
        end
    end)
    
    if isPlaying then
        if stopPlaying then
            stopPlaying()
        end
        wait(1)
        if config.manualPlayEnabled and not isPlaying and not isRecording then
            stopPlaying = startPlaying(true)
        end
    end
end)

-- Auto-start manual play if enabled in config
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2) -- Give time for everything to initialize
        stopPlaying = startPlaying(true)
    end)()
end
