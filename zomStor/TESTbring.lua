-- ReGui-based GUI for controlling the zombie bring loop (converted from Rayfield)
-- Original behavior preserved with toggles, buttons, dropdowns, and color controls

-- Load Dear ReGui
local ok, ReGuiOrErr = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua'))()
end)

if not ok then
    warn('[ReGui] Failed to load ReGui:', ReGuiOrErr)
    return
end

local ReGui = ReGuiOrErr

-- Services used across features
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

spawn(function()
    local GC = getconnections or get_signal_cons
	if GC then
		for i,v in pairs(GC(game.Players.LocalPlayer.Idled)) do
			if v["Disable"] then
				v["Disable"](v)
			elseif v["Disconnect"] then
				v["Disconnect"](v)
			end
		end
	else
		local VirtualUser = cloneref(game:GetService("VirtualUser"))
		game.Players.LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- Kill any previous "timer" updater if it exists (cleanup from older versions)
if getgenv().StatsConn then
    pcall(function() getgenv().StatsConn:Disconnect() end)
    getgenv().StatsConn = nil
end

-- Globals to control loop state
getgenv().Mob = getgenv().Mob == true -- preserve previous state if set
getgenv().MobThread = getgenv().MobThread -- preserve thread ref if any
getgenv().Mob2 = getgenv().Mob2 == true
getgenv().MobThread2 = getgenv().MobThread2

-- Elf teleport globals (moved from Main to Teleports and reworked to teleport under Elf)
getgenv().Elf = getgenv().Elf == true
getgenv().ElfThread = getgenv().ElfThread
getgenv().ElfTeleportReturnCFrame = getgenv().ElfTeleportReturnCFrame

-- Tracers globals
getgenv().ZombieTracersEnabled = getgenv().ZombieTracersEnabled == true
getgenv().ZombieTracersColor = getgenv().ZombieTracersColor or Color3.fromRGB(0, 255, 0)
getgenv().ZombieTracerConn = getgenv().ZombieTracerConn
getgenv().ZombieTracerLines = getgenv().ZombieTracerLines or {} -- [Model] = DrawingLine

-- Chams globals (Highlight-based ESP)
getgenv().ZombieChamsEnabled = getgenv().ZombieChamsEnabled == true
getgenv().ZombieChamsColor = getgenv().ZombieChamsColor or Color3.fromRGB(255, 0, 255) -- fill color
getgenv().ZombieChamsOutlineColor = getgenv().ZombieChamsOutlineColor or Color3.fromRGB(255, 255, 255)
getgenv().ZombieChamsConn = getgenv().ZombieChamsConn
getgenv().ZombieChamsMap = getgenv().ZombieChamsMap or {} -- [Model] = Highlight

-- Aimbot globals
getgenv().AimbotEnabled = getgenv().AimbotEnabled == true
getgenv().AimbotTargetPart = getgenv().AimbotTargetPart or "Head" -- "Head" or "HumanoidRootPart"
getgenv().AimbotFOVRadius = typeof(getgenv().AimbotFOVRadius) == "number" and getgenv().AimbotFOVRadius or 150
getgenv().AimbotConn = getgenv().AimbotConn

-- Legacy FOV circle refs (kept for compatibility; no longer used)
getgenv().AimbotFOVCircle = getgenv().AimbotFOVCircle -- Fill circle (Drawing) - deprecated
getgenv().AimbotFOVStroke = getgenv().AimbotFOVStroke -- Outline circle (Drawing) - deprecated

-- New dashed FOV ring globals
getgenv().AimbotFOVSegments = getgenv().AimbotFOVSegments or {} -- array of Drawing Lines
getgenv().AimbotFOVSegmentCount = typeof(getgenv().AimbotFOVSegmentCount) == "number" and getgenv().AimbotFOVSegmentCount or 72
getgenv().AimbotFOVDashRatio = typeof(getgenv().AimbotFOVDashRatio) == "number" and getgenv().AimbotFOVDashRatio or 0.55 -- 0..1

-- Ore globals
getgenv().TeleportEnabled = getgenv().TeleportEnabled == true
getgenv().TeleportType = getgenv().TeleportType or "Coal" -- "Coal", "Iron", or "Ring"
getgenv().TeleportThread = getgenv().TeleportThread
getgenv().TeleportReturnCFrame = getgenv().TeleportReturnCFrame

getgenv().LeversState = getgenv().LeversState or {
    items = {},      -- display items for Combo
    map = {},        -- label -> Instance (Model or BasePart)
    selected = nil,  -- selected label
}

-- Player tab globals (WalkSpeed & JumpPower loops)
getgenv().WSLoopEnabled = getgenv().WSLoopEnabled == true
getgenv().WSLoopEnabled = true
getgenv().WSLoopThread = getgenv().WSLoopThread
getgenv().WSpeedValue = typeof(getgenv().WSpeedValue) == "number" and getgenv().WSpeedValue or 50

getgenv().JPLoopEnabled = getgenv().JPLoopEnabled == true
getgenv().JPLoopThread = getgenv().JPLoopThread
getgenv().JPowerValue = typeof(getgenv().JPowerValue) == "number" and getgenv().JPowerValue or 50

getgenv().Floating = getgenv().Floating == true
getgenv().Clip = getgenv().Clip == false
-- Forward declare Window
local Window

function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

function NOFLY()
	FLYING = false
	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
	if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end


function randomString()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function getZombiesFolder()
    return game.Workspace:FindFirstChild("Zombies")
end

local function getHRP(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChild("HumanoidRootPart")
end

function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end
-- Helpers for Train and Ring references
local function getTrainModel()
    local etc = workspace:FindFirstChild("ETC")
    if not etc then return nil end
    local trainFinal = etc:FindFirstChild("TrainFinal")
    if not trainFinal then return nil end
    local train = trainFinal:FindFirstChild("Train")
    if not train or not train:IsA("Model") then return nil end
    return train
end

local function getAnyBasePart(model)
    if not model or not model:IsA("Model") then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

local function getTrainPosition()
    local train = getTrainModel()
    if not train then return nil end
    local part = getAnyBasePart(train)
    if not part then return nil end
    return part.Position
end

local function isElfNearTrain(elfHrp, threshold)
    if not elfHrp or not elfHrp.Position then return false end
    local trainPos = getTrainPosition()
    if not trainPos then return false end
    local dist = (elfHrp.Position - trainPos).Magnitude
    return dist <= (threshold or 10)
end

cloneref = missing("function", cloneref, function(...) return ... end)
IYMouse = cloneref(Players.LocalPlayer:GetMouse())

local lastDeath

function onDied()
	task.spawn(function()
		if pcall(function() Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') end) and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
			Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Died:Connect(function()
				if getRoot(Players.LocalPlayer.Character) then
					lastDeath = getRoot(Players.LocalPlayer.Character).CFrame
				end
			end)
		else
			wait(2)
			onDied()
		end
	end)
end

Clip = true
spDelay = 0.1
Players.LocalPlayer.CharacterAdded:Connect(function()
	NOFLY()
	getgenv().Floating = false

	if not getgenv().Clip then
		stopNoclip()
	end

	repeat wait() until getRoot(Players.LocalPlayer.Character)

	pcall(function()
		if spawnpoint and not refreshCmd and spawnpos ~= nil then
			wait(spDelay)
			getRoot(Players.LocalPlayer.Character).CFrame = spawnpos
		end
	end)

	onDied()
end)
onDied()
getgenv().Floating = false
floatName = randomString()
local function startFloatLoop()
    getgenv().Floating = true
    if getgenv().Floating then
        local pchar = game.Players.LocalPlayer.Character
        if pchar and not pchar:FindFirstChild(floatName) then
            task.spawn(function()
                local Float = Instance.new('Part')
                Float.Name = floatName
                Float.Parent = pchar
                Float.Transparency = 1
                Float.Size = Vector3.new(2, 0.2, 1.5)
                Float.Anchored = true
                Float.CanCollide = true -- important: make sure the platform can collide
                local FloatValue = -3.1
                Float.CFrame = getRoot(pchar).CFrame * CFrame.new(0, FloatValue, 0)

                qUp = IYMouse.KeyUp:Connect(function(KEY)
                    if KEY == 'q' then
                        FloatValue = FloatValue + 0.5
                    end
                end)
                eUp = IYMouse.KeyUp:Connect(function(KEY)
                    if KEY == 'e' then
                        FloatValue = FloatValue - 1.5
                    end
                end)
                qDown = IYMouse.KeyDown:Connect(function(KEY)
                    if KEY == 'q' then
                        FloatValue = FloatValue - 0.5
                    end
                end)
                eDown = IYMouse.KeyDown:Connect(function(KEY)
                    if KEY == 'e' then
                        FloatValue = FloatValue + 1.5
                    end
                end)

                -- safer: guard for missing humanoid
                local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
                if hum then
                    floatDied = hum.Died:Connect(function()
                        if FloatingFunc then FloatingFunc:Disconnect() end
                        if Float then Float:Destroy() end
                        if qUp then qUp:Disconnect() end
                        if eUp then eUp:Disconnect() end
                        if qDown then qDown:Disconnect() end
                        if eDown then eDown:Disconnect() end
                        if floatDied then floatDied:Disconnect() end
                    end)
                end

                local function FloatPadLoop()
                    local root = getRoot(pchar)
                    if pchar:FindFirstChild(floatName) and root then
                        -- update BEFORE physics so collisions will register
                        Float.CFrame = root.CFrame * CFrame.new(0, FloatValue, 0)
                    else
                        if FloatingFunc then FloatingFunc:Disconnect() end
                        if Float then Float:Destroy() end
                        if qUp then qUp:Disconnect() end
                        if eUp then eUp:Disconnect() end
                        if qDown then qDown:Disconnect() end
                        if eDown then eDown:Disconnect() end
                        if floatDied then floatDied:Disconnect() end
                    end
                end

                -- use Stepped instead of Heartbeat so physics sees the platform every step
                FloatingFunc = RunService.Stepped:Connect(FloatPadLoop)
            end)
        end
    end
end

local function stopFloatLoop()
    getgenv().Floating = false
	local pchar = game.Players.LocalPlayer.Character
	--notify('Float','Float Disabled')
	if pchar:FindFirstChild(floatName) then
		pchar:FindFirstChild(floatName):Destroy()
	end
	if floatDied then
		FloatingFunc:Disconnect()
		qUp:Disconnect()
		eUp:Disconnect()
		qDown:Disconnect()
		eDown:Disconnect()
		floatDied:Disconnect()
	end
end

local Noclipping = nil
local function startNoclip()
    getgenv().Clip = false
    task.wait(0.1)

    -- which parts to keep collidable when Floating is enabled
    local KEEP_COLLIDABLE = {
        HumanoidRootPart = true,
        Torso = true,
        UpperTorso = true,
        LowerTorso = true,
        -- you can also include feet/legs if needed:
        LeftFoot = true, RightFoot = true,
        LeftLowerLeg = true, RightLowerLeg = true,
        LeftUpperLeg = true, RightUpperLeg = true
    }

    local function NoclipLoop()
        if getgenv().Clip == false then
            local char = game.Players.LocalPlayer.Character
            if not char then return end

            for _, child in pairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    if child.Name == floatName then
                        -- never touch the float pad; it must remain collidable
                        -- child.CanCollide = true -- not strictly necessary here; ensured at creation
                    else
                        if getgenv().Floating and KEEP_COLLIDABLE[child.Name] then
                            child.CanCollide = true
                        else
                            child.CanCollide = false
                        end
                    end
                end
            end
        end
    end

    if Noclipping then
        Noclipping:Disconnect()
    end
    Noclipping = RunService.Stepped:Connect(NoclipLoop)
end

local function getRingCFrame()
    local ignore = workspace:FindFirstChild("Ignore") or workspace:FindFirstChild("ignore")
    if not ignore then return nil end
    local ring = ignore:FindFirstChild("Ring")
    if not ring then return nil end
    -- ring is expected to be a BasePart (CFrame exists)
    local okCF, cf = pcall(function() return ring.CFrame end)
    if okCF and typeof(cf) == "CFrame" then
        return cf
    end
    return nil
end

-- Helper: pick a reasonable BasePart to teleport to from a resource Model
local function getMainTeleportPart(model)
    if not model or not model:IsA("Model") then return nil end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end
    -- Common naming patterns
    local candidates = {"MainPart", "Main", "Core", "Part", "Base"}
    for _, name in ipairs(candidates) do
        local p = model:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            return p
        end
    end
    -- Fallback: first BasePart found
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            return d
        end
    end
    return nil
end

-- Elf Teleport: collects elf targets (HRP parts) - safer nil checks
local function collectElfTargets()
    local results = {}
    local ignore = workspace:FindFirstChild("Ignore")
    if not ignore then
        return results
    end

    for _, v in ipairs(ignore:GetChildren()) do
        if v and v:IsA("Model") and v.Name == "Elf" then
            local hrp = getHRP(v)
            if hrp then
                table.insert(results, hrp)
            end
        end
    end
    return results
end

local function runMobLoop()
    if getgenv().MobThread and coroutine.status(getgenv().MobThread) ~= "dead" then
        return
    end

    getgenv().MobThread = task.spawn(function()
        local LocalPlayer = Players.LocalPlayer

        while getgenv().Mob do
            getgenv().Mob = true
            task.wait()
            local zFolder = getZombiesFolder()
            if not zFolder then continue end

            for _, v in pairs(zFolder:GetChildren()) do
                if v and v:IsA("Model") then
                    if v.Name == "Nick" or v.Name == "Adam" or v.Name == "Bezerker" or v.Name == "Trickster" or v.Name == "SlasherGeneral" then
                        local hrp = getHRP(v)
                        local lpChar = LocalPlayer and LocalPlayer.Character
                        local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                        if hrp and lpHRP then
                            hrp.Anchored = false
                            hrp.CFrame = lpHRP.CFrame * CFrame.new(1.5, 1, -4)
                        end
                    end
                    if v.Name == "TaintedMastermind" then
                        local hrp = getHRP(v)
                        local lpChar = LocalPlayer and LocalPlayer.Character
                        local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                        if hrp and lpHRP then
                            hrp.Anchored = true
                            hrp.CFrame = lpHRP.CFrame * CFrame.new(1.5, 1, -10)
                        end
                    end
                end
            end
        end
    end)
end

--[[

werebeast?, Crazed One, Mad Clown

]]

local function runMobLoop2()
    if getgenv().MobThread2 and coroutine.status(getgenv().MobThread2) ~= "dead" then
        return
    end

    getgenv().MobThread2 = task.spawn(function()
        local LocalPlayer = Players.LocalPlayer

        while getgenv().Mob2 do
            getgenv().Mob2 = true
            task.wait()
            local zFolder = getZombiesFolder()
            if not zFolder then continue end

            for _, v in pairs(zFolder:GetChildren()) do
                if v:IsA("Model") then
                    if v.Name == "TaintedMastermind" then
                    else
                        local hrp = getHRP(v)
                        local lpChar = LocalPlayer and LocalPlayer.Character
                        local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
                        if hrp and lpHRP then
                            hrp.Anchored = false
                            hrp.CFrame = lpHRP.CFrame * CFrame.new(1.5, 1, -4)
                        end
                    end
                end
            end
        end
    end)
end

local function startElfTeleportLoop()
    if getgenv().ElfThread and coroutine.status(getgenv().ElfThread) ~= "dead" then
        return
    end

    -- Remember current position for elf teleport feature
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        getgenv().ElfTeleportReturnCFrame = hrp.CFrame
    else
        getgenv().ElfTeleportReturnCFrame = nil
    end

    getgenv().ElfThread = task.spawn(function()
        local hadElvesPreviously = false

        -- helper to return to saved position with respawn fallback
        local function returnToSavedPositionOnce()
            local saved = getgenv().ElfTeleportReturnCFrame
            if not saved then return end

            local lp2 = Players.LocalPlayer
            local char2 = lp2 and lp2.Character
            local myHrp = char2 and char2:FindFirstChild("HumanoidRootPart")
            if myHrp then
                myHrp.CFrame = saved
            else
                pcall(function()
                    lp2.CharacterAdded:Wait()
                end)
                task.wait(0.1)
                char2 = lp2.Character
                myHrp = char2 and char2:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    myHrp.CFrame = saved
                end
            end
        end

        while getgenv().Elf do
            local targets = collectElfTargets()

            if #targets == 0 then
                -- No elves found; if we previously had elves, return to saved position once
                if hadElvesPreviously then
                    returnToSavedPositionOnce()
                    hadElvesPreviously = false
                end
                task.wait()
            else
                hadTargetsPreviously = true -- Note: preserving original code behavior
                for _, elfHrp in ipairs(targets) do
                    if not getgenv().Elf then break end

                    -- If the elf is near the train (<=10 studs), return and disable
                    if isElfNearTrain(elfHrp, 10) then
                        returnToSavedPositionOnce()
                        getgenv().Elf = false
                        -- Exit the loop immediately
                        break
                    end

                    local lp2 = Players.LocalPlayer
                    local char2 = lp2 and lp2.Character
                    local myHrp = char2 and char2:FindFirstChild("HumanoidRootPart")
                    if myHrp and elfHrp and elfHrp.Parent then
                        -- Teleport under the elf's HRP
                        myHrp.CFrame = elfHrp.CFrame * CFrame.new(1, -6, 1)
                    end
                    task.wait()
                end
            end
        end
    end)
end

-- Missing earlier: stopElfTeleportLoop used by Panic Stop and the Elf Teleport toggle
local function stopElfTeleportLoop(teleportBack)
    -- Stop the running thread if any
    if getgenv().ElfThread then
        pcall(function()
            task.cancel(getgenv().ElfThread)
        end)
        getgenv().ElfThread = nil
    end

    -- Optionally return to the saved position
    if teleportBack and getgenv().ElfTeleportReturnCFrame then
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetCF = getgenv().ElfTeleportReturnCFrame

        if hrp then
            hrp.CFrame = targetCF
        else
            pcall(function()
                lp.CharacterAdded:Wait()
            end)
            task.wait(0.1)
            char = lp.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = targetCF
            end
        end
    end

    getgenv().ElfTeleportReturnCFrame = nil
    getgenv().Elf = false
end

-- Resource collection: scans typical containers for Models named Coal/Iron and returns their main BaseParts
local function collectResourceTargets(resource)
    local results = {}
    resource = tostring(resource or "Coal")

    local containers = {
        workspace,
        workspace:FindFirstChild("Ignore"),
        workspace:FindFirstChild("ignore"),
        workspace:FindFirstChild("Ores"),
        workspace:FindFirstChild("Ore"),
    }

    local seen = {}
    for _, container in ipairs(containers) do
        if container then
            for _, inst in ipairs(container:GetDescendants()) do
                if inst:IsA("Model") and inst.Name == resource then
                    local main = getMainTeleportPart(inst)
                    if main and main:IsA("BasePart") and main.Parent and not seen[main] then
                        table.insert(results, main)
                        seen[main] = true
                    end
                end
            end
        end
    end

    return results
end

-- NEW: Collect resource Models by name (Coal/Iron) in common containers
local function collectResourceModels(resource)
    local results = {}
    resource = tostring(resource or "Coal")

    local containers = {
        workspace,
        workspace:FindFirstChild("Ignore"),
        workspace:FindFirstChild("ignore"),
        workspace:FindFirstChild("Ores"),
        workspace:FindFirstChild("Ore"),
    }

    for _, container in ipairs(containers) do
        if container then
            for _, inst in ipairs(container:GetDescendants()) do
                if inst:IsA("Model") and inst.Name == resource and inst.Parent then
                    table.insert(results, inst)
                end
            end
        end
    end

    return results
end

-- NEW: Ensure only one Coal and one Iron exist; keep nearest to player and delete the rest
local function enforceSingleOreInstances()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    for _, resource in ipairs({ "Coal", "Iron" }) do
        local models = collectResourceModels(resource)

        if #models > 1 then
            local keepModel = models[1]

            if hrp then
                local bestDist = math.huge
                for _, m in ipairs(models) do
                    local main = getMainTeleportPart(m)
                    if main and main.Position then
                        local d = (hrp.Position - main.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            keepModel = m
                        end
                    end
                end
            end

            -- Delete extras
            for _, m in ipairs(models) do
                if m ~= keepModel and m.Parent then
                    pcall(function()
                        m:Destroy()
                    end)
                end
            end
        end
    end
end

local function resolveLeversFolder()
    local ws = workspace
    local map = ws:FindFirstChild("Map")
    if not map then return nil end
    local lds = map:FindFirstChild("LeverDoorSystem")
    if not lds then return nil end
    local levers = lds:FindFirstChild("Levers")
    return levers
end

-- Build list of teleportable entries under Levers
local function collectLeversObjects()
    local st = getgenv().LeversState
    st.items = {}
    st.map = {}

    local folder = resolveLeversFolder()
    if not folder then
        return st.items
    end

    for _, inst in ipairs(folder:GetChildren()) do
        if inst and inst.Parent then
            if inst:IsA("Model") or inst:IsA("BasePart") then
                local label = tostring(inst.Name)
                -- Deduplicate labels if needed
                local base = label
                local c = 1
                while st.map[label] ~= nil do
                    c += 1
                    label = string.format("%s[%d]", base, c)
                end
                st.map[label] = inst
                table.insert(st.items, label)
            end
        end
    end

    table.sort(st.items)
    return st.items
end

-- Teleport chosen entry in front of player
local function teleportLeversObjectInFront(label)
    local st = getgenv().LeversState
    local inst = st and st.map and st.map[label]
    if not inst then return false end
    if not inst.Parent then return false end

    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetCF = hrp.CFrame * CFrame.new(1, 1, -4)

    local ok = pcall(function()
        if inst:IsA("Model") then
            inst:PivotTo(targetCF)
        else
            -- BasePart
            inst.CFrame = targetCF
        end
    end)

    return ok
end


-- Add near the top (after Services) or alongside helpers
local function drawingAvailable()
    local ok = pcall(function()
        return Drawing and typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
    end)
    return ok and Drawing and typeof(Drawing.new) == "function"
end
local function forceCheckboxOff(control)
    if not control then return end
    -- Try common APIs to programmatically uncheck
    pcall(function() if control.Set then control:Set(false) end end)
    pcall(function() if control.SetValue then control:SetValue(false) end end)
    pcall(function() if control.SetChecked then control:SetChecked(false) end end)
    pcall(function() if control.Update then control:Update({ Value = false }) end end)
    -- Fallback: try setting property if library allows mutation
    pcall(function() control.Value = false end)
end

--Loops/Functions--
local function startOreTeleportLoop()
    if getgenv().TeleportThread and coroutine.status(getgenv().TeleportThread) ~= "dead" then
        return
    end

    -- Remember current position
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        getgenv().TeleportReturnCFrame = hrp.CFrame
    else
        getgenv().TeleportReturnCFrame = nil
    end

    getgenv().TeleportThread = task.spawn(function()
        local function returnToSavedPositionOnce()
            local saved = getgenv().TeleportReturnCFrame
            if not saved then return end

            local lp2 = Players.LocalPlayer
            local char2 = lp2 and lp2.Character
            local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
            if hrp2 then
                hrp2.CFrame = saved * CFrame.new(1, 4, 1)
            else
                pcall(function()
                    lp2.CharacterAdded:Wait()
                end)
                task.wait(0.1)
                char2 = lp2.Character
                hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                if hrp2 then
                    hrp2.CFrame = saved * CFrame.new(1, 4, 1)
                end
            end
        end

        local hadTargetsPreviously = false
        local lastEnforce = 0

        while getgenv().TeleportEnabled do
            -- Periodically ensure only 1 Coal and 1 Iron exist
            local now = os.clock()
            if now - lastEnforce > 1.0 then
                pcall(enforceSingleOreInstances)
                lastEnforce = now
            end

            local resource = getgenv().TeleportType or "Coal"

            -- Special-case: Ring (workspace.Ignore.Ring.CFrame)
            if resource == "Ring" then
                local ringCF = getRingCFrame()
                if ringCF then
                    hadTargetsPreviously = true
                    local lp2 = Players.LocalPlayer
                    local char2 = lp2 and lp2.Character
                    local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        hrp2.CFrame = ringCF * CFrame.new(1, -5, 1)
                    end
                else
                    if hadTargetsPreviously then
                        returnToSavedPositionOnce()
                        hadTargetsPreviously = false
                    end
                end
                task.wait()
            else
                local targets = collectResourceTargets(resource)

                if #targets == 0 then
                    if hadTargetsPreviously then
                        returnToSavedPositionOnce()
                        hadTargetsPreviously = false
                    end
                    task.wait()
                else
                    hadTargetsPreviously = true
                    for _, main in ipairs(targets) do
                        if not getgenv().TeleportEnabled then break end

                        -- Validate object is still present before teleporting to it
                        if not main or not main.Parent then
                            -- Target disappeared mid-iteration; return once
                            returnToSavedPositionOnce()
                            hadTargetsPreviously = false
                            break
                        end

                        local lp2 = Players.LocalPlayer
                        local char2 = lp2 and lp2.Character
                        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                        if hrp2 then
                            -- Teleport under the resource's MainPart
                            hrp2.CFrame = main.CFrame * CFrame.new(1, -5, 1)
                        end
                        task.wait()

                        -- Optional: if it vanished right after teleport, return
                        if not main.Parent then
                            returnToSavedPositionOnce()
                            hadTargetsPreviously = false
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function stopOreTeleportLoop(teleportBack)
    -- End loop immediately
    if getgenv().TeleportThread then
        pcall(function()
            task.cancel(getgenv().TeleportThread)
        end)
        getgenv().TeleportThread = nil
    end

    if teleportBack and getgenv().TeleportReturnCFrame then
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetCF = getgenv().TeleportReturnCFrame * CFrame.new(1, 4, 1)

        if hrp then
            hrp.CFrame = targetCF
        else
            -- Try once on respawn
            pcall(function()
                lp.CharacterAdded:Wait()
            end)
            task.wait(0.1)
            char = lp.Character
            hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = targetCF
            end
        end
    end

    getgenv().TeleportReturnCFrame = nil
end

-- Safer present teleport
local function getPresents()
    local ignoreCast = workspace:FindFirstChild("IgnoreCast")
    if not ignoreCast then
        return
    end

    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    for _, v in pairs(ignoreCast:GetChildren()) do
        if v and v.Name == "Present" then
            local main = v:FindFirstChild("MainPart") or getAnyBasePart(v)
            if main and main.CFrame then
                pcall(function()
                    main.CFrame = hrp.CFrame * CFrame.new(1, 1, -3)
                end)
            end
        end
    end
end

-- Safer present teleport
local function getAllInteractions()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    for _,v in pairs(workspace.InteractSystem:GetChildren()) do
        if v.Name == "Use" then
            if v:IsA("Part") then
                v.CFrame = hrp.CFrame * CFrame.new(1, 1, -4)
            end
        end
    end
end

local function teleportNoMoreLoadoutToPlayer()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ignore = workspace:FindFirstChild("Ignore") or workspace:FindFirstChild("ignore")
    if not ignore then return end
    local use = ignore.Interacts:FindFirstChild("LoadoutInteract")
    if not use then return end

    local targetPart = nil
    if use:IsA("BasePart") then
        targetPart = use
    elseif use:IsA("Model") then
        targetPart = getMainTeleportPart(use) or getAnyBasePart(use)
    end

    if targetPart then
        pcall(function()
            -- same offset style as interactables
            targetPart.CFrame = hrp.CFrame * CFrame.new(1, 1, -4)
        end)
    end
end

local function teleportScrapmetalFromJunk()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local junk = workspace:FindFirstChild("Junk") or workspace:FindFirstChild("junk")
    if not junk then return end

    for _, item in ipairs(junk:GetChildren()) do
        if item and item.Parent then
            local nm = string.lower(item.Name)
            if nm == "scrapmetal" then
                local targetPart = nil
                if item:IsA("BasePart") then
                    targetPart = item
                elseif item:IsA("Model") then
                    targetPart = getMainTeleportPart(item) or getAnyBasePart(item)
                end
                if targetPart then
                    pcall(function()
                        -- mirror the Present offset
                        targetPart.CFrame = hrp.CFrame * CFrame.new(1, 1, -3)
                    end)
                end
            end
        end
    end
end

-- Tracers implementation (uses Drawing API)
local function destroyAllTracerLines()
    for model, line in pairs(getgenv().ZombieTracerLines) do
        pcall(function()
            if line and line.Remove then
                line:Remove()
            elseif line and line.Destroy then
                line:Destroy()
            end
        end)
        getgenv().ZombieTracerLines[model] = nil
    end
end

local function stopZombieTracers()
    if getgenv().ZombieTracerConn then
        pcall(function()
            getgenv().ZombieTracerConn:Disconnect()
        end)
        getgenv().ZombieTracerConn = nil
    end
    destroyAllTracerLines()
end

local function startZombieTracers()
    -- stop any previous
    stopZombieTracers()

    if not drawingAvailable() then
        warn("[Visuals] Drawing API not available in this executor; Tracers disabled.")
        getgenv().ZombieTracersEnabled = false
        return
    end

    getgenv().ZombieTracerConn = RunService.RenderStepped:Connect(function()
        local zFolder = getZombiesFolder()
        local cam = workspace.CurrentCamera  -- always fetch the current camera
        if not zFolder or not cam then
            destroyAllTracerLines()
            return
        end

        -- Track which models were updated this frame
        local updated = {}

        local viewportSize = cam.ViewportSize
        local fromPos = Vector2.new(viewportSize.X / 2, viewportSize.Y) -- bottom center

        for _, model in ipairs(zFolder:GetChildren()) do
            if model and model:IsA("Model") then
                local hrp = getHRP(model)
                if hrp then
                    local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local toPos = Vector2.new(screenPos.X, screenPos.Y)
                        local line = getgenv().ZombieTracerLines[model]
                        if not line then
                            local okLine, obj = pcall(function()
                                return Drawing.new("Line")
                            end)
                            if okLine and obj then
                                line = obj
                                line.Thickness = 1.5
                                line.ZIndex = 2
                                line.Transparency = 1
                                getgenv().ZombieTracerLines[model] = line
                            end
                        end
                        if line then
                            line.From = fromPos
                            line.To = toPos
                            line.Visible = getgenv().ZombieTracersEnabled == true
                            line.Color = getgenv().ZombieTracersColor
                        end
                        updated[model] = true
                    end
                end
            end
        end

        -- Hide lines for models not updated/visible
        for model, line in pairs(getgenv().ZombieTracerLines) do
            if not updated[model] then
                if line then
                    line.Visible = false
                end
                -- also garbage collect lines whose model is no longer in workspace
                if not model or not model.Parent then
                    pcall(function()
                        if line and line.Remove then
                            line:Remove()
                        elseif line and line.Destroy then
                            line:Destroy()
                        end
                    end)
                    getgenv().ZombieTracerLines[model] = nil
                end
            end
        end
    end)
end


-- Chams implementation (Highlight-based ESP)
local function destroyAllChams()
    for model, hl in pairs(getgenv().ZombieChamsMap) do
        pcall(function()
            if hl and hl.Destroy then
                hl:Destroy()
            end
        end)
        getgenv().ZombieChamsMap[model] = nil
    end
end

local function stopZombieChams()
    if getgenv().ZombieChamsConn then
        pcall(function()
            getgenv().ZombieChamsConn:Disconnect()
        end)
        getgenv().ZombieChamsConn = nil
    end
    destroyAllChams()
end

local function applyChamProps(hl)
    if not hl then return end
    hl.FillColor = getgenv().ZombieChamsColor
    hl.OutlineColor = getgenv().ZombieChamsOutlineColor
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function startZombieChams()
    -- stop any previous
    stopZombieChams()

    getgenv().ZombieChamsConn = RunService.RenderStepped:Connect(function()
        local zFolder = getZombiesFolder()
        if not zFolder then
            destroyAllChams()
            return
        end

        local updated = {}

        for _, model in ipairs(zFolder:GetChildren()) do
            if model and model:IsA("Model") and getHRP(model) then
                local hl = getgenv().ZombieChamsMap[model]
                if not hl or not hl.Parent then
                    local okNew, newHl = pcall(function()
                        local h = Instance.new("Highlight")
                        h.Name = "ZombieCham"
                        h.Adornee = model
                        -- Parent to model to keep lifecycle tight and avoid CoreGui dependencies
                        h.Parent = model
                        return h
                    end)
                    if okNew and newHl then
                        hl = newHl
                        getgenv().ZombieChamsMap[model] = hl
                    end
                end
                if hl then
                    applyChamProps(hl)
                    updated[model] = true
                end
            end
        end

        -- Cleanup for removed models
        for model, hl in pairs(getgenv().ZombieChamsMap) do
            if not updated[model] or not model or not model.Parent then
                pcall(function()
                    if hl and hl.Destroy then
                        hl:Destroy()
                    end
                end)
                getgenv().ZombieChamsMap[model] = nil
            end
        end
    end)
end

-- Aimbot: Dashed FOV ring implementation (white dashed ring, no fill)
local function ensureDashedFOVRing()
    if not getgenv().AimbotFOVSegments then
        getgenv().AimbotFOVSegments = {}
    end

    local segments = getgenv().AimbotFOVSegments
    local desiredCount = tonumber(getgenv().AimbotFOVSegmentCount) or 72
    desiredCount = math.clamp(math.floor(desiredCount), 8, 360)

    local dashRatio = tonumber(getgenv().AimbotFOVDashRatio) or 0.55
    dashRatio = math.clamp(dashRatio, 0.05, 0.95)

    -- Create missing segments
    for i = 1, desiredCount do
        if not segments[i] then
            local ok, line = pcall(function()
                return Drawing.new("Line")
            end)
            if ok and line then
                line.Thickness = 2
                line.Color = Color3.fromRGB(255, 255, 255)
                line.Transparency = 0.95
                line.ZIndex = 2
                line.Visible = false
                segments[i] = line
            end
        end
    end

    -- Remove extras if any
    for i = desiredCount + 1, #segments do
        local ln = segments[i]
        if ln then
            pcall(function()
                if ln.Remove then
                    ln:Remove()
                elseif ln.Destroy then
                    ln:Destroy()
                end
            end)
        end
        segments[i] = nil
    end

    return segments, desiredCount, dashRatio
end

local function updateDashedFOVRing(center, radius, visible)
    local segments, count, dashRatio = ensureDashedFOVRing()
    local step = (2 * math.pi) / count

    for i = 1, count do
        local line = segments[i]
        if line then
            local a1 = (i - 1) * step
            local a2 = a1 + step * dashRatio

            local p1 = Vector2.new(center.X + radius * math.cos(a1), center.Y + radius * math.sin(a1))
            local p2 = Vector2.new(center.X + radius * math.cos(a2), center.Y + radius * math.sin(a2))

            line.From = p1
            line.To = p2
            line.Visible = visible
        end
    end
end

local function destroyDashedFOVRing()
    local segments = getgenv().AimbotFOVSegments
    if segments then
        for i, ln in ipairs(segments) do
            pcall(function()
                if ln and ln.Remove then
                    ln:Remove()
                elseif ln and ln.Destroy then
                    ln:Destroy()
                end
            end)
            segments[i] = nil
        end
    end
    getgenv().AimbotFOVSegments = nil
end

-- Keep compatibility: also remove any legacy fill/stroke circles if present
local function destroyFOVCircle()
    -- Clean up legacy circles
    local function destroy(obj)
        if not obj then return end
        pcall(function()
            if obj.Remove then
                obj:Remove()
            elseif obj.Destroy then
                obj:Destroy()
            end
        end)
    end
    destroy(getgenv().AimbotFOVCircle)
    destroy(getgenv().AimbotFOVStroke)
    getgenv().AimbotFOVCircle = nil
    getgenv().AimbotFOVStroke = nil

    -- Clean up dashed ring segments
    destroyDashedFOVRing()
end

local function getPreferredTargetPart(model)
    if not model or not model:IsA("Model") then return nil end
    local selected = getgenv().AimbotTargetPart or "Head"
    local part = model:FindFirstChild(selected)
    if selected == "HumanoidRootPart" then
        part = getHRP(model)
    end
    if part and part:IsA("BasePart") then return part end
    -- Fallbacks
    part = getHRP(model)
    if part then return part end
    return model:FindFirstChildWhichIsA("BasePart")
end

local function findClosestZombieWithinFOV(cam, screenPos, radius)
    local zFolder = getZombiesFolder()
    if not zFolder or not cam then return nil end
    local closestPart = nil
    local bestDist = math.huge

    for _, model in ipairs(zFolder:GetChildren()) do
        if model and model:IsA("Model") then
            local part = getPreferredTargetPart(model)
            if part then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local pt = Vector2.new(sp.X, sp.Y)
                    local dist = (pt - screenPos).Magnitude
                    if dist <= radius and dist < bestDist then
                        bestDist = dist
                        closestPart = part
                    end
                end
            end
        end
    end

    return closestPart
end

local function stopAimbot()
    if getgenv().AimbotConn then
        pcall(function()
            getgenv().AimbotConn:Disconnect()
        end)
        getgenv().AimbotConn = nil
    end
    destroyFOVCircle()
end

local function startAimbot()
    -- stop any previous
    stopAimbot()

    if not drawingAvailable() then
        warn("[Aimbot] Drawing API not available; FOV ring and aimbot disabled.")
        getgenv().AimbotEnabled = false
        return
    end

    getgenv().AimbotConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end

        local mousePos = UserInputService:GetMouseLocation()

        -- Update dashed FOV ring at the mouse position
        local showRing = getgenv().AimbotEnabled == true
        updateDashedFOVRing(mousePos, getgenv().AimbotFOVRadius, showRing)

        if not getgenv().AimbotEnabled then return end

        local targetPart = findClosestZombieWithinFOV(cam, mousePos, getgenv().AimbotFOVRadius)
        if targetPart then
            local camPos = cam.CFrame.Position
            cam.CFrame = CFrame.new(camPos, targetPart.Position)
        end
    end)
end


-- Player loops: WalkSpeed and JumpPower
local function startWSLoop()
    if getgenv().WSLoopThread and coroutine.status(getgenv().WSLoopThread) ~= "dead" then
        return
    end
    getgenv().WSLoopThread = task.spawn(function()
        while getgenv().WSLoopEnabled do
            local lp = Players.LocalPlayer
            local char = lp and lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.WalkSpeed = tonumber(getgenv().WSpeedValue) or 50
                end)
            end
            task.wait()
        end
    end)
end

local function stopWSLoop()
    if getgenv().WSLoopThread then
        pcall(function() task.cancel(getgenv().WSLoopThread) end)
        getgenv().WSLoopThread = nil
    end
end

local function startJPLoop()
    if getgenv().JPLoopThread and coroutine.status(getgenv().JPLoopThread) ~= "dead" then
        return
    end
    getgenv().JPLoopThread = task.spawn(function()
        while getgenv().JPLoopEnabled do
            local lp = Players.LocalPlayer
            local char = lp and lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.UseJumpPower = true
                    hum.JumpPower = tonumber(getgenv().JPowerValue) or 50
                end)
            end
            task.wait()
        end
    end)
end

local function stopJPLoop()
    if getgenv().JPLoopThread then
        pcall(function() task.cancel(getgenv().JPLoopThread) end)
        getgenv().JPLoopThread = nil
    end
end



local function stopNoclip()
    if Noclipping then
		Noclipping:Disconnect()
	end
	getgenv().Clip = true
end

local function startDex()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end

-- Weapon Editor helpers (scan, state, and setters)
getgenv().WeaponEditorState = getgenv().WeaponEditorState or {
    weapons = {},      -- array of { ref = objTable, name = string, id = any }
    items = {},        -- array of display strings parallel to weapons
    selectedItem = nil,-- selected display string (from Combo)
    selectedIndex = nil,
    selectedProp = nil,
    selectedSubProp = nil,
}

local function scanWeaponTables()
    local results = {}
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "Config") and rawget(obj, "WeaponId") then
            local nm = rawget(obj, "Name")
            local id = rawget(obj, "WeaponId")
            local name = nm and tostring(nm) or (id and tostring(id)) or "<unnamed>"
            table.insert(results, { ref = obj, name = name, id = id })
        end
    end
    table.sort(results, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)
    return results
end

local function rebuildWeaponItems()
    local st = getgenv().WeaponEditorState
    st.items = { "(none)" }
    st.weapons = scanWeaponTables()
    for i, entry in ipairs(st.weapons) do
        local label = string.format("%s (id:%s)", tostring(entry.name), tostring(entry.id))
        table.insert(st.items, label)
    end
end

local function getSelectedWeapon()
    local st = getgenv().WeaponEditorState
    if not st.selectedIndex then return nil end
    -- index 1 is (none)
    local idx = st.selectedIndex - 1
    if idx >= 1 and idx <= #st.weapons then
        return st.weapons[idx].ref
    end
    return nil
end

local function getConfigTable(weapon)
    if weapon and type(weapon) == "table" then
        return rawget(weapon, "Config")
    end
    return nil
end

local function getPropertyNames(cfg)
    local props = {}
    if type(cfg) == "table" then
        for k, _ in pairs(cfg) do
            table.insert(props, tostring(k))
        end
    end
    table.sort(props)
    return props
end

local function getSubPropertyNames(cfg, prop)
    if not cfg or not prop then return {} end
    local v = cfg[prop]
    if type(v) ~= "table" then return {} end
    local props = {}
    for k, _ in pairs(v) do
        table.insert(props, tostring(k))
    end
    table.sort(props)
    return props
end

local function readCurrentValue(weapon, prop, sub)
    local cfg = getConfigTable(weapon)
    if not cfg or not prop then return nil end
    local v = cfg[prop]
    if sub and type(v) == "table" then v = v[sub] end
    return v
end

local function coerceValueFromInputs(expectedValue, textInputValue, boolValue)
    local t = typeof(expectedValue)
    if t == "nil" then
        -- Try guess from text
        local asNum = tonumber(textInputValue)
        if asNum ~= nil then return asNum end
        if textInputValue == "true" then return true end
        if textInputValue == "false" then return false end
        return textInputValue
    elseif t == "boolean" then
        return boolValue == true
    elseif t == "number" then
        local n = tonumber(textInputValue)
        return n ~= nil and n or expectedValue
    elseif t == "string" then
        return tostring(textInputValue)
    else
        -- Unsupported complex type (Color3, Vector3, etc.)
        return expectedValue
    end
end

local function applyValue(weapon, prop, sub, newValue)
    local cfg = getConfigTable(weapon)
    if not cfg or not prop then return false end
    if sub then
        if type(cfg[prop]) ~= "table" then return false end
        cfg[prop][sub] = newValue
    else
        cfg[prop] = newValue
    end
    return true
end

-- General mods: bulk operations
local function modAllGuns()
    local list = scanWeaponTables()
    for _, entry in ipairs(list) do
        local cfg = getConfigTable(entry.ref)
        if type(cfg) == "table" then
            for _, key in ipairs({"Spread","BaseSpread","VerticalRecoil","HorizontalRecoil", "InsertTime"}) do
                if cfg[key] ~= nil then
                    cfg[key] = 0
                end
            end
            cfg.DrawSpeed = 1
            cfg.HolsterSpeed = 1
            cfg.StaminaRequired = 0
            cfg.EquippedWalkspeedMultiplier = 1.25
            cfg.HolsteredWalkspeedMultiplier = 1.25
            cfg.ADSSpeed = 1
            --cfg.EmptyReloadTime = 1
            cfg.CustomShootAnimation = nil
            --cfg.DelayPerShot = 0.051
        end
    end
end

local function modAllMelee()
    local list = scanWeaponTables()
    for _, entry in ipairs(list) do
        local cfg = getConfigTable(entry.ref)
        if type(cfg) == "table" then
            local sdata = cfg.SwingData
            if type(sdata) == "table" then
                for k, swing in pairs(sdata) do
                    if type(swing) == "table" then
                        local kl = string.lower(tostring(k))
                        if kl == "swing1" or kl == "swing2" or kl == "heavyswing" or kl == "heavyswing2" then
                            swing.max_dist = 100
                            swing.min_dist = 100
                            swing.num_times = 100
                        end
                    end
                end
                cfg.ChargeTime = 0
                cfg.EquippedWalkspeedMultiplier = 1.25
                cfg.HolsteredWalkspeedMultiplier = 1.25
                cfg.DrawSpeed = 1
                cfg.StaminaRequired = 0
                cfg.SwingComboStart = 0.1
                cfg.SwingComboEnd = 0.2
                cfg.SwingStart = 0.1
                cfg.SwingEnd = 0.2
                cfg.DelayPerShot = 0.2
                cfg.HeavyStaminaCost = 2
                cfg.HeavyChargeStaminaDrain = 0
                cfg.BlockStaminaRequired = 0
                cfg.HeavyDelayPerShot = 1
                cfg.HeavyStaminaRequired = 0
                cfg.BlackStaminaUse = 0
                cfg.Penetration = 10
                cfg.HeavySwingEnd = 0
                cfg.BlockStaminaDrain = -0.1
                cfg.BlockReduction = 1.1
            end
        end
    end
end

-- Build UI with ReGui
Window = ReGui:TabsWindow({
    Title = "Zombie Bring Controller",
    Size = UDim2.fromOffset(520, 420)
})

-- Main Tab
local MainTab = Window:CreateTab({ Name = "Main" })
MainTab:Label({ Text = "Controls" })
MainTab:Separator({})

MainTab:Checkbox({
    Label = "Bring Boss Zombies",
    Value = getgenv().Mob,
    Callback = function(self, state)
        getgenv().Mob = state
        if state then
            runMobLoop()
        else
            -- The loop will naturally exit on next check; thread will end
        end
    end
})

MainTab:Checkbox({
    Label = "Bring Most Zombies",
    Value = getgenv().Mob2,
    Callback = function(self, state)
        getgenv().Mob2 = state
        if state then
            runMobLoop2()
        else
            -- The loop will naturally exit on next check; thread will end
        end
    end
})

MainTab:Button({
    Text = "Panic Stop",
    Callback = function()
        getgenv().Mob = false
        getgenv().Mob2 = false
        getgenv().AimbotEnabled = false
        -- Stop aimbot
        stopAimbot()
        -- Stop elf teleport (return to saved pos)
        if getgenv().Elf then
            getgenv().Elf = false
            stopElfTeleportLoop(true)
        end
        -- Stop resource teleport (return to saved pos)
        if getgenv().TeleportEnabled then
            getgenv().TeleportEnabled = false
            stopOreTeleportLoop(true)
        end
        -- Stop player loops
        if getgenv().WSLoopEnabled then
            getgenv().WSLoopEnabled = false
            stopWSLoop()
        end
        if getgenv().JPLoopEnabled then
            getgenv().JPLoopEnabled = false
            stopJPLoop()
        end
    end
})

-- Teleports Tab
local TeleTab = Window:CreateTab({ Name = "Teleports" })
TeleTab:Label({ Text = "Resource Teleports" })
TeleTab:Separator({})

TeleTab:Combo({
    Label = "Resource Type",
    Selected = getgenv().TeleportType,
    Items = {"Coal", "Iron", "Ring"},
    Callback = function(self, value)
        local selected = tostring(value)
        if selected ~= "Coal" and selected ~= "Iron" and selected ~= "Ring" then
            selected = "Coal"
        end
        getgenv().TeleportType = selected
    end
})

TeleTab:Checkbox({
    Label = "Enable Resource Teleport",
    Value = getgenv().TeleportEnabled,
    Callback = function(self, state)
        getgenv().TeleportEnabled = state
        if state then
            startOreTeleportLoop()
        else
            stopOreTeleportLoop(true)
        end
    end
})

TeleTab:Label({ Text = "Levers Objects" })
TeleTab:Separator({})
local LeversCombo
local function refreshLeversList()
    local items = collectLeversObjects()
    local default = items[1]
    getgenv().LeversState.selected = default

    if LeversCombo and LeversCombo.Update then
        LeversCombo:Update({
            Items = items,
            Selected = default
        })
    end
end

LeversCombo = TeleTab:Combo({
    Label = "Levers Object",
    Items = collectLeversObjects(),
    Callback = function(self, value)
        getgenv().LeversState.selected = tostring(value)
    end
})

TeleTab:Button({
    Text = "Refresh Levers List",
    Callback = function()
        refreshLeversList()
    end
})

TeleTab:Button({
    Text = "Teleport Selected In Front",
    Callback = function()
        local sel = getgenv().LeversState.selected
        if not sel then
            refreshLeversList()
            sel = getgenv().LeversState.selected
        end

        if not sel then
            warn("[Levers] No selectable items found.")
            return
        end

        local ok = teleportLeversObjectInFront(sel)
        if not ok then
            warn(string.format("[Levers] Failed to teleport '%s'. It may have been removed.", tostring(sel)))
        end
    end
})

TeleTab:Label({ Text = "Elf Teleport" })
TeleTab:Separator({})

TeleTab:Checkbox({
    Label = "Enable Elf Teleport",
    Value = getgenv().Elf,
    Callback = function(self, state)
        getgenv().Elf = state
        if state then
            startElfTeleportLoop()
        else
            stopElfTeleportLoop(true)
        end
    end
})

TeleTab:Label({ Text = "Teleport Items" })
TeleTab:Separator({})

TeleTab:Button({
    Text = "Teleport Presents",
    Callback = function()
        getPresents()
    end
})

TeleTab:Button({
    Text = "Teleport Interactions",
    Callback = function()
        getAllInteractions()
    end
})

TeleTab:Button({
    Text = "Teleport Loadout(No More)",
    Callback = function()
        teleportNoMoreLoadoutToPlayer()
    end
})

TeleTab:Button({
    Text = "Teleport Scrapmetal",
    Callback = function()
        teleportScrapmetalFromJunk()
    end
})

-- ESP/Visuals Tab (Tracers + Color + Chams)
local EspTab = Window:CreateTab({ Name = "Esp" })
EspTab:Label({ Text = "Visuals" })
EspTab:Separator({})

local TracersCheckbox = EspTab:Checkbox({
    Label = "Zombie Tracers",
    Value = getgenv().ZombieTracersEnabled,
    Callback = function(self, state)
        if state then
            if not drawingAvailable() then
                warn("[Visuals] Drawing API not available; turning Tracers off.")
                getgenv().ZombieTracersEnabled = false
                stopZombieTracers()
                forceCheckboxOff(TracersCheckbox)
                return
            end
            getgenv().ZombieTracersEnabled = true
            startZombieTracers()
        else
            getgenv().ZombieTracersEnabled = false
            stopZombieTracers()
        end
    end
})

EspTab:DragColor3({
    Label = "Tracers Color",
    Value = getgenv().ZombieTracersColor,
    Callback = function(self, color)
        getgenv().ZombieTracersColor = color
    end
})

EspTab:Checkbox({
    Label = "Zombie Chams",
    Value = getgenv().ZombieChamsEnabled,
    Callback = function(self, state)
        getgenv().ZombieChamsEnabled = state
        if state then
            startZombieChams()
        else
            stopZombieChams()
        end
    end
})

EspTab:DragColor3({
    Label = "Chams Color",
    Value = getgenv().ZombieChamsColor,
    Callback = function(self, color)
        getgenv().ZombieChamsColor = color
        -- apply to existing highlights immediately
        for _, hl in pairs(getgenv().ZombieChamsMap) do
            pcall(function()
                if hl then
                    hl.FillColor = color
                end
            end)
        end
    end
})

-- Aimbot Tab
local AimTab = Window:CreateTab({ Name = "Aimbot" })
AimTab:Label({ Text = "Aimbot Controls" })
AimTab:Separator({})

local AimbotCheckbox = AimTab:Checkbox({
    Label = "Enable Aimbot",
    Value = getgenv().AimbotEnabled,
    Callback = function(self, state)
        if state then
            if not drawingAvailable() then
                warn("[Aimbot] Drawing API not available; turning Aimbot off.")
                getgenv().AimbotEnabled = false
                stopAimbot()
                forceCheckboxOff(AimbotCheckbox)
                return
            end
            getgenv().AimbotEnabled = true
            startAimbot()
        else
            getgenv().AimbotEnabled = false
            stopAimbot()
        end
    end
})

AimTab:Combo({
    Label = "Target Part",
    Selected = getgenv().AimbotTargetPart,
    Items = {"Head", "HumanoidRootPart"},
    Callback = function(self, value)
        local selected = tostring(value)
        if selected ~= "Head" and selected ~= "HumanoidRootPart" then
            selected = "Head"
        end
        getgenv().AimbotTargetPart = selected
    end
})

AimTab:SliderInt({
    Label = "FOV Radius",
    Minimum = 50,
    Maximum = 600,
    Value = getgenv().AimbotFOVRadius,
    Format = "FOV = %d px",
    Callback = function(self, value)
        getgenv().AimbotFOVRadius = value
        -- The dashed ring is updated every frame in startAimbot(), so no direct Drawing updates are required here.
    end
})

-- New: FOV dashed ring controls
AimTab:SliderInt({
    Label = "FOV Dashes",
    Minimum = 12,
    Maximum = 180,
    Value = math.clamp(math.floor(getgenv().AimbotFOVSegmentCount or 72), 8, 360),
    Format = "Dashes = %d",
    Callback = function(self, value)
        getgenv().AimbotFOVSegmentCount = value
        -- Segments will be reallocated/trimmed on the next frame automatically.
    end
})

AimTab:SliderInt({
    Label = "Dash Ratio",
    Minimum = 10,  -- 10%
    Maximum = 90,  -- 90%
    Value = math.clamp(math.floor((getgenv().AimbotFOVDashRatio or 0.55) * 100), 5, 95),
    Format = "Dash = %d%%",
    Callback = function(self, value)
        getgenv().AimbotFOVDashRatio = math.clamp(value / 100, 0.05, 0.95)
        -- Dash ratio takes effect next frame in the dashed ring updater.
    end
})

-- Player Tab (WalkSpeed & JumpPower)
local PlayerTab = Window:CreateTab({ Name = "Player" })
PlayerTab:Label({ Text = "Local Player Tweaks" })
PlayerTab:Separator({})

PlayerTab:Button({
    Text = "Float on",
    Callback = function()
        startFloatLoop()
    end
})
PlayerTab:Button({
    Text = "Float off",
    Callback = function()
        stopFloatLoop()
    end
})

PlayerTab:Checkbox({
    Label = "Noclip",
    Value = getgenv().Clip,
    Callback = function(self, state)
        getgenv().Clip = state
        if state then
            startNoclip()
        else
            stopNoclip()
        end
    end
})

PlayerTab:Button({
    Text = "Dex Explorer",
    Callback = function()
        startDex()
    end
})

PlayerTab:Checkbox({
    Label = "WalkSpeed Loop",
    Value = getgenv().WSLoopEnabled,
    Callback = function(self, state)
        getgenv().WSLoopEnabled = state
        if state then
            startWSLoop()
        else
            stopWSLoop()
        end
    end
})

PlayerTab:SliderInt({
    Label = "WalkSpeed",
    Minimum = 8,
    Maximum = 300,
    Value = getgenv().WSpeedValue,
    Format = "WS = %d",
    Callback = function(self, value)
        getgenv().WSpeedValue = value
    end
})

PlayerTab:Checkbox({
    Label = "JumpPower Loop",
    Value = getgenv().JPLoopEnabled,
    Callback = function(self, state)
        getgenv().JPLoopEnabled = state
        if state then
            startJPLoop()
        else
            stopJPLoop()
        end
    end
})

PlayerTab:SliderInt({
    Label = "JumpPower",
    Minimum = 25,
    Maximum = 300,
    Value = getgenv().JPowerValue,
    Format = "JP = %d",
    Callback = function(self, value)
        getgenv().JPowerValue = value
    end
})

-- Weapons Tab: Generalized weapon editor using Dear ReGui
local WeaponTab = Window:CreateTab({ Name = "Weapons" })
WeaponTab:Label({ Text = "Basic Button Mods" })
WeaponTab:Separator({})
WeaponTab:Button({
    Text = "Mod Guns",
    Callback = function()
        modAllGuns()
    end
})
WeaponTab:Button({
    Text = "Mod Melee",
    Callback = function()
        modAllMelee()
    end
})


WeaponTab:Label({ Text = "Specific Weapon Editor" })
WeaponTab:Separator({})

-- Ensure we have initial list
rebuildWeaponItems()

local st = getgenv().WeaponEditorState
local WeaponCombo
local Dyn = { -- dynamic controls that appear/disappear per selection
    PropertyCombo = nil,
    SubPropertyCombo = nil,
    ValueInput = nil,
    BoolInput = nil,
    ApplyButton = nil,
    CurrentLabel = nil,
}

local function destroyCtrl(ctrl)
    if not ctrl then return end
    pcall(function() if ctrl.Destroy then ctrl:Destroy() end end)
    pcall(function() if ctrl.Remove then ctrl:Remove() end end)
end

local function clearDynamic()
    for k, v in pairs(Dyn) do
        if v then destroyCtrl(v) end
        Dyn[k] = nil
    end
    st.selectedProp = nil
    st.selectedSubProp = nil
end

local function updateCurrentValueLabel()
    local w = getSelectedWeapon()
    if not w or not st.selectedProp then
        if Dyn.CurrentLabel then
            pcall(function() if Dyn.CurrentLabel.Update then Dyn.CurrentLabel:Update({ Text = "Current: (n/a)" }) end end)
        end
        return
    end
    local val = readCurrentValue(w, st.selectedProp, st.selectedSubProp)
    local repr
    local t = typeof(val)
    if t == "table" then
        repr = "<table>"
    elseif t == "nil" then
        repr = "nil"
    else
        repr = tostring(val)
    end
    if Dyn.CurrentLabel then
        pcall(function()
            if Dyn.CurrentLabel.Update then
                Dyn.CurrentLabel:Update({ Text = string.format("Current: %s (%s)", repr, t) })
            end
        end)
    end
end

local function rebuildValueEditors()
    -- Destroy old editors
    destroyCtrl(Dyn.ValueInput) ; Dyn.ValueInput = nil
    destroyCtrl(Dyn.BoolInput) ; Dyn.BoolInput = nil

    local w = getSelectedWeapon()
    if not w or not st.selectedProp then return end
    local expected = readCurrentValue(w, st.selectedProp, st.selectedSubProp)
    local t = typeof(expected)

    if t == "boolean" then
        Dyn.BoolInput = WeaponTab:Checkbox({
            Label = "New Value (bool)",
            Value = expected == true,
            Callback = function(self, value) end
        })
    else
        Dyn.ValueInput = WeaponTab:InputText({
            Label = "New Value (text/number)",
            Value = expected == nil and "" or tostring(expected)
        })
    end

    updateCurrentValueLabel()
end

local function onSubPropertySelected(self, subProp)
    st.selectedSubProp = tostring(subProp)
    rebuildValueEditors()
end

local function onPropertySelected(self, prop)
    st.selectedProp = tostring(prop)

    -- Rebuild sub-property combo depending on type
    destroyCtrl(Dyn.SubPropertyCombo) ; Dyn.SubPropertyCombo = nil

    local w = getSelectedWeapon()
    if not w then return end
    local cfg = getConfigTable(w)
    if not cfg then return end

    local v = cfg[st.selectedProp]
    if type(v) == "table" then
        local items = getSubPropertyNames(cfg, st.selectedProp)
        Dyn.SubPropertyCombo = WeaponTab:Combo({
            Label = "Sub-Property",
            Items = items,
            Callback = onSubPropertySelected
        })
        st.selectedSubProp = nil -- require user to pick one
    else
        st.selectedSubProp = nil
    end

    rebuildValueEditors()

    -- Rebuild/Place Apply button and current value label
    destroyCtrl(Dyn.ApplyButton) ; Dyn.ApplyButton = nil
    destroyCtrl(Dyn.CurrentLabel) ; Dyn.CurrentLabel = nil

    Dyn.ApplyButton = WeaponTab:Button({
        Text = "Apply Changes",
        Callback = function()
            local w2 = getSelectedWeapon()
            if not w2 or not st.selectedProp then return end

            local expected = readCurrentValue(w2, st.selectedProp, st.selectedSubProp)
            local textVal = (Dyn.ValueInput and Dyn.ValueInput.Value) or ""
            local boolVal = (Dyn.BoolInput and Dyn.BoolInput.Value) or false
            local newVal = coerceValueFromInputs(expected, textVal, boolVal)
            local ok = applyValue(w2, st.selectedProp, st.selectedSubProp, newVal)
            if ok then
                updateCurrentValueLabel()
            end
        end
    })

    Dyn.CurrentLabel = WeaponTab:Label({ Text = "Current: (n/a)" })
    updateCurrentValueLabel()

    
end
WeaponTab:Label({ Text = "Instructions: Pick a weapon, then a property.\n".. "If it is a table, pick a sub-property.\n".. "Enter a value or toggle, then click Apply Changes." })

WeaponTab:Button({
    Text = "Refresh / Rescan",
    Callback = function()
        rebuildWeaponItems()
        -- Try update Combo items if possible
        if WeaponCombo and WeaponCombo.Update then
            WeaponCombo:Update({ Items = st.items, Selected = "(none)" })
        end
        st.selectedItem = "(none)"
        st.selectedIndex = nil
        clearDynamic()
    end
})

WeaponCombo = WeaponTab:Combo({
    Label = "Weapon",
    Selected = st.selectedItem or "(none)",
    Items = st.items,
    Callback = function(self, value)
        st.selectedItem = tostring(value)
        -- Resolve to index
        st.selectedIndex = nil
        for i, label in ipairs(st.items) do
            if label == value then
                st.selectedIndex = i
                break
            end
        end
        clearDynamic()
        if st.selectedIndex and st.selectedIndex > 1 then
            local w = getSelectedWeapon()
            if not w then return end
            local cfg = getConfigTable(w)
            if not cfg then return end

            Dyn.PropertyCombo = WeaponTab:Combo({
                Label = "Property",
                Items = getPropertyNames(cfg),
                Callback = onPropertySelected
            })
        end
    end
})

-- Auto-start loops if previously enabled
if getgenv().Mob then
    runMobLoop()
end
if getgenv().Mob2 then
    runMobLoop2()
end

-- Auto-start teleports if previously enabled
if getgenv().TeleportEnabled then
    startOreTeleportLoop()
end
if getgenv().Elf then
    startElfTeleportLoop()
end

-- Auto-start tracers if previously enabled
if getgenv().ZombieTracersEnabled then
    if drawingAvailable() then
        startZombieTracers()
    else
        warn("[Visuals] Drawing API not available on auto-start; disabling Tracers.")
        getgenv().ZombieTracersEnabled = false
        -- UI may not be built yet in some load orders; guard the call
        pcall(function() forceCheckboxOff(TracersCheckbox) end)
    end
end

-- Auto-start chams if previously enabled
if getgenv().ZombieChamsEnabled then
    startZombieChams()
end

-- Auto-start aimbot if previously enabled
if getgenv().AimbotEnabled then
    if drawingAvailable() then
        startAimbot()
    else
        warn("[Aimbot] Drawing API not available on auto-start; disabling Aimbot.")
        getgenv().AimbotEnabled = false
        pcall(function() forceCheckboxOff(AimbotCheckbox) end)
    end
end

-- Auto-start player loops if previously enabled
if getgenv().WSLoopEnabled then
    startWSLoop()
end
if getgenv().JPLoopEnabled then
    startJPLoop()
end
if getgenv().Floating then
    startFloatLoop()
end
