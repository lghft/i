local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

newcclosure = newcclosure or function(f) return f end
setreadonly = setreadonly or function() end
getrawmetatable = getrawmetatable or getmetatable
clonefunction = clonefunction or nil
detour_function = detour_function or nil

if not buffer then
  buffer = {
    create  = function(s) return {_d={},_s=s} end,
    writef32= function(b,o,v) b._d[o]=v end,
    writeu32= function(b,o,v) b._d[o]=v end,
    writeu8 = function(b,o,v) b._d[o]=v end,
    readf32 = function(b,o) return b._d[o] or 0 end,
    readu32 = function(b,o) return b._d[o] or 0 end,
    readu8  = function(b,o) return b._d[o] or 0 end,
  }
end

local buf_readf32 = buffer.readf32
local buf_readu32 = buffer.readu32
local buf_readu8  = buffer.readu8
local buf_writef32= buffer.writef32
local buf_writeu32= buffer.writeu32
local buf_writeu8 = buffer.writeu8

local _pairs    = pairs
local _ipairs   = ipairs
local _tostring = tostring
local _tick     = tick
local _find     = string.find
local _type     = type
local _rawget   = rawget
local _next     = next
local _huge     = math.huge
local _V3new    = Vector3.new
local _tblclear = table.clear
local _tblcreate= table.create

local LocalPlayer  = Players.LocalPlayer
local GameClass    = LocalPlayer:WaitForChild("PlayerScripts").Client.GameClass
local TowerClass   = require(GameClass:WaitForChild("TowerClass"))
local EnemyClass   = require(GameClass:WaitForChild("EnemyClass"))

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local UseAbilReq = Remotes:WaitForChild("TowerUseAbilityRequest")
local TAtk       = Remotes:WaitForChild("TowerAttack")
local TChainAtk  = Remotes:WaitForChild("TowerChainAttack")

local Common      = ReplicatedStorage:WaitForChild("TDX_Shared"):WaitForChild("Common")
local TUtils      = require(Common:WaitForChild("TowerUtilities"))
local PathHandler = require(Common:WaitForChild("PathHandler"))

local Resources           = Common:WaitForChild("Resources")
local StaticEntityConfigs = Resources:WaitForChild("StaticEntities"):WaitForChild("Configs")
local TowerBuffsConfigs   = Resources:WaitForChild("TowerBuffs")

local function getStaticEntityCfg(entityType)
  if not entityType then return nil end
  local name = _tostring(entityType):match("[^.]+$")
  local mod = name and StaticEntityConfigs:FindFirstChild(name)
  if not mod then return nil end
  local ok, cfg = pcall(require, mod)
  return ok and cfg or nil
end

local SEBCache = {}
local SEBE = {Heal=1, Attack=2, PathSpawn=3}

local function getStaticBehavior(entityType)
  local k = _tostring(entityType)
  local v = SEBCache[k]
  if v then return v end
  local cfg = getStaticEntityCfg(entityType)
  if not cfg then return nil end
  local b = cfg.MultiHealData and cfg.MultiHealData.HealAmountPerTarget and SEBE.Heal
         or cfg.SpawnPathEntitySequence and SEBE.PathSpawn
         or cfg.AttackData and SEBE.Attack
  SEBCache[k] = b
  return b
end

local BuffTypeCache = {}

local function getBuffType(buffName)
  if not buffName then return "other" end
  local k = _tostring(buffName):match("[^.]+$") or _tostring(buffName)
  local v = BuffTypeCache[k]
  if v then return v end
  local mod = TowerBuffsConfigs:FindFirstChild(k)
  local ts = "other"
  if mod then
    local ok, cfg = pcall(require, mod)
    if ok and cfg and cfg.Type then
      ts = _tostring(cfg.Type):match("[^.]+$") or "other"
    end
  end
  BuffTypeCache[k] = ts
  return ts
end

local AttackBuffCfgCache = {}

local function isAttackBuffList(buffNames)
  if _type(buffNames) ~= "table" then return false end
  for _, bn in _ipairs(buffNames) do
    local t = getBuffType(bn)
    if t == "Damage" or t == "Damage2" or t == "Firerate" then return true end
  end
  return false
end

local function cfgIsAttackBuff(cfg)
  local v = AttackBuffCfgCache[cfg]
  if v ~= nil then return v end
  v = isAttackBuffList(cfg.TowerBuffNames)
  AttackBuffCfgCache[cfg] = v
  return v
end

local MOBSTER_DELAY = 0.5

local SETTINGS = {
  SeparateLogic = {
    ["Medic"]=true, ["Mobster"]=true, ["Golden Mobster"]=true,
  },
  SkipGeneralLogic = {
    ["Helicopter"]=true, ["Cryo Helicopter"]=true, ["Combat Drone"]=true,
    ["Machine Gunner"]=true, ["Refractor"]=true, ["Psycho Slayer"]=true,
  },
  SkipAirTargeting = {
    ["Slammer"]=true, ["Mobster"]=true, ["Golden Mobster"]=true, ["Toxicnator"]=true,
  },
  SkipMedicBuff = {
    ["Refractor"]=true, ["Mine Layer"]=true, ["Golden Mine Layer"]=true,
  },
}

local Initialized     = false
local AttackTriggered = {}

local FEnemies, EProgVal, EProgPath = {}, {}, {}
local FTowers = {}
local TStunCache, TKritzCache, TRangeCache, TRangeSqCache, TDPSCache = {}, {}, {}, {}, {}
local ALCache, ACfgCache, TStealthCache = {}, {}, {}
local TPath2Cache = {}
local AUGen = 0
local AUCacheGen = {}
local AUCacheVal = {}

local ActEnemies  = _tblcreate(200)
local ActEnemiesN = 0

local PathEnds = {}
local MedicPending, MedicPendingTime = {}, {}
local MedicKritzTarget, MedicKritzTime = {}, {}
local MEDIC_TO = 0.5
local MobLastUsed = {}
local MobPendingEnemy, MobPendingTime = {}, {}
local MOB_TO = 0.4
local StealthTgtLastUsed = {}
local STEALTH_TGT_TO = 0.2
local RevealLastUsed = -_huge
local StealthPending = false
local RevealPending  = false

