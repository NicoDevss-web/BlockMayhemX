--[[
    BLOCK MAYHEM X — by ImNotNickzy
    Rayfield UI | Magnet | Auto Blocks | Anti-AFK | Auto Potion System | Auto Vote Maps
]]

-- ═══════════════════════════════════════════════════════════════
--  SERVICES & REFERENCES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ServerRemotes = Remotes:WaitForChild("Server")
local ClientRemotes = Remotes:WaitForChild("Client")

local blocksRemotes = ClientRemotes:WaitForChild("Blocks")
local getBlocks = blocksRemotes:WaitForChild("GetCurrentBlocks")
local pickupBlock = blocksRemotes:WaitForChild("PickupBlock")

local CraftGear = ServerRemotes:WaitForChild("Gears"):WaitForChild("CraftGear")
local EquipGear = ServerRemotes:WaitForChild("Gears"):WaitForChild("EquipGear")
local ConsumeBoost = ServerRemotes:WaitForChild("Boosts"):WaitForChild("ConsumeBoost")
local SendVote = ClientRemotes:WaitForChild("Worlds"):WaitForChild("SendVote")

-- ═══════════════════════════════════════════════════════════════
--  RAYFIELD UI
-- ═══════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BLOCK MAYHEM X",
    Icon = 0,
    LoadingTitle = "BLOCK MAYHEM X",
    LoadingSubtitle = "by ImNotNickzy",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BlockMayhemX",
        FileName = "BMX_Config"
    },

    KeySystem = false,
})

-- ═══════════════════════════════════════════════════════════════
--  STATE VARIABLES
-- ═══════════════════════════════════════════════════════════════
local magnetEnabled = false
local blocksEnabled = false
local antiAFKEnabled = false
local potionSystemEnabled = false
local autoVoteEnabled = false

local magnetLoop = nil
local blocksLoop = nil
local antiAFKLoop = nil
local potionLoop = nil
local autoVoteLoop = nil

-- Potion config
local potionCount = 3
local useBeyondBreaker = true
local reEquipGear = "exagoniosinverter"
local potionDuration = 45

-- Vote config — ordered priority list
local votePriority = {
    {name = "baseplate",  label = "Baseplate",  enabled = true},
    {name = "glitch",     label = "Glitch",     enabled = true},
    {name = "void",       label = "Void",       enabled = false},
    {name = "overworld",  label = "Overworld",  enabled = false},
    {name = "arctic",     label = "Arctic",     enabled = false},
    {name = "dreamland",  label = "Dreamland",  enabled = false},
    {name = "cave",       label = "Cave",       enabled = false},
    {name = "ocean",      label = "Ocean",      enabled = false},
    {name = "lava",       label = "Lava",       enabled = false},
}
local selectedPriorityMap = "Baseplate" -- currently selected map in dropdown

