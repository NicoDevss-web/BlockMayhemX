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

-- Vote config
local voteGlitch = true
local voteBaseplate = true
local voteVoid = false
local voteOverworld = false
local voteArctic = false
local voteDreamland = false
local voteCave = false
local voteOcean = false
local voteLava = false

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
--  AUTO VOTE MAPS — Votes for rare maps (priority order)
-- ═══════════════════════════════════════════════════════════════
local function startAutoVote()
    autoVoteLoop = task.spawn(function()
        while autoVoteEnabled do
            -- Priority order: Baseplate > Glitch > Void > Overworld > Arctic > Dreamland > Cave > Ocean > Lava
            -- All enabled maps get voted for
            local voteMap = {
                {enabled = voteBaseplate, name = "baseplate"},
                {enabled = voteGlitch, name = "glitch"},
                {enabled = voteVoid, name = "void"},
                {enabled = voteOverworld, name = "overworld"},
                {enabled = voteArctic, name = "arctic"},
                {enabled = voteDreamland, name = "dreamland"},
                {enabled = voteCave, name = "cave"},
                {enabled = voteOcean, name = "ocean"},
                {enabled = voteLava, name = "lava"},
            }

            for _, entry in ipairs(voteMap) do
                if entry.enabled then
                    pcall(function() SendVote:FireServer(entry.name) end)
                    break -- Only vote for the highest priority enabled map
                end
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

VoteTab:CreateSection("Select Maps to Vote For (priority order)")

local BaseplateToggle = VoteTab:CreateToggle({
    Name = "Vote for Baseplate (highest priority)",
    CurrentValue = true,
    Flag = "VoteBaseplate",
    Callback = function(Value)
        voteBaseplate = Value
    end,
})

local GlitchToggle = VoteTab:CreateToggle({
    Name = "Vote for Glitch",
    CurrentValue = true,
    Flag = "VoteGlitch",
    Callback = function(Value)
        voteGlitch = Value
    end,
})

local VoidToggle = VoteTab:CreateToggle({
    Name = "Vote for Void",
    CurrentValue = false,
    Flag = "VoteVoid",
    Callback = function(Value)
        voteVoid = Value
    end,
})

local OverworldToggle = VoteTab:CreateToggle({
    Name = "Vote for Overworld",
    CurrentValue = false,
    Flag = "VoteOverworld",
    Callback = function(Value)
        voteOverworld = Value
    end,
})

local ArcticToggle = VoteTab:CreateToggle({
    Name = "Vote for Arctic",
    CurrentValue = false,
    Flag = "VoteArctic",
    Callback = function(Value)
        voteArctic = Value
    end,
})

local DreamlandToggle = VoteTab:CreateToggle({
    Name = "Vote for Dreamland",
    CurrentValue = false,
    Flag = "VoteDreamland",
    Callback = function(Value)
        voteDreamland = Value
    end,
})

local CaveToggle = VoteTab:CreateToggle({
    Name = "Vote for Cave",
    CurrentValue = false,
    Flag = "VoteCave",
    Callback = function(Value)
        voteCave = Value
    end,
})

local OceanToggle = VoteTab:CreateToggle({
    Name = "Vote for Ocean",
    CurrentValue = false,
    Flag = "VoteOcean",
    Callback = function(Value)
        voteOcean = Value
    end,
})

local LavaToggle = VoteTab:CreateToggle({
    Name = "Vote for Lava",
    CurrentValue = false,
    Flag = "VoteLava",
    Callback = function(Value)
        voteLava = Value
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
--  TAB: TESTING
-- ═══════════════════════════════════════════════════════════════
local TestTab = Window:CreateTab("Testing", "bug")

TestTab:CreateSection("Gear Switching")

TestTab:CreateButton({
    Name = "Switch Gear to Beyond Breaker",
    Callback = function()
        pcall(function() EquipGear:FireServer("beyondbreaker") end)
        Rayfield:Notify({
            Title = "Testing",
            Content = "Equipped Beyond Breaker!",
            Duration = 3,
        })
    end,
})

TestTab:CreateButton({
    Name = "Switch Gear to ExagoniosInverter",
    Callback = function()
        pcall(function() EquipGear:FireServer("exagoniosinverter") end)
        Rayfield:Notify({
            Title = "Testing",
            Content = "Equipped Exagonios Inverter!",
            Duration = 3,
        })
    end,
})

TestTab:CreateButton({
    Name = "Switch Gear to 404 Eradicator",
    Callback = function()
        pcall(function() EquipGear:FireServer("404eradicator") end)
        Rayfield:Notify({
            Title = "Testing",
            Content = "Equipped 404 Eradicator!",
            Duration = 3,
        })
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  LOAD CONFIG
-- ═══════════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()
