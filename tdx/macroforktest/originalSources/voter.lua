local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local function normalize(str)
    return string.upper((str:gsub("%s+", " ")):gsub("^%s*(.-)%s*$", "%1"))
end

local function titleCase(str)
    return string.gsub(str, "(%w)(%w*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

local function teleportToLobby()
    local lobbyPlaceId = 9503261072
    TeleportService:Teleport(lobbyPlaceId)
end

if not getgenv().TDX_Config or not getgenv().TDX_Config.mapvoting then return end

repeat task.wait() until gui:FindFirstChild("Interface")
    and gui.Interface:FindFirstChild("GameInfoBar")
    and gui.Interface.GameInfoBar:FindFirstChild("MapVoting")
    and gui.Interface.GameInfoBar.MapVoting.Visible

local targetMap = normalize(getgenv().TDX_Config.mapvoting)
local mapScreens = workspace:WaitForChild("Game"):WaitForChild("MapVoting"):WaitForChild("VotingScreens")

local found = false
for i = 1, 4 do
    local screen = mapScreens:FindFirstChild("VotingScreen"..i)
    if screen then
        local mapGui = screen:FindFirstChild("ScreenPart"):FindFirstChild("SurfaceGui")
        if mapGui and mapGui:FindFirstChild("MapName") then
            local displayedName = normalize(mapGui.MapName.Text)
            if displayedName == targetMap then
                found = true
                break
            end
        end
    end
end

if not found then
    local changeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MapChangeVoteCast")
    local changeGui = gui.Interface:WaitForChild("MapVotingScreen").Bottom.ChangeMap

    while not changeGui.Disabled.Visible do
        changeRemote:FireServer(true)
        task.wait(0.5)
    end

    teleportToLobby()
    return
end

local voteName = titleCase(getgenv().TDX_Config.mapvoting)
local voteRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MapVoteCast")
local readyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MapVoteReady")

local success, _ = pcall(function()
    voteRemote:FireServer(voteName)
    task.wait(0.1)
    readyRemote:FireServer()
end)

if not success then
    teleportToLobby()
end
