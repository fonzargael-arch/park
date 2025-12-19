--[[
    ═══════════════════════════════════════
    🅿️ PARKING GAME NOCLIP
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Para: Estaciona un coche 🅿️
    Función: Atraviesa conos, barreras y obstáculos
    ═══════════════════════════════════════
]]

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Variables
local noclipEnabled = false
local autoWinEnabled = false
local noclipConnection = nil
local originalProperties = {}
local processedParts = {}

-- Lista de nombres de obstáculos en juegos de estacionamiento
local obstacleKeywords = {
    -- Conos y barreras
    "Cone", "cone", "cono", "Cono", "TrafficCone",
    "Barrier", "barrier", "barrera", "Barrera",
    "Fence", "fence", "valla",
    
    -- Obstáculos generales
    "Obstacle", "obstacle", "obstaculo",
    "Block", "block", "bloque",
    "Wall", "wall", "muro", "Muro",
    
    -- Detectores de colisión
    "Damage", "damage", "Hit", "hit",
    "Collision", "collision",
    "Detect", "detect",
    
    -- Otros objetos
    "Hydrant", "hydrant", "hidrante",
    "Pole", "pole", "poste",
    "Sign", "sign", "señal",
    "Trash", "trash", "basura",
    "Cart", "cart", "carrito"
}

-- Función para verificar si un objeto es un obstáculo
local function isObstacle(part)
    if not part:IsA("BasePart") then return false end
    
    -- Ignorar el suelo y paredes principales
    if part.Name == "Floor" or part.Name == "Ground" or part.Name == "Baseplate" then
        return false
    end
    
    -- Verificar por nombre
    local partName = part.Name:lower()
    for _, keyword in ipairs(obstacleKeywords) do
        if string.find(partName, keyword:lower()) then
            return true
        end
    end
    
    -- Verificar por parent (carpetas de obstáculos)
    if part.Parent and (
        part.Parent.Name:find("Obstacle") or 
        part.Parent.Name:find("Hazard") or
        part.Parent.Name:find("Cone") or
        part.Parent.Name:find("Barrier")
    ) then
        return true
    end
    
    -- Verificar por color (conos naranjas/rojos/amarillos)
    local color = part.Color
    if (color.R > 0.7 and color.G < 0.5) or -- Rojo/Naranja
       (color.R > 0.7 and color.G > 0.6 and color.B < 0.3) then -- Amarillo
        return true
    end
    
    -- Verificar si tiene TouchEnded o Touched (detectores de daño)
    if #part:GetConnections() > 0 then
        return true
    end
    
    return false
end

-- Función para obtener el vehículo actual
local function getVehicle()
    local char = player.Character
    if not char then return nil end
    
    -- Método 1: Buscar por SeatPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        local vehicle = humanoid.SeatPart.Parent
        return vehicle
    end
    
    -- Método 2: Buscar en Workspace por el modelo del carro
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("VehicleSeat") then
            local seat = obj:FindFirstChild("VehicleSeat")
            if seat.Occupant and seat.Occupant.Parent == char then
                return obj
            end
        end
    end
    
    -- Método 3: Buscar carpeta de vehículos
    local vehiclesFolder = Workspace:FindFirstChild("Vehicles") or Workspace:FindFirstChild("Cars")
    if vehiclesFolder then
        for _, vehicle in pairs(vehiclesFolder:GetChildren()) do
            if vehicle:IsA("Model") then
                local seat = vehicle:FindFirstChild("VehicleSeat") or vehicle:FindFirstChild("DriveSeat")
                if seat and seat:IsA("VehicleSeat") and seat.Occupant then
                    if seat.Occupant.Parent == char then
                        return vehicle
                    end
                end
            end
        end
    end
    
    return nil
end

