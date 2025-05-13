--@diagnostic disable: undefined-global
local plr = game.Players.LocalPlayer
local OSTime = os.time()
local Time = os.date('!*t', OSTime)
local PlrLVL = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Mobile.PlayerStatus.PlayerStatus.Level.TextLabel.Text
local PlrXP = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Mobile.PlayerStatus.PlayerStatus.XP.BarFrame.TextLabel.Text
local gold = game:GetService("Players").LocalPlayer.PlayerGui.Topbar.Container.LeftFrame.Currency.gold.TextLabel.Text
local goldGain = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Rewards.GoldGained.Amount.Label.Text
local expGain = game:GetService("Players").LocalPlayer.PlayerGui.RetryVote.Frame.Rewards.XPGained.Amount.Label.Text

-- Function to get all reward images
local function getRewardImages()
    local rewards = {}
    local success, err = pcall(function()
        local rewardsFrame = plr.PlayerGui:WaitForChild("RetryVote", 5):WaitForChild("Frame", 5):WaitForChild("Rewards", 5):WaitForChild("ItemRewards", 5)
        if rewardsFrame then
            for _, child in pairs(rewardsFrame:GetChildren()) do
                if child:FindFirstChild("Container") then
                    local itemImage = child.Container:FindFirstChild("ItemImage")
                    if itemImage and itemImage:IsA("ImageLabel") then
                        local imageId = string.match(itemImage.Image, "%d+")
                        if imageId then
                            table.insert(rewards, {
                                name = child.Name,
                                url = "https://create.roblox.com/store/asset/"..imageId,
                                id = imageId
                            })
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("Failed to get rewards: "..tostring(err))
    end
    
    return rewards
end

local rewardItems = getRewardImages()
local rewardText = "No rewards found"

if #rewardItems > 0 then
    rewardText = ""
    for i, item in ipairs(rewardItems) do
        rewardText = rewardText..string.format("[%s](%s)", item.name, item.url)
        if i < #rewardItems then
            rewardText = rewardText.." • "
        end
    end
end

local folderName = "DQSetting"
local fileName = "WebHook.json"
local fullPath = folderName .. "/" .. fileName

-- Function to ensure the folder exists
function ensureFolderExists()
    if not isfolder(folderName) then
        makefolder(folderName)
    end
end

-- Function to write to the JSON file
function writeToJson(data)
    ensureFolderExists()
    local jsonString = game:GetService("HttpService"):JSONEncode(data)
    writefile(fullPath, jsonString)
    return true
end

-- Function to read from the JSON file
function readFromJson()
    ensureFolderExists()
    if not isfile(fullPath) then
        -- Create default file if it doesn't exist
        writeToJson(
            {
                url = ""
            }

        )
        return {}
    end
    
    local success, result = pcall(function()
        local fileContents = readfile(fullPath)
        return game:GetService("HttpService"):JSONDecode(fileContents)
    end)
    
    if not success then
        warn("Failed to read JSON file: " .. tostring(result))
        return nil
    end
    
    return result
end
local WHook = readFromJson() 
print(WHook.url)

local Content = 'Game Ended!'
local Embed = {
    ["title"] = "**「 Dungeon CLEARED 」**",
    ["description"] = "Username: ".."||"..plr.Name.."||".."\nDisplay Name: ||"..plr.DisplayName.."||",
    ["type"] = "rich",
    ["color"] = tonumber(0xffff00),
    ["thumbnail"] = {
        ["url"] = "https://raw.githubusercontent.com/lghft/i/main/5i.png"
    },
    ["fields"] = {
        {
            ["name"] = "**Player Stats**",
            ["value"] = "**:bar_chart:: **".."[ " ..PlrLVL.. " ]".. " ("..PlrXP..") +" .. expGain .."\n<:coins:1217991784148373604>".. " :" .. gold .. "   +" .. goldGain,
            ["inline"] = true
        },
        {
            ["name"] = "**Rewards**",
            ["value"] = rewardText,
            ["inline"] = false
        },
        {
            ["name"] = "Match Result",
            ["value"] = "Victory", -- Change this as needed
            ["inline"] = false
        },
    },

    ["footer"] = {
        ["text"] = "dq script",
        ["icon_url"] = "https://raw.githubusercontent.com/lghft/i/main/5i.png"
    },
    ["timestamp"] = string.format('%d-%d-%dT%02d:%02d:%02dZ', Time.year, Time.month, Time.day, Time.hour, Time.min, Time.sec),
}

-- Add image embeds if rewards were found
local embeds = {Embed}

(syn and syn.request or http_request or http.request) {
    Url = tostring(WHook.url),
    Method = 'POST',
    Headers = {
        ['Content-Type'] = 'application/json'
    },
    Body = game:GetService'HttpService':JSONEncode({content = Content; embeds = embeds})
}
