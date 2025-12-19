--[[
    ═══════════════════════════════════════
    🔍 PARKING GAME SCANNER v1.0
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Solo Scanner - Analiza el mapa completo
    ═══════════════════════════════════════
]]

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Variables de Escaneo
local scannedData = {
    obstacles = {},
    parkingZones = {},
    vehicles = {},
    checkpoints = {},
    collectibles = {},
    damageZones = {},
    teleporters = {},
    scripts = {},
    allParts = {}
}

local scanStats = {
    totalObjects = 0,
    scanTime = 0,
    lastScan = "Never"
}

-- ═══════════════════════════════════════
-- 🔍 FUNCIONES DE IDENTIFICACIÓN
-- ═══════════════════════════════════════

local function isObstacle(part)
    if not part or not part:IsA("BasePart") then return false end
    if part.Name == "Floor" or part.Name == "Ground" or part.Name == "Baseplate" then return false end
    
    local keywords = {
        "Cone", "cone", "cono", 
        "Barrier", "barrier", "barrera",
        "Obstacle", "obstacle", "obstaculo",
        "Hazard", "hazard", "peligro",
        "Block", "block", "bloque",
        "Wall", "wall", "muro",
        "Fence", "fence", "valla"
    }
    
    local partName = part.Name:lower()
    for _, keyword in ipairs(keywords) do
        if string.find(partName, keyword:lower()) then 
            return true 
        end
    end
    
    -- Detectar por color (conos naranjas/rojos)
    local color = part.Color
    if (color.R > 0.7 and color.G < 0.5) or 
       (color.R > 0.7 and color.G > 0.6 and color.B < 0.3) then
        return true
    end
    
    return false
end

