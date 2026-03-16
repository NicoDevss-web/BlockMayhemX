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
    ToggleUIKeybind = "Insert",
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

-- Vote config
local voteGlitch = true
local voteBaseplate = true

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
        -- 6x level 1
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_01", 1) end)
            task.wait(0.15)
        end
        task.wait(0.3)

        -- 6x level 2 (uses the 6 level 1)
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_02", 1) end)
            task.wait(0.15)
        end
        task.wait(0.3)

        -- 6x level 3 (uses the 6 level 2)
        for _ = 1, 6 do
            pcall(function() CraftGear:FireServer("luck_03", 1) end)
            task.wait(0.15)
        end
        task.wait(0.3)

        -- 1x level 4 (uses the 6 level 3)
        pcall(function() CraftGear:FireServer("luck_04", 1) end)
        task.wait(0.5)
    end
end

-- Consume a specific potion by its ID
local function consumePotion(potionId)
    pcall(function()
        ConsumeBoost:FireServer(potionId)
    end)
end

-- Drink potions — scans Backpack for potion tools and extracts IDs from their names
local function drinkPotions(amount)
    local consumed = 0

    -- Method 1: Scan Backpack for potion tools and extract numeric ID from their name
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if consumed >= amount then break end
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("luck") or nameLower:find("potion") or nameLower:find("boost") then
                    local potionId = tonumber(item.Name:match("%d+"))
                    if potionId then
                        consumePotion(potionId)
                        consumed += 1
                        task.wait(0.3)
                    end
                end
            end
        end
    end

    -- Method 2: Also check the Character (equipped tools)
    if consumed < amount and player.Character then
        for _, item in pairs(player.Character:GetChildren()) do
            if consumed >= amount then break end
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("luck") or nameLower:find("potion") or nameLower:find("boost") then
                    local potionId = tonumber(item.Name:match("%d+"))
                    if potionId then
                        consumePotion(potionId)
                        consumed += 1
                        task.wait(0.3)
                    end
                end
            end
        end
    end

    -- Method 3: Try with gear attribute IDs if name didn't have a number
    if consumed < amount and backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if consumed >= amount then break end
            if item:IsA("Tool") then
                local nameLower = item.Name:lower()
                if nameLower:find("luck") or nameLower:find("potion") or nameLower:find("boost") then
                    local potionId = item:GetAttribute("BoostId") or item:GetAttribute("GearId") or item:GetAttribute("Id")
                    if potionId then
                        consumePotion(potionId)
                        consumed += 1
                        task.wait(0.3)
                    end
                end
            end
        end
    end

    -- Method 4: Scan player data folders for boost entries
    if consumed < amount then
        local dataFolders = {"Data", "PlayerData", "Gears", "Boosts", "Inventory"}
        for _, folderName in pairs(dataFolders) do
            if consumed >= amount then break end
            local folder = player:FindFirstChild(folderName)
            if folder then
                for _, child in pairs(folder:GetDescendants()) do
                    if consumed >= amount then break end
                    local childLower = child.Name:lower()
                    if childLower:find("luck") or childLower:find("boost") then
                        local id = nil
                        if child:IsA("ValueBase") then
                            id = child.Value
                        else
                            id = child:GetAttribute("Id") or child:GetAttribute("BoostId")
                        end
                        if id then
                            consumePotion(id)
                            consumed += 1
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end

    -- Method 5: Try string-based and no-arg approaches as last resort
    if consumed < amount then
        for i = 1, (amount - consumed) do
            pcall(function() ConsumeBoost:FireServer("luck_04") end)
            task.wait(0.2)
        end
    end

    return consumed
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
--  AUTO VOTE MAPS — Votes for rare maps (Baseplate > Glitch)
-- ═══════════════════════════════════════════════════════════════
local function startAutoVote()
    autoVoteLoop = task.spawn(function()
        while autoVoteEnabled do
            -- Priority: Baseplate > Glitch
            -- Vote for the highest priority map that is enabled
            if voteBaseplate then
                pcall(function() SendVote:FireServer("baseplate") end)
            end
            if voteGlitch and not voteBaseplate then
                pcall(function() SendVote:FireServer("glitch") end)
            elseif voteGlitch and voteBaseplate then
                -- Both enabled: still vote baseplate (priority), but also try glitch
                -- The primary vote is baseplate; send glitch too in case baseplate isn't available
                pcall(function() SendVote:FireServer("glitch") end)
            end

            -- Re-vote periodically to ensure the vote sticks
            task.wait(5)
        end
    end)
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

PotionTab:CreateSection("Configuration")

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

local BBToggle = PotionTab:CreateToggle({
    Name = "Use Beyond Breaker (before drinking)",
    CurrentValue = true,
    Flag = "UseBBToggle",
    Callback = function(Value)
        useBeyondBreaker = Value
        if Value then
            potionDuration = 45
        else
            potionDuration = 30
        end
    end,
})

local GearDropdown = PotionTab:CreateDropdown({
    Name = "Gear to Re-equip After",
    Options = {"Exagonios Inverter", "404 Eradicator"},
    CurrentOption = {"Exagonios Inverter"},
    MultipleOptions = false,
    Flag = "ReEquipGear",
    Callback = function(Options)
        local selected = Options[1] or Options
        if selected == "Exagonios Inverter" then
            reEquipGear = "exagoniosinverter"
        elseif selected == "404 Eradicator" then
            reEquipGear = "404eradicator"
        end
    end,
})

local DurationDropdown = PotionTab:CreateDropdown({
    Name = "Potion Duration",
    Options = {"30 min (no BB)", "45 min (with BB)"},
    CurrentOption = {"45 min (with BB)"},
    MultipleOptions = false,
    Flag = "PotionDuration",
    Callback = function(Options)
        local selected = Options[1] or Options
        if selected == "30 min (no BB)" then
            potionDuration = 30
        elseif selected == "45 min (with BB)" then
            potionDuration = 45
        end
    end,
})

PotionTab:CreateSection("Control")

local PotionToggle = PotionTab:CreateToggle({
    Name = "Auto Potion System",
    CurrentValue = false,
    Flag = "PotionSystem",
    Callback = function(Value)
        potionSystemEnabled = Value
        if Value then
            startPotionSystem()
        else
            if potionLoop then pcall(function() task.cancel(potionLoop) end) end
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  TAB: AUTO VOTE MAPS
-- ═══════════════════════════════════════════════════════════════
local VoteTab = Window:CreateTab("Auto Vote Maps", "vote")

VoteTab:CreateSection("Select Rare Maps to Vote For")

local GlitchToggle = VoteTab:CreateToggle({
    Name = "Vote for Glitch",
    CurrentValue = true,
    Flag = "VoteGlitch",
    Callback = function(Value)
        voteGlitch = Value
    end,
})

local BaseplateToggle = VoteTab:CreateToggle({
    Name = "Vote for Baseplate (highest priority)",
    CurrentValue = true,
    Flag = "VoteBaseplate",
    Callback = function(Value)
        voteBaseplate = Value
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
--  LOAD CONFIG
-- ═══════════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()
