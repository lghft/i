local Places = {
	[11739766412] = "Game",
	[9503261072] = "Lobby",
}

local request = request or http_request or syn.request or HttpPost
local LocalPlayer = game:GetService("Players").LocalPlayer
local function debugPrint(message)
    if getgenv().Debug then
        print("[Webhook Debug] " .. message)
    end
end

function SendMessageEMBED(url, embed)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {embed}
    }
    local body = http:JSONEncode(data)
    local success, err = pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end)

    if success then
        debugPrint("Webhook sent successfully")
    else
        warn("[Webhook] request failed: " .. tostring(err))
    end
end

local currentPlace = Places[game.PlaceId]

if currentPlace == "Game" then
    local mapImages = {
        ["Anchor"] = "https://static.wikia.nocookie.net/tdx/images/c/c0/Anchor.png",
        ["Ancient Sky Island"] = "https://static.wikia.nocookie.net/tdx/images/8/8a/AncientSkyIslandIcon.png",
        ["Apocalypse"] = "https://static.wikia.nocookie.net/tdx/images/6/6b/ApocalypseIcon.png",
        ["Arctic Research Base"] = "https://static.wikia.nocookie.net/tdx/images/1/1a/ArcticResearchBaseMap.png",
        ["Assembly Line"] = "https://static.wikia.nocookie.net/tdx/images/0/08/Assembly_Line.png",
        ["Asteroid"] = "https://static.wikia.nocookie.net/tdx/images/0/0e/Asteroid.png",
        ["Baseplate"] = "https://static.wikia.nocookie.net/tdx/images/5/55/Baseplate.png",
        ["Blade Works"] = "https://static.wikia.nocookie.net/tdx/images/9/9b/Blade_Works.png",
        ["Blox Out"] = "https://static.wikia.nocookie.net/tdx/images/2/2a/Blox_Island.png",
        ["Borderlands"] = "https://static.wikia.nocookie.net/tdx/images/0/09/Borderlands.png",
        ["Calamity"] = "https://static.wikia.nocookie.net/tdx/images/9/99/CalamityMap.png",
        ["Carrier"] = "https://static.wikia.nocookie.net/tdx/images/0/0c/CarrierBig.png",
        ["Cathedral"] = "https://static.wikia.nocookie.net/tdx/images/a/aa/CathedralIcon.png",
        ["Chalet"] = "https://static.wikia.nocookie.net/tdx/images/f/f7/Chalet.png",
        ["Cow Annoyance"] = "https://static.wikia.nocookie.net/tdx/images/0/03/CowAnnoyanceIcon.png",
        ["Coastal Defense"] = "https://static.wikia.nocookie.net/tdx/images/7/72/CoastalDefenseIcon.png",
        ["Dead End Valley"] = "https://static.wikia.nocookie.net/tdx/images/b/ba/DeadEndValley.png",
        ["Deserted Island"] = "https://static.wikia.nocookie.net/tdx/images/9/98/Deserted_Island_Preview.png",
        ["Factorium"] = "https://static.wikia.nocookie.net/tdx/images/3/39/Factorium.png/",
        ["Fort Summit"] = "https://static.wikia.nocookie.net/tdx/images/9/96/FortSummit.png",
        ["Fortress Snowlyn"] = "https://static.wikia.nocookie.net/tdx/images/3/3d/FortressSnowlynMap.png",
        ["Gas Station"] = "https://static.wikia.nocookie.net/tdx/images/b/b9/GasStation.png",
        ["GDI Port City"] = "https://static.wikia.nocookie.net/tdx/images/3/35/GDIPortCity.png",
        ["Grasslands"] = "https://static.wikia.nocookie.net/tdx/images/6/6c/Grasslands.png",
        ["G.U.N. Facility"] = "https://static.wikia.nocookie.net/tdx/images/a/a1/G.U.N.2.png",
        ["Hakurei Shrine"] = "https://static.wikia.nocookie.net/tdx/images/b/b0/HakureiShrine.png",
        ["Hellspire"] = "https://static.wikia.nocookie.net/tdx/images/6/66/HellspireThumb.png",
        ["Highrise"] = "https://static.wikia.nocookie.net/tdx/images/8/85/HighriseIcon.png",
        ["Junction"] = "https://static.wikia.nocookie.net/tdx/images/6/69/Junction.png",
        ["Limbo"] = "https://static.wikia.nocookie.net/tdx/images/b/bc/Limbo.png",
        ["Military Harbor"] = "https://static.wikia.nocookie.net/tdx/images/2/21/Military_harbour.png",
        ["Military HQ"] = "https://static.wikia.nocookie.net/tdx/images/f/fb/MilitaryHQ.png",
        ["Misleading Pond"] = "https://static.wikia.nocookie.net/tdx/images/b/bc/Misleading_Pond_Map.png",
        ["Military Base"] = "https://static.wikia.nocookie.net/tdx/images/0/03/MilitaryBaseIcon.png",
        ["Moon Outpost"] = "https://static.wikia.nocookie.net/tdx/images/9/95/Moon_Outpost_img.png",
        ["Obscure Island"] = "https://static.wikia.nocookie.net/tdx/images/1/1f/Obscure_island_map.png",
        ["Oil Rig"] = "https://static.wikia.nocookie.net/tdx/images/b/bd/OilRigIcon.png",
        ["Oil Field"] = "https://static.wikia.nocookie.net/tdx/images/d/d9/OilFieldIcon.png",
        ["Outpost Forge"] = "https://static.wikia.nocookie.net/tdx/images/7/7d/OutpostForge.png",
        ["Pond"] = "https://static.wikia.nocookie.net/tdx/images/1/10/Pond.png",
        ["Purgatory"] = "https://static.wikia.nocookie.net/tdx/images/d/d3/Purgatory.png",
        ["Ragnarok"] = "https://static.wikia.nocookie.net/tdx/images/6/68/Ragnarok.png",
        ["Research Base"] = "https://static.wikia.nocookie.net/tdx/images/1/18/Research_Base.png",
        ["R&D"] = "https://static.wikia.nocookie.net/tdx/images/1/16/R%26DMapIcon.png",
        ["Route"] = "https://static.wikia.nocookie.net/tdx/images/c/c1/Route.png",
        ["Santa's Stronghold"] = "https://static.wikia.nocookie.net/tdx/images/4/44/SantasStrongholdIcon.png",
        ["Santa's Stronghold (Alt)"] = "https://static.wikia.nocookie.net/tdx/images/f/fb/Santa%27s_stronghold.png",
        ["Scorched Passage"] = "https://static.wikia.nocookie.net/tdx/images/0/0b/Scorched_Passage.png",
        ["Secret Forest"] = "https://static.wikia.nocookie.net/tdx/images/a/a2/Secretforest.png",
        ["SFOTH"] = "https://static.wikia.nocookie.net/tdx/images/d/dd/Sfoth.png",
        ["Singularity"] = "https://static.wikia.nocookie.net/tdx/images/d/d0/Singularity.png",
        ["Simulation"] = "https://static.wikia.nocookie.net/tdx/images/d/d0/SimulationIcon.png",
        ["Sorrows Harbor"] = "https://static.wikia.nocookie.net/tdx/images/5/58/SorrowsHarborIcon.png",
        ["Survival 202"] = "https://static.wikia.nocookie.net/tdx/images/c/c1/Survival202.png",
        ["Treasure Cove"] = "https://static.wikia.nocookie.net/tdx/images/8/8a/TreasureCoveBig.png",
        ["Tutorial"] = "https://static.wikia.nocookie.net/tdx/images/d/d0/SimulationIcon.png",
        ["Unforgiving Winter"] = "https://static.wikia.nocookie.net/tdx/images/4/43/Unforgiving_Winter_map.png",
        ["Vapor City"] = "https://static.wikia.nocookie.net/tdx/images/8/87/Vapor_Downtown.png",
        ["Vinland"] = "https://static.wikia.nocookie.net/tdx/images/c/cd/Vinland.png",
        ["Volcanic Mishap"] = "https://static.wikia.nocookie.net/tdx/images/d/d8/Volcanomishap.png",
        ["Western"] = "https://static.wikia.nocookie.net/tdx/images/9/95/Western.png",
        ["Winter Fort"] = "https://static.wikia.nocookie.net/tdx/images/a/a6/Winter_Fort.png",
    }
    local defaultImageUrl = "https://t6.rbxcdn.com/180DAY-7e74c34a381f4e8dc9bbe672f41d6b56"

    repeat
        task.wait()
    until LocalPlayer:FindFirstChild("PlayerGui") and
          LocalPlayer.PlayerGui:FindFirstChild("Interface") and
          LocalPlayer.PlayerGui.Interface:FindFirstChild("GameOverScreen")
    debugPrint("GameOverScreen Found")

    local Interface = LocalPlayer.PlayerGui.Interface
    local GameOverScreen = Interface.GameOverScreen
    debugPrint("Wait for the game to end")

    local mapImagesUpper = {}
    for key, value in pairs(mapImages) do
        mapImagesUpper[key:upper()] = value
    end

    function getMapImageUrl(mapName)
        local url = mapImagesUpper[mapName] or defaultImageUrl
        debugPrint("Map image URL for " .. mapName .. ": " .. url)
        return url
    end

    function getEmbedColorAndTitle()
        if GameOverScreen.Main.VictoryText.Visible then
            debugPrint("Victory detected")
            return 0x15d415, "**You triumphed!**"
        elseif GameOverScreen.Main.DefeatText.Visible then
            debugPrint("Defeat detected")
            return 0xd41515, "**Better luck next time!**"
        else
            return 0x424c51, "**Game Over**"
        end
    end

    function sendWebhook()
        local mapImageUrl = getMapImageUrl(GameOverScreen.Main.InfoFrame.Map.Text)
        local embedColor, TitleMsg = getEmbedColorAndTitle()
        local fields = {
            {name = "**:star: EXP:**", value = GameOverScreen.Main.RewardsFrame.InnerFrame.XP.TextLabel.Text, inline = true},
            {name = "**:coin: Gold:**", value = GameOverScreen.Main.RewardsFrame.InnerFrame.Gold.TextLabel.Text, inline = true},
        }

        local tokensLabel = GameOverScreen.Main.RewardsFrame.InnerFrame:FindFirstChild("Tokens") and
                            GameOverScreen.Main.RewardsFrame.InnerFrame.Tokens:FindFirstChild("TextLabel")

        local crystalsLabel = GameOverScreen.Main.RewardsFrame.InnerFrame:FindFirstChild("Crystals") and
                            GameOverScreen.Main.RewardsFrame.InnerFrame.Crystals:FindFirstChild("TextLabel")

        if tokensLabel and tokensLabel.Visible then
            table.insert(fields, {name = "**:comet: Tokens:**", value = tokensLabel.Text, inline = true})
            debugPrint("Tokens detected: " .. tokensLabel.Text)
        end

        if crystalsLabel and crystalsLabel.Visible then
            table.insert(fields, {name = "**:gem: Crystals:**", value = crystalsLabel.Text, inline = true})
            debugPrint("Crystals detected: " .. crystalsLabel.Text)
        end

        local powerUpsContainer = GameOverScreen.Rewards.Content:FindFirstChild("PowerUps1")
        if powerUpsContainer and #powerUpsContainer.Items:GetChildren() > 0 then
            debugPrint("Power-ups detected, adding reward fields")
            for _, drop in pairs(powerUpsContainer.Items:GetChildren()) do
                if drop:IsA("Frame") and drop.Name ~= "ItemTemplate" then
                    table.insert(fields, {name = "**" .. drop.NameText.Text .. ":**", value = drop.CountText.Text, inline = true})
                end
            end
        else
            debugPrint("No power-ups found")
        end

        debugPrint("Title message: " .. TitleMsg)

        local embed = {
            author = {
                name = "Tower Defense X  |  Notification system",
                icon_url = "https://i.imgur.com/aPNN9Lp.png"
            },
            title = "**Player: ||" .. LocalPlayer.Name .. "||**  |  " .. TitleMsg,
            description = string.format(
                "**Map:** %s\n**Mode:** %s\n**Time:** %s\n**Wave:** %s",
                GameOverScreen.Main.InfoFrame.Map.Text,
                GameOverScreen.Main.InfoFrame.Mode.Text,
                GameOverScreen.Main.InfoFrame.Time.Text,
                (Interface.GameInfoBar.Wave.WaveText.Text):match("%d+")
            ),
            color = embedColor,
            fields = fields,
            image = {
                url = mapImageUrl
            },
            thumbnail = {
                url = "https://i.imgur.com/MWxktrO.png"
            },
            footer = {
                text = "Modified by Gurty",
                icon_url = "https://i1.sndcdn.com/artworks-OYitqLrvBDkyH2Go-ywy2lg-t500x500.jpg"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
        }

        if getgenv().SendMatchResult then
            debugPrint("Sending webhook")
            SendMessageEMBED(getgenv().Webhook, embed)
        end

        if getgenv().ReturnLobby then
            if (getgenv().UsePrivateServer and (getgenv().PrivateLink and getgenv().PrivateLink ~= "")) or
               (getgenv().UsePrivateServer and (getgenv().PrivateCode and getgenv().PrivateCode ~= ""))

            then
                game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestUpdateSetting"):FireServer("AutoSkip", false)
                task.wait()

                local MainPrivateCode
                if getgenv().PrivateCode ~= "" and getgenv().PrivateLink == "" then
                    MainPrivateCode = getgenv().PrivateCode
                elseif getgenv().PrivateLink ~= "" and getgenv().PrivateCode == "" then
                    local URL = getgenv().PrivateLink
                    MainPrivateCode = string.match(URL, "privateServerLinkCode=([^&]+)")
                end

                local infoTable = {
                    placeId = 9503261072,
                    linkCode = tostring(MainPrivateCode)
                }
                game:GetService("ExperienceService"):LaunchExperience(infoTable)
                game:Shutdown()
            else
                game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestUpdateSetting"):FireServer("AutoSkip", false)
                task.wait()
                game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestTeleportToLobby"):FireServer()
                debugPrint("Taking you back to the lobby.")
            end
        end
    end

    GameOverScreen.Changed:Connect(function(property)
        if property == "Visible" then
            debugPrint("GameOverScreen visibility changed")
            task.wait(5)
            task.spawn(sendWebhook)
        end
    end)

elseif currentPlace == "Lobby" then

    repeat
        task.wait()
    until LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("GUI")
    debugPrint("GUI Found")

    local GUI = LocalPlayer.PlayerGui.GUI

    function sendWebhook()
        function getEmbedColorAndTitle()
            return 0xffd700, "**Stats Tracking**"
        end

        local fields = {
            {name = "**:trophy: Wins:**", value = LocalPlayer.leaderstats.Wins.Value, inline = true},
            {name = "**:chart_with_upwards_trend: Level:**", value = LocalPlayer.leaderstats.Level.Value, inline = true},
        }
        local embedColor, TitleMsg = getEmbedColorAndTitle()
        local embed = {
            author = {
                name = "Tower Defense X  |  Notification system",
                icon_url = "https://i.imgur.com/aPNN9Lp.png"
            },
            title = "**Player: ||" .. LocalPlayer.Name .. "||**  |  " .. TitleMsg,
            description = string.format(
                "**:star2: EXP Bar:** %s\n**:coin: Golds:** %s\n**:gem: Crystals:** %s",
                GUI:WaitForChild("XPLevel"):WaitForChild("xp").Text,
                GUI:WaitForChild("CurrencyDisplay"):WaitForChild("GoldDisplay"):WaitForChild("ValueText").Text,
                GUI:WaitForChild("CurrencyDisplay"):WaitForChild("CrystalsDisplay"):WaitForChild("ValueText").Text
            ),
            color = embedColor,
            fields = fields,
            thumbnail = {
                url = "https://i.imgur.com/MWxktrO.png"
            },
            footer = {
                text = "Modified by Gurty",
                icon_url = "https://i1.sndcdn.com/artworks-OYitqLrvBDkyH2Go-ywy2lg-t500x500.jpg"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
        }
        debugPrint("Sending webhook")
        SendMessageEMBED(getgenv().Webhook, embed)
    end

    repeat task.wait() until game:IsLoaded()
    if getgenv().StatsTracking then
        task.spawn(sendWebhook)
    end

end
