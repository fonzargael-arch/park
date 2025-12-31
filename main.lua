--[[
    ═══════════════════════════════════════
    🍬 PARK A CAR - AUTO FARM CANDIES
    ═══════════════════════════════════════
    Auto recolecta candies automáticamente
    by Gael Fonzar
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
local collectRadius = 50
local teleportSpeed = 0.1

local candiesCollected = 0
local candyMarkers = {}

-- Colors
local candyColor = Color3.fromRGB(255, 105, 180)

-- ═══════════════════════════════════════
-- 🍬 CANDY FINDER
-- ═══════════════════════════════════════

local function findCandies()
    local candies = {}
    
    -- Buscar en diferentes ubicaciones posibles
    local searchLocations = {
        Workspace,
        Workspace:FindFirstChild("Candies"),
        Workspace:FindFirstChild("Candy"),
        Workspace:FindFirstChild("Items"),
        Workspace:FindFirstChild("Collectibles")
    }
    
    for _, location in pairs(searchLocations) do
        if location then
            for _, obj in pairs(location:GetDescendants()) do
                local name = obj.Name:lower()
                
                -- Buscar por nombre común de candies
                if (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") or obj:IsA("Model")) and 
                   (name:find("candy") or name:find("sweet") or name:find("coin") or name:find("collect")) then
                    
                    -- Verificar que tenga ClickDetector o ProximityPrompt
                    local hasInteraction = obj:FindFirstChildOfClass("ClickDetector") or 
                                          obj:FindFirstChildOfClass("ProximityPrompt") or
                                          obj:FindFirstChild("ClickDetector") or
                                          obj:FindFirstChild("ProximityPrompt")
                    
                    if hasInteraction or obj:IsA("Model") then
                        table.insert(candies, obj)
                    end
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
    if candy:FindFirstChild("CANDY_MARKER") then return end
    
    local candyPart = candy:IsA("Model") and candy.PrimaryPart or candy
    if not candyPart then return end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "CANDY_MARKER"
    highlight.Parent = candy
    highlight.FillColor = candyColor
    highlight.OutlineColor = candyColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    
    -- Billboard con distancia
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CANDY_BILLBOARD"
    billboard.Parent = candyPart
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    local frame = Instance.new("Frame")
    frame.Parent = billboard
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 1, 0)
    
    local candyLabel = Instance.new("TextLabel")
    candyLabel.Parent = frame
    candyLabel.Size = UDim2.new(1, 0, 0.5, 0)
    candyLabel.BackgroundTransparency = 1
    candyLabel.TextColor3 = candyColor
    candyLabel.TextStrokeTransparency = 0
    candyLabel.Font = Enum.Font.GothamBold
    candyLabel.TextSize = 14
    candyLabel.Text = "🍬"
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = frame
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12
    
    -- Update distancia
    task.spawn(function()
        while distLabel.Parent and candyPart.Parent do
            task.wait(0.5)
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (candyPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                distLabel.Text = math.floor(dist) .. "m"
            end
        end
    end)
    
    table.insert(candyMarkers, candy)
end

local function enableCandyESP()
    candyESPEnabled = true
    
    local candies = findCandies()
    
    for _, candy in pairs(candies) do
        createCandyMarker(candy)
    end
end

local function disableCandyESP()
    candyESPEnabled = false
    
    for _, candy in pairs(candyMarkers) do
        if candy and candy.Parent then
            local marker = candy:FindFirstChild("CANDY_MARKER")
            local billboard = candy:FindFirstChild("CANDY_BILLBOARD")
            if marker then marker:Destroy() end
            if billboard then billboard:Destroy() end
        end
    end
    candyMarkers = {}
end

local function updateCandyESP()
    disableCandyESP()
    task.wait(0.2)
    if candyESPEnabled then
        enableCandyESP()
    end
end

-- ═══════════════════════════════════════
-- 🚀 AUTO FARM
-- ═══════════════════════════════════════

local function collectCandy(candy)
    if not candy or not candy.Parent then return false end
    
    local candyPart = candy:IsA("Model") and candy.PrimaryPart or candy
    if not candyPart then return false end
    
    local char = player.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Teleport al candy
    local originalCFrame = hrp.CFrame
    hrp.CFrame = candyPart.CFrame + Vector3.new(0, 3, 0)
    
    task.wait(teleportSpeed)
    
    -- Intentar activar ClickDetector
    local clickDetector = candy:FindFirstChildOfClass("ClickDetector") or 
                         candyPart:FindFirstChildOfClass("ClickDetector")
    
    if clickDetector then
        fireclickdetector(clickDetector)
    end
    
    -- Intentar activar ProximityPrompt
    local proximityPrompt = candy:FindFirstChildOfClass("ProximityPrompt") or 
                           candyPart:FindFirstChildOfClass("ProximityPrompt")
    
    if proximityPrompt then
        fireproximityprompt(proximityPrompt)
    end
    
    task.wait(0.1)
    
    return true
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
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            
            table.sort(candies, function(a, b)
                local aPart = a:IsA("Model") and a.PrimaryPart or a
                local bPart = b:IsA("Model") and b.PrimaryPart or b
                
                if not aPart or not bPart then return false end
                
                local distA = (aPart.Position - hrp.Position).Magnitude
                local distB = (bPart.Position - hrp.Position).Magnitude
                
                return distA < distB
            end)
            
            -- Recolectar candies dentro del radio
            for _, candy in pairs(candies) do
                if not autoFarmEnabled then break end
                
                local candyPart = candy:IsA("Model") and candy.PrimaryPart or candy
                if candyPart then
                    local dist = (candyPart.Position - hrp.Position).Magnitude
                    
                    if dist <= collectRadius then
                        local success = collectCandy(candy)
                        if success then
                            candiesCollected = candiesCollected + 1
                            task.wait(teleportSpeed)
                        end
                    end
                end
            end
        end
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
                Content = "Activado - Recolectando candies", 
                Duration = 3
            })
        else
            disableAutoFarm()
            Rayfield:Notify({
                Title = "Auto Farm", 
                Content = "Desactivado", 
                Duration = 2
            })
        end
    end
})

