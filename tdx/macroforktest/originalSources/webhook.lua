repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local LOBBY_PLACE_ID = 9503261072
local MATCH_START_TIME = os.clock()

local DataService = require(
    ReplicatedStorage
        :WaitForChild("TDX_Shared")
        :WaitForChild("Client")
        :WaitForChild("Services")
        :WaitForChild("Data")
)

local MAX_RETRY = 3

local function getWebhookURL()
    return getgenv().webhookConfig and getgenv().webhookConfig.webhookUrl or ""
end

local function formatTime(seconds)
    seconds = tonumber(seconds)
    if not seconds then return "N/A" end

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    else
        return string.format("%dm %ds", m, s)
    end
end

local function formatRuntime()
    local elapsed = os.clock() - MATCH_START_TIME

    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = math.floor(elapsed % 60)

    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    else
        return string.format("%dm %ds", m, s)
    end
end

local function safeGetData(key)
    if DataService and DataService.Get then
        return DataService.Get(key)
    end
    return nil
end

local function sendToWebhook(data)
    local url = getWebhookURL()
    if url == "" then return end

    local embedFields = {}
    local content = {}

    for k, v in pairs(data.stats or data.rewards or {}) do
        content[k] = v
    end

    local function addField(name, value, inline)
        if value == nil then return end
        table.insert(embedFields, {
            name   = tostring(name),
            value  = tostring(value),
            inline = inline
        })
    end

    table.insert(embedFields, {
        name   = "Player",
        value  = "||" .. LocalPlayer.Name .. "||",
        inline = false
    })

    local priorityKeys = {
        "Map", "Mode", "Result", "Wave", "Time", "RealTime",
        "Level", "Wins",
        "Gold", "Crystals", "Cookies", "Envelopes", "Tokens", "XP"
    }

    for _, key in ipairs(priorityKeys) do
        if content[key] ~= nil then
            addField(key, content[key], true)
            content[key] = nil
        end
    end

    for k, v in pairs(content) do
        addField(k, v, false)
    end

    local body = HttpService:JSONEncode({
        embeds = {{
            title  = data.type == "game" and "Game Result" or "Lobby Info",
            color  = 0x5B9DFF,
            fields = embedFields,
        }}
    })

    task.spawn(function()
        for _ = 1, MAX_RETRY do
            local success = pcall(function()
                if typeof(http_request) == "function" then
                    http_request({
                        Url     = url,
                        Method  = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body    = body
                    })
                else
                    HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
                end
            end)
            if success then break end
            task.wait(1)
        end
    end)
end

local function hookGameReward()
    task.spawn(function()
        local handler
        local success = pcall(function()
            handler = require(
                LocalPlayer.PlayerScripts.Client.UserInterfaceHandler
                    :WaitForChild("GameOverScreenHandler")
            )
        end)

        if not success or not handler then return end

        local oldDisplay = handler.DisplayScreen
        handler.DisplayScreen = function(p_u_115)
            task.spawn(function()
                local pName = LocalPlayer.Name

                local function getVal(map)
                    if not map then return nil end
                    local val = map[pName]
                    if type(val) == "number" and val > 0 then
                        return tostring(val)
                    end
                    return nil
                end

                local rewards = {
                    Map       = p_u_115.MapName or "Unknown",
                    Mode      = tostring(p_u_115.Difficulty or "Unknown"),
                    Result    = p_u_115.Victory and "Victory" or "Defeat",
                    Wave      = p_u_115.LastPassedWave and tostring(p_u_115.LastPassedWave) or "N/A",
                    Time      = formatTime(p_u_115.TimeElapsed),
                    RealTime  = formatRuntime(),
                    Gold      = getVal(p_u_115.PlayerNameToGoldMap),
                    Crystals  = getVal(p_u_115.PlayerNameToCrystalsMap),
                    Cookies   = getVal(p_u_115.PlayerNameToCookiesMap),
                    Envelopes = getVal(p_u_115.PlayerNameToEnvelopesMap),
                    Tokens    = getVal(p_u_115.PlayerNameToTokensMap),
                    XP        = getVal(p_u_115.PlayerNameToXPMap),
                }

                local puMap  = (p_u_115.PlayerNameToPowerUpsRewardedMapMap or {})[pName] or {}
                local puList = {}
                for id, count in pairs(puMap) do
                    if type(count) == "number" and count > 0 then
                        table.insert(puList, id .. " x" .. count)
                    end
                end
                if #puList > 0 then
                    rewards.PowerUps = table.concat(puList, ", ")
                end

                local towerRewards = (p_u_115.PlayerNameToTowerRewardMap or {})[pName] or {}
                if #towerRewards > 0 then
                    rewards.NewTowers = table.concat(towerRewards, ", ")
                end

                sendToWebhook({ type = "game", rewards = rewards })
            end)

            return oldDisplay(p_u_115)
        end
    end)
end

if game.PlaceId ~= LOBBY_PLACE_ID then
    hookGameReward()
end