-- ═══════════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════════
local function getRootPart()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════════════════════════════
--  MAGNET — Collects ALL money/gems instantly
-- ═══════════════════════════════════════════════════════════════
local function startMagnet()
    magnetLoop = task.spawn(function()
        while magnetEnabled do
            local root = getRootPart()
            if root then
                local folder = workspace:FindFirstChild("Collectables")
                if folder then
                    for _, obj in pairs(folder:GetChildren()) do
                        if obj:IsA("Part") and (obj.Name == "Money" or obj.Name == "Gems") then
                            obj.CFrame = root.CFrame
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO COLLECT BLOCKS
-- ═══════════════════════════════════════════════════════════════
local function startBlocks()
    blocksLoop = task.spawn(function()
        while blocksEnabled do
            local success, blocks = pcall(function()
                return getBlocks:InvokeServer()
            end)
            if not success or type(blocks) ~= "table" then
                task.wait(0.2)
                continue
            end
            local root = getRootPart()
            local cf = root and root.CFrame or CFrame.new(0, 100, 0)
            local collected = 0
            local max_burst = 50
            for _, blockData in pairs(blocks) do
                local uuid = blockData.UUID or blockData.id or blockData.GUID or blockData.blockId
                if typeof(uuid) == "string" and #uuid >= 28 then
                    pcall(function()
                        pickupBlock:FireServer(uuid, cf)
                    end)
                    collected += 1
                    if collected % 5 == 0 then
                        task.wait(0.001)
                    end
                    if collected >= max_burst then break end
                end
            end
            task.wait(0.01 + math.random(0, 10) / 1000)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ANTI-AFK
-- ═══════════════════════════════════════════════════════════════
local function startAntiAFK()
    antiAFKLoop = task.spawn(function()
        local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
        local index = 1
        while antiAFKEnabled do
            local key = keys[index]
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.6)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
            index = (index % #keys) + 1
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO POTION SYSTEM — Craft, Equip BB, Drink, Re-equip
-- ═══════════════════════════════════════════════════════════════

-- Craft all potions needed for N level-4 potions
local function craftPotions(amount)
    for i = 1, amount do
        -- 6x level 1 (fastest safe speed)
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_01", 1) end)
            task.wait(0.05)
        end
        task.wait(0.1)

        -- 6x level 2 (uses the 6 level 1)
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_02", 1) end)
            task.wait(0.05)
        end
        task.wait(0.1)

        -- 6x level 3 (uses the 6 level 2)
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_03", 1) end)
            task.wait(0.05)
        end
        task.wait(0.1)

        -- 1x level 4 (uses the 6 level 3)
        pcall(function() CraftGear:FireServer("luck_04", 1) end)
        task.wait(0.15)
    end
end

-- Drink potions — fires ConsumeBoost with the string potion ID
-- Uses 2 second delay between each drink to respect the map's cooldown
local function drinkPotions(amount)
    for i = 1, amount do
        pcall(function() ConsumeBoost:FireServer("luck_04") end)
        Rayfield:Notify({
            Title = "Auto Potion",
            Content = "Drinking potion " .. i .. "/" .. amount .. "...",
            Duration = 3,
        })
        if i < amount then
            task.wait(2) -- 2 second delay between drinks (map cooldown)
        end
    end
end

-- Main potion system loop
local function startPotionSystem()
    potionLoop = task.spawn(function()
        while potionSystemEnabled do
            -- 1. Craft the potions
            Rayfield:Notify({
                Title = "Auto Potion",
                Content = "Crafting " .. potionCount .. " level 4 potions...",
                Duration = 5,
            })
            craftPotions(potionCount)
            task.wait(1)

            -- 2. Equip Beyond Breaker (if enabled)
            if useBeyondBreaker then
                pcall(function() EquipGear:FireServer("beyondbreaker") end)
                task.wait(0.5)
            end

            -- 3. Drink the potions
            Rayfield:Notify({
                Title = "Auto Potion",
                Content = "Drinking " .. potionCount .. " potions...",
                Duration = 5,
            })
            drinkPotions(potionCount)
            task.wait(1)

            -- 4. Re-equip the chosen gear
            pcall(function() EquipGear:FireServer(reEquipGear) end)
            task.wait(0.5)

            -- 5. Wait for potion duration before repeating
            local waitSeconds = potionDuration * 60
            Rayfield:Notify({
                Title = "Auto Potion",
                Content = "Potions active! Next cycle in " .. potionDuration .. " minutes.",
                Duration = 8,
            })

            local elapsed = 0
            while elapsed < waitSeconds and potionSystemEnabled do
                task.wait(1)
                elapsed += 1
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO VOTE MAPS — Votes for highest-priority enabled map every 10s
-- ═══════════════════════════════════════════════════════════════
local function getHighestPriorityVote()
    for _, entry in ipairs(votePriority) do
        if entry.enabled then
            return entry.name
        end
    end
    return nil
end

local function startAutoVote()
    autoVoteLoop = task.spawn(function()
        -- Fire immediately on enable
        local mapName = getHighestPriorityVote()
        if mapName then
            pcall(function() SendVote:FireServer(mapName) end)
        end
        while autoVoteEnabled do
            task.wait(10)
            mapName = getHighestPriorityVote()
            if mapName then
                pcall(function() SendVote:FireServer(mapName) end)
            end
        end
    end)
end

-- Helper: build a string showing the current priority order
local function getPriorityString()
    local parts = {}
    for i, entry in ipairs(votePriority) do
        local status = entry.enabled and "✔" or "✘"
        parts[#parts + 1] = i .. ". " .. entry.label .. " [" .. status .. "]"
    end
    return table.concat(parts, "\n")
end

-- Helper: find index in votePriority by label
local function findPriorityIndex(label)
    for i, entry in ipairs(votePriority) do
        if entry.label == label then
            return i
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
--  TAB: MAIN
-- ═══════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main", "home")

MainTab:CreateSection("Farming")

local MagnetToggle = MainTab:CreateToggle({
    Name = "Magnet (Money + Gems)",
    CurrentValue = false,
    Flag = "MagnetToggle",
    Callback = function(Value)
        magnetEnabled = Value
        if Value then
            startMagnet()
        else
            if magnetLoop then pcall(function() task.cancel(magnetLoop) end) end
        end
    end,
})

local BlocksToggle = MainTab:CreateToggle({
    Name = "Auto Collect Blocks",
    CurrentValue = false,
    Flag = "BlocksToggle",
    Callback = function(Value)
        blocksEnabled = Value
        if Value then
            startBlocks()
        else
            if blocksLoop then pcall(function() task.cancel(blocksLoop) end) end
        end
    end,
})

MainTab:CreateSection("Utility")

local AntiAFKToggle = MainTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFKEnabled = Value
        if Value then
            startAntiAFK()
        else
            if antiAFKLoop then pcall(function() task.cancel(antiAFKLoop) end) end
        end
    end,
})

MainTab:CreateButton({
    Name = "UNLOAD SCRIPT",
    Callback = function()
        magnetEnabled = false
        blocksEnabled = false
        antiAFKEnabled = false
        potionSystemEnabled = false
        autoVoteEnabled = false
        if magnetLoop then pcall(function() task.cancel(magnetLoop) end) end
        if blocksLoop then pcall(function() task.cancel(blocksLoop) end) end
        if antiAFKLoop then pcall(function() task.cancel(antiAFKLoop) end) end
        if potionLoop then pcall(function() task.cancel(potionLoop) end) end
        if autoVoteLoop then pcall(function() task.cancel(autoVoteLoop) end) end
        Rayfield:Destroy()
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  TAB: POTIONS
-- ═══════════════════════════════════════════════════════════════
local PotionTab = Window:CreateTab("Potions", "flask-conical")

PotionTab:CreateSection("Auto Potion Create")

local PotionSlider = PotionTab:CreateSlider({
    Name = "Potions to Create",
    Range = {1, 3},
    Increment = 1,
    Suffix = " potions",
    CurrentValue = 3,
    Flag = "PotionCount",
    Callback = function(Value)
        potionCount = Value
    end,
})

PotionTab:CreateButton({
    Name = "Craft Potions",
    Callback = function()
        Rayfield:Notify({
            Title = "Auto Potion",
            Content = "Crafting " .. potionCount .. " level 4 potions...",
            Duration = 5,
        })
        craftPotions(potionCount)
    end,
})

PotionTab:CreateSection("Auto Potion Use")

PotionTab:CreateToggle({
    Name = "Auto Potion System",
    CurrentValue = false,
    Flag = "PotionSystem",
    Callback = function(Value)
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Auto Potion Use non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

PotionTab:CreateToggle({
    Name = "Use Beyond Breaker (before drinking)",
    CurrentValue = false,
    Flag = "UseBBToggle",
    Callback = function(Value)
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Auto Potion Use non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

PotionTab:CreateDropdown({
    Name = "Gear to Re-equip After",
    Options = {"Exagonios Inverter", "404 Eradicator"},
    CurrentOption = {"Exagonios Inverter"},
    MultipleOptions = false,
    Flag = "ReEquipGear",
    Callback = function(Options)
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Auto Potion Use non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

PotionTab:CreateDropdown({
    Name = "Potion Duration",
    Options = {"30 min (no BB)", "45 min (with BB)"},
    CurrentOption = {"45 min (with BB)"},
    MultipleOptions = false,
    Flag = "PotionDuration",
    Callback = function(Options)
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Auto Potion Use non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  TAB: AUTO VOTE MAPS (with priority ordering)
-- ═══════════════════════════════════════════════════════════════
local VoteTab = Window:CreateTab("Auto Vote Maps", "vote")

VoteTab:CreateSection("Enable / Disable Maps")

-- Individual toggles for each map
for _, entry in ipairs(votePriority) do
    VoteTab:CreateToggle({
        Name = "Vote for " .. entry.label,
        CurrentValue = entry.enabled,
        Flag = "Vote" .. entry.label,
        Callback = function(Value)
            entry.enabled = Value
            -- Update the priority display
            if PriorityLabel then
                PriorityLabel:Set(getPriorityString())
            end
        end,
    })
end

VoteTab:CreateSection("Priority Order")

local PriorityLabel = VoteTab:CreateParagraph({
    Title = "Current Priority (top = highest)",
    Content = getPriorityString(),
})

local mapLabels = {}
for _, entry in ipairs(votePriority) do
    mapLabels[#mapLabels + 1] = entry.label
end

local PriorityDropdown = VoteTab:CreateDropdown({
    Name = "Select Map to Reorder",
    Options = mapLabels,
    CurrentOption = {selectedPriorityMap},
    MultipleOptions = false,
    Flag = "PrioritySelect",
    Callback = function(Options)
        selectedPriorityMap = Options[1] or Options
    end,
})

VoteTab:CreateButton({
    Name = "⬆ Move Up",
    Callback = function()
        local idx = findPriorityIndex(selectedPriorityMap)
        if idx and idx > 1 then
            votePriority[idx], votePriority[idx - 1] = votePriority[idx - 1], votePriority[idx]
            PriorityLabel:Set(getPriorityString())
            Rayfield:Notify({
                Title = "Auto Vote",
                Content = selectedPriorityMap .. " moved up to #" .. (idx - 1),
                Duration = 2,
            })
        end
    end,
})

VoteTab:CreateButton({
    Name = "⬇ Move Down",
    Callback = function()
        local idx = findPriorityIndex(selectedPriorityMap)
        if idx and idx < #votePriority then
            votePriority[idx], votePriority[idx + 1] = votePriority[idx + 1], votePriority[idx]
            PriorityLabel:Set(getPriorityString())
            Rayfield:Notify({
                Title = "Auto Vote",
                Content = selectedPriorityMap .. " moved down to #" .. (idx + 1),
                Duration = 2,
            })
        end
    end,
})

VoteTab:CreateSection("Control")

local VoteToggle = VoteTab:CreateToggle({
    Name = "Auto Vote System",
    CurrentValue = false,
    Flag = "AutoVoteSystem",
    Callback = function(Value)
        autoVoteEnabled = Value
        if Value then
            startAutoVote()
        else
            if autoVoteLoop then pcall(function() task.cancel(autoVoteLoop) end) end
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  TAB: GEARS
-- ═══════════════════════════════════════════════════════════════
local GearsTab = Window:CreateTab("Gears", "gem")

GearsTab:CreateSection("Gears")

GearsTab:CreateButton({
    Name = "Equip Thermic Engine",
    Callback = function()
        pcall(function() EquipGear:FireServer("thermicengine") end)
        Rayfield:Notify({
            Title = "Gears",
            Content = "Equipped Thermic Engine!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Beyond Breaker",
    Callback = function()
        pcall(function() EquipGear:FireServer("beyondbreaker") end)
        Rayfield:Notify({
            Title = "Gears",
            Content = "Equipped Beyond Breaker!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Exagonios Inverter",
    Callback = function()
        pcall(function() EquipGear:FireServer("exagoniosinverter") end)
        Rayfield:Notify({
            Title = "Gears",
            Content = "Equipped Exagonios Inverter!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip 404 Eradicator",
    Callback = function()
        pcall(function() EquipGear:FireServer("404eradicator") end)
        Rayfield:Notify({
            Title = "Gears",
            Content = "Equipped 404 Eradicator!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Sacrinare Sacrificier",
    Callback = function()
        local variants = {"sacrinaresacrificer", "sacrinare_sacrificer", "sacrinare sacrificer"}
        for _, v in ipairs(variants) do
            pcall(function() EquipGear:FireServer(v) end)
            task.wait(0.15)
        end
        Rayfield:Notify({
            Title = "Gears",
            Content = "Tried equipping Sacrinare Sacrificier (all variants)!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Euphoria Enchanter",
    Callback = function()
        local variants = {"euphoriaenchanter", "euphoria_enchanter", "euphoria enchanter"}
        for _, v in ipairs(variants) do
            pcall(function() EquipGear:FireServer(v) end)
            task.wait(0.15)
        end
        Rayfield:Notify({
            Title = "Gears",
            Content = "Tried equipping Euphoria Enchanter (all variants)!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateSection("Equip Unique Gears")

GearsTab:CreateButton({
    Name = "Equip Chrono Band",
    Callback = function()
        pcall(function() EquipGear:FireServer("chronoband") end)
        Rayfield:Notify({
            Title = "Unique Gears",
            Content = "Equipped Chrono Band!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Terraform",
    Callback = function()
        pcall(function() EquipGear:FireServer("terraform") end)
        Rayfield:Notify({
            Title = "Unique Gears",
            Content = "Equipped Terraform!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Contract Papers",
    Callback = function()
        pcall(function() EquipGear:FireServer("contractpapers") end)
        Rayfield:Notify({
            Title = "Unique Gears",
            Content = "Equipped Contract Papers!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip Summoners Crown",
    Callback = function()
        -- Try all possible argument variants
        local variants = {"summonerscrown", "summoners_crown", "summoners crown"}
        for _, v in ipairs(variants) do
            pcall(function() EquipGear:FireServer(v) end)
            task.wait(0.15)
        end
        Rayfield:Notify({
            Title = "Unique Gears",
            Content = "Tried equipping Summoners Crown (all variants)!",
            Duration = 3,
        })
    end,
})

GearsTab:CreateButton({
    Name = "Equip The Ascender",
    Callback = function()
        -- Try all possible argument variants
        local variants = {"theascender", "the_ascender", "the ascender"}
        for _, v in ipairs(variants) do
            pcall(function() EquipGear:FireServer(v) end)
            task.wait(0.15)
        end
        Rayfield:Notify({
            Title = "Unique Gears",
            Content = "Tried equipping The Ascender (all variants)!",
            Duration = 3,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  TAB: UTILS
-- ═══════════════════════════════════════════════════════════════
local UtilsTab = Window:CreateTab("Utils", "wrench")

UtilsTab:CreateSection("Shortcuts")

UtilsTab:CreateButton({
    Name = "Open Shop",
    Callback = function()
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Open Shop non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

UtilsTab:CreateButton({
    Name = "Open Summon",
    Callback = function()
        Rayfield:Notify({
            Title = "Coming Soon",
            Content = "Open Summon non è ancora disponibile!",
            Duration = 3,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  LOAD CONFIG
-- ═══════════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()