-- Función para hacer noclip al vehículo
local function enableVehicleNoclip()
    local vehicle = getVehicle()
    if not vehicle then return end
    
    for _, part in pairs(vehicle:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "VehicleSeat" and part.Name ~= "DriveSeat" then
            if not originalProperties[part] then
                originalProperties[part] = {
                    CanCollide = part.CanCollide,
                    Massless = part.Massless
                }
            end
            part.CanCollide = false
            part.Massless = true -- Evita físicas raras
        end
    end
end

-- Función para hacer noclip a obstáculos
local function noclipObstacles()
    -- Buscar en Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and isObstacle(obj) and not processedParts[obj] then
            originalProperties[obj] = {
                CanCollide = obj.CanCollide,
                Transparency = obj.Transparency
            }
            obj.CanCollide = false
            obj.Transparency = math.min(obj.Transparency + 0.3, 0.8) -- Semi-transparente
            processedParts[obj] = true
        end
    end
end

-- Función principal de noclip
local function startNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    
    -- Hacer noclip inicial a todos los obstáculos
    noclipObstacles()
    
    noclipConnection = RunService.Heartbeat:Connect(function()
        if not noclipEnabled then
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            return
        end
        
        -- Noclip del vehículo cada frame
        enableVehicleNoclip()
    end)
    
    -- Conectar evento para nuevos obstáculos
    Workspace.DescendantAdded:Connect(function(obj)
        if noclipEnabled and obj:IsA("BasePart") and isObstacle(obj) then
            task.wait(0.1)
            if not originalProperties[obj] then
                originalProperties[obj] = {
                    CanCollide = obj.CanCollide,
                    Transparency = obj.Transparency
                }
            end
            obj.CanCollide = false
            obj.Transparency = math.min(obj.Transparency + 0.3, 0.8)
            processedParts[obj] = true
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    -- Restaurar propiedades
    for obj, props in pairs(originalProperties) do
        if obj and obj.Parent then
            pcall(function()
                obj.CanCollide = props.CanCollide
                if props.Transparency then
                    obj.Transparency = props.Transparency
                end
                if props.Massless ~= nil then
                    obj.Massless = props.Massless
                end
            end)
        end
    end
    originalProperties = {}
    processedParts = {}
end

-- Función para auto-ganar (teleport al punto de estacionamiento)
local function autoWin()
    local vehicle = getVehicle()
    if not vehicle then
        Fluent:Notify({
            Title = "❌ Error",
            Content = "No estás en un vehículo!",
            Duration = 2
        })
        return
    end
    
    -- Buscar el punto de estacionamiento (zona verde)
    local parkingZone = nil
    
    -- Buscar por nombre común
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (
            obj.Name:find("Park") or 
            obj.Name:find("Goal") or 
            obj.Name:find("Target") or
            obj.Name:find("Win") or
            obj.Name:find("Finish")
        ) and (obj.Color == Color3.fromRGB(0, 255, 0) or obj.BrickColor.Name == "Lime green") then
            parkingZone = obj
            break
        end
    end
    
    if parkingZone then
        local vehicleRoot = vehicle.PrimaryPart or vehicle:FindFirstChild("VehicleSeat")
        if vehicleRoot then
            vehicleRoot.CFrame = parkingZone.CFrame + Vector3.new(0, 5, 0)
            Fluent:Notify({
                Title = "✅ Estacionado!",
                Content = "Teleportado a la zona de estacionamiento",
                Duration = 2
            })
        end
    else
        Fluent:Notify({
            Title = "⚠️ No encontrado",
            Content = "No se pudo encontrar la zona de estacionamiento",
            Duration = 2
        })
    end
end

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "🅿️ Parking Game Helper",
    SubTitle = "by Gael Fonzar",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 420),
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
    Main = Window:AddTab({ Title = "🅿️ Main", Icon = "car" }),
    Auto = Window:AddTab({ Title = "🤖 Auto", Icon = "zap" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🅿️ MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "🅿️ Parking Game Helper",
    Content = "Atraviesa conos y obstáculos sin perder dinero!\n\n✅ Compatible con Estaciona un coche\n✅ Sin detecciones\n✅ Fácil de usar"
})

Tabs.Main:AddSection("Noclip")

local NoclipToggle = Tabs.Main:AddToggle("VehicleNoclip", {
    Title = "👻 Noclip de Vehículo",
    Description = "Atraviesa TODOS los obstáculos",
    Default = false,
    Callback = function(Value)
        noclipEnabled = Value
        
        if Value then
            startNoclip()
            Fluent:Notify({
                Title = "✅ Noclip ON",
                Content = "Atraviesa todo sin daño!",
                Duration = 3
            })
        else
            stopNoclip()
            Fluent:Notify({
                Title = "❌ Noclip OFF",
                Content = "Colisiones restauradas",
                Duration = 2
            })
        end
    end
})

Tabs.Main:AddButton({
    Title = "🔄 Reiniciar Noclip",
    Description = "Si cambias de vehículo",
    Callback = function()
        stopNoclip()
        task.wait(0.5)
        if NoclipToggle then
            noclipEnabled = true
            startNoclip()
            Fluent:Notify({
                Title = "🔄 Reiniciado",
                Content = "Noclip reactivado",
                Duration = 2
            })
        end
    end
})

Tabs.Main:AddSection("Información")

Tabs.Main:AddParagraph({
    Title = "ℹ️ Cómo Usar",
    Content = "1. Sube a tu vehículo\n2. Activa el Noclip\n3. Maneja normalmente\n4. Los conos y barreras serán atravesables\n\n💡 Los obstáculos se volverán semi-transparentes"
})

-- ═══════════════════════════════════════
-- 🤖 AUTO TAB
-- ═══════════════════════════════════════

Tabs.Auto:AddParagraph({
    Title = "🤖 Funciones Automáticas",
    Content = "Herramientas para completar niveles fácilmente"
})

Tabs.Auto:AddSection("Teleport")

Tabs.Auto:AddButton({
    Title = "🎯 Teleport a Zona de Estacionamiento",
    Description = "Auto-completar el nivel",
    Callback = function()
        autoWin()
    end
})

Tabs.Auto:AddSection("Información")

Tabs.Auto:AddParagraph({
    Title = "⚠️ Nota",
    Content = "La función de Auto-Win puede no funcionar en todos los niveles. Si no funciona, usa el Noclip para llegar manualmente."
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddButton({
    Title = "🗑️ Unload Script",
    Callback = function()
        stopNoclip()
        Fluent:Destroy()
    end
})

Tabs.Settings:AddSection("Info")

Tabs.Settings:AddParagraph({
    Title = "👤 Parking Game Helper v1.0",
    Content = "Created by: Gael Fonzar\nTheme: Dark + Red\nStatus: ✅ Loaded\n\nCompatible con:\n• Estaciona un coche 🅿️\n• Otros juegos de estacionamiento"
})

-- Detectar cuando el jugador cambia de vehículo
player.CharacterAdded:Connect(function(char)
    task.wait(2)
    if noclipEnabled then
        stopNoclip()
        task.wait(0.5)
        noclipEnabled = true
        startNoclip()
    end
end)

-- Cleanup
local function cleanup()
    stopNoclip()
    Fluent:Notify({
        Title = "👋 Unloaded",
        Content = "Parking Helper removed",
        Duration = 2
    })
end

Window:OnUnload(cleanup)

-- Final notification
Fluent:Notify({
    Title = "🅿️ Parking Game Helper",
    Content = "Listo! Activa el noclip y estaciona sin problemas\nPress RightShift to toggle",
    Duration = 4
})

print("════════════════════════════════")
print("🅿️ Parking Game Helper v1.0")
print("Created by: Gael Fonzar")
print("Features:")
print("• Atraviesa conos y obstáculos")
print("• Sin perder dinero")
print("• Auto-Win (experimental)")
print("• Compatible con Estaciona un coche")
print("Press RightShift to open")
print("════════════════════════════════")
