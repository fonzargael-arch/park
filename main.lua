--[[
    ═══════════════════════════════════════
    🔍 PARK A CAR - MINI SCANNER
    ═══════════════════════════════════════
    Escanea y muestra TODO lo coleccionable
    by Gael Fonzar
    ═══════════════════════════════════════
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Load UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🔍 Park A Car Scanner",
    LoadingTitle = "Escaneando...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

local ScanTab = Window:CreateTab("🔍 Scanner", 4483362458)
local ResultsTab = Window:CreateTab("📋 Results", 4483362458)

local scanResults = {
    total = 0,
    withClick = 0,
    withProximity = 0,
    withTouch = 0,
    items = {}
}

-- ═══════════════════════════════════════
-- 🔍 SCANNER FUNCTIONS
-- ═══════════════════════════════════════

local function scanWorkspace()
    scanResults = {
        total = 0,
        withClick = 0,
        withProximity = 0,
        withTouch = 0,
        items = {}
    }
    
    local consoleOutput = ""
    
    consoleOutput = consoleOutput .. "═══════════════════════════════════\n"
    consoleOutput = consoleOutput .. "🔍 INICIANDO ESCANEO COMPLETO...\n"
    consoleOutput = consoleOutput .. "═══════════════════════════════════\n"
    
    print("═══════════════════════════════════")
    print("🔍 INICIANDO ESCANEO COMPLETO...")
    print("═══════════════════════════════════")
    
    -- Escanear TODO el Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            
            -- Buscar palabras clave
            local keywords = {
                "candy", "coin", "collect", "sweet", "prize", 
                "reward", "pickup", "loot", "gem", "star",
                "money", "cash", "dollar", "gold"
            }
            
            local isCollectable = false
            local matchedKeyword = ""
            
            for _, keyword in pairs(keywords) do
                if name:find(keyword) then
                    isCollectable = true
                    matchedKeyword = keyword
                    break
                end
            end
            
            if isCollectable then
                -- Detectar métodos de interacción
                local hasClick = obj:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
                local hasProximity = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
                local hasTouch = obj.CanTouch or obj:FindFirstChildWhichIsA("TouchTransmitter", true) ~= nil
                
                local itemInfo = {
                    name = obj.Name,
                    path = obj:GetFullName(),
                    type = obj.ClassName,
                    keyword = matchedKeyword,
                    hasClick = hasClick,
                    hasProximity = hasProximity,
                    hasTouch = hasTouch,
                    position = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetModelCFrame().Position or Vector3.new(0,0,0))
                }
                
                table.insert(scanResults.items, itemInfo)
                scanResults.total = scanResults.total + 1
                
                if hasClick then scanResults.withClick = scanResults.withClick + 1 end
                if hasProximity then scanResults.withProximity = scanResults.withProximity + 1 end
                if hasTouch then scanResults.withTouch = scanResults.withTouch + 1 end
                
                -- Print individual
                local itemOutput = "───────────────────────────────────\n"
                itemOutput = itemOutput .. "📦 ENCONTRADO: " .. obj.Name .. "\n"
                itemOutput = itemOutput .. "   Tipo: " .. obj.ClassName .. "\n"
                itemOutput = itemOutput .. "   Path: " .. obj:GetFullName() .. "\n"
                itemOutput = itemOutput .. "   Keyword: " .. matchedKeyword .. "\n"
                itemOutput = itemOutput .. "   ClickDetector: " .. (hasClick and "✅" or "❌") .. "\n"
                itemOutput = itemOutput .. "   ProximityPrompt: " .. (hasProximity and "✅" or "❌") .. "\n"
                itemOutput = itemOutput .. "   Touch: " .. (hasTouch and "✅" or "❌") .. "\n"
                
                if obj:IsA("BasePart") then
                    itemOutput = itemOutput .. "   Position: " .. tostring(obj.Position) .. "\n"
                end
                
                consoleOutput = consoleOutput .. itemOutput
                
                print("───────────────────────────────────")
                print("📦 ENCONTRADO: " .. obj.Name)
                print("   Tipo: " .. obj.ClassName)
                print("   Path: " .. obj:GetFullName())
                print("   Keyword: " .. matchedKeyword)
                print("   ClickDetector: " .. (hasClick and "✅" or "❌"))
                print("   ProximityPrompt: " .. (hasProximity and "✅" or "❌"))
                print("   Touch: " .. (hasTouch and "✅" or "❌"))
                
                if obj:IsA("BasePart") then
                    print("   Position: " .. tostring(obj.Position))
                end
            end
        end
    end
    
    print("═══════════════════════════════════")
    print("📊 RESUMEN DEL ESCANEO:")
    print("═══════════════════════════════════")
    print("Total encontrados: " .. scanResults.total)
    print("Con ClickDetector: " .. scanResults.withClick)
    print("Con ProximityPrompt: " .. scanResults.withProximity)
    print("Con Touch: " .. scanResults.withTouch)
    print("═══════════════════════════════════")
    
    -- Agregar resumen al output
    consoleOutput = consoleOutput .. "═══════════════════════════════════\n"
    consoleOutput = consoleOutput .. "📊 RESUMEN DEL ESCANEO:\n"
    consoleOutput = consoleOutput .. "═══════════════════════════════════\n"
    consoleOutput = consoleOutput .. "Total encontrados: " .. scanResults.total .. "\n"
    consoleOutput = consoleOutput .. "Con ClickDetector: " .. scanResults.withClick .. "\n"
    consoleOutput = consoleOutput .. "Con ProximityPrompt: " .. scanResults.withProximity .. "\n"
    consoleOutput = consoleOutput .. "Con Touch: " .. scanResults.withTouch .. "\n"
    consoleOutput = consoleOutput .. "═══════════════════════════════════\n"
    
    -- Copiar automáticamente al clipboard
    pcall(function()
        setclipboard(consoleOutput)
        print("✅ RESULTADOS COPIADOS AL PORTAPAPELES!")
    end)
    
    return scanResults
end

local function createVisualMarkers()
    -- Limpiar markers anteriores
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "SCANNER_MARKER" or obj.Name == "SCANNER_BILLBOARD" then
            obj:Destroy()
        end
    end
    
    -- Crear markers para cada item encontrado
    for _, item in pairs(scanResults.items) do
        pcall(function()
            local obj = game:GetService("Workspace"):FindFirstChild(item.name, true)
            if obj and obj.Parent then
                -- Highlight
                local highlight = Instance.new("Highlight")
                highlight.Name = "SCANNER_MARKER"
                highlight.Parent = obj
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                
                -- Billboard
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "SCANNER_BILLBOARD"
                    billboard.Parent = part
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 200, 0, 80)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    
                    local frame = Instance.new("Frame")
                    frame.Parent = billboard
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Parent = frame
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextSize = 12
                    nameLabel.TextColor3 = Color3.new(1, 1, 1)
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.Text = "🎯 " .. item.name
                    
                    local infoLabel = Instance.new("TextLabel")
                    infoLabel.Parent = frame
                    infoLabel.BackgroundTransparency = 1
                    infoLabel.Size = UDim2.new(1, 0, 0.6, 0)
                    infoLabel.Position = UDim2.new(0, 0, 0.4, 0)
                    infoLabel.Font = Enum.Font.Gotham
                    infoLabel.TextSize = 10
                    infoLabel.TextColor3 = Color3.new(1, 1, 1)
                    infoLabel.TextStrokeTransparency = 0
                    
                    local methods = {}
                    if item.hasClick then table.insert(methods, "Click") end
                    if item.hasProximity then table.insert(methods, "Prox") end
                    if item.hasTouch then table.insert(methods, "Touch") end
                    
                    infoLabel.Text = table.concat(methods, ", ")
                end
            end
        end)
    end
