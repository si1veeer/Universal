local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

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
    BoxType = "Box",
    BoxColor = Color3.fromRGB(255, 255, 255),
    HealthBar = true,
    HealthBarSide = "Left",
    DynamicHealthColor = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    HealthText = false,
    Weapon = false,
    WeaponColor = Color3.fromRGB(255, 255, 255),
    VisCheck = false,
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    Distance = true,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    Chams = false,
    ChamsFillColor = Color3.fromRGB(0, 251, 255),
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsOutlineTransparency = 0,
    ChamsFillTransparency = 50,
    ChamsMaterial = "SmoothPlastic",
    ChamsVisibleCheck = false,
    ChamsVisibleColor = Color3.fromRGB(0, 255, 0),
    ChamsHiddenColor = Color3.fromRGB(255, 0, 0),
    OffScreenArrows = false,
    ArrowColor = Color3.fromRGB(255, 255, 255),
    ArrowSize = 22,
    ArrowRadius = 150,
    ArrowDistanceText = false,
    ArrowTextSize = 11,
    ArrowTextOffset = 24,
    TeamCheck = false,
    Fullbright = false,
    RemoveFog = false,
    CustomTime = false,
    TimeOfDay = 14,
    AmbientColorEnabled = false,
    AmbientColor = Color3.fromRGB(255, 255, 255),
    Thickness = 1.5
}

local ESPData = {}
local ChamsData = {}
local Connections = {}

local function createDrawing(class, properties)
    local draw = Drawing.new(class)
    for prop, val in pairs(properties) do
        pcall(function()
            draw[prop] = val
        end)
    end
    return draw
end

local function removeChams(player)
    if ChamsData[player] then
        if ChamsData[player].Highlight then
            pcall(function()
                ChamsData[player].Highlight:Destroy()
            end)
        end
        ChamsData[player] = nil
    end
end

local function removeESP(player)
    if ESPData[player] then
        pcall(function()
            if ESPData[player].Connection then ESPData[player].Connection:Disconnect() end
            if ESPData[player].Box then ESPData[player].Box:Remove() end
            if ESPData[player].BoxOutline then ESPData[player].BoxOutline:Remove() end
            
            if ESPData[player].CornerLines then
                for _, line in pairs(ESPData[player].CornerLines) do
                    line:Remove()
                end
            end

            if ESPData[player].HealthBar then ESPData[player].HealthBar:Remove() end
            if ESPData[player].HealthBarOutline then ESPData[player].HealthBarOutline:Remove() end
            if ESPData[player].HealthTag then ESPData[player].HealthTag:Remove() end
            if ESPData[player].WeaponTag then ESPData[player].WeaponTag:Remove() end
            if ESPData[player].NameTag then ESPData[player].NameTag:Remove() end
            if ESPData[player].DistanceTag then ESPData[player].DistanceTag:Remove() end
            if ESPData[player].Tracer then ESPData[player].Tracer:Remove() end
            if ESPData[player].Arrow then ESPData[player].Arrow:Remove() end
            if ESPData[player].ArrowText then ESPData[player].ArrowText:Remove() end
            
            if ESPData[player].SkeletonLines then
                for _, line in pairs(ESPData[player].SkeletonLines) do
                    line:Remove()
                end
            end
        end)
        ESPData[player] = nil
    end
    removeChams(player)
end

