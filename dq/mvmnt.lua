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
            config.windowPosition.x = 0 -- Force left side
        end
    end
end

local function saveConfig()
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
        SafeTeleport(waypoint.Position + (waypoint.Action == Enum.PathWaypointAction.Jump and Vector3.new(0,5,0) or Vector3.zero))
        UpdatePredictionHistory(gregg)
        task.wait(0.025)
    end
    return true
end

-- Gregg Handling
local function handleGregg()
    local gregg = findGregg()
    if gregg and isPlaying and not greggDetected then
        greggDetected = true
        macroPaused = true
        pauseTime = tick() - playbackStartTime
        
        if stopPlaying then stopPlaying() end
        
        if EnhancedMoveToGregg(gregg) then
            local greggDefeated = false
            greggConnection = gregg.Humanoid.Died:Connect(function() greggDefeated = true end)
            
            while not greggDefeated and isEnemyAlive(gregg) do
                UpdatePredictionHistory(gregg)
                SafeTeleport(PredictPosition(gregg, Prediction.PREDICTION_FRAMES))
                wait(0.5)
            end
            
            if greggConnection then greggConnection:Disconnect() end
        end
        
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
MainFrame.Position = UDim2.new(0, 10, config.windowPosition.y, -225)
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- [Rest of GUI elements...]
-- Note: Include all your GUI elements here following the same pattern as before

-- Macro Functions
local function createMacroButton(macroName)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 35)
    button.Text = macroName
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = MacroList
    
    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.PaddingLeft = UDim.new(0, 15)
    buttonPadding.Parent = button
    
    button.MouseButton1Click:Connect(function()
        if selectedMacro == macroName then
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            selectedMacro = nil
            config.selectedMacro = nil
            saveConfig()
            return
        end
        
        for _, otherButton in ipairs(MacroList:GetChildren()) do
            if otherButton:IsA("TextButton") then
                otherButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end
        
        button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        selectedMacro = macroName
        config.selectedMacro = macroName
        saveConfig()
    end)
    
    return button
end

-- [Include all other functions like refreshMacroList, startRecording, startPlaying here]

-- Idle Detection System
local lastMovementTime = tick()
local idleThreshold = 60 -- 1 minute

local function checkIdle()
    while true do
        wait(5)
        if not isPlaying and config.manualPlayEnabled and selectedMacro then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                if humanoid.MoveDirection.Magnitude < 0.1 then
                    if tick() - lastMovementTime > idleThreshold then
                        print("Player idle - restarting macro")
                        if stopPlaying then stopPlaying() end
                        stopPlaying = startPlaying(true)
                    end
                else
                    lastMovementTime = tick()
                end
            end
        end
    end
end

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
coroutine.wrap(checkIdle)()
refreshMacroList()

-- Auto-start if enabled
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2)
        stopPlaying = startPlaying(true)
    end)()
end