end

local function clearMarkers()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "SCANNER_MARKER" or obj.Name == "SCANNER_BILLBOARD" then
            obj:Destroy()
        end
    end
end

-- ═══════════════════════════════════════
-- 🎨 GUI - SCAN TAB
-- ═══════════════════════════════════════

ScanTab:CreateButton({
    Name = "🔍 ESCANEAR TODO",
    Callback = function()
        Rayfield:Notify({
            Title = "Escaneando...", 
            Content = "Revisa la consola (F9)", 
            Duration = 3
        })
        
        local results = scanWorkspace()
        
        Rayfield:Notify({
            Title = "✅ Escaneo Completo", 
            Content = "Encontrados: " .. results.total .. " (Copiado!)", 
            Duration = 5
        })
    end
})

ScanTab:CreateButton({
    Name = "👁️ Mostrar Markers Visuales",
    Callback = function()
        if scanResults.total == 0 then
            Rayfield:Notify({
                Title = "Error", 
                Content = "Primero escanea!", 
                Duration = 3
            })
            return
        end
        
        createVisualMarkers()
        Rayfield:Notify({
            Title = "✅ Markers Creados", 
            Content = scanResults.total .. " items marcados", 
            Duration = 3
        })
    end
})

ScanTab:CreateButton({
    Name = "🗑️ Limpiar Markers",
    Callback = function()
        clearMarkers()
        Rayfield:Notify({
            Title = "✅ Limpiado", 
            Content = "Markers eliminados", 
            Duration = 2
        })
    end
})

