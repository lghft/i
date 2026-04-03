local CONFIG_LEVEL = (getgenv().TDX_Config and getgenv().TDX_Config["FpsLevel"] or 2)

local function makeEmptyModel(modelName, headOffset, needTorso)
    local m = Instance.new("Model")
    m.Name = modelName
    m:SetAttribute("NoAnimations", true)
    m:SetAttribute("IgnoreTurretConfigs", true)
    m:SetAttribute("NoHead", true)
    m:SetAttribute("_IsEmptyModel", true)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(0.05, 0.05, 0.05)
    root.Transparency = 1
    root.CanCollide = false
    root.CanQuery = false
    root.CanTouch = false
    root.Anchored = false
    root.CastShadow = false
    root.Parent = m
    m.PrimaryPart = root

    if needTorso then
        local t = Instance.new("Part")
        t.Name = "Torso"
        t.Size = Vector3.new(0.05,0.05,0.05)
        t.Transparency = 1
        t.CanCollide = false
        t.CanQuery = false
        t.CanTouch = false
        t.Anchored = false
        t.CastShadow = false
        t.Parent = m
        local w = Instance.new("WeldConstraint")
        w.Part0 = root
        w.Part1 = t
        w.Parent = root
    else
        m:SetAttribute("NoTorso", true)
    end

    if headOffset then
        local h = Instance.new("Part")
        h.Name = "Head"
        h.Size = Vector3.new(0.05,0.05,0.05)
        h.Transparency = 1
        h.CanCollide = false
        h.CanQuery = true
        h.CanTouch = false
        h.Anchored = false
        h.CastShadow = false
        h:SetAttribute("IsHead", true)
        h.Parent = m
        local w = Instance.new("WeldConstraint")
        w.Part0 = root
        w.Part1 = h
        w.Parent = root
        h.CFrame = root.CFrame * CFrame.new(0, headOffset, 0)
        m:SetAttribute("NoHead", false)
    end
    return m
end

local DUMMY_CC = {}
DUMMY_CC.__index = DUMMY_CC
local function noop() end
DUMMY_CC.Initialize = noop
DUMMY_CC.Run_FromCharacter = noop
DUMMY_CC.AbilityUsed = noop
DUMMY_CC.AbilityAnimationKeyframeReached = noop
DUMMY_CC.SpeedMultiplierChanged_FromCharacter = noop
DUMMY_CC.EnemyDestroyed = noop
DUMMY_CC.PathEntityDestroyed = noop
DUMMY_CC.CharacterCleanedUp = noop
DUMMY_CC.AnimationStateChanged = noop
local function makeDummyCC() return setmetatable({}, DUMMY_CC) end

local function stripEntityConfig(cfg)
    if not cfg then return end
    cfg.SpawnEffectInstanceNames = nil
    cfg.DeathEffectInstanceNames = nil
    cfg.DeathEffectsData = nil
    cfg.DeathExplodePartsDelay = nil
    cfg.DeathExplodePartsScale = nil
    cfg.FootstepEffectInstanceNames = nil
    cfg.PostTeleportEffectParentInstanceNames = nil
    cfg.GunModelName = nil
    cfg.GunModelSoundGroupName = nil
    cfg.GunModelSoundGroupStopDelay = nil
    cfg.GunModelSoundGroupStopDelayBufferForTowers = nil
    cfg.TurretConfigs = nil
    cfg.RotatingBarrelData = nil
    cfg.DeathEffect = nil
    cfg.DeathEffectPlayed = nil
    cfg.DeathColor = nil
    cfg.DeathMaterial = nil
    cfg.DeathRemoveTextures = nil
    cfg.HasChangeColorParts = nil
    cfg.ShipHandlerClass = nil
    cfg.NoStealthShimmer = nil
    cfg.NoAnimations = true
    cfg.NoHead = true
end

local function stripAbilityConfig(self)
    local cfg = self.Config
    if cfg then
        cfg.HiddenWhenBeingUsedModelName = nil
        cfg.ShownWhenBeingUsedModelNames = nil
        cfg.EffectParentInstanceNames = nil
        cfg.InstantPlayEffectParentInstanceNames = nil
        cfg.EnemyToTowerRangedDataSequence = nil
        cfg.DestroyInstanceNames = nil
    end
    self.AnimationName = nil
    self.SecondaryAnimationForKeyframeEventsName = nil
    self.AdditionalAnimationsForKeyframeEventsNames = nil
end

