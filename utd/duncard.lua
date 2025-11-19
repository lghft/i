repeat task.wait(0.25) until game:IsLoaded()

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local ChallengeCardSelection = MainGui:WaitForChild("ChallengeCardSelection")
local NormalChallengeList = ChallengeCardSelection:WaitForChild("NormalChallengeList")

-- Priority table
local targetCards = {
    { name = "Poison Immunity",        priority = 10 },
    { name = "Bleed Immunity",         priority = 10 },
    { name = "Burn Immunity",          priority = 10 },
    { name = "Slow Immunity",          priority = 10 },
    { name = "Timestop Immunity",      priority = 10 },
    { name = "Single Placement Towers",priority = 10 },
    { name = "No Selling",             priority = 10 },
    { name = "No Refunds",             priority = 10 },
    { name = "Useless Traits",         priority = 6  },
    { name = "Double Boss Spawns",     priority = 6  },
    { name = "Armored Enemies",        priority = 4  },
    { name = "Healing Enemies",        priority = 8  },
    { name = "Tank Enemies",           priority = 4  },
    { name = "Explosive Enemies",      priority = 6  },
    { name = "Stealth Enemies",        priority = 1  },
    { name = "Elemental Enemies",      priority = 1  },
    { name = "Degrading Towers",       priority = 0  },
    { name = "Double Tower Costs",     priority = 1  },
}

local avoidList = {
    ["stealth enemies"]   = true,
    ["elemental enemies"] = true,
    ["degrading towers"]  = true,
}

-- Build a fast lookup for priorities (normalized)
local priorityMap = {}
do
    local function norm(s)
        s = string.lower(s)
        s = string.gsub(s, "^%s+", "")
        s = string.gsub(s, "%s+$", "")
        s = string.gsub(s, "%s+", " ")
        return s
    end
    for _, t in ipairs(targetCards) do
        priorityMap[norm(t.name)] = t.priority
    end
end

local function normalizeName(s)
    if type(s) ~= "string" then return "" end
    s = string.lower(s)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    s = string.gsub(s, "%s+", " ")
    return s
end

local function getPriority(cardName)
    return priorityMap[normalizeName(cardName)]
end

local function isAvoid(cardName)
    return avoidList[normalizeName(cardName)] == true
end

-- Extract the display name and clickable instance from a card entry
local function getCardInfo(cardFrame)
    -- Expected structure:
    -- cardFrame.CardSlot.Foreground.PathName.Text
    -- Clickable target may be the cardFrame itself if ImageButton, or a descendant ImageButton
    if not cardFrame or not cardFrame:IsA("GuiObject") then
        return nil
    end

    local slot = cardFrame:FindFirstChild("CardSlot")
    if not slot or not slot:IsA("GuiObject") then
        return nil
    end

    local fg = slot:FindFirstChild("Foreground")
    if not fg or not fg:IsA("GuiObject") then
        return nil
    end

    local pathName = fg:FindFirstChild("PathName")
    if not pathName or not pathName:IsA("TextLabel") then
        return nil
    end

    -- Wait a short time for the text to populate if empty
    local t0 = os.clock()
    while (pathName.Text == nil or pathName.Text == "") and os.clock() - t0 < 1.5 do
        task.wait(0.05)
    end

    local displayName = pathName.Text or cardFrame.Name

    -- Find clickable target
    local clickable = nil
    if cardFrame:IsA("ImageButton") or cardFrame:IsA("TextButton") then
        clickable = cardFrame
    else
        -- Search first ImageButton descendant
        for _, d in ipairs(cardFrame:GetDescendants()) do
            if d:IsA("ImageButton") or d:IsA("TextButton") then
                clickable = d
                break
            end
        end
        -- Fall back to the slot if none found (will try click anyway)
        if not clickable and slot:IsA("GuiObject") then
            clickable = slot
        end
    end

    return {
        name = displayName,
        clickable = clickable,
        frame = cardFrame,
        path = pathName,
    }
