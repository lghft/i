local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Create GUI for key system
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KeySystemGUI"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 280)
frame.Position = UDim2.new(0.5, -200, 0.5, -140)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

-- Make frame draggable
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
})
gradient.Rotation = 45
gradient.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = ""
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.Parent = frame

-- Make title also draggable
title.Active = true
title.Draggable = true

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = title

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.8, 0, 0, 50)
infoLabel.Position = UDim2.new(0.1, 0, 0.25, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
infoLabel.Text = "Join our Discord to get the key!\nhttps://discord.gg/rhfRE2Pn"
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.Parent = frame
infoLabel.Visible = false

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0.8, 0, 0, 40)
inputBox.Position = UDim2.new(0.1, 0, 0.55, 0)
inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.PlaceholderText = "Enter key from Discord..."
inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 16
inputBox.Parent = frame
inputBox.Visible = false

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0.8, 0, 0, 40)
submitButton.Position = UDim2.new(0.1, 0, 0.75, 0)
submitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.Text = "SUBMIT KEY"
submitButton.Font = Enum.Font.GothamBold
submitButton.TextSize = 16
submitButton.Parent = frame
submitButton.Visible = false

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.8, 0, 0, 20)
statusLabel.Position = UDim2.new(0.1, 0, 0.65, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.Text = ""
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = frame

-- Correct key
local correctKey = "plsfeedback"

-- Copy Discord link to clipboard immediately
local function copyToClipboard(text)
    local clipBoard = setclipboard or toclipboard or set_clipboard
    if clipBoard then
        clipBoard(text)
        return true
    end
    return false
end

-- Copy Discord link on startup
copyToClipboard("https://discord.gg/rhfRE2Pn")

-- Cool typing animation
local function typeWriterEffect(textLabel, text, speed)
    textLabel.Text = ""
    for i = 1, #text do
        textLabel.Text = text:sub(1, i)
        task.wait(speed)
    end
end

-- Main animation sequence
local function startAnimation()
    -- Initial scale up animation
    frame.Size = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    
    local scaleTween = TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 280),
        BackgroundTransparency = 0
    })
    scaleTween:Play()
    
    scaleTween.Completed:Wait()
    
    -- Typewriter effect for title
    task.spawn(function()
        typeWriterEffect(title, "pidrila hub", 0.08)
        
        -- Pulse animation for title
        while true do
            local pulse1 = TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(255, 150, 50)
            })
            local pulse2 = TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            
            pulse1:Play()
            pulse1.Completed:Wait()
            pulse2:Play()
            pulse2.Completed:Wait()
        end
    end)
    
    -- Show other elements with delay
    task.wait(0.5)
    infoLabel.Visible = true
    local infoTween = TweenService:Create(infoLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        TextTransparency = 0
    })
    infoTween:Play()
    
    task.wait(0.3)
    inputBox.Visible = true
    local inputTween = TweenService:Create(inputBox, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0,
        TextTransparency = 0
    })
    inputTween:Play()
    
    task.wait(0.2)
    submitButton.Visible = true
    local buttonTween = TweenService:Create(submitButton, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        TextTransparency = 0
    })
    buttonTween:Play()
end

-- Main script function
local function startMainScript()
    local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
    local key = "pidrilahubtopchik"

    if workspace:FindFirstChild("Elevators") then
        local args = {
            [1] = "Multiplayer",
            [2] = "v2:start",
            [3] = {
                ["count"] = 1,
                ["mode"] = "halloween",
                ["key"] = key
            }
        }
        remoteFunction:InvokeServer(unpack(args))
    else
        remoteFunction:InvokeServer("Voting", "Skip")
        task.wait(1)
    end

    local guiPath = player:WaitForChild("PlayerGui")
        :WaitForChild("ReactUniversalHotbar")
        :WaitForChild("Frame")
        :WaitForChild("values")
        :WaitForChild("cash")
        :WaitForChild("amount")

    local function getCash()
        local rawText = guiPath.Text or ""
        local cleaned = rawText:gsub("[^%d%-]", "")
        return tonumber(cleaned) or 0
    end

    local function waitForCash(minAmount)
        while getCash() < minAmount do
            task.wait(1)
        end
    end

    local function safeInvoke(args, cost)
        waitForCash(cost)
        local success, err = pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(1)
    end

    local sequence = {
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(4.668, 2.349, -37.184) }, "Shotgunner" }, cost = 300 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(-1.643, 2.349, -36.870) }, "Shotgunner" }, cost = 300 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(4.487, 2.386, -34.154) }, "Shotgunner" }, cost = 300 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(-1.185, 2.386, -33.905) }, "Shotgunner" }, cost = 300 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(-0.616, 2.386, -30.504) }, "Shotgunner" }, cost = 300 },

        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(7.143, 2.350, -39.064) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(7.671, 2.386, -35.299) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(-4.269, 2.349, -38.972) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(4.907, 2.386, -31.026) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(7.948, 2.386, -30.539) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(0.052, 2.386, -27.333) }, "Trapper" }, cost = 500 },
        { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(3.450, 2.386, -25.265) }, "Trapper" }, cost = 500 },
    }

    for _, step in ipairs(sequence) do
        safeInvoke(step.args, step.cost)
    end

    local timerThread = task.delay(260, function()
        TeleportService:Teleport(3260590327)
    end)

    local towerFolder = workspace:WaitForChild("Towers")
    while true do
        local towers = towerFolder:GetChildren()
        for i, tower in ipairs(towers) do
            local args = {
                "Troops",
                "Upgrade",
                "Set",
                {
                    Troop = tower,
                    Path = 1
                }
            }
            pcall(function()
                remoteFunction:InvokeServer(unpack(args))
            end)
        end
        task.wait(1)
    end
end

-- Submit button handler
submitButton.MouseButton1Click:Connect(function()
    local enteredKey = inputBox.Text:gsub("%s+", ""):lower()
    
    if enteredKey == correctKey then
        statusLabel.Text = "Key verified! Starting script..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        -- Cool exit animation
        local exitTween = TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1
        })
        exitTween:Play()
        
        exitTween.Completed:Wait()
        screenGui:Destroy()
        startMainScript()
    else
        statusLabel.Text = "Invalid key! Join Discord to get correct key."
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        -- Shake animation for wrong key
        local shakeTween = TweenService:Create(inputBox, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true), {
            Position = UDim2.new(0.12, 0, 0.55, 0)
        })
        shakeTween:Play()
    end
end)

-- Enter key handler in textbox
inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitButton.MouseButton1Click:Fire()
    end
end)

-- Start the animation
startAnimation()