local Q_CAP = 64
local SQ_h  = _tblcreate(Q_CAP)
local SQ_i  = _tblcreate(Q_CAP)
local SQ_p  = _tblcreate(Q_CAP)
local SQ_th = _tblcreate(Q_CAP)
local SQ_ab = _tblcreate(Q_CAP)
local SQ_hd, SQ_tl, SQ_sz = 1, 0, 0

local MAX_E     = 200
local ES_STRIDE = 28
local ES_buf    = buffer.create(MAX_E * ES_STRIDE)
local ES_e      = _tblcreate(MAX_E)
local ESSize    = 0

local AtkQueue     = _tblcreate(64)
local AtkQueueN    = 0
local AtkQueueTime = 0

local function setTI(n)
  if setthreadidentity then setthreadidentity(n)
  elseif syn then syn.set_thread_identity(n) end
end

local TPosCache = {}

local function getTPos(tower)
  local h = tower.Hash
  local v = TPosCache[h]
  if v then return v end
  v = tower:GetPosition()
  if v then TPosCache[h] = v end
  return v
end

local function getRange(tower)
  local h = tower.Hash
  local v = TRangeCache[h]
  if v then return v end
  v = tower:GetCurrentRange()
  TRangeCache[h] = v
  TRangeSqCache[h] = v * v
  return v
end

local function getRangeSq(tower)
  local h = tower.Hash
  local v = TRangeSqCache[h]
  if v then return v end
  local r = tower:GetCurrentRange()
  TRangeCache[h] = r
  v = r * r
  TRangeSqCache[h] = v
  return v
end

local function refreshDPS(hash, tower)
  if not tower.LevelHandler then TDPSCache[hash]=0; return end
  local ls = tower.LevelHandler:GetLevelStats()
  local bs = tower.BuffHandler and tower.BuffHandler:GetStatMultipliers() or nil
  local r = TUtils.CalculateDPS(ls, bs)
  TDPSCache[hash] = _type(r)=="number" and r or 0
end

local function refreshBuffState(hash, tower)
  local bh = tower.BuffHandler
  if not bh then return end
  TStunCache[hash] = bh:IsStunned()
  local kritz = false
  for _, b in _pairs(bh.ActiveBuffs or {}) do
    if b and b.Name and _find(_tostring(b.Name), "^MedicKritz") then kritz=true; break end
  end
  TKritzCache[hash] = kritz
end

local function getDPS(tower)
  local h = tower.Hash
  local v = TDPSCache[h]
  if v then return v end
  refreshDPS(h, tower)
  return TDPSCache[h] or 0
end

local function buildAList(hash, ah)
  local map, abs = ah.AbilityIndexToNameMap, ah.Abilities
  if not map or not abs then ALCache[hash]=nil; ACfgCache[hash]=nil; return end
  local t, cfgs, anyValid = _tblcreate(3), _tblcreate(3), false
  for i = 1, 3 do
    local n = map[i]
    if not n then break end
    local ab = abs[n]
    if ab and not ab.Tower then ab = nil end
    if ab and ab.Config and ab.Config.Passive then ab = nil end
    t[i]=ab; cfgs[i]=ab and ab.Config or nil
    if ab then anyValid=true end
  end
  if not anyValid then return end
  ALCache[hash]=t; ACfgCache[hash]=cfgs
end

local function onTAdd(hash, tower)
  FTowers[hash] = tower
  local ah = tower.AbilityHandler
  if ah then buildAList(hash, ah) end
  local r = tower:GetCurrentRange()
  TRangeCache[hash] = r
  TRangeSqCache[hash] = r * r
  if tower.LevelHandler then TPath2Cache[hash] = tower.LevelHandler.Path2Level or 0 end
  TStealthCache[hash] = tower.Stealth == true
  refreshDPS(hash, tower)
  refreshBuffState(hash, tower)
end

local function onTRemove(hash)
  local al = ALCache[hash]
  if al then
    for i=1,3 do
      local ab = al[i]
      if ab then AUCacheGen[ab]=nil; AUCacheVal[ab]=nil end
    end
  end
  FTowers[hash]=nil; ALCache[hash]=nil; TStunCache[hash]=nil; TKritzCache[hash]=nil
  TDPSCache[hash]=nil; TRangeCache[hash]=nil; TRangeSqCache[hash]=nil
  TStealthCache[hash]=nil; ACfgCache[hash]=nil; TPosCache[hash]=nil
  TPath2Cache[hash]=nil; StealthTgtLastUsed[hash]=nil
end

local function onEAdd(hash, enemy)
  if enemy.IsFakeEnemy then return end
  FEnemies[hash] = enemy
  local mh = enemy.MovementHandler
  if mh then
    local pi = mh.PathIndex or 0
    EProgVal[hash]=pi+(mh.PathPercentage or 0); EProgPath[hash]=pi
  end
end

local function onERemove(hash)
  FEnemies[hash]=nil; EProgVal[hash]=nil; EProgPath[hash]=nil
end

local function hookFn(tbl, key, wrapper)
  local orig = _rawget(tbl, key) or tbl[key]
  if not orig then return end
  if clonefunction and detour_function then
    local ok, cloned = pcall(clonefunction, orig)
    if ok and cloned then
      pcall(detour_function, orig, newcclosure(function(...) return wrapper(cloned, ...) end))
      return
    end
  end
  local mt = getrawmetatable and getrawmetatable(tbl)
  if mt and setreadonly then pcall(setreadonly, mt, false) end
  tbl[key] = newcclosure(function(...) return wrapper(orig, ...) end)
end

