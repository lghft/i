-- Macro Recorder/Player with Enhanced Gregg Detection
repeat wait(6) until game:IsLoaded()
wait(16)

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

-- State Variables
local isRecording = false
local isPlaying = false
local currentRecording = {}
local recordingStartTime = 0
local recordingConnection = nil
local selectedMacro = nil
local stopPlaying = nil
local greggDetected = false
local macroPaused = false
local pauseTime = 0
local lastMovementTime = tick()

-- Configuration
local config = {
    manualPlayEnabled = false,
    selectedMacro = nil,
    windowPosition = {x = 0, y = 0.5} -- Left side by default
}

-- Utility Functions
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function loadConfig()
    if isfile("MacroTesting/config.json") then
        local success, loaded = pcall(function()
            return HttpService:JSONDecode(readfile("MacroTesting/config.json"))
        end)
        if success then
            config = loaded
            config.manualPlayEnabled = config.manualPlayEnabled or false
            config.windowPosition = config.windowPosition or {x = 0, y = 0.5}
            config.windowPosition.x = 0 -- Force left side
        end
    end
end

local function saveConfig()
    config.windowPosition = config.windowPosition or {x = 0, y = 0.5}
    config.windowPosition.x = 0 -- Lock to left side
    writefile("MacroTesting/config.json", HttpService:JSONEncode(config))
end

-- Setup folders
if not isfolder("MacroTesting") then makefolder("MacroTesting") end
if not isfolder("MacroTesting/Macros") then makefolder("MacroTesting/Macros") end
loadConfig()

-- Prediction System
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
    if not Prediction.History[enemy] then Prediction.History[enemy] = {} end
    table.insert(Prediction.History[enemy], 1, enemy:GetPivot().Position)
    if #Prediction.History[enemy] > 10 then table.remove(Prediction.History[enemy]) end
end

-- Enemy Handling
local function isEnemyAlive(enemy)
    if not enemy:FindFirstChild("HumanoidRootPart") then return false end
    local enemyHumanoid = enemy:FindFirstChild("Humanoid")
    return not (enemyHumanoid and enemyHumanoid.Health <= 0)
end

local function findGregg()
    local dungeon = Workspace:FindFirstChild("dungeon")
    if not dungeon then return nil end
    
    for _, descendant in ipairs(dungeon:GetDescendants()) do
        if descendant.Name == "enemyFolder" then
            for _, enemy in ipairs(descendant:GetChildren()) do
                if enemy:IsA("Model") and enemy.Name == "Gregg" and isEnemyAlive(enemy) then
                    return enemy
                end
            end
        end
    end
    return nil
end

-- Movement Functions
local function SafeTeleport(position)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    character.HumanoidRootPart.CFrame = CFrame.new(position)
    return true
end

local function ComputePath(target)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 2
    })
    path:ComputeAsync(LocalPlayer.Character:GetPivot().Position, PredictPosition(target, Prediction.PREDICTION_FRAMES))
    return path
end

local function EnhancedMoveToGregg(gregg)
    if not gregg or not gregg:FindFirstChild("HumanoidRootPart") then return false end
    
    local path = ComputePath(gregg)
    if not path or path.Status ~= Enum.PathStatus.Success then return false end

    for _, waypoint in ipairs(path:GetWaypoints()) do
        if not isEnemyAlive(gregg) then return false end
        
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            SafeTeleport(waypoint.Position + Vector3.new(0, 5, 0))
        else
            SafeTeleport(waypoint.Position)
        end
        
        UpdatePredictionHistory(gregg)
        task.wait(0.1)
    end
    return true
end

-- Recording Functions
local function startRecording()
    print("Starting recording...")
    if isPlaying or isRecording then 
        warn("Cannot start recording - already playing or recording")
        return 
    end
    if not selectedMacro then 
        warn("No macro selected for recording")
        return 
    end
    
    currentRecording = {}
    isRecording = true
    recordingStartTime = tick()
    if RecordButton then
        RecordButton.Text = "⏹ STOP REC"
        RecordButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    end
    
    recordingConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            table.insert(currentRecording, {
                time = tick() - recordingStartTime,
                position = char.HumanoidRootPart.Position,
                moveDirection = char.Humanoid.MoveDirection
            })
        end
    end)
end

