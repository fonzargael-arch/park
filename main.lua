--[[
    ═══════════════════════════════════════
    🍬 PARK A CAR - AUTO FARM CANDIES V2
    ═══════════════════════════════════════
    Auto recolecta candies automáticamente
    by Gael Fonzar
    
    LOADSTRING:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fonzargael-arch/park/main/main.lua"))()
    ═══════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Load UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local autoFarmEnabled = false
local candyESPEnabled = false
local collectRadius = 100
local teleportDelay = 0.2

local candiesCollected = 0
local candyMarkers = {}

-- Colors
local candyColor = Color3.fromRGB(255, 105, 180)

-- ═══════════════════════════════════════
-- 🔍 DETECTAR ESTRUCTURA DEL JUEGO
-- ═══════════════════════════════════════

local function debugWorkspace()
    print("═══════════════════════════════════")
    print("🔍 DEBUG: Escaneando Workspace...")
    print("═══════════════════════════════════")
    
    for _, child in pairs(Workspace:GetChildren()) do
        print("📁 Workspace." .. child.Name .. " (" .. child.ClassName .. ")")
    end
    
    print("═══════════════════════════════════")
end

-- ═══════════════════════════════════════
-- 🍬 CANDY FINDER - MEJORADO
-- ═══════════════════════════════════════

local function findCandies()
    local candies = {}
    
    -- Buscar en TODO el Workspace recursivamente
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- Buscar objetos coleccionables
            local isCandy = name:find("candy") or 
                          name:find("coin") or 
                          name:find("collect") or
                          name:find("sweet") or
                          name:find("prize") or
                          name:find("reward") or
                          name:find("pickup")
            
            if isCandy then
                -- Verificar que tenga algún método de interacción
                local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true)
                local hasProximity = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                local hasTouchInterest = obj:FindFirstChildWhichIsA("TouchTransmitter", true)
                
                if hasClick or hasProximity or hasTouchInterest or obj.CanTouch then
                    table.insert(candies, obj)
                end
            end
        end
    end
    
    return candies
end

-- ═══════════════════════════════════════
-- 🎯 CANDY ESP
-- ═══════════════════════════════════════

local function createCandyMarker(candy)
    pcall(function()
        if candy:FindFirstChild("CANDY_MARKER") then return end
        
        local candyPart = candy:IsA("Model") and (candy.PrimaryPart or candy:FindFirstChildWhichIsA("BasePart")) or candy
        if not candyPart or not candyPart:IsA("BasePart") then return end
        
        -- Highlight
        local highlight = Instance.new("Highlight")
        highlight.Name = "CANDY_MARKER"
        highlight.Parent = candy
        highlight.FillColor = candyColor
        highlight.OutlineColor = candyColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Adornee = candy
        
        -- Billboard
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CANDY_BILLBOARD"
        billboard.Parent = candyPart
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboard
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = candyColor
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.Text = "🍬 CANDY"
        
        table.insert(candyMarkers, candy)
    end)
end

local function enableCandyESP()
    candyESPEnabled = true
    
    task.spawn(function()
        while candyESPEnabled do
            local candies = findCandies()
            
            for _, candy in pairs(candies) do
                if candy.Parent then
                    createCandyMarker(candy)
                end
            end
            
            task.wait(2)
        end
    end)
end

local function disableCandyESP()
    candyESPEnabled = false
    
    for _, candy in pairs(candyMarkers) do
        pcall(function()
            if candy and candy.Parent then
                local marker = candy:FindFirstChild("CANDY_MARKER")
                local billboard = candy:FindFirstChild("CANDY_BILLBOARD")
                if marker then marker:Destroy() end
                if billboard then billboard:Destroy() end
            end
        end)
    end
    candyMarkers = {}
end

-- ═══════════════════════════════════════
-- 🚀 AUTO FARM - MÉTODO UNIVERSAL
-- ═══════════════════════════════════════

local function tryCollectCandy(candy)
    local success = false
    
    pcall(function()
        if not candy or not candy.Parent then return end
        
        local char = player.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Obtener la parte principal
        local candyPart = candy:IsA("Model") and (candy.PrimaryPart or candy:FindFirstChildWhichIsA("BasePart")) or candy
        if not candyPart or not candyPart:IsA("BasePart") then return end
        
        -- Guardar posición original
        local originalCFrame = hrp.CFrame
        
        -- Teleport cerca del candy
        hrp.CFrame = candyPart.CFrame + Vector3.new(0, 5, 0)
        task.wait(0.05)
        
        -- Método 1: ClickDetector
        local clickDetector = candy:FindFirstChildWhichIsA("ClickDetector", true)
        if clickDetector then
            fireclickdetector(clickDetector)
            success = true
        end
        
        -- Método 2: ProximityPrompt
        local proximityPrompt = candy:FindFirstChildWhichIsA("ProximityPrompt", true)
        if proximityPrompt then
            fireproximityprompt(proximityPrompt)
            success = true
        end
        
        -- Método 3: Touch (para candies que se activan por toque)
        if candyPart.CanTouch then
            hrp.CFrame = candyPart.CFrame
            task.wait(0.1)
            success = true
        end
        
        -- Método 4: Tocar físicamente
        firetouchinterest(hrp, candyPart, 0)
        task.wait(0.05)
        firetouchinterest(hrp, candyPart, 1)
        success = true
        
        task.wait(teleportDelay)
    end)
    
    return success
end

local function autoFarmLoop()
    while autoFarmEnabled do
        task.wait(0.5)
        
        local candies = findCandies()
        
        if #candies == 0 then
            task.wait(2)
            continue
        end
        
        -- Ordenar por distancia
        pcall(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                
                table.sort(candies, function(a, b)
                    local aPart = a:IsA("Model") and (a.PrimaryPart or a:FindFirstChildWhichIsA("BasePart")) or a
                    local bPart = b:IsA("Model") and (b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")) or b
                    
                    if not aPart or not bPart then return false end
                    
                    local distA = (aPart.Position - hrp.Position).Magnitude
                    local distB = (bPart.Position - hrp.Position).Magnitude
                    
                    return distA < distB
                end)
                
                -- Recolectar candies
                for _, candy in pairs(candies) do
                    if not autoFarmEnabled then break end
                    
                    local candyPart = candy:IsA("Model") and (candy.PrimaryPart or candy:FindFirstChildWhichIsA("BasePart")) or candy
                    
                    if candyPart and candyPart:IsA("BasePart") then
                        local dist = (candyPart.Position - hrp.Position).Magnitude
                        
                        if dist <= collectRadius then
                            if tryCollectCandy(candy) then
                                candiesCollected = candiesCollected + 1
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function enableAutoFarm()
    autoFarmEnabled = true
    task.spawn(autoFarmLoop)
end

local function disableAutoFarm()
    autoFarmEnabled = false
end

-- ═══════════════════════════════════════
-- 🎨 GUI
-- ═══════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "🍬 Park A Car - Auto Farm V2",
    LoadingTitle = "Cargando...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ParkACarHub",
        FileName = "Config"
    },
    KeySystem = false
})

