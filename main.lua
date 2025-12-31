--[[
    ═══════════════════════════════════════
    🍬 PARK A CAR - AUTO FARM (WORKING)
    ═══════════════════════════════════════
    Auto recolecta candies por Touch
    by Gael Fonzar
    
    LOADSTRING:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fonzargael-arch/park/main/main.lua"))()
    ═══════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Load UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local autoFarmEnabled = false
local candyESPEnabled = false
local collectRadius = 150
local teleportDelay = 0.15
local useInstantTP = true

local candiesCollected = 0
local sessionStart = tick()

-- ═══════════════════════════════════════
-- 🍬 CANDY FINDER - OPTIMIZADO
-- ═══════════════════════════════════════

local function findAllCandies()
    local candies = {}
    
    -- Buscar en Workspace.CandyCurrencies
    local candyFolder = Workspace:FindFirstChild("CandyCurrencies")
    if candyFolder then
        for _, obj in pairs(candyFolder:GetChildren()) do
            if obj.Name == "Candy" and obj:IsA("BasePart") then
                table.insert(candies, obj)
            end
        end
    end
    
    return candies
end

-- ═══════════════════════════════════════
-- 🎯 CANDY ESP
-- ═══════════════════════════════════════

local espObjects = {}

local function createCandyESP(candy)
    if not candy or not candy.Parent then return end
    if candy:FindFirstChild("ESP_MARKER") then return end
    
    pcall(function()
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_MARKER"
        highlight.Parent = candy
        highlight.FillColor = Color3.fromRGB(255, 105, 180)
        highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        -- BillboardGui
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_BILLBOARD"
        billboard.Parent = candy
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        
        local label = Instance.new("TextLabel")
        label.Parent = billboard
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Text = "🍬"
        
        table.insert(espObjects, {candy = candy, highlight = highlight, billboard = billboard})
    end)
end

local function updateCandyESP()
    local candies = findAllCandies()
    
    for _, candy in pairs(candies) do
        if candy and candy.Parent then
            createCandyESP(candy)
        end
    end
end

local function enableCandyESP()
    candyESPEnabled = true
    
    task.spawn(function()
        while candyESPEnabled do
            updateCandyESP()
            task.wait(2)
        end
    end)
end

local function disableCandyESP()
    candyESPEnabled = false
    
    for _, espData in pairs(espObjects) do
        pcall(function()
            if espData.highlight then espData.highlight:Destroy() end
            if espData.billboard then espData.billboard:Destroy() end
        end)
    end
    
    espObjects = {}
end

-- ═══════════════════════════════════════
-- 🚀 AUTO FARM - TOUCH METHOD
-- ═══════════════════════════════════════

local function collectCandy(candy)
    if not candy or not candy.Parent then return false end
    
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local success = false
    
    pcall(function()
        -- Método 1: Teleport directo (instantáneo)
        if useInstantTP then
            hrp.CFrame = candy.CFrame
            task.wait(0.05)
        else
            -- Método 2: Teleport suave
            local distance = (candy.Position - hrp.Position).Magnitude
            local steps = math.ceil(distance / 50)
            
            for i = 1, steps do
                if not candy.Parent then break end
                
                local alpha = i / steps
                hrp.CFrame = hrp.CFrame:Lerp(candy.CFrame, alpha)
                task.wait(0.02)
            end
        end
        
        -- Tocar el candy (método principal)
        firetouchinterest(hrp, candy, 0)
        task.wait(0.02)
        firetouchinterest(hrp, candy, 1)
        
        task.wait(teleportDelay)
        success = true
    end)
    
    return success
end

local function autoFarmLoop()
    while autoFarmEnabled do
        task.wait(0.1)
        
        local candies = findAllCandies()
        
        if #candies == 0 then
            task.wait(1)
            continue
        end
        
        -- Obtener posición del jugador
        pcall(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            local hrp = player.Character.HumanoidRootPart
            
            -- Ordenar por distancia
            table.sort(candies, function(a, b)
                if not a.Parent or not b.Parent then return false end
                
                local distA = (a.Position - hrp.Position).Magnitude
                local distB = (b.Position - hrp.Position).Magnitude
                
                return distA < distB
            end)
            
            -- Recolectar candies cercanos
            for _, candy in pairs(candies) do
                if not autoFarmEnabled then break end
                if not candy.Parent then continue end
                
                local dist = (candy.Position - hrp.Position).Magnitude
                
                if dist <= collectRadius then
                    if collectCandy(candy) then
                        candiesCollected = candiesCollected + 1
                    end
                end
            end
        end)
    end
end

local function enableAutoFarm()
    autoFarmEnabled = true
    sessionStart = tick()
    task.spawn(autoFarmLoop)
end

local function disableAutoFarm()
    autoFarmEnabled = false
end

-- ═══════════════════════════════════════
-- 📊 STATS
-- ═══════════════════════════════════════

local function getSessionTime()
    local elapsed = tick() - sessionStart
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    return string.format("%dm %ds", minutes, seconds)
end

local function getCandiesPerMinute()
    local elapsed = tick() - sessionStart
    if elapsed < 1 then return 0 end
    return math.floor((candiesCollected / elapsed) * 60)
end

-- ═══════════════════════════════════════
-- 🎨 GUI
-- ═══════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "🍬 Park A Car - Auto Farm",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ParkACarHub",
        FileName = "Config"
    },
    KeySystem = false
})

