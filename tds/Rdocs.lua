================================================================================
                    TDS AUTOMATION API: TECHNICAL DOCUMENTATION
================================================================================

[ CORE ENGINE METHODS ]
--------------------------------------------------------------------------------
TDS:Place(name, x, y, z)    -> Places tower, returns index.
TDS:Equip(name)             -> Equips tower by name.
TDS:Upgrade(idx, path)      -> Upgrades tower at index (path 1 or 2).
TDS:Sell(idx)               -> Sells tower at index.
TDS:SetTarget(idx, mode)    -> Targeting: "First", "Strong", "Last", "Random".
TDS:UnlockTimeScale()      -> Unlocks time scale control.
TDS:TimeScale(val)       -> Sets speed: 0.5, 1, 1.5, or 2.
TDS:GameInfo(map, modifiers)       -> Selects the desired Map and Modifiers
TDS:VoteSkip(start_wave, end_wave) -> Vote to skip on the wave of your choice. Ex: TDS:VoteSkip(1) or TDS:VoteSkip(1,5)
Modifiers:
HiddenEnemies = true, Glass = true, ExplodingEnemies = true, Limitation = true, Committed = true, HealthyEnemies = true, SpeedyEnemies = true, Quarantine = true, Fog = true, FlyingEnemies = true, Broke = true, Jailed = true, Inflation = true

Usage: TDS:GameInfo("Simplicity", {HiddenEnemies = true, ExplodingEnemies = true})

--------------------------------------------------------------------------------
[ TDS:SetOption ]
Description: Used for towers with toggles or unit selection.
Usage: TDS:SetOption(index, "OptionName", "Value", requiredWave)

1. Mercenary Base:
   - "Unit 1" (or 2, 3) --> "Grenadier", "Rifleman", "Riot Guard", "Field Medic"

2. Trapper:
   - "Trap" --> "Spike" or "Landmine"

3. DJ Booth:
   - "Track" --> "Green", "Red", or "Purple"

--------------------------------------------------------------------------------
[ TDS:Ability ]
Description: Triggers special abilities. Set 'loop' to true for auto-spam.
Usage: TDS:Ability(index, "AbilityName", dataTable, loop)

• Commander:
  - "Call Of Arms" (No data)
  - "Support Caravan" (No data)

• DJ Booth:
  - "Drop The Beat" (No data)

• Medic:
  - "Ubercharge" (No data)

• Hacker:
  - "Hologram Tower"
    Data: { towerToClone = index, towerPosition = Vector3.new(x, y, z) }

• Pursuit:
  - "Patrol" 
    Data: { ["position"] = Vector3.new(x, y, z) }

• Gatling Gun:
  - "FPS"
    Data: { ["enabled"] = true/false }

• Brawler:
  - "Reposition"
    Data: { ["position"] = Vector3.new(x, y, z) }

• Mercenary Base / Military Base:
  - "Air-Drop" or "Airstrike"
    Data: { 
        ["pathName"] = 1, 
        ["dist"] = 0 to 200, -- (Simplicity Max: 156)
        ["pointToEnd"] = 0 to 200,
        ["directionCFrame"] = CFrame.new() 
    }

--------------------------------------------------------------------------------
[ GLOBAL CONFIGURATION (_G) ]
--------------------------------------------------------------------------------
_G.AutoStrat     = true  -- Enables the 24/7 infinite loop
_G.AutoSkip      = true  -- Automatically votes to skip waves
_G.AutoPickups = true  -- Automatically collects event snowballs
_G.Webhook       = ""    -- Your Discord Webhook URL
_G.SendWebhook   = true  -- Toggles match result logging
_G.AntiLag     = true     -- Stops you from lagging too hard

--------------------------------------------------------------------------------
[ ADVANCED: INFINITE LOOP (Autoexec) ]
--------------------------------------------------------------------------------
For 24/7 AFK, place the script into your executor's 'Autoexec' folder.

--------------------------------------------------------------------------------
[ ADVANCED: POSITIONING (dist / pointToEnd) ]
--------------------------------------------------------------------------------
The "dist" (Mercenary Base) and "pointToEnd" (Military Base) parameters control 
WHERE on the path the ability triggers.

• 0 = The START of the road (where enemies spawn).
• The higher the number, the further down the road the ability targets.
• Each map has a different maximum distance (Simplicity is ~156).

HOW TO FIND VALUES FOR OTHER MAPS:
1. Open a RemoteSpy (like SimpleSpy or Hydroxide).
2. Use the Ability manually in-game.
3. Look for the 'RemoteFunction' call named "Troops" with the action "Abilities".
4. Check the 'Data' table in the spy's log to see the exact 'dist' or 
   'pointToEnd' number your cursor was pointing at.

NOTE: If you set the value to 999, the unit/airstrike will often target the 
very end of the path or remain "stuck" at the exit until it times out.

TROUBLESHOOTING & TIPS 
• ERROR "No HTTP Function": Your executor does not support 'request'. Use a
supported executor like Wave, Xeno, Delta, or Arceus X.
• TOWERS NOT PLACING: Ensure you have enough money. The script will retry
automatically, but it cannot bypass your in-game cash balance.
• INDEXING: Towers are indexed in the order they are placed (1, 2, 3...). If
you sell Index 1, Index 2 remains 2; it does not shift down.
• WEBHOOKS: Ensure your Webhook URL is the "Raw" Discord link. If the script
freezes at the end of a match, check if your Webhook URL is valid.

================================================================================
                    COPYRIGHT 2025 DUXII - PERSONAL USE ONLY
================================================================================
