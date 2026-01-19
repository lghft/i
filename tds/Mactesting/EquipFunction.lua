-- === TDS:Equip FUNCTION === --
function TDS:Equip(tower_input)
    if game_state ~= "GAME" then
        return false
    end
    local tower_table = type(tower_input) == "string" and {tower_input} or tower_input
    
    if type(tower_table) ~= "table" then
		log("Equip: Invalid input - expected string or table" .. tower_input, "yellow")
        return
    end
	log("Equipping tower: " .. tower_input, "green")
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
				log("Successfully equipped:" .. tower_input, "green")
            else
				log("Failed to equip: " .. tower_input, "orange")
            end
        else
			log("Error equipping " .. tower_input, "red")
        end
        
        task.wait(0.5) -- Prevent rate limiting
    end
end
-- ===============================
