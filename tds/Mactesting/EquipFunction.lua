-- === NEW TDS:Equip FUNCTION ===
function TDS:Equip(tower_input)
    if game_state ~= "GAME" then
        return false
    end
    local tower_table = type(tower_input) == "string" and {tower_input} or tower_input
    
    if type(tower_table) ~= "table" then
        warn("[TDS] Equip: Invalid input - expected string or table")
        return
    end

    for _, tower_name in ipairs(tower_table) do
        if tower_name == "" then continue end
        
        local args = {
            "Inventory",
            "Equip",
            "tower",
            tower_name
        }
        
        local success, result = pcall(function()
            return remote_func:InvokeServer(unpack(args))
        end)
        
        if success then
            if result == true or (type(result) == "table" and result.Success) or (typeof(result) == "Instance" and result:IsA("Model")) then
                print("[TDS] Successfully equipped: " .. tower_name)
            else
                warn("[TDS] Failed to equip: " .. tower_name .. " (remote returned false/nil)")
            end
        else
            warn("[TDS] Error equipping " .. tower_name .. ": " .. tostring(result))
        end
        
        task.wait(0.5) -- Prevent rate limiting
    end
end
-- ===============================
