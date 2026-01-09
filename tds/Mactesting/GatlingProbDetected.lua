local ggchannel = require(game.ReplicatedStorage.Resources.Universal.NewNetwork).Channel("GatlingGun")
local gganim = require(game:GetService("ReplicatedStorage").Content.Tower["Gatling Gun"].Animator)
getgenv().gatlingcooldown = 0.01
getgenv().multiplytimes = 60
getgenv().norecoil = true
gganim._fireGun = function(arg1)
local stores = require(game:GetService("ReplicatedStorage").Client.Interfaces.Stores)
local camcontroller = require(game:GetService("ReplicatedStorage").Content.Tower["Gatling Gun"].Animator.CameraController)
local minigun = arg1.Replicator:Get("Minigun")
if minigun then
    local canfire = arg1.Replicator:Get("CanFire")
end
if not arg1.Replicator:Get("Minigun") and true or canfire then
    arg1:_fire(camcontroller.position)
    if not getgenv().norecoil then
        stores.CrosshairStore.store:dispatch({
            ["type"] = "addSpread",
            ["spread"] = arg1.Stats.Attributes.SpreadAdd or 10
        })
        camcontroller.recoil(arg1.Stats.Attributes.Recoil or 0.03)
    end
end
local camposition = camcontroller.result and camcontroller.result.Position or camcontroller.position
for i = 1, getgenv().multiplytimes do
    ggchannel:fireServer("Fire", camposition, workspace:GetAttribute("Sync"), workspace:GetServerTimeNow())
end
arg1:Wait(getgenv().gatlingcooldown)
end