local function hookAHC()
  local ahcPath = GameClass:FindFirstChild("TowerClass")
              and GameClass.TowerClass:FindFirstChild("AbilityHandlerClass")
  local ahc
  if ahcPath then
    local ok, m = pcall(require, ahcPath); if ok then ahc=m end
  end
  if not ahc then
    local ok, upvals = pcall(debug.getupvalues, TowerClass.New)
    if ok and upvals then
      for _, v in _pairs(upvals) do
        if _type(v)=="table" and _rawget(v,"_GenerateAbilities") then ahc=v; break end
      end
    end
  end
  if not ahc and filtergc then
    local candidates = filtergc("table", {keys=true})
    if candidates then
      for _, v in _ipairs(candidates) do
        if _rawget(v,"_GenerateAbilities") and _rawget(v,"SetTower") then ahc=v; break end
      end
    end
  end
  if not ahc then return false end

  hookFn(ahc, "SetTower", function(orig, self, tower, ...)
    orig(self, tower, ...)
    if tower and tower.Hash then buildAList(tower.Hash, self); AUGen=AUGen+1 end
  end)

  local ahcPath2 = ahcPath and ahcPath:FindFirstChild("AbilityClass")
  local ac
  if ahcPath2 then
    local ok, m = pcall(require, ahcPath2); if ok then ac=m end
  end
  if not ac then
    local ok, upvals = pcall(debug.getupvalues, ahc._GenerateAbilities)
    if ok and upvals then
      for _, v in _pairs(upvals) do
        if _type(v)=="table" and _rawget(v,"BeginCooldown") and _rawget(v,"CanUse") then ac=v; break end
      end
    end
  end
  if not ac and filtergc then
    local candidates = filtergc("table", {keys=true})
    if candidates then
      for _, v in _ipairs(candidates) do
        if _rawget(v,"BeginCooldown") and _rawget(v,"CanUse") and _rawget(v,"Use") then ac=v; break end
      end
    end
  end
  if ac then
    hookFn(ac, "BeginCooldown", function(orig, ab, ...)
      orig(ab, ...)
      AUCacheGen[ab]=AUGen; AUCacheVal[ab]=false
    end)

    -- Guard GetTowerRebuilding khỏi nil crash khi AbilityHotbarHandler refresh
    -- trước khi SetTower hoàn tất (race condition khi chạy 3 script cùng lúc).
    -- Phải trả TRUE khi Tower = nil để CanUse() → false → game không gọi Tower:GetPosition()
    hookFn(ac, "GetTowerRebuilding", function(orig, ab, ...)
      if not ab.Tower then return true end
      return orig(ab, ...)
    end)

  end
  return true
end

local function updateBuffCache(tower)
  local hash = tower and tower.Hash
  if not hash then return end
  TRangeCache[hash]=nil; TRangeSqCache[hash]=nil; TDPSCache[hash]=nil
  refreshBuffState(hash, tower)
  refreshDPS(hash, tower)
end

local function hookTC()
  hookFn(TowerClass, "New", function(orig, ...)
    local tower = orig(...)
    if tower and tower.Hash then onTAdd(tower.Hash, tower) end
    return tower
  end)
  hookFn(TowerClass, "Destroy", function(orig, tower, ...)
    local hash = tower and tower.Hash
    -- NOTE: Không set ab.Tower = nil ở đây vì AbilityHotbarHandler của game
    -- vẫn còn giữ reference đến ability object và có thể gọi CanUse() →
    -- GetTowerRebuilding() → Tower:Alive() trong cùng frame → crash nil.
    -- Game tự cleanup Tower reference sau khi orig() hoàn tất.
    orig(tower, ...); if hash then onTRemove(hash) end
  end)
  hookFn(TowerClass, "ApplyBuffData",  function(orig, tower, ...) orig(tower, ...); updateBuffCache(tower) end)
  hookFn(TowerClass, "RemoveBuffData", function(orig, tower, ...) orig(tower, ...); updateBuffCache(tower) end)
  hookFn(TowerClass, "SetStealth", function(orig, tower, stealth, ...)
    orig(tower, stealth, ...)
    local hash = tower and tower.Hash
    if hash then TStealthCache[hash]=stealth==true end
  end)
  hookFn(TowerClass, "Upgrade", function(orig, tower, ...)
    if not tower then return orig(tower, ...) end
    local hash = tower.Hash
    local ok = pcall(orig, tower, ...)
    if ok and hash then
      TRangeCache[hash]=nil; TRangeSqCache[hash]=nil; TDPSCache[hash]=nil
      local lh = tower.LevelHandler
      if lh then TPath2Cache[hash] = lh.Path2Level or 0 end
      local ah = tower.AbilityHandler
      if ah then buildAList(hash, ah) end
    end
  end)
end

local function hookEC()
  hookFn(EnemyClass, "New", function(orig, ...)
    local ok, enemy = pcall(orig, ...)
    if not ok or not enemy then return nil end
    if enemy.Hash then onEAdd(enemy.Hash, enemy) end
    return enemy
  end)
  hookFn(EnemyClass, "Destroy", function(orig, enemy, ...)
    local hash = enemy and enemy.Hash
    pcall(orig, enemy, ...); if hash then onERemove(hash) end
  end)
end

local function hookPaths()
  if _type(PathHandler) ~= "table" then return end
  local ok, positions = pcall(function()
    return PathHandler.GetEndNodePositions and PathHandler.GetEndNodePositions()
  end)
  if ok and _type(positions)=="table" then
    for i, pos in _ipairs(positions) do PathEnds[i]=pos end
  end
end

local function populate()
  local rawE = EnemyClass.GetEnemies()
  if rawE then
    for hash, enemy in _pairs(rawE) do
      if enemy and not enemy.IsFakeEnemy and enemy.IsAlive then onEAdd(hash, enemy) end
    end
  end
  local rawT = TowerClass.GetTowers()
  if rawT then
    for hash, tower in _pairs(rawT) do if tower then onTAdd(hash, tower) end end
  end
end

local function snapEnemies()
  local n = 0
  for _, e in _pairs(FEnemies) do
    if e.IsAlive then n=n+1; ActEnemies[n]=e end
  end
  for i = n+1, ActEnemiesN do ActEnemies[i]=nil end
  ActEnemiesN = n
end

