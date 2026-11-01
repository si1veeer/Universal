local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if getgenv().ESP and typeof(getgenv().ESP.Destroy) == "function" then
    pcall(function() getgenv().ESP:Destroy() end)
end

local ESP = {}
ESP.__index = ESP

-- ค่าเริ่มต้นมาตรฐาน (Default Settings)
ESP.Settings = {
    Enabled = true,
    MaxDistance = 1000,
    TextSize = 14,
    Name = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    Box = true,
    BoxType = "Corner",
    BoxColor = Color3.fromRGB(255, 255, 255),
    HealthBar = true,
    HealthBarSide = "Left",
    DynamicHealthColor = false,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    Distance = true,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    Thickness = 1.25,
    -- เพิ่ม Setting ใหม่ๆ รองรับการเปิด/ปิด
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = false
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
            if ESPData[player].CornerLines then
                for _, line in pairs(ESPData[player].CornerLines) do line:Remove() end
            end
            if ESPData[player].HealthBar then ESPData[player].HealthBar:Remove() end
            if ESPData[player].HealthBarOutline then ESPData[player].HealthBarOutline:Remove() end
            if ESPData[player].NameTag then ESPData[player].NameTag:Remove() end
            if ESPData[player].DistanceTag then ESPData[player].DistanceTag:Remove() end
            if ESPData[player].Tracer then ESPData[player].Tracer:Remove() end
            if ESPData[player].SkeletonLines then
                for _, line in pairs(ESPData[player].SkeletonLines) do line:Remove() end
            end
        end)
        ESPData[player] = nil
    end
end