local function isParkingZone(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local keywords = {"Park", "park", "Goal", "goal", "Target", "target", "Win", "win", "Finish", "finish"}
    for _, keyword in ipairs(keywords) do
        if string.find(part.Name, keyword) then 
            return true 
        end
    end
    
    -- Detectar por color verde
    if part.Color == Color3.fromRGB(0, 255, 0) or 
       part.BrickColor.Name == "Lime green" or
       part.BrickColor.Name == "Bright green" then
        return true
    end
    
    return false
end

local function isVehicle(model)
    if not model or not model:IsA("Model") then return false end
    return model:FindFirstChild("VehicleSeat") or model:FindFirstChild("DriveSeat")
end

local function isCollectible(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local keywords = {"Coin", "coin", "Money", "money", "Cash", "cash", "Dollar", "dollar"}
    for _, keyword in ipairs(keywords) do
        if string.find(part.Name, keyword) then 
            return true 
        end
    end
    
    -- Detectar por color amarillo/dorado
    local color = part.Color
    if (color.R > 0.8 and color.G > 0.7 and color.B < 0.3) then
        return true
    end
    
    return false
end

local function isDamageZone(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local keywords = {"Damage", "damage", "Kill", "kill", "Death", "death", "Lava", "lava"}
    for _, keyword in ipairs(keywords) do
        if string.find(part.Name, keyword) then 
            return true 
        end
    end
    
    -- Detectar zonas rojas
    if part.Color == Color3.fromRGB(255, 0, 0) or part.BrickColor.Name == "Really red" then
        return true
    end
    
    return false
end

local function isCheckpoint(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local keywords = {"Checkpoint", "checkpoint", "Point", "point", "Stage", "stage"}
    for _, keyword in ipairs(keywords) do
        if string.find(part.Name, keyword) then 
            return true 
        end
    end
    
    return false
end

local function isTeleporter(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local keywords = {"Teleport", "teleport", "Portal", "portal", "Warp", "warp"}
    for _, keyword in ipairs(keywords) do
        if string.find(part.Name, keyword) then 
            return true 
        end
    end
    
    return false
end

-- ═══════════════════════════════════════
-- 🔍 FUNCIÓN DE ESCANEO PRINCIPAL
-- ═══════════════════════════════════════

local function performScan()
    local startTime = tick()
    
    -- Resetear datos
    scannedData = {
        obstacles = {},
        parkingZones = {},
        vehicles = {},
        checkpoints = {},
        collectibles = {},
        damageZones = {},
        teleporters = {},
        scripts = {},
        allParts = {}
    }
    
    scanStats.totalObjects = 0
    
    -- Escanear todo el Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        scanStats.totalObjects = scanStats.totalObjects + 1
        
        pcall(function()
            -- Escanear BaseParts
            if obj:IsA("BasePart") then
                table.insert(scannedData.allParts, {
                    name = obj.Name,
                    class = obj.ClassName,
                    position = obj.Position,
                    size = obj.Size,
                    color = obj.Color,
                    material = obj.Material.Name
                })
                
                if isObstacle(obj) then
                    table.insert(scannedData.obstacles, obj)
                elseif isParkingZone(obj) then
                    table.insert(scannedData.parkingZones, obj)
                elseif isCollectible(obj) then
                    table.insert(scannedData.collectibles, obj)
                elseif isDamageZone(obj) then
                    table.insert(scannedData.damageZones, obj)
                elseif isCheckpoint(obj) then
                    table.insert(scannedData.checkpoints, obj)
                elseif isTeleporter(obj) then
                    table.insert(scannedData.teleporters, obj)
                end
            end
            
            -- Escanear Modelos (Vehículos)
            if obj:IsA("Model") and isVehicle(obj) then
                table.insert(scannedData.vehicles, obj)
            end
            
            -- Escanear Scripts
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local fullPath = obj:GetFullName()
                table.insert(scannedData.scripts, {
                    name = obj.Name,
                    class = obj.ClassName,
                    parent = obj.Parent and obj.Parent.Name or "nil",
                    fullPath = fullPath,
                    enabled = obj.Enabled or false
                })
            end
        end)
    end
    
    scanStats.scanTime = math.floor((tick() - startTime) * 1000) / 1000
    scanStats.lastScan = os.date("%H:%M:%S")
    
    return scannedData
end

-- ═══════════════════════════════════════
-- 📊 FUNCIONES DE REPORTE
-- ═══════════════════════════════════════

local function getBasicReport()
    return string.format(
        "📊 SCAN REPORT\n\n" ..
        "🚧 Obstáculos: %d\n" ..
        "🅿️ Zonas de Estacionamiento: %d\n" ..
        "🚗 Vehículos: %d\n" ..
        "📍 Checkpoints: %d\n" ..
        "💰 Coleccionables: %d\n" ..
        "💀 Zonas de Daño: %d\n" ..
        "🌀 Teleportadores: %d\n" ..
        "📜 Scripts: %d\n\n" ..
        "⏱️ Tiempo: %ss\n" ..
        "🔢 Total Objetos: %d",
        #scannedData.obstacles,
        #scannedData.parkingZones,
        #scannedData.vehicles,
        #scannedData.checkpoints,
        #scannedData.collectibles,
        #scannedData.damageZones,
        #scannedData.teleporters,
        #scannedData.scripts,
        scanStats.scanTime,
        scanStats.totalObjects
    )
end

local function getDetailedObstacleReport()
    local report = "🚧 OBSTÁCULOS DETECTADOS:\n\n"
    
    if #scannedData.obstacles == 0 then
        return report .. "No se encontraron obstáculos"
    end
    
    for i, obs in ipairs(scannedData.obstacles) do
        if i <= 10 then -- Mostrar solo los primeros 10
            report = report .. string.format(
                "%d. %s\n   Pos: (%.0f, %.0f, %.0f)\n   Color: RGB(%.0f, %.0f, %.0f)\n\n",
                i, obs.Name,
                obs.Position.X, obs.Position.Y, obs.Position.Z,
                obs.Color.R * 255, obs.Color.G * 255, obs.Color.B * 255
            )
        end
    end
    
    if #scannedData.obstacles > 10 then
        report = report .. string.format("... y %d más", #scannedData.obstacles - 10)
    end
    
    return report
end

local function getDetailedParkingReport()
    local report = "🅿️ ZONAS DE ESTACIONAMIENTO:\n\n"
    
    if #scannedData.parkingZones == 0 then
        return report .. "No se encontraron zonas de estacionamiento"
    end
    
    for i, zone in ipairs(scannedData.parkingZones) do
        report = report .. string.format(
            "%d. %s\n   Pos: (%.0f, %.0f, %.0f)\n   Tamaño: %.0f x %.0f x %.0f\n\n",
            i, zone.Name,
            zone.Position.X, zone.Position.Y, zone.Position.Z,
            zone.Size.X, zone.Size.Y, zone.Size.Z
        )
    end
    
    return report
end

local function getScriptReport()
    local report = "📜 SCRIPTS DETECTADOS:\n\n"
    
    if #scannedData.scripts == 0 then
        return report .. "No se encontraron scripts"
    end
    
    for i, script in ipairs(scannedData.scripts) do
        if i <= 15 then
            report = report .. string.format(
                "%d. [%s] %s\n   Parent: %s\n\n",
                i, script.class, script.name, script.parent
            )
        end
    end
    
    if #scannedData.scripts > 15 then
        report = report .. string.format("... y %d más", #scannedData.scripts - 15)
    end
    
    return report
end

local function getFullScriptExport()
    local export = "═══════════════════════════════════════\n"
    export = export .. "📜 FULL SCRIPT EXPORT - Parking Game\n"
    export = export .. "═══════════════════════════════════════\n\n"
    export = export .. string.format("Total Scripts: %d\n", #scannedData.scripts)
    export = export .. string.format("Scan Time: %s\n", scanStats.lastScan)
    export = export .. string.format("Total Objects Scanned: %d\n\n", scanStats.totalObjects)
    export = export .. "═══════════════════════════════════════\n\n"
    
    for i, script in ipairs(scannedData.scripts) do
        export = export .. string.format(
            "Script #%d\n" ..
            "├─ Name: %s\n" ..
            "├─ Class: %s\n" ..
            "├─ Parent: %s\n" ..
            "└─ Full Path: Workspace.%s\n\n",
            i, script.name, script.class, script.parent, script.fullPath or "Unknown"
        )
    end
    
    return export
end

local function getFullObstacleExport()
    local export = "═══════════════════════════════════════\n"
    export = export .. "🚧 FULL OBSTACLE EXPORT\n"
    export = export .. "═══════════════════════════════════════\n\n"
    export = export .. string.format("Total Obstacles: %d\n\n", #scannedData.obstacles)
    
    for i, obs in ipairs(scannedData.obstacles) do
        export = export .. string.format(
            "Obstacle #%d: %s\n" ..
            "├─ Position: Vector3.new(%.2f, %.2f, %.2f)\n" ..
            "├─ Size: Vector3.new(%.2f, %.2f, %.2f)\n" ..
            "├─ Color: Color3.fromRGB(%.0f, %.0f, %.0f)\n" ..
            "└─ Material: %s\n\n",
            i, obs.Name,
            obs.Position.X, obs.Position.Y, obs.Position.Z,
            obs.Size.X, obs.Size.Y, obs.Size.Z,
            obs.Color.R * 255, obs.Color.G * 255, obs.Color.B * 255,
            obs.Material.Name
        )
    end
    
    return export
end

local function getFullParkingExport()
    local export = "═══════════════════════════════════════\n"
    export = export .. "🅿️ FULL PARKING ZONES EXPORT\n"
    export = export .. "═══════════════════════════════════════\n\n"
    export = export .. string.format("Total Parking Zones: %d\n\n", #scannedData.parkingZones)
    
    for i, zone in ipairs(scannedData.parkingZones) do
        export = export .. string.format(
            "Zone #%d: %s\n" ..
            "├─ Position: Vector3.new(%.2f, %.2f, %.2f)\n" ..
            "├─ Size: Vector3.new(%.2f, %.2f, %.2f)\n" ..
            "├─ Color: Color3.fromRGB(%.0f, %.0f, %.0f)\n" ..
            "└─ CFrame: CFrame.new(%.2f, %.2f, %.2f)\n\n",
            i, zone.Name,
            zone.Position.X, zone.Position.Y, zone.Position.Z,
            zone.Size.X, zone.Size.Y, zone.Size.Z,
            zone.Color.R * 255, zone.Color.G * 255, zone.Color.B * 255,
            zone.CFrame.Position.X, zone.CFrame.Position.Y, zone.CFrame.Position.Z
        )
    end
    
    return export
end

local function getAllDataExport()
    local export = "═══════════════════════════════════════\n"
    export = export .. "🔍 COMPLETE MAP DATA EXPORT\n"
    export = export .. "Created by: Gael Fonzar Scanner\n"
    export = export .. "═══════════════════════════════════════\n\n"
    export = export .. getBasicReport() .. "\n\n"
    export = export .. "═══════════════════════════════════════\n\n"
    
    -- Scripts
    export = export .. "📜 SCRIPTS (" .. #scannedData.scripts .. "):\n"
    for i, script in ipairs(scannedData.scripts) do
        export = export .. string.format("%d. [%s] %s (Parent: %s)\n", 
            i, script.class, script.name, script.parent)
    end
    
    export = export .. "\n═══════════════════════════════════════\n\n"
    
    -- Parking Zones (primeras 10)
    export = export .. "🅿️ PARKING ZONES (Top 10):\n"
    for i = 1, math.min(10, #scannedData.parkingZones) do
        local zone = scannedData.parkingZones[i]
        export = export .. string.format("%d. %s - Pos(%.0f, %.0f, %.0f)\n", 
            i, zone.Name, zone.Position.X, zone.Position.Y, zone.Position.Z)
    end
    
    export = export .. "\n═══════════════════════════════════════\n\n"
    
    -- Vehicles
    export = export .. "🚗 VEHICLES (" .. #scannedData.vehicles .. "):\n"
    for i, vehicle in ipairs(scannedData.vehicles) do
        export = export .. string.format("%d. %s\n", i, vehicle.Name)
    end
    
    export = export .. "\n═══════════════════════════════════════\n"
    export = export .. "End of Export\n"
    
    return export
end

-- ═══════════════════════════════════════
-- 🎨 UI CREATION
-- ═══════════════════════════════════════

local Window = Fluent:CreateWindow({
    Title = "🔍 Parking Game Scanner",
    SubTitle = "by Gael Fonzar",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Apply Dark Theme
pcall(function()
    local gui = game:GetService("CoreGui"):FindFirstChild("FluentUI") or player.PlayerGui:FindFirstChild("FluentUI")
    if gui then
        for _, obj in pairs(gui:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                obj.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                obj.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
            if obj:IsA("TextLabel") and obj.Name:find("Title") then
                obj.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end
end)

-- Create Tabs
local Tabs = {
    Scanner = Window:AddTab({ Title = "🔍 Scanner", Icon = "search" }),
    Results = Window:AddTab({ Title = "📊 Results", Icon = "bar-chart" }),
    Details = Window:AddTab({ Title = "📋 Details", Icon = "file-text" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🔍 SCANNER TAB
-- ═══════════════════════════════════════

Tabs.Scanner:AddParagraph({
    Title = "🔍 Map Scanner",
    Content = "Escanea el mapa completo para detectar:\n• Obstáculos y conos\n• Zonas de estacionamiento\n• Vehículos disponibles\n• Coleccionables y dinero\n• Scripts y elementos ocultos"
})

Tabs.Scanner:AddSection("Control de Escaneo")

Tabs.Scanner:AddButton({
    Title = "🔍 Escanear Mapa Completo",
    Description = "Analiza todo el Workspace",
    Callback = function()
        Fluent:Notify({
            Title = "🔍 Escaneando...",
            Content = "Por favor espera...",
            Duration = 2
        })
        
        task.spawn(function()
            performScan()
            
            Fluent:Notify({
                Title = "✅ Escaneo Completo!",
                Content = string.format(
                    "Encontrados:\n" ..
                    "• %d Obstáculos\n" ..
                    "• %d Zonas de Estacionamiento\n" ..
                    "• %d Vehículos\n" ..
                    "Tiempo: %ss",
                    #scannedData.obstacles,
                    #scannedData.parkingZones,
                    #scannedData.vehicles,
                    scanStats.scanTime
                ),
                Duration = 5
            })
        end)
    end
})

Tabs.Scanner:AddSection("Información")

local ScanInfoParagraph = Tabs.Scanner:AddParagraph({
    Title = "📊 Estado del Escaneo",
    Content = "No se ha realizado ningún escaneo todavía.\n\nPresiona 'Escanear Mapa Completo' para comenzar."
})

-- Actualizar información cada segundo
task.spawn(function()
    while true do
        task.wait(1)
        if scanStats.lastScan ~= "Never" then
            ScanInfoParagraph:SetDesc(string.format(
                "Último escaneo: %s\n" ..
                "Objetos totales: %d\n" ..
                "Tiempo de escaneo: %ss\n\n" ..
                "✅ Datos listos para ver en Results",
                scanStats.lastScan,
                scanStats.totalObjects,
                scanStats.scanTime
            ))
        end
    end
end)

-- ═══════════════════════════════════════
-- 📊 RESULTS TAB
-- ═══════════════════════════════════════

Tabs.Results:AddParagraph({
    Title = "📊 Resultados del Escaneo",
    Content = "Aquí verás el resumen de los objetos encontrados"
})

Tabs.Results:AddSection("Resumen General")

local BasicReportParagraph = Tabs.Results:AddParagraph({
    Title = "📊 Reporte Básico",
    Content = "Escanea el mapa primero para ver los resultados"
})

Tabs.Results:AddButton({
    Title = "🔄 Actualizar Reporte",
    Description = "Mostrar últimos resultados",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            BasicReportParagraph:SetDesc(getBasicReport())
            Fluent:Notify({
                Title = "✅ Actualizado",
                Content = "Reporte actualizado",
                Duration = 2
            })
        end
    end
})

Tabs.Results:AddSection("Exportar Datos")

Tabs.Results:AddButton({
    Title = "📋 Copiar Reporte Completo",
    Description = "Copia TODO al portapapeles",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            setclipboard(getAllDataExport())
            Fluent:Notify({
                Title = "✅ Copiado!",
                Content = "TODOS los datos copiados al portapapeles",
                Duration = 3
            })
        end
    end
})

Tabs.Results:AddButton({
    Title = "📜 Copiar Solo Scripts",
    Description = "Exporta solo los scripts detectados",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            setclipboard(getFullScriptExport())
            Fluent:Notify({
                Title = "✅ Scripts Copiados!",
                Content = string.format("%d scripts exportados", #scannedData.scripts),
                Duration = 2
            })
        end
    end
})

Tabs.Results:AddButton({
    Title = "🚧 Copiar Solo Obstáculos",
    Description = "Exporta obstáculos con posiciones",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            setclipboard(getFullObstacleExport())
            Fluent:Notify({
                Title = "✅ Obstáculos Copiados!",
                Content = string.format("%d obstáculos exportados", #scannedData.obstacles),
                Duration = 2
            })
        end
    end
})

Tabs.Results:AddButton({
    Title = "🅿️ Copiar Zonas de Parking",
    Description = "Exporta zonas con coordenadas",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            setclipboard(getFullParkingExport())
            Fluent:Notify({
                Title = "✅ Parking Copiado!",
                Content = string.format("%d zonas exportadas", #scannedData.parkingZones),
                Duration = 2
            })
        end
    end
})

Tabs.Results:AddButton({
    Title = "📊 Copiar Solo Resumen",
    Description = "Estadísticas básicas",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({
                Title = "⚠️ Aviso",
                Content = "Primero escanea el mapa!",
                Duration = 2
            })
        else
            setclipboard(getBasicReport())
            Fluent:Notify({
                Title = "✅ Resumen Copiado!",
                Content = "Estadísticas copiadas",
                Duration = 2
            })
        end
    end
})

-- ═══════════════════════════════════════
-- 📋 DETAILS TAB
-- ═══════════════════════════════════════

Tabs.Details:AddParagraph({
    Title = "📋 Detalles Específicos",
    Content = "Información detallada de cada categoría"
})

Tabs.Details:AddSection("Obstáculos")

local ObstacleDetailParagraph = Tabs.Details:AddParagraph({
    Title = "🚧 Detalles de Obstáculos",
    Content = "Escanea el mapa primero"
})

Tabs.Details:AddButton({
    Title = "🚧 Ver Obstáculos Detallados",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({Title = "⚠️ Aviso", Content = "Escanea primero!", Duration = 2})
        else
            ObstacleDetailParagraph:SetDesc(getDetailedObstacleReport())
        end
    end
})

Tabs.Details:AddSection("Zonas de Estacionamiento")

local ParkingDetailParagraph = Tabs.Details:AddParagraph({
    Title = "🅿️ Detalles de Parking",
    Content = "Escanea el mapa primero"
})

Tabs.Details:AddButton({
    Title = "🅿️ Ver Zonas Detalladas",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({Title = "⚠️ Aviso", Content = "Escanea primero!", Duration = 2})
        else
            ParkingDetailParagraph:SetDesc(getDetailedParkingReport())
        end
    end
})

Tabs.Details:AddSection("Scripts")

local ScriptDetailParagraph = Tabs.Details:AddParagraph({
    Title = "📜 Scripts Detectados",
    Content = "Escanea el mapa primero"
})

Tabs.Details:AddButton({
    Title = "📜 Ver Scripts",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({Title = "⚠️ Aviso", Content = "Escanea primero!", Duration = 2})
        else
            ScriptDetailParagraph:SetDesc(getScriptReport())
        end
    end
})

Tabs.Details:AddButton({
    Title = "📜 Copiar Scripts Completos",
    Description = "Exporta TODOS los scripts con rutas",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({Title = "⚠️ Aviso", Content = "Escanea primero!", Duration = 2})
        else
            setclipboard(getFullScriptExport())
            Fluent:Notify({
                Title = "✅ Scripts Exportados!",
                Content = string.format("%d scripts con rutas completas", #scannedData.scripts),
                Duration = 3
            })
        end
    end
})

Tabs.Details:AddSection("Análisis Avanzado")

Tabs.Details:AddButton({
    Title = "🔍 Copiar Datos RAW (JSON)",
    Description = "Exporta datos sin formato para análisis",
    Callback = function()
        if scanStats.lastScan == "Never" then
            Fluent:Notify({Title = "⚠️ Aviso", Content = "Escanea primero!", Duration = 2})
        else
            local rawData = string.format(
                "{\n" ..
                '  "obstacles": %d,\n' ..
                '  "parkingZones": %d,\n' ..
                '  "vehicles": %d,\n' ..
                '  "scripts": %d,\n' ..
                '  "checkpoints": %d,\n' ..
                '  "collectibles": %d,\n' ..
                '  "totalObjects": %d,\n' ..
                '  "scanTime": %s\n' ..
                "}",
                #scannedData.obstacles,
                #scannedData.parkingZones,
                #scannedData.vehicles,
                #scannedData.scripts,
                #scannedData.checkpoints,
                #scannedData.collectibles,
                scanStats.totalObjects,
                scanStats.scanTime
            )
            setclipboard(rawData)
            Fluent:Notify({
                Title = "✅ JSON Copiado!",
                Content = "Datos en formato JSON",
                Duration = 2
            })
        end
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddButton({
    Title = "🗑️ Unload Script",
    Callback = function()
        Fluent:Destroy()
    end
})

Tabs.Settings:AddSection("Info")

Tabs.Settings:AddParagraph({
    Title = "👤 Parking Game Scanner v1.0",
    Content = "Created by: Gael Fonzar\nTheme: Dark + Red\nStatus: ✅ Loaded\n\nEste scanner detecta:\n• Obstáculos y barreras\n• Zonas de estacionamiento\n• Vehículos\n• Coleccionables\n• Scripts ocultos\n• Y mucho más!"
})

-- Final notification
Fluent:Notify({
    Title = "🔍 Scanner Loaded",
    Content = "Presiona 'Escanear Mapa' para comenzar\nRightShift para abrir/cerrar",
    Duration = 4
})

print("════════════════════════════════")
print("🔍 Parking Game Scanner v1.0")
print("Created by: Gael Fonzar")
print("Features:")
print("• Escaneo completo del mapa")
print("• Detección de obstáculos")
print("• Análisis de zonas de parking")
print("• Detección de scripts")
print("Press RightShift to open")
print("════════════════════════════════")