local function isUsable(ab)
  if not ab then return false end
  if AUCacheGen[ab]==AUGen then return AUCacheVal[ab] end
  if not ab.Tower then
    AUCacheGen[ab]=AUGen; AUCacheVal[ab]=false
    return false
  end
  local r
  if ab.Config and ab.Config.HotbarData then
    r = (ab.CooldownRemaining or 0) <= 0
  else
    r = ab:CanUse()
  end
  AUCacheGen[ab]=AUGen; AUCacheVal[ab]=r
  return r
end

local function hasUsable(al)
  if not al then return false end
  for i = 1, 3 do
    local ab = al[i]
    if ab==nil then break end
    if isUsable(ab) then return true end
  end
  return false
end

local function useAb(ab)
  AUCacheGen[ab]=AUGen; AUCacheVal[ab]=false
  if not ab:Use() then AUCacheGen[ab]=nil; AUCacheVal[ab]=nil end
end

local function enqueue(hash, index, pos, targetHash)
  local al = ALCache[hash]
  local ab = al and al[index]
  if ab then
    if not ab.Tower or not ab:CanUse() then return end
    AUCacheGen[ab]=AUGen; AUCacheVal[ab]=false
  end
  if SQ_sz >= Q_CAP then return end
  SQ_tl = SQ_tl % Q_CAP + 1
  SQ_h[SQ_tl]=hash; SQ_i[SQ_tl]=index; SQ_p[SQ_tl]=pos
  SQ_th[SQ_tl]=targetHash; SQ_ab[SQ_tl]=ab
  SQ_sz = SQ_sz + 1
end

local function cachePaths()
  if not _next(PathEnds) then hookPaths() end
end

local function getEnemyAttackRange(e)
  local ah = e.AttackHandler
  if ah then
    local r = ah.AttackRange or ah.Range
    if r then return r end
  end
  local abh = e.AbilityHandler
  if abh then
    if abh.AttackRange then return abh.AttackRange end
    local abs = abh.Abilities
    if _type(abs) == "table" then
      for _, ab in _pairs(abs) do
        if ab and ab.Config then
          local r = ab.Config.AttackRange
                 or ab.Config.ManualAimCustomRange
                 or ab.Config.EffectRadius
          if r then return r end
        end
      end
    end
  end
  return nil
end

local function buildESnap(enemies)
  local n = 0
  for _, e in _ipairs(enemies) do
    local ep = e:GetPosition()
    if not ep then continue end
    local hash = e.Hash
    local mh = e.MovementHandler
    if mh then
      local pi = mh.PathIndex or 0
      EProgVal[hash]  = pi + (mh.PathPercentage or 0)
      EProgPath[hash] = pi
    end
    local base = n * ES_STRIDE
    buf_writef32(ES_buf, base,    ep.X)
    buf_writef32(ES_buf, base+4,  ep.Z)
    local hh = e.HealthHandler
    buf_writef32(ES_buf, base+8,  hh and hh:GetMaxHealth() or 0)
    buf_writef32(ES_buf, base+12, EProgVal[hash] or 0)
    local bd = e.BountyDisplayHandler
    buf_writeu32(ES_buf, base+16, bd and bd.BountyCount or 0)
    buf_writeu8 (ES_buf, base+20, e.IsAirUnit and 1 or 0)
    buf_writeu8 (ES_buf, base+21, e.Stealth and 1 or 0)
    local ear = getEnemyAttackRange(e) or 0
    buf_writeu8 (ES_buf, base+22, ear > 0 and 1 or 0)
    buf_writef32(ES_buf, base+24, ear)
    n=n+1; ES_e[n]=e
  end
  for i = n+1, ESSize do ES_e[i]=nil end
  ESSize = n
end

local function getFarEnemy(pos, range, noAir)
  local rsq = range*range
  local px, pz = pos.X, pos.Z
  local best, bestPrg = nil, -1
  local base = 0
  for i = 0, ESSize-1 do
    if noAir and buf_readu8(ES_buf,base+20)==1 then base=base+ES_STRIDE; continue end
    local dx = buf_readf32(ES_buf,base)   - px
    local dz = buf_readf32(ES_buf,base+4) - pz
    if dx*dx+dz*dz <= rsq then
      local prg = buf_readf32(ES_buf,base+12)
      if prg > bestPrg then bestPrg=prg; best=base end
    end
    base = base + ES_STRIDE
  end
  if best then
    return _V3new(buf_readf32(ES_buf,best), 0, buf_readf32(ES_buf,best+4))
  end
end

local function getStrongEnemy(pos, range, noAir)
  local rsq = range*range
  local px, pz = pos.X, pos.Z
  local best, bestHP = nil, -1
  local base = 0
  for i = 0, ESSize-1 do
    if noAir and buf_readu8(ES_buf,base+20)==1 then base=base+ES_STRIDE; continue end
    local dx = buf_readf32(ES_buf,base)   - px
    local dz = buf_readf32(ES_buf,base+4) - pz
    if dx*dx+dz*dz <= rsq then
      local hp = buf_readf32(ES_buf,base+8)
      if hp > bestHP then bestHP=hp; best=base end
    end
    base = base + ES_STRIDE
  end
  if best then
    return _V3new(buf_readf32(ES_buf,best), 0, buf_readf32(ES_buf,best+4))
  end
end

local function getRelicTgt()
  local bestPrg, bestPath = -1, 1
  local base = 0
  for i = 0, ESSize-1 do
    if buf_readu8(ES_buf,base+20)==0 then
      local prg = buf_readf32(ES_buf,base+12)
      if prg > bestPrg then
        bestPrg = prg
        local e = ES_e[i+1]
        local pi = e and (EProgPath[e.Hash] or 1) or 1
        if pi >= 1 then bestPath=pi end
      end
    end
    base = base + ES_STRIDE
  end
  local ok, endNode = pcall(PathHandler.GetEnd, bestPath)
  if ok and endNode then return endNode.Position end
  return PathEnds[1]
end

local function getHealDroneTgt(selfHash)
  local best, bestScore = nil, -1
  for h, t in _pairs(FTowers) do
    if not t.IsAlive then continue end
    local hh = t.HealthHandler
    if not hh then continue end
    local hp, maxHp = hh:GetHealth(), hh:GetMaxHealth()
    if maxHp <= 0 or hp >= maxHp then continue end
    local tp = getTPos(t)
    if not tp then continue end
    local score = (TDPSCache[h] or getDPS(t)) * (1 - hp/maxHp)
    if score > bestScore then bestScore=score; best=tp end
  end
  return best
