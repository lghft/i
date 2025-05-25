
-- Helper: Find all indicator parts in workspace
local function getIndicatorParts()
    local indicators = {}
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") then
            for _, desc in ipairs(model:GetDescendants()) do
                if desc:IsA("BasePart") and desc.Name == "indicator" then
                    table.insert(indicators, desc)
                end
            end
        end
    end
    return indicators
end

-- Helper: Check if any indicator is touching the player's HumanoidRootPart
local function isTouchingIndicator()
    local root = humanoidRootPart
    for _, indicator in ipairs(getIndicatorParts()) do
        -- Use GetTouchingParts for both root and indicator
        for _, part in ipairs(indicator:GetTouchingParts()) do
            if part == root then
                return true
            end
        end
        for _, part in ipairs(root:GetTouchingParts()) do
            if part == indicator then
                return true
            end
        end
    end
    return false
end

-- Platform pause/resume state
local pausedForIndicator = false

-- Autofarm loop (replace the old health logic)
spawn(function()
    while true do
        -- Indicator check
        if isTouchingIndicator() and not pausedForIndicator then
            pausedForIndicator = true
            healthStatusLabel.Text = "Indicator detected! Waiting..."
            moveToTempPlatform()
        end

        while pausedForIndicator do
            moveToTempPlatform()
            if not isTouchingIndicator() then
                pausedForIndicator = false
                healthStatusLabel.Text = ""
                removeTempPlatform()
            end
            wait(0.5)
        end

        if autofarmActive and isSinglePlayer() then
            local enemy = getNearestEnemy()
            currentTarget = enemy
            if enemy then
                tweenAboveEnemy(enemy, heightAboveEnemy)
                while enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not pausedForIndicator and isSinglePlayer() do
                    if isTouchingIndicator() then
                        pausedForIndicator = true
                        healthStatusLabel.Text = "Indicator detected! Waiting..."
                        moveToTempPlatform()
                        break
                    end
                    local enemyPos = enemy.HumanoidRootPart.Position + Vector3.new(0, heightAboveEnemy, 0)
                    local dist = (humanoidRootPart.Position - enemyPos).Magnitude
                    if dist <= 1.5 then
                        break
                    end
                    local goal = {}
                    goal.CFrame = CFrame.new(enemyPos)
                    TweenService:Create(
                        humanoidRootPart,
                        TweenInfo.new(0.2, Enum.EasingStyle.Linear),
                        goal
                    ):Play()
                    wait(0.2)
                end
                if enemy.Parent == enemiesFolder and enemy.Humanoid.Health > 0 and autofarmActive and not pausedForIndicator and isSinglePlayer() then
                    orbitAroundEnemy(enemy, heightAboveEnemy, orbitRadius, orbitSpeed)
                end
            else
                wait(0.5)
            end
        else
            currentTarget = nil
            wait(0.5)
        end
    end
end)

-- Auto spell loop (replace health check with indicator check)
spawn(function()
    while true do
        if autospellActive and not pausedForIndicator and isSinglePlayer() then
            for _, spell in ipairs(SPELLS) do
                if autospellActive and not pausedForIndicator and isSinglePlayer() then
                    ReplicatedStorage:WaitForChild("useSpell"):FireServer(spell)
                end
                wait(SPELL_INTERVAL)
            end
        else
            wait(0.2)
        end
    end
end)