-- FARM TAB
local FarmTab = Window:CreateTab("🍬 Auto Farm", 4483362458)

FarmTab:CreateToggle({
    Name = "🍬 Enable Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        if v then
            enableAutoFarm()
            Rayfield:Notify({
                Title = "Auto Farm", 
                Content = "✅ Activado - Recolectando candies", 
                Duration = 3
            })
        else
            disableAutoFarm()
            Rayfield:Notify({
                Title = "Auto Farm", 
                Content = "❌ Desactivado", 
                Duration = 2
            })
        end
    end
})

FarmTab:CreateToggle({
    Name = "⚡ Instant Teleport",
    CurrentValue = true,
    Flag = "InstantTP",
    Callback = function(v)
        useInstantTP = v
    end
})

FarmTab:CreateSlider({
    Name = "Collect Radius",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "CollectRadius",
    Callback = function(v)
        collectRadius = v
    end
})

FarmTab:CreateSlider({
    Name = "Teleport Delay (s)",
    Range = {0.05, 0.5},
    Increment = 0.05,
    CurrentValue = 0.15,
    Flag = "TeleportDelay",
    Callback = function(v)
        teleportDelay = v
    end
})

FarmTab:CreateLabel("═══════════════════════")

local statsLabel = FarmTab:CreateLabel("📊 Candies: 0")
local timeLabel = FarmTab:CreateLabel("⏱️ Time: 0m 0s")
local rateLabel = FarmTab:CreateLabel("⚡ Rate: 0/min")

-- Update stats
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statsLabel:Set("📊 Candies: " .. candiesCollected)
            timeLabel:Set("⏱️ Time: " .. getSessionTime())
            rateLabel:Set("⚡ Rate: " .. getCandiesPerMinute() .. "/min")
        end)
    end
end)

FarmTab:CreateButton({
    Name = "🔄 Reset Stats",
    Callback = function()
        candiesCollected = 0
        sessionStart = tick()
        Rayfield:Notify({Title = "Stats", Content = "Reseteadas", Duration = 2})
    end
})

-- ESP TAB
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "👁️ Candy ESP",
    CurrentValue = false,
    Flag = "CandyESP",
    Callback = function(v)
        if v then
            enableCandyESP()
            Rayfield:Notify({Title = "ESP", Content = "✅ Activado", Duration = 2})
        else
            disableCandyESP()
            Rayfield:Notify({Title = "ESP", Content = "❌ Desactivado", Duration = 2})
        end
    end
})

ESPTab:CreateButton({
    Name = "🔄 Refresh ESP",
    Callback = function()
        disableCandyESP()
        task.wait(0.3)
        enableCandyESP()
        Rayfield:Notify({Title = "ESP", Content = "Actualizado", Duration = 2})
    end
})

ESPTab:CreateLabel("═══════════════════════")
ESPTab:CreateLabel("✅ Detecta candies en:")
ESPTab:CreateLabel("📁 Workspace.CandyCurrencies")
ESPTab:CreateLabel("🎯 Método: Touch")

-- MISC TAB
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end
})

MiscTab:CreateButton({
    Name = "🗑️ Destroy GUI",
    Callback = function()
        disableAutoFarm()
        disableCandyESP()
        Rayfield:Destroy()
    end
})

MiscTab:CreateLabel("═══════════════════════")
MiscTab:CreateLabel("✅ Working 100%")
MiscTab:CreateLabel("🎯 Touch method")
MiscTab:CreateLabel("⚡ Instant teleport")
MiscTab:CreateLabel("📊 Stats en tiempo real")

-- Notificación de carga
Rayfield:Notify({
    Title = "✅ Loaded!",
    Content = "Auto Farm listo para usar",
    Duration = 5
})

print("═══════════════════════════════════")
print("✅ Park A Car - Auto Farm WORKING")
print("📁 Detecta: Workspace.CandyCurrencies.Candy")
print("🎯 Método: Touch (firetouchinterest)")
print("═══════════════════════════════════")
