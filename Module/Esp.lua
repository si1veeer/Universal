local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ลบ ESP ตัวเก่าก่อนถ้ามีรันอยู่
if getgenv().ESP then
    pcall(function() getgenv().ESP:Destroy() end)
end

local ESP = {}
ESP.__index = ESP

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    ClockTime = Lighting.ClockTime
}

ESP.Settings = {
    Enabled = true,
    MaxDistance = 1000,
    TextSize = 14,
    Name = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    Box = true,
    BoxColor = Color3.fromRGB(255, 255, 255),
    HealthBar = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    Thickness = 1.5
}

local ESPData = {}
local Connections = {}

local function createDrawing(class, properties)
    local draw = Drawing.new(class)
    for prop, val in pairs(properties) do
        pcall(function() draw[prop] = val end)
    end
    return draw
end

local function removeESP(player)
    if ESPData[player] then
        pcall(function()
            if ESPData[player].Connection then ESPData[player].Connection:Disconnect() end
            if ESPData[player].Box then ESPData[player].Box:Remove() end
            if ESPData[player].BoxOutline then ESPData[player].BoxOutline:Remove() end
            if ESPData[player].HealthBar then ESPData[player].HealthBar:Remove() end
            if ESPData[player].HealthBarOutline then ESPData[player].HealthBarOutline:Remove() end
            if ESPData[player].NameTag then ESPData[player].NameTag:Remove() end
        end)
        ESPData[player] = nil
    end
end

local function addPlayer(player)
    if player == LocalPlayer then return end

    local pData = {
        BoxOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Filled = false, Visible = false}),
        Box = createDrawing("Square", {Color = ESP.Settings.BoxColor, Thickness = ESP.Settings.Thickness, Filled = false, Visible = false}),
        HealthBarOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Visible = false}),
        HealthBar = createDrawing("Square", {Color = ESP.Settings.HealthBarColor, Thickness = 1, Filled = true, Visible = false}),
        NameTag = createDrawing("Text", {Color = ESP.Settings.NameColor, Size = ESP.Settings.TextSize, Center = true, Outline = true, Visible = false})
    }

    ESPData[player] = pData

    local function hideAll()
        pData.Box.Visible = false
        pData.BoxOutline.Visible = false
        pData.HealthBar.Visible = false
        pData.HealthBarOutline.Visible = false
        pData.NameTag.Visible = false
    end

    pData.Connection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local head = character and character:FindFirstChild("Head")

        if not ESP.Settings.Enabled or not rootPart or not humanoid or not head or humanoid.Health <= 0 then
            hideAll()
            return
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if not onScreen then
            hideAll()
            return
        end

        local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
        local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight / 2.0 
        local boxX = rootPos.X - (boxWidth / 2)
        local boxY = topPos.Y

        -- Render Box
        if ESP.Settings.Box then
            pData.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            pData.BoxOutline.Position = Vector2.new(boxX, boxY)
            pData.BoxOutline.Visible = true

            pData.Box.Size = Vector2.new(boxWidth, boxHeight)
            pData.Box.Position = Vector2.new(boxX, boxY)
            pData.Box.Visible = true
        else
            pData.Box.Visible = false
            pData.BoxOutline.Visible = false
        end

        -- Render Health Bar
        if ESP.Settings.HealthBar then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = boxHeight * healthPercent
            local barX = boxX - 5
            
            pData.HealthBarOutline.Size = Vector2.new(3, boxHeight)
            pData.HealthBarOutline.Position = Vector2.new(barX, boxY)
            pData.HealthBarOutline.Visible = true

            pData.HealthBar.Size = Vector2.new(1, barHeight)
            pData.HealthBar.Position = Vector2.new(barX + 1, boxY + boxHeight - barHeight)
            pData.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            pData.HealthBar.Visible = true
        else
            pData.HealthBar.Visible = false
            pData.HealthBarOutline.Visible = false
        end

        -- Render Name Tag
        if ESP.Settings.Name then
            pData.NameTag.Text = player.Name
            pData.NameTag.Size = ESP.Settings.TextSize
            pData.NameTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY - ESP.Settings.TextSize - 4)
            pData.NameTag.Visible = true
        else
            pData.NameTag.Visible = false
        end
    end)
end

function ESP:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        addPlayer(player)
    end
    table.insert(Connections, Players.PlayerAdded:Connect(addPlayer))
    table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))
end

-- 🔥 ฟังก์ชันสำหรับเคลียร์ทุกอย่างออกจากหน้าจอแบบสะอาด 100%
function ESP:Destroy()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    local list = {}
    for player in pairs(ESPData) do
        table.insert(list, player)
    end

    for _, player in ipairs(list) do
        removeESP(player)
    end
    
    getgenv().ESP = nil
end

ESP:Init()
getgenv().ESP = ESP -- บันทึกเข้า Global ทันทีที่รัน
