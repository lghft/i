repeat wait(6) until game:IsLoaded()
wait(2)
-- Macro Recorder/Player with Config Saving
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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
    windowPosition = {x = 0.5, y = 0.5}
}

local function loadConfig()
    if isfile("MacroTesting/config.json") then
        local success, loaded = pcall(function()
            return HttpService:JSONDecode(readfile("MacroTesting/config.json"))
        end)
        if success then
            config = loaded
            config.manualPlayEnabled = config.manualPlayEnabled or false
        end
    end
end

local function saveConfig()
    writefile("MacroTesting/config.json", HttpService:JSONEncode(config))
end

loadConfig()

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroGui"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 450)
MainFrame.Position = UDim2.new(config.windowPosition.x, -175, config.windowPosition.y, -225)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Make the window draggable
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    MainFrame.Position = newPos
    config.windowPosition = {x = newPos.X.Scale, y = newPos.Y.Scale}
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

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, 0, 0, 25)
ListTitle.Position = UDim2.new(0, 0, 0, 0)
ListTitle.Text = "SAVED MACROS"
ListTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ListTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
ListTitle.Font = Enum.Font.Gotham
ListTitle.TextSize = 14
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Parent = ListContainer

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 10)
TitlePadding.Parent = ListTitle

local MacroList = Instance.new("ScrollingFrame")
MacroList.Size = UDim2.new(1, 0, 1, -25)
MacroList.Position = UDim2.new(0, 0, 0, 25)
MacroList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MacroList.BorderSizePixel = 0
MacroList.ScrollBarThickness = 6
MacroList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
MacroList.CanvasSize = UDim2.new(0, 0, 0, 0)
MacroList.AutomaticCanvasSize = Enum.AutomaticSize.Y
MacroList.Parent = ListContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = MacroList

-- Control Buttons
local buttonYOffset = 310
local buttonWidth = 0.45
local buttonSpacing = 0.525

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(buttonWidth, 0, 0, 35)
RefreshButton.Position = UDim2.new(0.025, 0, 0, buttonYOffset)
RefreshButton.Text = "🔄 REFRESH"
RefreshButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.TextSize = 14
RefreshButton.Parent = MainFrame

local DeleteButton = Instance.new("TextButton")
DeleteButton.Size = UDim2.new(buttonWidth, 0, 0, 35)
DeleteButton.Position = UDim2.new(buttonSpacing, 0, 0, buttonYOffset)
DeleteButton.Text = "❌ DELETE"
DeleteButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteButton.Font = Enum.Font.GothamBold
DeleteButton.TextSize = 14
DeleteButton.Parent = MainFrame

-- New Macro Creation
local NewMacroFrame = Instance.new("Frame")
NewMacroFrame.Size = UDim2.new(1, -20, 0, 70)
NewMacroFrame.Position = UDim2.new(0, 10, 0, 355)
NewMacroFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
NewMacroFrame.BorderSizePixel = 0
NewMacroFrame.Parent = MainFrame

local MacroNameBox = Instance.new("TextBox")
MacroNameBox.Size = UDim2.new(0.65, 0, 0, 35)
MacroNameBox.Position = UDim2.new(0, 5, 0, 5)
MacroNameBox.PlaceholderText = "Enter Macro Name..."
MacroNameBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MacroNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MacroNameBox.Font = Enum.Font.Gotham
MacroNameBox.TextSize = 14
MacroNameBox.Parent = NewMacroFrame

local CreateButton = Instance.new("TextButton")
CreateButton.Size = UDim2.new(0.3, 0, 0, 35)
CreateButton.Position = UDim2.new(0.675, 0, 0, 5)
CreateButton.Text = "➕ CREATE"
CreateButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CreateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CreateButton.Font = Enum.Font.GothamBold
CreateButton.TextSize = 14
CreateButton.Parent = NewMacroFrame

