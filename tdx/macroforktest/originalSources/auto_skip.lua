local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local Config = { CheDoDebug = true }

if not _G.WaveConfig or type(_G.WaveConfig) ~= "table" then
    error("please assign _G.WaveConfig before running the script!")
end

local function debugPrint(...)
    if Config.CheDoDebug then print(...) end
end

local SkipEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkipWaveVoteCast")
local TDX_Shared = ReplicatedStorage:WaitForChild("TDX_Shared")
local Common = TDX_Shared:WaitForChild("Common")
local NetworkingHandler = require(Common:WaitForChild("NetworkingHandler"))

NetworkingHandler.GetEvent("SkipWaveVoteStateUpdate"):AttachCallback(function(data)
    if not data or not data.VotingEnabled then return end

    local waveText = PlayerGui.Interface.GameInfoBar.Default.Wave.WaveText.Text
    local waveName = string.upper(waveText):gsub("^%s*(.-)%s*$", "%1")

    local configValue = _G.WaveConfig[waveName]

    if configValue ~= nil then
        if configValue == 0 then
            return
        end

        if configValue == "i" or configValue == "now" then
            debugPrint("skip instantly:", waveName)
            SkipEvent:FireServer(true)
            return
        end

        if tonumber(configValue) then
            local number = tonumber(configValue)

            local mins = math.floor(number / 100)
            local secs = number % 100
            local targetTimeStr = string.format("%02d:%02d", mins, secs)

            local currentTime = PlayerGui.Interface.GameInfoBar.Default.TimeLeft.TimeLeftText.Text

            local function normalize(t)
                local m, s = t:match("(%d+):(%d+)")
                if not m then return t end
                return tostring(tonumber(m)) .. ":" .. string.format("%02d", tonumber(s))
            end

            if normalize(currentTime) == normalize(targetTimeStr) then
                debugPrint("skip at:", waveName, targetTimeStr)
                SkipEvent:FireServer(true)
            end
            return
        end

        debugPrint("invalid config:", waveName, configValue)
        return
    end

    if _G.WaveConfig.skip == true then
        debugPrint("skip:", waveName)
        SkipEvent:FireServer(true)
    end
end)

debugPrint("autoskip loaded")