ScanTab:CreateLabel("═══════════════════════")
ScanTab:CreateLabel("📋 INSTRUCCIONES:")
ScanTab:CreateLabel("1. Click 'ESCANEAR TODO'")
ScanTab:CreateLabel("2. Se copia AUTOMÁTICAMENTE")
ScanTab:CreateLabel("3. Pégalo donde quieras (Ctrl+V)")
ScanTab:CreateLabel("4. También sale en consola (F9)")

-- ═══════════════════════════════════════
-- 🎨 GUI - RESULTS TAB
-- ═══════════════════════════════════════

local statsLabel = ResultsTab:CreateLabel("📊 Total: 0")
local clickLabel = ResultsTab:CreateLabel("🖱️ ClickDetector: 0")
local proxLabel = ResultsTab:CreateLabel("📍 ProximityPrompt: 0")
local touchLabel = ResultsTab:CreateLabel("✋ Touch: 0")

ResultsTab:CreateButton({
    Name = "🔄 Actualizar Stats",
    Callback = function()
        statsLabel:Set("📊 Total: " .. scanResults.total)
        clickLabel:Set("🖱️ ClickDetector: " .. scanResults.withClick)
        proxLabel:Set("📍 ProximityPrompt: " .. scanResults.withProximity)
        touchLabel:Set("✋ Touch: " .. scanResults.withTouch)
        
        Rayfield:Notify({
            Title = "Stats", 
            Content = "Actualizadas", 
            Duration = 2
        })
    end
})

ResultsTab:CreateLabel("═══════════════════════")
ResultsTab:CreateLabel("📝 DETALLES:")

ResultsTab:CreateButton({
    Name = "📋 Copiar Lista al Clipboard",
    Callback = function()
        if scanResults.total == 0 then
            Rayfield:Notify({
                Title = "Error", 
                Content = "No hay resultados", 
                Duration = 2
            })
            return
        end
        
        local output = "═══════ SCAN RESULTS ═══════\n"
        output = output .. "Total: " .. scanResults.total .. "\n"
        output = output .. "ClickDetector: " .. scanResults.withClick .. "\n"
        output = output .. "ProximityPrompt: " .. scanResults.withProximity .. "\n"
        output = output .. "Touch: " .. scanResults.withTouch .. "\n\n"
        
        for i, item in pairs(scanResults.items) do
            output = output .. i .. ". " .. item.name .. "\n"
            output = output .. "   Path: " .. item.path .. "\n"
            output = output .. "   Type: " .. item.type .. "\n"
            local methods = {}
            if item.hasClick then table.insert(methods, "Click") end
            if item.hasProximity then table.insert(methods, "Prox") end
            if item.hasTouch then table.insert(methods, "Touch") end
            output = output .. "   Methods: " .. table.concat(methods, ", ") .. "\n\n"
        end
        
        setclipboard(output)
        
        Rayfield:Notify({
            Title = "✅ Copiado", 
            Content = "Lista en clipboard", 
            Duration = 3
        })
    end
})

-- ═══════════════════════════════════════
-- 🎨 GUI - MISC TAB
-- ═══════════════════════════════════════

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
        clearMarkers()
        Rayfield:Destroy()
    end
})

MiscTab:CreateLabel("═══════════════════════")
MiscTab:CreateLabel("🔍 Mini Scanner v1.0")
MiscTab:CreateLabel("📊 Detecta todo coleccionable")
MiscTab:CreateLabel("✅ Métodos de interacción")

-- Notificación inicial
Rayfield:Notify({
    Title = "✅ Scanner Loaded!",
    Content = "Presiona F9 para ver resultados",
    Duration = 5
})

print("═══════════════════════════════════")
print("🔍 PARK A CAR - MINI SCANNER")
print("═══════════════════════════════════")
print("✅ Scanner cargado")
print("📋 Presiona 'ESCANEAR TODO' para comenzar")
print("═══════════════════════════════════")