-- AUTO FARM TAB
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
                Content = "✅ Farmeo activado", 
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

FarmTab:CreateSlider({
    Name = "Collect Radius",
    Range = {20, 300},
    Increment = 10,
    CurrentValue = 100,
    Flag = "CollectRadius",
    Callback = function(v)
        collectRadius = v
    end
})

FarmTab:CreateSlider({
    Name = "Teleport Delay",
    Range = {0.1, 1},
    Increment = 0.05,
    CurrentValue = 0.2,
    Flag = "TeleportDelay",
    Callback = function(v)
        teleportDelay = v
    end
})

local statsLabel = FarmTab:CreateLabel("Candies: 0")

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            statsLabel:Set("Candies Collected: " .. candiesCollected)
        end)
    end
end)

FarmTab:CreateButton({
    Name = "🔄 Reset Counter",
    Callback = function()
        candiesCollected = 0
        Rayfield:Notify({Title = "Reset", Content = "Contador en 0", Duration = 2})
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
    Name = "🔍 Debug Workspace",
    Callback = function()
        debugWorkspace()
        Rayfield:Notify({Title = "Debug", Content = "Revisa la consola F9", Duration = 3})
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

-- MISC TAB
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateButton({
    Name = "🔄 Rejoin",
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

MiscTab:CreateLabel("✅ V2 - Universal candy detector")
MiscTab:CreateLabel("🔍 Busca en todo el Workspace")
MiscTab:CreateLabel("⚡ 4 métodos de colección")

-- Notificación final
Rayfield:Notify({
    Title = "✅ Loaded!",
    Content = "Auto Farm V2 - Método universal",
    Duration = 5
})

print("═══════════════════════════════════")
print("✅ Park A Car Auto Farm V2")
print("🍬 Método universal de detección")
print("═══════════════════════════════════")

-- Auto-debug al cargar
task.wait(2)
debugWorkspace()
