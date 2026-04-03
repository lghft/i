wait(10)
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

repeat
    task.wait(0.1)
until ContentProvider.RequestQueueSize == 0

warn("load")

local macroFolder = "tdx/macros"
local macroFile = macroFolder .. "/endless v2.json"
local loaderURL = "https://raw.githubusercontent.com/lghft/i/refs/heads/main/tdx/macroforktest/loaderEdit.lua"
local skipWaveURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/auto_skip.lua"
local webhookScriptURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/webhook.lua"
local fpsScriptURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/fps.lua"
local blackScriptURL = "https://raw.githubusercontent.com/mmr1337/loader.lua/refs/heads/main/black.lua"
local webhookEnable = true
local webhookUrl = "https://discord.com/api/webhooks/1414475376230535199/F6V5IZJkOUMdxd-ZdC32JdlaTw-FGDz-raRMGW7a6FsYTmYtRkqOSfLy123hat3xSNR1"
local fpsBoost = false
local blackScreen = false

if not isfolder("tdx") then makefolder("tdx") end
if not isfolder(macroFolder) then makefolder(macroFolder) end

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

getgenv().TDX_Config = {
    ["mapvoting"] = "OIL RIG",
    ["Return Lobby"] = true,
    ["x1.5 Speed"] = true,
    ["loadout"] = 0,
    ["PlaceByTiming"] = false,
    ["UpgradeByTiming"] = false,
    ["Auto Skill"] = true,
    ["Map"] = "OIL RIG",
    ["Macros"] = "run",
    ["Macro Name"] = "endless v2",
    ["Auto Difficulty"] = "Endless"
}

loadstring(game:HttpGet(loaderURL))()

do
    if webhookEnable and type(webhookUrl) == "string" and webhookUrl:match("%S") then
        local env = (getgenv and getgenv()) or _G
        env.webhookConfig = env.webhookConfig or {}
        env.webhookConfig.webhookUrl = webhookUrl:gsub("^%s+", ""):gsub("%s+$", "")
        env.webhookConfig.logInventory = true
        pcall(function() loadstring(game:HttpGet(webhookScriptURL))() end)
    end
    if fpsBoost then
        pcall(function() loadstring(game:HttpGet(fpsScriptURL))() end)
    end
    if blackScreen then
        pcall(function() loadstring(game:HttpGet(blackScriptURL))() end)
        if _G.blackon then pcall(_G.blackon) end
    end
end

do
    local waveConfig = { ["WAVE 0"] = "i" }
    if readfile and isfile and isfile(macroFile) then
        local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(macroFile)) end)
        if ok and type(data) == "table" then
            for _, entry in ipairs(data) do
                if entry.SkipWave and type(entry.SkipWave) == "string" and entry.SkipWave ~= "" then
                    local w = (entry.SkipWave:gsub("^%s*(.-)%s*$", "%1")):upper()
                    if w ~= "" then waveConfig[w] = "i" end
                end
            end
        end
    end
    _G.WaveConfig = waveConfig
end

loadstring(game:HttpGet(skipWaveURL))()