end

local function clickGuiObject(guiObj)
    if not guiObj or not guiObj.Visible then
        return false
    end
    -- Ensure full ancestry is visible
    local ancestor = guiObj
    while ancestor and ancestor ~= PlayerGui do
        if ancestor:IsA("GuiObject") and ancestor.Visible == false then
            return false
        end
        ancestor = ancestor.Parent
    end

    local insetTopLeft, insetBottomRight = GuiService:GetGuiInset()
    local insetOffset = insetTopLeft - insetBottomRight

    local absPos = guiObj.AbsolutePosition
    local absSize = guiObj.AbsoluteSize
    if not absPos or not absSize then
        return false
    end

    local center = absPos + insetOffset + (absSize / 2)
    local X = center.X
    local Y = center.Y

    VIM:SendMouseButtonEvent(X, Y, 0, true, game, 0)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(X, Y, 0, false, game, 0)
    return true
end

local selecting = false

local function gatherCards()
    local listChildren = NormalChallengeList:GetChildren()
    local cards = {}
    for _, obj in ipairs(listChildren) do
        -- Heuristic: accept Frames or ImageButtons that actually look like cards (have CardSlot/Foreground/PathName)
        if obj:IsA("Frame") or obj:IsA("ImageButton") or obj:IsA("TextButton") then
            local info = getCardInfo(obj)
            if info and info.name and info.clickable then
                table.insert(cards, info)
            end
        end
    end
    return cards
end

local function chooseBestCard(cards)
    if #cards == 0 then return nil end

    local highest = -math.huge
    local candidates = {}

    -- First pass: consider only cards in priority map
    for _, info in ipairs(cards) do
        local p = getPriority(info.name)
        if p then
            if p > highest then
                highest = p
                candidates = { info }
            elseif p == highest then
                table.insert(candidates, info)
            end
        end
    end

    if #candidates > 0 then
        return candidates[math.random(1, #candidates)]
    end

    -- Second pass: pick any non-avoid
    local nonAvoid = {}
    for _, info in ipairs(cards) do
        if not isAvoid(info.name) then
            table.insert(nonAvoid, info)
        end
    end
    if #nonAvoid > 0 then
        return nonAvoid[math.random(1, #nonAvoid)]
    end

    -- Fallback: anything
    return cards[math.random(1, #cards)]
end

local function trySelectCard()
    if selecting then return end
    if not ChallengeCardSelection.Visible or not NormalChallengeList.Visible then
        return
    end
    selecting = true

    -- Small delay to allow UI to populate fully after visibility change
    task.wait(0.1)

    local cards = gatherCards()
    if #cards == 0 then
        selecting = false
        return
    end

    local chosen = chooseBestCard(cards)
    if not chosen then
        selecting = false
        return
    end

    print("[CardSelect] Choosing:", chosen.name)
    local clicked = clickGuiObject(chosen.clickable)
    if not clicked then
        warn("[CardSelect] Failed to click card:", chosen.name)
        selecting = false
        return
    end

    -- Optional: click a confirm button if your UI requires it
    -- Adjust the path if there is a Confirm/Select button
    local confirmBtn = ChallengeCardSelection:FindFirstChild("ConfirmButton", true)
    if confirmBtn and confirmBtn:IsA("GuiObject") and confirmBtn.Visible then
        task.wait(0.1)
        clickGuiObject(confirmBtn)
    end

    selecting = false
end

-- React when UI shows up
NormalChallengeList:GetPropertyChangedSignal("Visible"):Connect(function()
    task.defer(trySelectCard)
end)

ChallengeCardSelection:GetPropertyChangedSignal("Visible"):Connect(function()
    task.defer(trySelectCard)
end)

-- Also poll lightly in case visibility events fire before content is ready
task.spawn(function()
    while true do
        if ChallengeCardSelection.Visible and NormalChallengeList.Visible then
            trySelectCard()
        end
        task.wait(0.5)
    end
end)
