local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local scriptEnabled = true

local enemyModule
pcall(function()
    enemyModule = require(LocalPlayer.PlayerScripts.Client.GameClass.EnemyClass)
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.DisplayOrder = 2147483647
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local black = Instance.new("Frame")
black.Size = UDim2.fromScale(1,1)
black.BackgroundColor3 = Color3.new(0,0,0)
black.BorderSizePixel = 0
black.Parent = gui

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Size = UDim2.new(1,-20,0,30)
header.Position = UDim2.new(0,10,0,10)
header.TextColor3 = Color3.new(1,1,1)
header.Font = Enum.Font.SourceSansBold
header.TextSize = 24
header.TextXAlignment = Enum.TextXAlignment.Left
header.Text = "Enemies"
header.Parent = gui

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.Size = UDim2.new(1,-20,1,-50)
list.Position = UDim2.new(0,10,0,40)
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.Parent = gui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

-- label pool
local pool = {}
local active = {}

local function getLabel()

    local label = table.remove(pool)

    if not label then
        label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 22
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.RichText = true
        label.AutomaticSize = Enum.AutomaticSize.X
        label.Size = UDim2.new(0,0,0,22)
        label.Parent = list
    end

    label.Visible = true
    table.insert(active,label)

    return label
end

local function releaseLabels()

    for _,l in ipairs(active) do
        l.Visible = false
        table.insert(pool,l)
    end

    table.clear(active)

end

local function percent(v)
    if v < 0 then v = 0 end
    return math.floor(v*100+0.5).."%"
end

local SHIELD = "rgb(0,170,255)"

local UPDATE_RATE = 0.1
local timer = 0

RunService.Heartbeat:Connect(function(dt)

    if not scriptEnabled then return end

    timer += dt
    if timer < UPDATE_RATE then return end
    timer = 0

    if not enemyModule or not enemyModule.GetEnemies then return end

    releaseLabels()

    local groups = {}

    for _,enemy in pairs(enemyModule.GetEnemies()) do

        if enemy and enemy.IsAlive and not enemy.IsFakeEnemy then

            local hh = enemy.HealthHandler
            if not hh then continue end

            local max = hh:GetMaxHealth()
            if not max or max <= 0 then continue end

            local hp = hh:GetHealth() or 0
            local shield = hh.GetShield and hh:GetShield() or 0

            local name = enemy.DisplayName or "Unknown"

            groups[name] = groups[name] or {count=0,data={}}

            table.insert(groups[name].data,{
                hp = percent((hp+shield)/max),
                shield = shield > 0
            })

            groups[name].count += 1

        end

    end

    -- sắp xếp tên enemy để GUI không nhảy vị trí
    local names = {}
    for name in pairs(groups) do
        table.insert(names,name)
    end

    table.sort(names)

    for _,name in ipairs(names) do

        local data = groups[name]

        local label = getLabel()

        local buffer = {}

        for i,v in ipairs(data.data) do
            if v.shield then
                buffer[i] = '<font color="'..SHIELD..'">'..v.hp.."</font>"
            else
                buffer[i] = v.hp
            end
        end

        label.Text = name.." (x"..data.count.."): "..table.concat(buffer,", ")

    end

    list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)

end)

-- toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,80,0,28)
toggle.Position = UDim2.new(1,-90,0,10)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Text = "ON"
toggle.BackgroundColor3 = Color3.fromRGB(0,170,80)
toggle.Parent = gui

toggle.MouseButton1Click:Connect(function()

    scriptEnabled = not scriptEnabled

    if scriptEnabled then

        toggle.Text = "ON"
        toggle.BackgroundColor3 = Color3.fromRGB(0,170,80)

        RunService:Set3dRenderingEnabled(false)

        black.Visible = true
        list.Visible = true
        header.Visible = true

    else

        toggle.Text = "OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(180,40,40)

        RunService:Set3dRenderingEnabled(true)

        black.Visible = false
        list.Visible = false
        header.Visible = false

    end

end)
