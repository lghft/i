print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plrAmount = #Players:GetPlayers()
local wave = game:GetService("Players").LocalPlayer.PlayerGui.ReactGameTopGameDisplay.Frame.wave.container.value
local Ending = game:GetService("Players").LocalPlayer.PlayerGui.ReactGameRewards.Frame.gameOver
local leave = Ending.content.buttons.lobby.content
if plrAmount == 1 and game.Players.LocalPlayer and plrAmount < 2 then
  print("game?")
  repeat wait() until game.ReplicatedStorage.RemoteFunction
print("yezfunc")
spawn(function()
  while true do
  	if wave.Text == "1" then
		print("its wave 1")
  		local args = {
			"Voting",
			"Skip"
		}
		game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
  	end
  	if Ending.Visible == true then
  		--clickButton(leave)
  	end
  	if wave.Text == "39" then
  		local args = {
  	"Troops",
  	"Option",
  	"Set",
  	{
  		Troop = workspace.Towers.Masquerade,
  		Name = "Track",
  		Value = "Red"
  	}
  }
  game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
  	end
	  local args = {
	  	"Troops",
	  	"Abilities",
	  	"Activate",
	  	{
	  		Troop = workspace.Towers.Masquerade,
	  		Name = "Drop The Beat",
	  		Data = {}
	  	}
	  }
	  game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
  
  wait(1)
	end
  end)
elseif plrAmount > 1 then
    local args = {
	"Multiplayer",
	"v2:start",
	{
		difficulty = "Fallen",
		mode = "survival",
		count = 1
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
end
