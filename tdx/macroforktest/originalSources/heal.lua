local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Tìm Prompt gốc
local promptPart = workspace:FindFirstChild("Game")
if promptPart then promptPart = promptPart:FindFirstChild("Map") end
if promptPart then promptPart = promptPart:FindFirstChild("ProximityPrompts") end
if promptPart then promptPart = promptPart:FindFirstChild("Prompt") end
if not promptPart then
	warn("Không tìm thấy Part chứa Prompt.")
	return
end

local prompt = promptPart:FindFirstChildWhichIsA("ProximityPrompt")
if not prompt then
	warn("Không tìm thấy ProximityPrompt.")
	return
end

-- Cấu hình Prompt
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 999999
prompt.HoldDuration = 999999
prompt.Enabled = true

-- 🧱 Tạo Part cực kỳ nhỏ và vô hình, không ảnh hưởng gì
local ghostPart = Instance.new("Part")
ghostPart.Name = "PromptCamPart"
ghostPart.Size = Vector3.new(0.0001, 0.0001, 0.0001)
ghostPart.Transparency = 1
ghostPart.Anchored = true
ghostPart.CanCollide = false
ghostPart.CanQuery = false
ghostPart.CanTouch = false
ghostPart.Parent = workspace

-- Gắn Prompt gốc vào Part này
prompt.Parent = ghostPart

-- 🔁 Cập nhật Part để luôn đứng trước camera
RunService.RenderStepped:Connect(function()
	if camera and ghostPart then
		local camCF = camera.CFrame
		ghostPart.CFrame = camCF * CFrame.new(0, 0, -3) -- trước camera 3 studs
	end
end)

-- 🔁 Giữ Prompt liên tục
task.spawn(function()
	while true do
		if prompt and prompt.Enabled then
			pcall(function()
				prompt:InputHoldBegin()
			end)
		end
		task.wait(0.5)
	end
end)

-- 🧹 Xoá GUI nếu có
local function xoaGuiPrompt()
	local existed = playerGui:FindFirstChild("ProximityPrompts")
	if existed then existed:Destroy() end
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "ProximityPrompts" then
			task.wait()
			child:Destroy()
		end
	end)
end

xoaGuiPrompt()
