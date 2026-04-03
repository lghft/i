local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Kiểm tra Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    return
end

local Remote = Remotes:FindFirstChild("SoloToggleSpeedControl")
if not Remote then
    return
end

-- Hàm kiểm tra UI elements
local function getUIElements()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

    local interface = playerGui:FindFirstChild("Interface")
    if not interface then return nil end

    local speedChangeScreen = interface:FindFirstChild("SpeedChangeScreen")
    if not speedChangeScreen then return nil end

    local owned = speedChangeScreen:FindFirstChild("Owned")
    if not owned then return nil end

    local active = owned:FindFirstChild("Active")
    local default = owned:FindFirstChild("Default")
    
    return {
        active = active,
        default = default,
        owned = owned
    }
end

-- Hàm kiểm tra xem có bị disable không
local function isSpeedControlDisabled()
    local ui = getUIElements()
    if not ui or not ui.default then return true end

    -- Kiểm tra button Speed trong Default
    local speedButton = ui.default:FindFirstChild("Speed")
    if speedButton then
        local activateButton = speedButton:FindFirstChild("Activate")
        if activateButton and not activateButton.Interactable then
            return true
        end
    end

    -- Kiểm tra button Slow trong Default
    local slowButton = ui.default:FindFirstChild("Slow")
    if slowButton then
        local activateButton = slowButton:FindFirstChild("Activate")
        if activateButton and not activateButton.Interactable then
            return true
        end
    end

    -- Kiểm tra các điều kiện game state khác
    if workspace:GetAttribute("IsTutorial") then
        return true
    end

    if workspace:GetAttribute("SpeedBoostLocked") then
        return true
    end

    return false
end

-- Biến kiểm soát
local isWaiting = false
local monitoring = true
local lastCheckTime = 0

-- Chế độ giám sát thông minh
RunService.Heartbeat:Connect(function()
    if not monitoring then return end
    
    local currentTime = tick()
    if currentTime - lastCheckTime < 0.5 then return end -- Chỉ kiểm tra mỗi 0.5 giây
    lastCheckTime = currentTime

    local ui = getUIElements()
    if not ui or not ui.active then
        task.wait(5)
        return
    end

    -- Kiểm tra nếu Speed Control bị tắt và không bị disable
    if not ui.active.Visible and not isWaiting and not isSpeedControlDisabled() then
        isWaiting = true

        -- Đợi 3 giây trước khi kích hoạt
        task.wait(3)

        -- Kiểm tra lại một lần nữa trước khi gửi remote
        if not isSpeedControlDisabled() then
            -- Gửi remote
            if Remote:IsA("RemoteEvent") then
                Remote:FireServer(true, true)
            elseif Remote:IsA("RemoteFunction") then
                Remote:InvokeServer(true, true)
            end

            -- Chờ xác nhận
            task.wait(0.5)
        end

        isWaiting = false
    end
end)

-- Hàm dừng monitoring (có thể gọi từ bên ngoài)
_G.StopSpeedMonitoring = function()
    monitoring = false
end

-- Hàm khởi động lại monitoring
_G.StartSpeedMonitoring = function()
    monitoring = true
end