-- Action Buttons
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
RecordButton.Position = UDim2.new(0.025, 0, 0, 400)
RecordButton.Text = "⏺ RECORD"
RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.Font = Enum.Font.GothamBold
RecordButton.TextSize = 16
RecordButton.Parent = MainFrame

local PlayButton = Instance.new("TextButton")
PlayButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
PlayButton.Position = UDim2.new(buttonSpacing, 0, 0, 400)
PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
PlayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayButton.Font = Enum.Font.GothamBold
PlayButton.TextSize = 16
PlayButton.Parent = MainFrame

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

-- Wait for character
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

-- Functions
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

local function refreshMacroList()
    for _, child in ipairs(MacroList:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local success, files = pcall(function()
        local allFiles = listfiles("MacroTesting/Macros")
        local macroFiles = {}
        
        for _, filePath in ipairs(allFiles) do
            local fileName = filePath:match(".+[\\/](.+)%.json$") or filePath:match(".+[\\/](.+)$")
            if fileName then
                table.insert(macroFiles, fileName)
            end
        end
        
        return macroFiles
    end)
    
    if not success then
        warn("Failed to list macro files: "..tostring(files))
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 30)
        label.Text = "Error loading macros"
        label.TextColor3 = Color3.fromRGB(255, 100, 100)
        label.BackgroundTransparency = 1
        label.Parent = MacroList
        return
    end
    
    if #files == 0 then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 30)
        label.Text = "No macros found"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.BackgroundTransparency = 1
        label.Parent = MacroList
    else
        table.sort(files, function(a, b)
            return a:lower() < b:lower()
        end)
        
        for _, fileName in ipairs(files) do
            local button = createMacroButton(fileName)
            if fileName == config.selectedMacro then
                button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                selectedMacro = fileName
            end
        end
    end
end

local function startRecording()
    if isPlaying or isRecording then return end
    
    if not selectedMacro then
        warn("Please select a macro first")
        return
    end
    
    if #Players:GetPlayers() > 1 then
        warn("Cannot record with other players in game")
        return
    end
    
    isRecording = true
    currentRecording = {}
    recordingStartTime = tick()
    RecordButton.Text = "⏹ STOP REC"
    RecordButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick() - recordingStartTime
        local currentPosition = LocalPlayer.Character.HumanoidRootPart.Position
        local moveDirection = LocalPlayer.Character.Humanoid.MoveDirection
        
        table.insert(currentRecording, {
            time = currentTime,
            position = {
                x = currentPosition.X,
                y = currentPosition.Y,
                z = currentPosition.Z
            },
            moveDirection = {
                x = moveDirection.X,
                y = moveDirection.Y,
                z = moveDirection.Z
            }
        })
    end)
    
    return function()
        connection:Disconnect()
        isRecording = false
        RecordButton.Text = "⏺ RECORD"
        RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        
        local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
        writefile(fileName, HttpService:JSONEncode(currentRecording))
        refreshMacroList()
    end
end