local function isEmptyModel(character)
    if not character then return false end
    local model = character.GetCharacterModel and character:GetCharacterModel()
    return model ~= nil and model:GetAttribute("_IsEmptyModel") == true
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
local Client = PlayerScripts:WaitForChild("Client")
local GameClass = Client:WaitForChild("GameClass")
local UserInterfaceHandler = Client:WaitForChild("UserInterfaceHandler")
local TDX_Shared = ReplicatedStorage:WaitForChild("TDX_Shared")
local Common = TDX_Shared:WaitForChild("Common")
local Wrappers = Common:WaitForChild("Wrappers")
local BaseClasses = GameClass:WaitForChild("BaseClasses")

local CharacterClass = require(BaseClasses:WaitForChild("CharacterClass"))
local ProjectileHandler = require(GameClass:WaitForChild("ProjectileHandler"))
local TowerClass = require(GameClass:WaitForChild("TowerClass"))
local EnemyClass = require(GameClass:WaitForChild("EnemyClass"))

do
    local orig = ProjectileHandler.NewProjectile
    ProjectileHandler.NewProjectile = function(packet)
        if packet and packet.OriginEntityClass == "Tower" then
            local tower = TowerClass.GetTower(packet.OriginHash)
            if tower then
                if tostring(tower.Type) == "Combat Drone"
                or tostring(tower.Name) == "Combat Drone" then
                    return orig(packet)
                end
            end
        end
        return {}
    end
end

do
    local TowerUIHandler = UserInterfaceHandler
        and UserInterfaceHandler:FindFirstChild("TowerUIHandler")
    if TowerUIHandler then
        local UHH = require(TowerUIHandler:WaitForChild("UpgradeHoverHandler"))
        if UHH and UHH.UpgradeHovered then
            local orig = UHH.UpgradeHovered
            UHH.UpgradeHovered = function(...) pcall(orig, ...) end
        end
    end
end

do
    local BEH = require(Common:WaitForChild("BeamEffectHelper"))
    BEH.NewBeamEffects = function() return {} end
    BEH.StartBeamEffects = function() end
    BEH.StopBeamEffects = function() end
    BEH.RunBeamEffects = function() end
    CharacterClass.RunDefaultBeamEffects = function() end
end

do
    local DUMMY_TURRET = setmetatable({}, {
        __index = function() return function() end end
    })

    local origFace = CharacterClass.FaceTurretToTarget
    if origFace then
        CharacterClass.FaceTurretToTarget = function(self, ...)
            if not self.TurretHandler
            or self.TurretHandler == DUMMY_TURRET then return end
            return origFace(self, ...)
        end
    end

    local origNew = CharacterClass.New
    CharacterClass.New = function(initData, ...)
        if initData and (initData.EntityClass == "Enemy"
                      or initData.EntityClass == "PathEntity") then
            initData.TurretConfigs = nil
            initData.RotatingBarrelData = nil
            stripEntityConfig(initData.Config)
        end
        local inst = origNew(initData, ...)
        if inst and inst.TurretHandler == nil then
            inst.TurretHandler = DUMMY_TURRET
        end
        return inst
    end
end

local DUMMY_VFX = { StopEarly = function() end, Run = function() end }

do
    local DEH = require(BaseClasses:WaitForChild("CharacterClass"):WaitForChild("DeathEffectHandler"))
    local orig = DEH.NewDeathEffect
    DEH.NewDeathEffect = function(trackInstance, _, deathSound, speedMultiplier)
        return orig(trackInstance, nil, deathSound, speedMultiplier)
    end
end