end

local function hasStealthInRange(pos, radius)
  local rsq = radius*radius
  local px, pz = pos.X, pos.Z
  local base = 0
  for i = 0, ESSize-1 do
    if buf_readu8(ES_buf,base+21)==1 then
      local dx = buf_readf32(ES_buf,base)   - px
      local dz = buf_readf32(ES_buf,base+4) - pz
      if dx*dx+dz*dz <= rsq then return true end
    end
    base = base + ES_STRIDE
  end
  return false
end

local function getBestStealthTgt(selfHash, now)
  if ESSize == 0 then return nil end
  local bestHash, bestDPS = nil, -1
  for h, t in _pairs(FTowers) do
    if not t.IsAlive or TStealthCache[h] then continue end
    local last = StealthTgtLastUsed[h]
    if last and now - last < STEALTH_TGT_TO then continue end
    local tp = getTPos(t)
    if not tp then continue end
    local dps = TDPSCache[h] or getDPS(t)
    if dps > bestDPS then bestDPS=dps; bestHash=h end
  end
  return bestHash
end

local function markStealthSplash(tPos, now, splashRadius)
  local sr2 = splashRadius * splashRadius
  local tx, tz = tPos.X, tPos.Z
  for h2, t2 in _pairs(FTowers) do
    if not t2.IsAlive then continue end
    local tp2 = getTPos(t2)
    if not tp2 then continue end
    local dx = tp2.X - tx
    local dz = tp2.Z - tz
    if dx*dx + dz*dz <= sr2 then
      StealthTgtLastUsed[h2] = now
    end
  end
end

local function getStealthTgtPos(hash, now, splashRadius)
  local th = getBestStealthTgt(hash, now)
  if not th then return nil end
  local tPos = getTPos(FTowers[th])
  if not tPos then return nil end
  if splashRadius and splashRadius > 0 then
    markStealthSplash(tPos, now, splashRadius)
  else
    StealthTgtLastUsed[th] = now
  end
  return tPos
end

local function checkTowers(selfHash, pos, radius, checkHeal, checkStun, selfOnly)
  if selfOnly then
    local t = FTowers[selfHash]
    if not t then return false end
    if checkHeal then
      local hh = t.HealthHandler
      if hh and hh:GetHealth() < hh:GetMaxHealth() then return true end
    end
    return checkStun and TStunCache[selfHash] or false
  end
  local rsq = radius and radius*radius
  local px = pos and pos.X or 0
  local pz = pos and pos.Z or 0
  for h, t in _pairs(FTowers) do
    if not t.IsAlive then continue end
    if rsq then
      local tp = getTPos(t)
      if not tp then continue end
      local dx=tp.X-px; local dz=tp.Z-pz
      if dx*dx+dz*dz > rsq then continue end
    end
    if checkHeal then
      local hh = t.HealthHandler
      if hh and hh:GetHealth() < hh:GetMaxHealth() then return true end
    end
    if checkStun and TStunCache[h] then return true end
  end
  return false
end

local function getMedicTgt(medicTower, medicHash)
  local medicPos = getTPos(medicTower)
  if not medicPos then return nil end
  local mrsq = getRangeSq(medicTower)
  local bestHash, bestDPS = nil, -1
  local mpx, mpz = medicPos.X, medicPos.Z
  for hash, tower in _pairs(FTowers) do
    if hash==medicHash or not tower.IsAlive then continue end
    if SETTINGS.SkipMedicBuff[tower.Type or ""] or TKritzCache[hash]==true then continue end
    local tp = getTPos(tower)
    if not tp then continue end
    local dx=tp.X-mpx; local dz=tp.Z-mpz
    if dx*dx+dz*dz > mrsq then continue end
    local dps = TDPSCache[hash] or getDPS(tower)
    if dps > bestDPS then bestDPS=dps; bestHash=hash end
  end
  return bestHash
end

local function getCMedicTgtIfNeeded(hash)
  local best, bestDPS = nil, -1
  for h, t in _pairs(FTowers) do
    if h==hash or not t.IsAlive then continue end
    if t.v10 and t.v10.NoHeal then continue end
    local hh = t.HealthHandler
    if not hh or hh:GetHealth() >= hh:GetMaxHealth() then continue end
    local tp = getTPos(t)
    if not tp then continue end
    local dps = TDPSCache[h] or getDPS(t)
    if dps > bestDPS then bestDPS=dps; best=tp end
  end
  return best
end

local function getMobTgt(tower, now)
  local pos = getTPos(tower)
  if not pos then return nil end
  local rsq = getRangeSq(tower)
  local px, pz = pos.X, pos.Z
  if _next(MobPendingEnemy) then
    for id in _pairs(MobPendingEnemy) do
      local e = MobPendingEnemy[id]
      if (e and e.BountyDisplayHandler and e.BountyDisplayHandler.BountyCount>0)
      or now-MobPendingTime[id]>MOB_TO or not (e and e.IsAlive) then
        MobPendingEnemy[id]=nil; MobPendingTime[id]=nil
      end
    end
  end
  local bE, bHP, bPrg = nil, -1, -1
  local base = 0
  for i = 0, ESSize-1 do
    if buf_readu8(ES_buf,base+20)==0 and buf_readu32(ES_buf,base+16)==0 then
      local id = _tostring(ES_e[i+1])
      if not MobPendingEnemy[id] then
        local dx = buf_readf32(ES_buf,base)   - px
        local dz = buf_readf32(ES_buf,base+4) - pz
        if dx*dx+dz*dz <= rsq then
          local hp  = buf_readf32(ES_buf,base+8)
          local prg = buf_readf32(ES_buf,base+12)
          if hp>bHP or (hp==bHP and prg>bPrg) then bHP=hp; bPrg=prg; bE=ES_e[i+1] end
        end
      end
    end
    base = base + ES_STRIDE
  end
  return bE