local function startPlaying(manualTrigger)
    if isPlaying or isRecording then return end
    
    if not selectedMacro then
        warn("Please select a macro first")
        return
    end
    
    if #Players:GetPlayers() > 1 then
        warn("Cannot play with other players in game")
        return
    end
    
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if not isfile(fileName) then
        warn("Macro file not found")
        return
    end
    
    -- For manual play, wait for timeLeftGui to be enabled
    if manualTrigger then
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
        
        if not timeLeftGui or not timeLeftGui.Enabled then
            PlayButton.Text = "⏳ WAITING..."
            PlayButton.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            
            local startWait = tick()
            repeat
                wait(0.1)
                timeLeftGui = playerGui:FindFirstChild("timeLeftGui")
            until timeLeftGui and timeLeftGui.Enabled or (tick() - startWait) > 10
            
            if not timeLeftGui or not timeLeftGui.Enabled then
                PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
                PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
                warn("Timed out waiting for timeLeftGui")
                return
            end
        end
    end
    
    local success, macroData = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)
    
    if not success or not macroData or #macroData == 0 then
        warn("Failed to load macro data or empty macro")
        return
    end
    
    isPlaying = true
    playbackStartTime = tick()
    playbackIndex = 1
    PlayButton.Text = "⏹ STOP PLAY"
    PlayButton.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    
    local character = LocalPlayer.Character
    if not character then
        warn("No character found")
        isPlaying = false
        PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
        PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
        return
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("No HumanoidRootPart found")
        isPlaying = false
        PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
        PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
        return
    end
    
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        if not isPlaying then
            connection:Disconnect()
            return
        end
        
        local currentTime = tick() - playbackStartTime
        
        while playbackIndex <= #macroData and macroData[playbackIndex].time <= currentTime do
            playbackIndex = playbackIndex + 1
        end
        
        if playbackIndex > #macroData then
            isPlaying = false
            connection:Disconnect()
            PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
            PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
            return
        end
        
        local prevFrame = macroData[playbackIndex - 1]
        local nextFrame = macroData[playbackIndex]
        
        if prevFrame and nextFrame then
            local alpha = (currentTime - prevFrame.time) / (nextFrame.time - prevFrame.time)
            
            humanoidRootPart.CFrame = CFrame.new(
                Vector3.new(
                    prevFrame.position.x + (nextFrame.position.x - prevFrame.position.x) * alpha,
                    prevFrame.position.y + (nextFrame.position.y - prevFrame.position.y) * alpha,
                    prevFrame.position.z + (nextFrame.position.z - prevFrame.position.z) * alpha
                )
            )
            
            local moveDir = Vector3.new(
                prevFrame.moveDirection.x + (nextFrame.moveDirection.x - prevFrame.moveDirection.x) * alpha,
                prevFrame.moveDirection.y + (nextFrame.moveDirection.y - prevFrame.moveDirection.y) * alpha,
                prevFrame.moveDirection.z + (nextFrame.moveDirection.z - prevFrame.moveDirection.z) * alpha
            )
            
            humanoid:Move(moveDir, false)
        end
    end)
    
    return function()
        isPlaying = false
        if connection then
            connection:Disconnect()
        end
        PlayButton.Text = config.manualPlayEnabled and "✅ MANUAL PLAY" or "▶ MANUAL PLAY"
        PlayButton.BackgroundColor3 = config.manualPlayEnabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(60, 60, 60)
    end
end

-- Connect buttons
RefreshButton.MouseButton1Click:Connect(function()
    refreshMacroList()
end)

DeleteButton.MouseButton1Click:Connect(function()
    if not selectedMacro then return end
    
    local fileName = "MacroTesting/Macros/"..selectedMacro..".json"
    if isfile(fileName) then
        delfile(fileName)
        selectedMacro = nil
        config.selectedMacro = nil
        saveConfig()
        refreshMacroList()
    end
end)

CreateButton.MouseButton1Click:Connect(function()
    local macroName = MacroNameBox.Text
    if macroName == "" then return end
    
    macroName = macroName:gsub("[^%w%s_-]", ""):gsub("%s+", " ")
    macroName = trim(macroName)
    if macroName == "" then return end
    
    local fileName = "MacroTesting/Macros/"..macroName..".json"
    if not isfile(fileName) then
        writefile(fileName, "[]")
        selectedMacro = macroName
        config.selectedMacro = macroName
        MacroNameBox.Text = ""
        saveConfig()
        refreshMacroList()
    else
        warn("Macro with this name already exists")
    end
end)

RecordButton.MouseButton1Click:Connect(function()
    if isRecording then
        if stopRecording then
            stopRecording()
        end
    else
        stopRecording = startRecording()
    end
end)

PlayButton.MouseButton1Click:Connect(function()
    if isPlaying then
        if stopPlaying then
            stopPlaying()
        end
    else
        config.manualPlayEnabled = true
        saveConfig()
        PlayButton.Text = "✅ MANUAL PLAY"
        PlayButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        stopPlaying = startPlaying(true)
    end
end)

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
    
    if isPlaying then
        if stopPlaying then
            stopPlaying()
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