local function stopRecording()
    print("Stopping recording...")
    if not isRecording then
        warn("No active recording to stop")
        return
    end
    
    if recordingConnection then
        recordingConnection:Disconnect()
        recordingConnection = nil
    end
    
    isRecording = false
    if RecordButton then
        RecordButton.Text = "⏺ RECORD"
        RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    end
    
    if #currentRecording > 0 then
        local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
        writefile(fileName, HttpService:JSONEncode(currentRecording))
        refreshMacroList()
    end
end

-- Playback Functions
local function lerpVector3(a, b, alpha)
    return Vector3.new(
        a.X + (b.X - a.X) * alpha,
        a.Y + (b.Y - a.Y) * alpha,
        a.Z + (b.Z - a.Z) * alpha
    )
end

local function startPlaying(manualTrigger, resumeTime)
    if isPlaying or isRecording then return end
    if not selectedMacro then return end
    
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if not isfile(fileName) then return end
    
    if manualTrigger then
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
        
        if not timeLeftGui or not timeLeftGui.Enabled then
            if PlayButton then
                PlayButton.Text = "⏳ WAITING..."
                PlayButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            end
            
            local startWait = tick()
            repeat
                wait(0.1)
                timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
            until (timeLeftGui and timeLeftGui.Enabled) or (tick() - startWait > 10)
            
            if not timeLeftGui or not timeLeftGui.Enabled then
                if PlayButton then
                    PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
                    PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
                end
                return
            end
        end
    end
    
    local success, macroData = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    
    if not success or not macroData or #macroData == 0 then return end
    
    isPlaying = true
    local playbackStartTime = tick() - (resumeTime or 0)
    local playbackIndex = 1
    if PlayButton then
        PlayButton.Text = "⏹ STOP PLAY"
        PlayButton.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    end
    
    local connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            connection:Disconnect()
            return
        end
        
        local currentTime = tick() - playbackStartTime
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        while playbackIndex <= #macroData and macroData[playbackIndex].time <= currentTime do
            playbackIndex = playbackIndex + 1
        end
        
        if playbackIndex > #macroData then
            isPlaying = false
            if PlayButton then
                PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
                PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
            end
            return
        end
        
        if playbackIndex > 1 then
            local prevFrame = macroData[playbackIndex - 1]
            local nextFrame = macroData[playbackIndex]
            local alpha = (currentTime - prevFrame.time) / (nextFrame.time - prevFrame.time)
            local position = lerpVector3(
                Vector3.new(prevFrame.position.X, prevFrame.position.Y, prevFrame.position.Z),  -- Fixed line 444
                Vector3.new(nextFrame.position.X, nextFrame.position.Y, nextFrame.position.Z),  -- Fixed line 444
                alpha
            )
            char.HumanoidRootPart.CFrame = CFrame.new(position)
            
            local moveDir = lerpVector3(
                Vector3.new(prevFrame.moveDirection.X, prevFrame.moveDirection.Y, prevFrame.moveDirection.Z),  -- Fixed line 444
                Vector3.new(nextFrame.moveDirection.X, nextFrame.moveDirection.Y, nextFrame.moveDirection.Z),  -- Fixed line 444
                alpha
            )
            char.Humanoid:Move(moveDir)
        end
    end)
    
    stopPlaying = function()
        isPlaying = false
        connection:Disconnect()
        if PlayButton then
            PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
            PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
        end
    end
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroGui"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(0, 10, config.windowPosition.y or 0.5, -225)
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "MACRO RECORDER (Drag Here)"
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Macro List Container
local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -20, 0, 250)
ListContainer.Position = UDim2.new(0, 10, 0, 50)
ListContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ListContainer.BorderSizePixel = 0
ListContainer.Parent = MainFrame

-- [Rest of your GUI creation code remains the same...]

-- Initialize PlayButton safely
local function initPlayButton()
    if not PlayButton then return end
    local manualEnabled = config.manualPlayEnabled or false
    PlayButton.Text = manualEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
    PlayButton.BackgroundColor3 = manualEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
end

-- [Rest of your script remains the same...]

-- Initialize
if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

-- Movement tracking
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if humanoid.MoveDirection.Magnitude > 0.1 then
        lastMovementTime = tick()
    end
end)

-- Start systems
refreshMacroList()
initPlayButton()  -- Initialize PlayButton after creation

-- Auto-start if enabled
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2)
        stopPlaying = startPlaying(true)
    end)()
end

print("Macro Recorder initialized successfully")