do
    CharacterClass.SetChangeColorPartsColor = function(self, color, tweenTime)
        if not self.ChangeColorParts then return end
        if tweenTime then
            for _, part in pairs(self.ChangeColorParts) do
                game:GetService("TweenService")
                    :Create(part, TweenInfo.new(tweenTime), {Color = color}):Play()
            end
        else
            for _, part in pairs(self.ChangeColorParts) do
                part.Color = color
            end
        end
    end

    CharacterClass._PlayDeathEffects = function() end
    CharacterClass.ExplodeParts = function() end

    CharacterClass.RunDeathLogic = function(self, dt, dtReal)
        if self.DeathAnimationFinished then
            local delayLeft = self.DeathFadeOutDelayTimeLeft
            if delayLeft and delayLeft > 0 then
                self.DeathFadeOutDelayTimeLeft = delayLeft - dt
                return
            end
            local fadeLeft = self.DeathFadeOutTimeLeft
            if fadeLeft and fadeLeft > 0 then
                local delta = self.EntityClass == "Tower" and dtReal or dt
                fadeLeft = fadeLeft - delta
                self.DeathFadeOutTimeLeft = fadeLeft
                local alpha = math.max(0, 1 - fadeLeft / self.FadeOutTime)
                for _, part in pairs(self.DeathFadeOutParts) do
                    part.Transparency = math.max(part.Transparency, alpha)
                end
                if fadeLeft <= 0 then
                    local removeDelay = self.DeathFadeOutRemoveDelayTimeLeft
                    if removeDelay and removeDelay > 0 then
                        self.DeathFadeOutRemoveDelayTimeLeft = removeDelay - dt
                        return
                    end
                    self.FadeOutOnDeath = false
                    self:_Cleanup()
                end
            end
        end
        if self.GeneralWrapperDeathStopTimeLeft
        and self.GeneralWrapperDeathStopTimeLeft > 0 then
            self.GeneralWrapperDeathStopTimeLeft =
                self.GeneralWrapperDeathStopTimeLeft - dt
            if self.GeneralWrapperDeathStopTimeLeft <= 0 then
                self:StopGeneralWrappers()
                self.GeneralWrapperDeathStopTimeLeft = nil
            end
        end
    end
end

do
    TowerClass._PlayDeathEffects = function() end
end

do
    local EnemyAbilityClass = require(
        GameClass:WaitForChild("EnemyClass")
            :WaitForChild("AbilityHandlerClass")
            :WaitForChild("AbilityClass")
    )
    local PEAbilityClass = require(
        GameClass:WaitForChild("PathEntityClass")
            :WaitForChild("AbilityHandlerClass")
            :WaitForChild("AbilityClass")
    )

    local origSetEnemy = EnemyAbilityClass.SetEnemy
    EnemyAbilityClass.SetEnemy = function(self, enemy, ...)
        if enemy and isEmptyModel(enemy.Character) then
            stripAbilityConfig(self)
        elseif enemy and enemy.Character
               and not enemy.Character.PrimaryAnimationHandler then
            self.AnimationName = nil
            self.SecondaryAnimationForKeyframeEventsName = nil
            self.AdditionalAnimationsForKeyframeEventsNames = nil
        end
        return origSetEnemy(self, enemy, ...)
    end

    local origSetPE = PEAbilityClass.SetPathEntity
    if origSetPE then
        PEAbilityClass.SetPathEntity = function(self, pe, ...)
            if pe and isEmptyModel(pe.Character) then
                stripAbilityConfig(self)
            elseif pe and pe.Character
                   and not pe.Character.PrimaryAnimationHandler then
                self.AnimationName = nil
                self.SecondaryAnimationForKeyframeEventsName = nil
                self.AdditionalAnimationsForKeyframeEventsNames = nil
            end
            return origSetPE(self, pe, ...)
        end
    end

    local AHC = require(
        GameClass:WaitForChild("EnemyClass"):WaitForChild("AbilityHandlerClass")
    )
    AHC.AbilityUsed = function(self, data)
        local ability = self.Abilities[data[1]] or self.DeathAbilities[data[1]]
        if ability then ability:AbilityUsedOnServer(data) end
    end

    EnemyClass.AbilityUsed = function(self, data)
        if self.AbilityHandler then
            self.AbilityHandler:AbilityUsed(data)
        end
    end
end

do
    local VEH = require(GameClass:WaitForChild("VisualEffectHandler"))
    local PFH = require(GameClass:WaitForChild("VisualEffectHandler")
        :WaitForChild("PartFadingHelper"))
    PFH.Fade = function() end
    PFH.Run = function() end
    VEH.NewVisualEffect = function() return DUMMY_VFX end
end

do
    local EW = require(Wrappers:WaitForChild("EmitterWrapperClass"))
    EW.PlayTriggered = function() end
    EW.PlayContinuous = function() end
    EW.PlayAll = function() end
    EW.PlayKeyframeTriggered = function() end

    local ESW = require(Wrappers:WaitForChild("EmitterAndSoundWrapperClass"))
    ESW.PlayTriggered = function() end
    ESW.PlayContinuous = function() end
    ESW.PlayAll = function() end
    ESW.PlayKeyframeTriggered = function() end
end

