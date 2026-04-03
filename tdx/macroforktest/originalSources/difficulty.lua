local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local voteRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("DifficultyVoteCast", true)
local readyRemote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("DifficultyVoteReady", true)

if not voteRemote then
    return
end

local mode = getgenv().TDX_Config and getgenv().TDX_Config["Auto Difficulty"]
if not mode then
    return
end

local difficultyVoteScreen
repeat
    task.wait(0.25)
    local interface = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("Interface")
    difficultyVoteScreen = interface and interface:FindFirstChild("DifficultyVoteScreen")
until difficultyVoteScreen and difficultyVoteScreen.Visible

voteRemote:FireServer(mode)

if readyRemote then
    task.wait(0.25)
    readyRemote:FireServer()
end