end

local function procMobster(tower, hash, now)
  local al = ALCache[hash]
  if not hasUsable(al) then return end
  if MobLastUsed[hash] and now-MobLastUsed[hash] < MOBSTER_DELAY then return end
  for i = 1, 3 do
    local ab = al[i]
    if isUsable(ab) then
      local e = getMobTgt(tower, now)
      if e then
        local ep = e:GetPosition()
        if ep then
          enqueue(hash, i, ep, nil)
          local id = _tostring(e)
          MobPendingEnemy[id]=e; MobPendingTime[id]=now
          MobLastUsed[hash]=now
          break
        end
      end
    end
  end
end

local function getManualAimPos(cfg, pos, range)
  if cfg.ManualAimInfiniteRange then return getRelicTgt() end
  return getFarEnemy(pos, cfg.ManualAimCustomRange or range, false)
end

local function hasTowerAttackingInRange(selfHash, pos, radius)
  local rsq = radius*radius
  local px, pz = pos.X, pos.Z
  for h, t in _pairs(FTowers) do
    if h==selfHash or not t.IsAlive then continue end
    local tp = getTPos(t)
    if not tp then continue end
    local dx=tp.X-px; local dz=tp.Z-pz
    if dx*dx+dz*dz <= rsq then
      local trsq = getRangeSq(t)
      local tx, tz = tp.X, tp.Z
      local base = 0
      for ei = 0, ESSize-1 do
        local ex = buf_readf32(ES_buf,base)   - tx
        local ez = buf_readf32(ES_buf,base+4) - tz
        if ex*ex+ez*ez <= trsq then return true end
        base = base + ES_STRIDE
      end
    end
  end
  return false
end

local function procGeneric(tower, hash, now)
  local al = ALCache[hash]
  if not hasUsable(al) then return end
  local cfgs = ACfgCache[hash]
  if not cfgs then return end

  local pos   = getTPos(tower)
  local range = getRange(tower)

  for i = 1, 3 do
    local ab = al[i]
    if not ab or not isUsable(ab) then continue end
    local cfg = cfgs[i]
    if not cfg then continue end

    local tPos, allow = nil, false

    if cfg.SpawnStaticEntityData then
      local sed = cfg.SpawnStaticEntityData
      local entry = (_type(sed)=="table" and sed[1]) and sed[1] or sed
      local entityType = entry and (entry.StaticEntityType or entry.Name)
      local beh = entityType and getStaticBehavior(entityType)
      if beh == SEBE.Heal then
        if MedicPendingTime[hash] then
          if now-MedicPendingTime[hash] > MEDIC_TO then
            MedicPending[hash]=nil; MedicPendingTime[hash]=nil
          end
        end
        if not MedicPendingTime[hash] then
          local th = getCMedicTgtIfNeeded(hash)
          if th then
            enqueue(hash, i, th, nil)
            MedicPending[hash]=true; MedicPendingTime[hash]=now
            break
          end
        end
      elseif beh==SEBE.Attack or beh==SEBE.PathSpawn then
        if cfg.IsManualAimAtPath or cfg.IsManualAimAtGround then
          tPos=getManualAimPos(cfg, pos, range); allow=tPos~=nil
        else
          allow = ESSize > 0
        end
      end
    end

    if cfg.SpawnPathEntityData and ESSize > 0 then
      if cfg.IsManualAimAtPath then
        tPos=getManualAimPos(cfg, pos, range); allow=tPos~=nil
      else
        allow = true
      end
    end

    if not allow and cfg.HasRevealEffect and pos then
      local radius = cfg.UseTowerRangeForRadius and range or (cfg.EffectRadius or range)
      allow = hasStealthInRange(pos, radius)
    end

    if cfg.ProjectileHitDataAffectTowers then
      local phd = cfg.ProjectileHitData
      if phd and phd.TowerStealthDuration then
        if not StealthPending then
          local sr = phd.SplashRadius or 0
          local tp2 = getStealthTgtPos(hash, now, sr)
          if tp2 then
            StealthPending = true
            task.defer(function() StealthPending = false end)
            enqueue(hash, i, tp2, nil)
            break
          end
        end
      elseif not allow then
        allow = ESSize > 0
        if allow and (cfg.IsManualAimAtGround or cfg.IsManualAimAtPath) then
          tPos=getManualAimPos(cfg, pos, range); allow=tPos~=nil
        end
      end
    end

    if not allow and cfg.RadiusDamage and cfg.EffectRadius and pos then
      local rsq = cfg.EffectRadius * cfg.EffectRadius
      local px, pz = pos.X, pos.Z
      local base = 0
      for ei = 0, ESSize-1 do
        local dx = buf_readf32(ES_buf,base)   - px
        local dz = buf_readf32(ES_buf,base+4) - pz
        if dx*dx+dz*dz <= rsq then allow=true; break end
        base = base + ES_STRIDE
      end
    end

    if not allow and cfg.ProjectileHitData and not cfg.ProjectileHitDataAffectTowers then
      local phd = cfg.ProjectileHitData
      if phd.IsSplash or phd.SpawnStaticEntityData then
        if cfg.IsManualAimAtPath or cfg.IsManualAimAtGround then
          tPos=getManualAimPos(cfg, pos, range); allow=tPos~=nil
        elseif pos then
          tPos=getFarEnemy(pos, range, false); allow=tPos~=nil
        end
      end
    end

    if not allow and cfg.HasRadiusEffect and pos then
      local radius = cfg.UseTowerRangeForRadius and range or (cfg.EffectRadius or range)
      if cfg.HealPercentage or cfg.HealAmount or cfg.Unstun then
        allow = checkTowers(hash, pos, radius,
          cfg.HealPercentage~=nil or cfg.HealAmount~=nil,
          cfg.Unstun==true, cfg.TargetSelf==true)
      elseif cfg.TowerBuffNames then
        if cfg.UseTowerRangeForRadius and cfgIsAttackBuff(cfg) then
          allow = hasTowerAttackingInRange(hash, pos, radius)
        else
          allow = true
        end
      end
    end

    if allow then enqueue(hash, i, tPos, nil); break end
  end