FarmTab:CreateSlider({
    Name = "Collect Radius",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "CollectRadius",
    Callback = function(v)
        collectRadius = v
    end
})

FarmTab:CreateSlider({
    Name = "Teleport Speed",
    Range = {0, 1},
    Increment = 0.05,
    CurrentValue = 0.1,
    Flag = "TeleportSpeed",
    Callback = function(v)
        teleportSpeed = v
    end
})

FarmTab:CreateLabel("Candies Collected: 0")

-- Actualizar contador
task.spawn(function()
    while true do
        task.wait(1)
        
        -- Buscar el label y actualizarlo
        for _, tab in pairs(Window.Tabs) do
            if tab.Name == "🍬 Auto Farm" then
                for _, element in pairs(tab.Elements) do
                    if element.Type == "Label" and element.Name:find("Candies") then
                        element:Set("Candies Collected: " .. candiesCollected)
                    end
                end
            end
        end
    end
end)

FarmTab:CreateButton({
    Name = "🔄 Reset Counter",
    Callback = function()
        candiesCollected = 0
        Rayfield:Notify({Title = "Counter", Content = "Reseteado", Duration = 2})
    end
})

-- ESP TAB
local ESPTab = Window:CreateTab("👁️ Candy ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "👁️ Enable Candy ESP",
    CurrentValue = false,
    Flag = "CandyESP",
    Callback = function(v)
        if v then
            enableCandyESP()
            Rayfield:Notify({Title = "ESP", Content = "Activado", Duration = 2})
        else
            disableCandyESP()
        end
    end
})

ESPTab:CreateButton({
    Name = "🔄 Refresh ESP",
    Callback = function()
        updateCandyESP()
        Rayfield:Notify({Title = "ESP", Content = "Actualizado", Duration = 2})
    end
})

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

MiscTab:CreateLabel("🍬 Auto Farm Candies")
MiscTab:CreateLabel("⚡ Teleport instantáneo")
MiscTab:CreateLabel("✅ ESP incluido")

-- Success
Rayfield:Notify({
    Title = "✅ Loaded!",
    Content = "Park A Car Auto Farm listo",
    Duration = 5
})

print("✅ Park A Car - Auto Farm Candies loaded!")
print("🍬 Recolección automática activada")
