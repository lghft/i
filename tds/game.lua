print("lby?")
repeat wait(5) until game:IsLoaded()
print("Lby Loaded1")
local char = game.Players.LocalPlayer.Character
local Players = game:GetService('Players')
local plr = Players.LocalPlayer
local plrAmount = #Players:GetPlayers()

function clickButton(ClickOnPart)
    local vim = game:GetService("VirtualInputManager")
    local inset1, inset2 = game:GetService('GuiService'):GetGuiInset()
    local insetOffset = inset1 - inset2
    -- Replace "button location here" with the actual GUI object (e.g., a TextButton)
    local part = ClickOnPart
    -- Calculate the center of the GUI element
    local topLeft = part.AbsolutePosition + insetOffset
    local center = topLeft + (part.AbsoluteSize / 2)
    -- Adjust the click position if needed
    local X = center.X + 15
    local Y = center.Y
    -- Simulate a mouse click
    vim:SendMouseButtonEvent(X, Y, 0, true, game, 0) -- Mouse down
    task.wait(0.1) -- Small delay to simulate a real click
    vim:SendMouseButtonEvent(X, Y, 0, false, game, 0) -- Mouse up
    task.wait(1)
    print("Clicked: ", ClickOnPart)
end

if plrAmount == 1 and game.Players.LocalPlayer and plrAmount < 2 then
  print("game?")
repeat wait() until plr.PlayerGui.ReactGameTopGameDisplay
local wave = game:GetService("Players").LocalPlayer.PlayerGui.ReactGameTopGameDisplay.Frame.wave.container.value
local Ending = game:GetService("Players").LocalPlayer.PlayerGui.ReactGameRewards.Frame.gameOver
local leave = Ending.content.buttons.lobby.content
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
