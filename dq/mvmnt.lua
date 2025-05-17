repeat wait(6) until game:IsLoaded()
wait(16)

-- Macro Recorder/Player with Config Saving, Auto-Restart on Respawn, and Auto-Close UI
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
    windowPosition = {x = 0.5, y = 0.5},
    autoCloseUI = false -- New config option
}

local function loadConfig()
    if isfile("MacroTesting/config.json") then
        local success, loaded = pcall(function()
            return HttpService:JSONDecode(readfile("MacroTesting/config.json"))
        end)
        if success then
            for k, v in pairs(loaded) do
                config[k] = v
            end
            config.manualPlayEnabled = config.manualPlayEnabled or false
            config.autoCloseUI = config.autoCloseUI or false -- Initialize if not present
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
MainFrame.Size = UDim2.new(0, 350, 0, 500) -- Increased height for new toggle
MainFrame.Position = UDim2.new(config.windowPosition.x, -175, config.windowPosition.y, -250) -- Adjusted position
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

-- Auto-Close UI Toggle
local AutoCloseFrame = Instance.new("Frame")
AutoCloseFrame.Size = UDim2.new(1, -20, 0, 40)
AutoCloseFrame.Position = UDim2.new(0, 10, 0, 435)
AutoCloseFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
AutoCloseFrame.BorderSizePixel = 0
AutoCloseFrame.Parent = MainFrame

local AutoCloseLabel = Instance.new("TextLabel")
AutoCloseLabel.Size = UDim2.new(0.7, 0, 1, 0)
AutoCloseLabel.Text = "Auto-Close UI When Playing:"
AutoCloseLabel.BackgroundTransparency = 1
AutoCloseLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AutoCloseLabel.Font = Enum.Font.Gotham
AutoCloseLabel.TextSize = 14
AutoCloseLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoCloseLabel.Parent = AutoCloseFrame

local AutoClosePadding = Instance.new("UIPadding")
AutoClosePadding.PaddingLeft = UDim.new(0, 10)
AutoClosePadding.Parent = AutoCloseLabel

local AutoCloseToggle = Instance.new("TextButton")
AutoCloseToggle.Size = UDim2.new(0.25, 0, 0.7, 0)
AutoCloseToggle.Position = UDim2.new(0.725, 0, 0.15, 0)
AutoCloseToggle.Text = config.autoCloseUI and "✅ ON" or "❌ OFF"
AutoCloseToggle.BackgroundColor3 = config.autoCloseUI and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
AutoCloseToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoCloseToggle.Font = Enum.Font.GothamBold
AutoCloseToggle.TextSize = 14
AutoCloseToggle.Parent = AutoCloseFrame

AutoCloseToggle.MouseButton1Click:Connect(function()
    config.autoCloseUI = not config.autoCloseUI
    AutoCloseToggle.Text = config.autoCloseUI and "✅ ON" or "❌ OFF"
    AutoCloseToggle.BackgroundColor3 = config.autoCloseUI and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
    saveConfig()
end)

-- Action Buttons
local RecordButton = Instance.new("TextButton")
RecordButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
RecordButton.Position = UDim2.new(0.025, 0, 0, 485)
RecordButton.Text = "⏺ RECORD"
RecordButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
RecordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RecordButton.Font = Enum.Font.GothamBold
RecordButton.TextSize = 16
RecordButton.Parent = MainFrame

local PlayButton = Instance.new("TextButton")
PlayButton.Size = UDim2.new(buttonWidth, 0, 0, 40)
PlayButton.Position = UDim2.new(buttonSpacing, 0, 0, 485)
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
local macroRestartPending = false
local lastPlaybackTime = 0
local respawnCount = 0
local MAX_RESPAWN_ATTEMPTS = 3

-- Function to toggle UI visibility
local function toggleUI(visible)
    if config.autoCloseUI and not visible then
        MainFrame.Visible = false
    else
        MainFrame.Visible = true
    end
end

-- Wait for character
if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end
humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

-- [Rest of the functions remain the same until the PlayButton connection]

PlayButton.MouseButton1Click:Connect(function()
    if isPlaying then
        if stopPlaying then
            stopPlaying()
        end
        toggleUI(true) -- Show UI when stopping playback
    else
        config.manualPlayEnabled = true
        saveConfig()
        PlayButton.Text = "✅ MANUAL PLAY"
        PlayButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        stopPlaying = startPlaying(true)
        if config.autoCloseUI then
            toggleUI(false) -- Hide UI when starting playback
        end
    end
end)

-- [Rest of the original script remains the same]

-- Add keybind to show/hide UI when auto-close is enabled
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    elseif input.KeyCode == Enum.KeyCode.F1 then
        -- Toggle UI visibility with F1 key
        if config.autoCloseUI then
            toggleUI(MainFrame.Visible == false)
        end
    end
end)

-- Initialize UI visibility
toggleUI(true)

-- Auto-start manual play if enabled in config
if config.manualPlayEnabled and selectedMacro then
    coroutine.wrap(function()
        wait(2) -- Give time for everything to initialize
        stopPlaying = startPlaying(true)
        if config.autoCloseUI then
            toggleUI(false)
        end
    end)()
end