do
    local VSH = require(GameClass:WaitForChild("VisualSequenceHandler"))
    VSH.StartNewSequence = function() end

    local DCH = require(GameClass:WaitForChild("DropCoinsHandler"))
    if DCH then DCH.DropCoins = function() end end
end

do
    local origEnemyNew = EnemyClass.New
    EnemyClass.New = function(...)
        local enemy = origEnemyNew(...)
        if not enemy then return enemy end
        if enemy.CustomCode then
            for _, tbl in ipairs({
                enemy.CustomCode._TimingHelpers,
                enemy.CustomCode._DeathTimingHelpers,
                enemy.CustomCode._VisualHelpers,
                enemy.CustomCode._EffectHelpers
            }) do
                if tbl then
                    for name, helper in pairs(tbl) do
                        if helper and helper.Config then
                            local n = tostring(name)
                            if (n:find("Death") or n:find("Visual")
                            or n:find("Effect") or n:find("Beam")
                            or n:find("Chain") or n:find("Fade"))
                            and not n:find("Anim") then
                                helper.Config.Callback = function() end
                            end
                        end
                    end
                end
            end
        end
        return enemy
    end
end

if CONFIG_LEVEL >= 2 then

    do
        local RM = require(Common:WaitForChild("ResourceManager"))
        RM.GetEnemyModel = function(modelName, _)
            return makeEmptyModel(modelName, 2, true)
        end
        RM.GetPathEntityModel = function(modelName, _)
            return makeEmptyModel(modelName, nil, true)
        end
    end

    do
        local PEC = require(GameClass:WaitForChild("PathEntityClass"))
        for _, pe in pairs(PEC.GetPathEntities()) do
            if pe.Character then
                pe.Character.FootstepEffectWrapper = nil
                pe.Character.FootstepEffectInstanceNames = nil
                pe.Character.TurretHandler = nil
            end
            if pe.Config then
                stripEntityConfig(pe.Config)
                pe.Config.NoAnimations = true
                pe.Config.NoHead = true
            end
        end
    end

    do
        local root = ReplicatedStorage:WaitForChild("TDX_Shared")
            :WaitForChild("Common"):WaitForChild("Resources")
            :WaitForChild("CustomCode"):WaitForChild("Client")

        local safeMethods = {
            "EnemyDestroyed","PathEntityDestroyed","Run_FromCharacter",
            "AbilityUsed","AnimationStateChanged","AbilityAnimationKeyframeReached",
            "CharacterCleanedUp","SpeedMultiplierChanged_FromCharacter",
        }

        local function wrapFolder(folder)
            for _, mod in pairs(folder:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    local ok, cc = pcall(require, mod)
                    if ok and type(cc) == "table" then

                        if type(cc.Initialize) == "function" then
                            local origInit = cc.Initialize
                            cc.Initialize = function(self, enemy, cfg, ...)
                                local char = enemy and enemy.Character
                                if char and isEmptyModel(char) then
                                    return
                                end
                                return origInit(self, enemy, cfg, ...)
                            end
                        end

                        for _, m in ipairs(safeMethods) do
                            if type(cc[m]) == "function" then
                                local orig = cc[m]
                                cc[m] = function(self, ...)
                                    if self.CharacterModel == nil then return end
                                    return orig(self, ...)
                                end
                            end
                        end
                    end
                end
            end
        end

        local eCC = root:FindFirstChild("Enemy")
        if eCC then wrapFolder(eCC) end

        local pCC = root:FindFirstChild("PathEntity")
        if pCC then wrapFolder(pCC) end
    end

    do
        local AHC = require(BaseClasses:WaitForChild("AnimationHandlerClass"))
        local orig = AHC.New
        AHC.New = function(hash, charType, entityClass, config, model, ...)
            if (entityClass == "Enemy" or entityClass == "PathEntity")
            and not model:FindFirstChild("Animations") then
                return nil
            end
            return orig(hash, charType, entityClass, config, model, ...)
        end
    end

    do
        local FPHHC = require(
            BaseClasses:WaitForChild("CharacterClass")
                :WaitForChild("FirstPersonHitHandlerClass")
        )
        local dummy = {
            Hit = function() end,
            Destroy = function() end,
            Run = function() end
        }
        FPHHC.New = function() return dummy end
    end

    do
        local SW = require(Wrappers:WaitForChild("SoundWrapperClass"))
        SW.PlayTriggered = function() end
        SW.PlayContinuous = function() end
        SW.PlayAll = function() end
        SW.PlayKeyframeTriggered = function() end
    end

end