local function addPlayer(player)
    if player == LocalPlayer then return end
    
    local skeletonJoints = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    }

    local skeletonJointsR6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }

    local pData = {
        BoxOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Filled = false, Visible = false}),
        Box = createDrawing("Square", {Color = ESP.Settings.BoxColor, Thickness = ESP.Settings.Thickness, Filled = false, Visible = false}),
        CornerLines = {},
        HealthBarOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Visible = false}),
        HealthBar = createDrawing("Square", {Color = ESP.Settings.HealthBarColor, Thickness = 1, Filled = true, Visible = false}),
        HealthTag = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 12, Center = false, Outline = true, Visible = false}),
        WeaponTag = createDrawing("Text", {Color = ESP.Settings.WeaponColor, Size = ESP.Settings.TextSize, Center = true, Outline = true, Visible = false}),
        NameTag = createDrawing("Text", {Color = ESP.Settings.NameColor, Size = ESP.Settings.TextSize, Center = true, Outline = true, Visible = false}),
        DistanceTag = createDrawing("Text", {Color = ESP.Settings.DistanceColor, Size = ESP.Settings.TextSize, Center = true, Outline = true, Visible = false}),
        Tracer = createDrawing("Line", {Color = ESP.Settings.TracerColor, Thickness = 1, Visible = false}),
        Arrow = createDrawing("Triangle", {Color = ESP.Settings.ArrowColor, Filled = true, Visible = false, Transparency = 0.8}),
        ArrowText = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 11, Center = true, Outline = true, Visible = false}),
        SkeletonLines = {},
        LastVisCheck = 0,
        CachedVisResult = true
    }

    for i = 1, 16 do
        pData.CornerLines[i] = createDrawing("Line", {Color = ESP.Settings.BoxColor, Thickness = 1.5, Visible = false})
    end

    for i = 1, 14 do
        pData.SkeletonLines[i] = createDrawing("Line", {Color = ESP.Settings.SkeletonColor, Thickness = 1, Visible = false, Transparency = 0.8})
    end

    ESPData[player] = pData

    local highlight = Instance.new("Highlight")
    highlight.Adornee = nil
    highlight.FillColor = ESP.Settings.ChamsFillColor
    highlight.OutlineColor = ESP.Settings.ChamsOutlineColor
    highlight.FillTransparency = ESP.Settings.ChamsFillTransparency / 100
    highlight.OutlineTransparency = ESP.Settings.ChamsOutlineTransparency / 100
    highlight.Enabled = false
    highlight.Parent = CoreGui
    ChamsData[player] = {Highlight = highlight}

    local function hideAll()
        pData.Box.Visible = false
        pData.BoxOutline.Visible = false
        for _, line in pairs(pData.CornerLines) do line.Visible = false end
        pData.HealthBar.Visible = false
        pData.HealthBarOutline.Visible = false
        pData.HealthTag.Visible = false
        pData.WeaponTag.Visible = false
        pData.NameTag.Visible = false
        pData.DistanceTag.Visible = false
        pData.Tracer.Visible = false
        pData.Arrow.Visible = false
        pData.ArrowText.Visible = false
        for _, line in pairs(pData.SkeletonLines) do line.Visible = false end
        highlight.Enabled = false
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

        if ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team and LocalPlayer.Team ~= nil then
            hideAll()
            return
        end

        local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude or 0
        if distance > ESP.Settings.MaxDistance then
            hideAll()
            return
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if not onScreen then
            hideAll()
            return
        end

        local topWorld = head.Position + Vector3.new(0, 0.8, 0)
        local bottomWorld = rootPart.Position - Vector3.new(0, 3, 0)
        local topPos = Camera:WorldToViewportPoint(topWorld)
        local bottomPos = Camera:WorldToViewportPoint(bottomWorld)

        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight / 2.0 
        local boxX = rootPos.X - (boxWidth / 2)
        local boxY = topPos.Y

        if ESP.Settings.Box then
            pData.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
            pData.BoxOutline.Position = Vector2.new(boxX, boxY)
            pData.BoxOutline.Visible = true

            pData.Box.Size = Vector2.new(boxWidth, boxHeight)
            pData.Box.Position = Vector2.new(boxX, boxY)
            pData.Box.Color = ESP.Settings.BoxColor
            pData.Box.Visible = true
        else
            pData.Box.Visible = false
            pData.BoxOutline.Visible = false
        end

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

        if ESP.Settings.Name then
            pData.NameTag.Text = player.Name
            pData.NameTag.Size = ESP.Settings.TextSize
            pData.NameTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY - ESP.Settings.TextSize - 4)
            pData.NameTag.Color = ESP.Settings.NameColor
            pData.NameTag.Visible = true
        else
            pData.NameTag.Visible = false
        end
    end)

    player.AncestryChanged:Connect(function(_, parent)
        if not parent then removeESP(player) end
    end)
end

function ESP:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        addPlayer(player)
    end

    table.insert(Connections, Players.PlayerAdded:Connect(addPlayer))
    table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))
end

function ESP:Destroy()
    -- 1. ตัด Connection ทั้งหมดก่อน
    for _, conn in ipairs(Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    Connections = {}

    -- 2. ดึงรายชื่อผู้เล่นทั้งหมดใส่ตารางชั่วคราว เพื่อความปลอดภัยในการวนลูปเคลียร์
    local playersToClear = {}
    for player, _ in pairs(ESPData) do
        table.insert(playersToClear, player)
    end

    for _, player in ipairs(playersToClear) do
        removeESP(player)
    end

    -- 3. คืนค่าสภาพแวดล้อมแสงเดิม
    pcall(function()
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.Ambient = OriginalLighting.Ambient
    end)
end

ESP:Init()

return ESP