end

local function procAttack(attackHash, now)
  local atTower = FTowers[attackHash]
  if not atTower then return end
  local atPos = getTPos(atTower)
  if not atPos then return end
  local atX, atZ = atPos.X, atPos.Z

  for hash, tower in _pairs(FTowers) do
    if hash==attackHash or not tower.IsAlive then continue end
    local tp = getTPos(tower)
    if not tp then continue end
    local dx=tp.X-atX; local dz=tp.Z-atZ
    if dx*dx+dz*dz > getRangeSq(tower) then continue end
    local al = ALCache[hash]
    if not al then continue end
    local cfgs = ACfgCache[hash]

    if cfgs then
      for i = 1, 3 do
        local ab, cfg = al[i], cfgs[i]
        if not ab or not cfg then break end
        if cfg.HasRadiusEffect and cfg.TowerBuffNames
        and not (cfg.HealPercentage or cfg.HealAmount or cfg.Unstun)
        and cfgIsAttackBuff(cfg) and isUsable(ab) then
          AttackTriggered[hash] = true
          break
        end
      end
    end

    if tower.Type == "Medic" then
      local p2 = TPath2Cache[hash] or 0
      if p2 < 4 then continue end
      if MedicKritzTarget[hash] then
        local targetTower = MedicKritzTarget[hash]
        local timedOut = now-MedicKritzTime[hash] > MEDIC_TO
        local buffed = targetTower and targetTower.IsAlive and TKritzCache[targetTower.Hash]==true
        if buffed or timedOut then
          MedicKritzTarget[hash]=nil; MedicKritzTime[hash]=nil
        else
          continue
        end
      end
      for i = 1, 3 do
        local ab = al[i]
        if not ab then break end
        if isUsable(ab) then
          local th = getMedicTgt(tower, hash)
          if th then
            enqueue(hash, i, nil, th)
            MedicKritzTarget[hash]=FTowers[th]; MedicKritzTime[hash]=now
            break
          end
        end
      end
    end
  end
end

TAtk.OnClientEvent:Connect(newcclosure(function(data)
  if not Initialized or not _next(FTowers) then return end
  AtkQueueTime = _tick()
  for _, d in _ipairs(data) do
    if d and d.X then AtkQueueN=AtkQueueN+1; AtkQueue[AtkQueueN]=d.X end
  end
end))

TChainAtk.OnClientEvent:Connect(newcclosure(function(data)
  if not Initialized or not _next(FTowers) then return end
  AtkQueueTime = _tick()
  for _, d in _ipairs(data) do
    if d and d[1] then AtkQueueN=AtkQueueN+1; AtkQueue[AtkQueueN]=d[1] end
  end
end))

