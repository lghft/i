local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local config = getgenv().TDX_Config or {}

local isVIP = false
for i = 1, 30 do
	local attr = LocalPlayer:GetAttribute("VIP")
	if attr ~= nil then
		isVIP = (attr == true)
		break
	end
	task.wait(0.5)
end

local mapAliases = {
	["nm"] = "NightmareWithMapVoting", ["NM"] = "NightmareWithMapVoting", ["Nightmare"] = "NightmareWithMapVoting",
	["Inter"] = "Intermediate",
	["HW24Part1"] = "Halloween24Part1", ["HW24Part2"] = "Halloween24Part2",
	["HW24Part3"] = "Halloween24Part3", ["HW24Part4"] = "Halloween24Part4",
	["xmas24Part1"] = "Christmas24Part1", ["xmas24Part2"] = "Christmas24Part2",
	["xmas25part1"] = "Christmas25Part1",
	["tb"] = "Tower Battles",
}

local specialMaps = {
	["Halloween Part 1"]=true,["Halloween Part 2"]=true,["Halloween Part 3"]=true,["Halloween Part 4"]=true,
	["Halloween24Part1"]=true,["Halloween24Part2"]=true,["Halloween24Part3"]=true,["Halloween24Part4"]=true,
	["Halloween2025"]=true,["Tower Battles"]=true,
	["Christmas24Part1"]=true,["Christmas24Part2"]=true,["Christmas25Part1"]=true,["Christmas25Part2"]=true,
	["Easy"]=true,["Intermediate"]=true,["Elite"]=true,["Expert"]=true,["Endless"]=true,
	["NightmareWithMapVoting"]=true,
}

local targetMapName = mapAliases[config["Map"] or "Christmas24Part1"] or config["Map"] or "Christmas24Part1"

if game.PlaceId == 9503261072 then
	-- Use the client party system to set map and start game
	local Network = ReplicatedStorage:WaitForChild("Network")

	Network:WaitForChild("ClientChangePartyTypeRequest"):FireServer("Party")
	Network:WaitForChild("ClientChangePartyMapRequest"):FireServer(targetMapName)
	task.wait(1.5)
	Network:WaitForChild("ClientStartGameRequest"):FireServer()
end

if config.mapvoting then
	local function normalize(t) return string.upper((t:gsub("%s+", " ")):gsub("^%s*(.-)%s*$", "%1")) end
	local function titleCase(t) return t:gsub("(%w)(%w*)", function(a,b) return a:upper()..b:lower() end) end

	local targetMap = normalize(config.mapvoting)
	local voteName = titleCase(config.mapvoting)

	if isVIP then
		local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
		if not Remotes then return end

		pcall(function()
			Remotes:WaitForChild("MapOverride"):FireServer(voteName)
		end)

		task.wait(1)

		pcall(function()
			Remotes:WaitForChild("MapVoteCast"):FireServer(voteName)
		end)

		task.wait(1)

		pcall(function()
			Remotes:WaitForChild("MapVoteReady"):FireServer()
		end)

		return
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local mapVotingScreen = playerGui:WaitForChild("Interface"):WaitForChild("MapVotingScreen")
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")

	repeat task.wait() until mapVotingScreen.Visible

	local mapFound = false
	for i = 1, 4 do
		local screen = workspace:WaitForChild("Game"):WaitForChild("MapVoting"):WaitForChild("VotingScreens"):FindFirstChild("VotingScreen"..i)
		if screen and normalize(screen:WaitForChild("ScreenPart"):WaitForChild("SurfaceGui"):WaitForChild("MapName").Text) == targetMap then
			mapFound = true
			break
		end
	end

	if not mapFound then
		local changeRemote = Remotes:WaitForChild("MapChangeVoteCast")
		local changeBtn = mapVotingScreen.Bottom:WaitForChild("ChangeMap")
		while not changeBtn.Disabled.Visible do
			changeRemote:FireServer(true)
			task.wait(0.5)
		end
		TeleportService:Teleport(9503261072)
		return
	end

	Remotes:WaitForChild("MapVoteCast"):FireServer(voteName)
	task.wait(0.1)
	Remotes:WaitForChild("MapVoteReady"):FireServer()
end