local function addPlayer(player)
    if player == LocalPlayer then return end

    local pData = {
        BoxOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 3, Filled = false, Visible = false}),
        Box = createDrawing("Square", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, Filled = false, Visible = false}),
        CornerLines = {},
        HealthBarOutline = createDrawing("Square", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Filled = true, Visible = false}),
        HealthBar = createDrawing("Square", {Color = Color3.fromRGB(0, 255, 0), Thickness = 1, Filled = true, Visible = false}),
        NameTag = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 14, Center = true, Outline = true, Visible = false}),
        DistanceTag = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 14, Center = true, Outline = true, Visible = false}),
        Tracer = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Visible = false}),
        SkeletonLines = {}
    }

    for i = 1, 16 do
        pData.CornerLines[i] = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1.25, Visible = false})
    end

    for i = 1, 10 do
        pData.SkeletonLines[i] = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Visible = false})
    end

    ESPData[player] = pData

    local function hideAll()
        pData.Box.Visible = false
        pData.BoxOutline.Visible = false
        for _, line in pairs(pData.CornerLines) do line.Visible = false end
        pData.HealthBar.Visible = false
        pData.HealthBarOutline.Visible = false
        pData.NameTag.Visible = false
        pData.DistanceTag.Visible = false
        pData.Tracer.Visible = false
        for _, line in pairs(pData.SkeletonLines) do line.Visible = false end
    end

    pData.Connection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not ESP.Settings.Enabled or not character or not rootPart or not humanoid or humanoid.Health <= 0 then
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

        local cframe, size = character:GetBoundingBox()
        local topWorld = cframe.Position + Vector3.new(0, size.Y / 2, 0)
        local bottomWorld = cframe.Position - Vector3.new(0, size.Y / 2, 0)
        
        local topPos = Camera:WorldToViewportPoint(topWorld)
        local bottomPos = Camera:WorldToViewportPoint(bottomWorld)
        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if not onScreen then
            hideAll()
            return
        end

        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight / 2.0 
        local boxX = rootPos.X - (boxWidth / 2)
        local boxY = topPos.Y

        if ESP.Settings.Box then
            if ESP.Settings.BoxType == "Box" then
                for _, line in pairs(pData.CornerLines) do line.Visible = false end
                pData.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                pData.BoxOutline.Position = Vector2.new(boxX, boxY)
                pData.BoxOutline.Visible = true

                pData.Box.Size = Vector2.new(boxWidth, boxHeight)
                pData.Box.Position = Vector2.new(boxX, boxY)
                pData.Box.Color = ESP.Settings.BoxColor
                pData.Box.Visible = true
            elseif ESP.Settings.BoxType == "Corner" then
                pData.Box.Visible = false
                pData.BoxOutline.Visible = false

                local lengthX = boxWidth / 4
                local lengthY = boxHeight / 4
                local lines = pData.CornerLines
                local outlineColor = Color3.fromRGB(0, 0, 0)
                local boxColor = ESP.Settings.BoxColor

                for i = 1, 16 do
                    lines[i].Color = boxColor
                end

                lines[1].From = Vector2.new(boxX, boxY) lines[1].To = Vector2.new(boxX + lengthX, boxY) lines[1].Color = outlineColor lines[1].Thickness = 3
                lines[2].From = Vector2.new(boxX, boxY) lines[2].To = Vector2.new(boxX + lengthX, boxY) lines[2].Color = boxColor lines[2].Thickness = 1.25
                lines[3].From = Vector2.new(boxX, boxY) lines[3].To = Vector2.new(boxX, boxY + lengthY) lines[3].Color = outlineColor lines[3].Thickness = 3
                lines[4].From = Vector2.new(boxX, boxY) lines[4].To = Vector2.new(boxX, boxY + lengthY) lines[4].Color = boxColor lines[4].Thickness = 1.25

                lines[5].From = Vector2.new(boxX + boxWidth, boxY) lines[5].To = Vector2.new(boxX + boxWidth - lengthX, boxY) lines[5].Color = outlineColor lines[5].Thickness = 3
                lines[6].From = Vector2.new(boxX + boxWidth, boxY) lines[6].To = Vector2.new(boxX + boxWidth - lengthX, boxY) lines[6].Color = boxColor lines[6].Thickness = 1.25
                lines[7].From = Vector2.new(boxX + boxWidth, boxY) lines[7].To = Vector2.new(boxX + boxWidth, boxY + lengthY) lines[7].Color = outlineColor lines[7].Thickness = 3
                lines[8].From = Vector2.new(boxX + boxWidth, boxY) lines[8].To = Vector2.new(boxX + boxWidth, boxY + lengthY) lines[8].Color = boxColor lines[8].Thickness = 1.25

                lines[9].From = Vector2.new(boxX, boxY + boxHeight) lines[9].To = Vector2.new(boxX + lengthX, boxY + boxHeight) lines[9].Color = outlineColor lines[9].Thickness = 3
                lines[10].From = Vector2.new(boxX, boxY + boxHeight) lines[10].To = Vector2.new(boxX + lengthX, boxY + boxHeight) lines[10].Color = boxColor lines[10].Thickness = 1.25
                lines[11].From = Vector2.new(boxX, boxY + boxHeight) lines[11].To = Vector2.new(boxX, boxY + boxHeight - lengthY) lines[11].Color = outlineColor lines[11].Thickness = 3
                lines[12].From = Vector2.new(boxX, boxY + boxHeight) lines[12].To = Vector2.new(boxX, boxY + boxHeight - lengthY) lines[12].Color = boxColor lines[12].Thickness = 1.25

                lines[13].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[13].To = Vector2.new(boxX + boxWidth - lengthX, boxY + boxHeight) lines[13].Color = outlineColor lines[13].Thickness = 3
                lines[14].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[14].To = Vector2.new(boxX + boxWidth - lengthX, boxY + boxHeight) lines[14].Color = boxColor lines[14].Thickness = 1.25
                lines[15].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[15].To = Vector2.new(boxX + boxWidth, boxY + boxHeight - lengthY) lines[15].Color = outlineColor lines[15].Thickness = 3
                lines[16].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[16].To = Vector2.new(boxX + boxWidth, boxY + boxHeight - lengthY) lines[16].Color = boxColor lines[16].Thickness = 1.25

                for i = 1, 16 do lines[i].Visible = true end
            end
        else
            pData.Box.Visible = false
            pData.BoxOutline.Visible = false
            for _, line in pairs(pData.CornerLines) do line.Visible = false end
        end

        if ESP.Settings.HealthBar then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = boxHeight * healthPercent
            local barX = (ESP.Settings.HealthBarSide == "Left") and (boxX - 6) or (boxX + boxWidth + 3)
            
            pData.HealthBarOutline.Size = Vector2.new(3, boxHeight)
            pData.HealthBarOutline.Position = Vector2.new(barX, boxY)
            pData.HealthBarOutline.Visible = true

            pData.HealthBar.Size = Vector2.new(1, barHeight)
            pData.HealthBar.Position = Vector2.new(barX + 1, boxY + boxHeight - barHeight)
            pData.HealthBar.Color = ESP.Settings.DynamicHealthColor and Color3.fromHSV(healthPercent * 0.3, 1, 1) or ESP.Settings.HealthBarColor
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

        if ESP.Settings.Distance then
            pData.DistanceTag.Text = "[" .. math.floor(distance) .. "m]"
            pData.DistanceTag.Size = ESP.Settings.TextSize
            pData.DistanceTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY + boxHeight + 2)
            pData.DistanceTag.Color = ESP.Settings.DistanceColor
            pData.DistanceTag.Visible = true
        else
            pData.DistanceTag.Visible = false
        end

        if ESP.Settings.Tracers then
            pData.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            pData.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            pData.Tracer.Color = ESP.Settings.TracerColor
            pData.Tracer.Visible = true
        else
            pData.Tracer.Visible = false
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

    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.KeypadOne then
            pcall(function() ESP:Destroy() end)
        end
    end))
end

function ESP:UpdateSettings(newSettings)
    if type(newSettings) == "table" then
        for k, val in pairs(newSettings) do
            ESP.Settings[k] = val
        end
    end
end

function ESP:Destroy()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    for _, player in ipairs(Players:GetPlayers()) do
        removeESP(player)
    end
    getgenv().ESP = nil
end

ESP:Init()
getgenv().ESP = ESP
return ESP