local _HBTick = 0
RunService.Heartbeat:Connect(newcclosure(function()
  _HBTick = _HBTick + 1
  if not Initialized or not _next(FTowers) then return end

  local doSnap = _HBTick % 2 == 0
  local doMain = _HBTick % 5 == 0
  if not doSnap and not doMain then return end

  local now = _tick()

  if doSnap then
    for k, e in _pairs(FEnemies) do if not e.IsAlive then onERemove(k) end end
    snapEnemies(); cachePaths(); buildESnap(ActEnemies)
    if AtkQueueN > 0 then
      local now2 = AtkQueueTime
      for i = 1, AtkQueueN do procAttack(AtkQueue[i], now2); AtkQueue[i]=nil end
      AtkQueueN = 0
    end
  end

  if not doMain then return end

  AUGen = AUGen + 1
  _tblclear(TPosCache)

  local revealFired   = false
  local stealthExists = false
  do
    local base = 0
    for i = 0, ESSize-1 do
      if buf_readu8(ES_buf, base+21)==1 then stealthExists=true; break end
      base = base + ES_STRIDE
    end
  end

  for hash, tower in _pairs(FTowers) do
    if not tower.IsAlive then continue end
    local tType = tower.Type
    if SETTINGS.SkipGeneralLogic[tType] then continue end

    local al   = ALCache[hash]
    local cfgs = ACfgCache[hash]
    if not hasUsable(al) then continue end

    if SETTINGS.SeparateLogic[tType] then
      if tType == "Medic" then continue end
      local p2 = TPath2Cache[hash] or 0
      if (tType=="Mobster" or tType=="Golden Mobster") and p2>=3 and p2<=5 then
        procMobster(tower, hash, now)
      else
        procGeneric(tower, hash, now)
      end
      continue
    end

    local pos   = getTPos(tower)
    local range = pos and getRange(tower)
    local noAir = SETTINGS.SkipAirTargeting[tType]
    local atkFired = AttackTriggered[hash]

    if tType == "Jet Trooper" then
      local ab = al and al[2]
      if ab and isUsable(ab) then useAb(ab) end
      continue
    end

    if tType == "Toxicnator" then
      if pos then
        for i = 1, 3 do
          local ab = al[i]
          if ab and isUsable(ab) then
            local tPos = getStrongEnemy(pos, range, noAir)
            if tPos then enqueue(hash, i, tPos, nil) end
            break
          end
        end
      end
      continue
    end

    local needsGeneralLogic = false
    for idx = 1, 3 do
      local ab, cfg = al[idx], cfgs and cfgs[idx]
      if not ab or not cfg then break end
      if not isUsable(ab) then continue end

      if cfg.HasRadiusEffect and cfg.TowerBuffNames and cfgIsAttackBuff(cfg)
      and not cfg.HealPercentage and not cfg.HealAmount and not cfg.Unstun then
        if atkFired then
          AttackTriggered[hash] = nil; atkFired = nil
          enqueue(hash, idx, nil, nil)
        end
        continue
      end

      if cfg.HasRadiusEffect and (cfg.HealPercentage or cfg.HealAmount or cfg.Unstun) then
        if pos then
          local radius = cfg.UseTowerRangeForRadius and range or (cfg.EffectRadius or range)
          if checkTowers(hash, pos, radius,
            cfg.HealPercentage~=nil or cfg.HealAmount~=nil,
            cfg.Unstun==true, cfg.TargetSelf==true) then
            enqueue(hash, idx, nil, nil)
          end
        end
        continue
      end

      if cfg.SpawnPathEntityData
      and not cfg.IsManualAimAtGround and not cfg.IsManualAimAtPath and not cfg.ManualAimInfiniteRange then
        enqueue(hash, idx, nil, nil)
        continue
      end

      if cfg.HasRevealEffect then
        if not revealFired and not RevealPending and stealthExists and now-RevealLastUsed >= (cfg.Delay or 0) then
          local radius = cfg.UseTowerRangeForRadius and range or (cfg.EffectRadius or range)
          if pos and hasStealthInRange(pos, radius) then
            revealFired=true; RevealLastUsed=now
            RevealPending = true
            task.defer(function() RevealPending = false end)
            enqueue(hash, idx, nil, nil)
          end
        end
        continue
      end

      needsGeneralLogic = true
    end

    if not needsGeneralLogic then continue end
    if not pos then continue end
    if ESSize == 0 then
      local hasHealDrone = false
      for idx = 1, 3 do
        local cfg = cfgs and cfgs[idx]
        if cfg and cfg.SpawnStaticEntityData and cfg.IsManualAimAtGround then
          local ssd = cfg.SpawnStaticEntityData
          if _type(ssd)=="table" then
            for _, e in _ipairs(ssd) do
              if e.StaticEntityType and getStaticBehavior(e.StaticEntityType)==SEBE.Heal then
                hasHealDrone=true; break
              end
            end
          end
        end
        if hasHealDrone then break end
      end
      if not hasHealDrone then continue end
    end

    for idx = 1, 3 do
      local ab, cfg = al[idx], cfgs and cfgs[idx]
      if not ab or not cfg then break end
      if not isUsable(ab) then continue end
      if cfg.HasRadiusEffect or cfg.HasRevealEffect
      or (cfg.SpawnPathEntityData and not cfg.IsManualAimAtGround and not cfg.IsManualAimAtPath) then
        continue
      end

      local cr     = cfg.RadiusDamage and cfg.EffectRadius or range
      local tPos   = nil
      local allow  = true
      local needPos = cfg.IsManualAimAtGround or cfg.IsManualAimAtPath or cfg.ManualAimInfiniteRange
      if needPos then
        local useStealthTgt = cfg.ProjectileHitDataAffectTowers
                           and cfg.ProjectileHitData
                           and cfg.ProjectileHitData.TowerStealthDuration
        if useStealthTgt then
          if not StealthPending then
            local sr = cfg.ProjectileHitData.SplashRadius or 0
            local tPos2 = getStealthTgtPos(hash, now, sr)
            if tPos2 then
              StealthPending = true
              task.defer(function() StealthPending = false end)
              enqueue(hash, idx, tPos2, nil)
            end
          end
          allow = false
        else
          local inf = cfg.ManualAimInfiniteRange
          local spawnsHeal, spawnsPath = false, false
          if cfg.SpawnStaticEntityData and _type(cfg.SpawnStaticEntityData)=="table" then
            for _, e in _ipairs(cfg.SpawnStaticEntityData) do
              local b = e.StaticEntityType and getStaticBehavior(e.StaticEntityType)
              if b == SEBE.Heal then spawnsHeal=true
              elseif b == SEBE.PathSpawn then spawnsPath=true end
            end
          end
          if not spawnsHeal and not spawnsPath
          and cfg.ProjectileHitData and _type(cfg.ProjectileHitData.SpawnStaticEntityData)=="table" then
            local entry = cfg.ProjectileHitData.SpawnStaticEntityData
            local entityType = entry.StaticEntityType or entry.Name
            local b = entityType and getStaticBehavior(entityType)
            if b == SEBE.PathSpawn then spawnsPath=true
            elseif b == SEBE.Heal then spawnsHeal=true end
          end
          if spawnsHeal then
            tPos = getHealDroneTgt(hash)
          elseif spawnsPath then
            tPos = inf and getRelicTgt() or getFarEnemy(pos, cfg.ManualAimCustomRange or cr, noAir)
          elseif inf then
            tPos = getFarEnemy(pos, _huge, noAir)
          else
            tPos = getFarEnemy(pos, cfg.ManualAimCustomRange or cr, noAir)
          end
          allow = tPos ~= nil
        end
      else
        local rsq = cr*cr
        local px, pz = pos.X, pos.Z
        allow = false
        local base = 0
        for i = 0, ESSize-1 do
          if noAir and buf_readu8(ES_buf,base+20)==1 then base=base+ES_STRIDE; continue end
          local dx = buf_readf32(ES_buf,base)   - px
          local dz = buf_readf32(ES_buf,base+4) - pz
          if dx*dx+dz*dz <= rsq then allow=true; break end
          base = base + ES_STRIDE
        end
      end

      if allow then
        if tPos then enqueue(hash, idx, tPos, nil) else useAb(ab) end
      end
    end
  end
end))

task.spawn(function()
  setTI(2)
  repeat task.wait(0.1) until EnemyClass.GetEnemies() and TowerClass.GetTowers()
  populate()
  hookTC(); hookEC(); hookAHC()
  snapEnemies()
  Initialized = true
end)

task.spawn(function()
  setTI(2)
  while true do
    if SQ_sz > 0 then
      local h = SQ_hd
      local ok, serverCooldown = UseAbilReq:InvokeServer(SQ_h[h], SQ_i[h], SQ_p[h], SQ_th[h])
      local ab = SQ_ab[h]
      SQ_h[h]=nil; SQ_p[h]=nil; SQ_th[h]=nil; SQ_ab[h]=nil
      SQ_hd = h % Q_CAP + 1
      SQ_sz = SQ_sz - 1
      if ab then
        if ok and serverCooldown then
          ab:BeginCooldown()
          ab.CooldownRemaining = serverCooldown
        elseif not ok then
          ab.CooldownRemaining = 0
          AUCacheGen[ab]=AUGen; AUCacheVal[ab]=nil
        end
      end
    end
    task.wait(0.03)
  end
end)
