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

-- ==========================================
-- 1. Configuration & Settings Table (ตารางตั้งค่าส่วนกลาง)
-- ==========================================
ESP.Settings = {
    Enabled = true,
    MaxDistance = 1000,
    TextSize = 14,
    DistanceSize = 12,                       -- ขนาดตัวหนังสือระยะทาง (ไม่มีวงเงิน และขนาดเล็กลง)
    Name = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    Box = true,
    BoxType = "Corner",
    BoxColor = Color3.fromRGB(255, 255, 255),
    HealthBar = true,
    HealthBarSide = "Left",
    DynamicHealthColor = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    Distance = true,
    DistanceColor = Color3.fromRGB(255, 255, 255),
    Thickness = 1.25,
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    TeamCheck = false,
    Skeleton = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    VisCheck = false,
    VisibleColor = Color3.fromRGB(0, 255, 0),
    InvisibleColor = Color3.fromRGB(255, 0, 0),
    Weapon = false,
    WeaponColor = Color3.fromRGB(255, 255, 255),
    
    -- ฟังก์ชันเสริมระดับโปร
    OffScreenArrows = false,
    OffScreenArrowColor = Color3.fromRGB(255, 255, 255),
    OffScreenArrowRadius = 150,
    GazeLine = false,
    GazeLineColor = Color3.fromRGB(255, 255, 255),
    GazeLineLength = 5,
    FadeDistance = false
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

-- ==========================================
-- 2. Lifecycle Management & Player Tracking (ระบบจัดการผู้เล่นเข้า-ออก)
-- ==========================================
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
            if ESPData[player].WeaponTag then ESPData[player].WeaponTag:Remove() end
            if ESPData[player].Tracer then ESPData[player].Tracer:Remove() end
            if ESPData[player].OffScreenArrow then ESPData[player].OffScreenArrow:Remove() end
            if ESPData[player].GazeLine then ESPData[player].GazeLine:Remove() end
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
        DistanceTag = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 12, Center = true, Outline = true, Visible = false}),
        WeaponTag = createDrawing("Text", {Color = Color3.fromRGB(255, 255, 255), Size = 14, Center = true, Outline = true, Visible = false}),
        Tracer = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Visible = false}),
        OffScreenArrow = createDrawing("Triangle", {Color = Color3.fromRGB(255, 255, 255), Filled = true, Visible = false}),
        GazeLine = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Visible = false}),
        SkeletonLines = {}
    }

    for i = 1, 16 do
        pData.CornerLines[i] = createDrawing("Line", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1.25, Visible = false})
    end

    for i = 1, 14 do
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
        pData.WeaponTag.Visible = false
        pData.Tracer.Visible = false
        pData.OffScreenArrow.Visible = false
        pData.GazeLine.Visible = false
        for _, line in pairs(pData.SkeletonLines) do line.Visible = false end
    end

    -- Core Render Loop (เรนเดอร์เรียลไทม์ทุกเฟรมเพื่อให้ลื่นไหลสูงสุด)
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

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if not onScreen then
            if ESP.Settings.OffScreenArrows then
                hideAll()
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local camCFrame = Camera.CFrame
                local relPos = camCFrame:PointToObjectSpace(rootPart.Position)
                local angle = math.atan2(relPos.X, -relPos.Y)
                
                local radius = ESP.Settings.OffScreenArrowRadius
                local arrowPos = screenCenter + Vector2.new(math.sin(angle), -math.cos(angle)) * radius
                
                local size = 12
                local tip = arrowPos + Vector2.new(math.sin(angle), -math.cos(angle)) * size
                local left = arrowPos + Vector2.new(math.sin(angle + 2.4), -math.cos(angle + 2.4)) * (size * 0.7)
                local right = arrowPos + Vector2.new(math.sin(angle - 2.4), -math.cos(angle - 2.4)) * (size * 0.7)
                
                pData.OffScreenArrow.PointA = tip
                pData.OffScreenArrow.PointB = left
                pData.OffScreenArrow.PointC = right
                pData.OffScreenArrow.Color = ESP.Settings.OffScreenArrowColor
                pData.OffScreenArrow.Visible = true
            else
                hideAll()
            end
            return
        else
            pData.OffScreenArrow.Visible = false
        end

        local isVisible = true
        if ESP.Settings.VisCheck then
            local head = character:FindFirstChild("Head")
            if head then
                local parts = Camera:GetPartsObscuringTarget({head.Position}, {Camera, LocalPlayer.Character, character})
                if #parts > 0 then
                    isVisible = false
                end
            end
        end

        local activeBoxColor = ESP.Settings.BoxColor
        if ESP.Settings.VisCheck then
            activeBoxColor = isVisible and ESP.Settings.VisibleColor or ESP.Settings.InvisibleColor
        end

        local cframe, size = character:GetBoundingBox()
        local topWorld = cframe.Position + Vector3.new(0, size.Y / 2, 0)
        local bottomWorld = cframe.Position - Vector3.new(0, size.Y / 2, 0)
        
        local topPos = Camera:WorldToViewportPoint(topWorld)
        local bottomPos = Camera:WorldToViewportPoint(bottomWorld)

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
                pData.Box.Color = activeBoxColor
                pData.Box.Visible = true
            elseif ESP.Settings.BoxType == "Corner" then
                pData.Box.Visible = false
                pData.BoxOutline.Visible = false

                local lengthX = boxWidth / 4
                local lengthY = boxHeight / 4
                local lines = pData.CornerLines
                local outlineColor = Color3.fromRGB(0, 0, 0)

                for i = 1, 16 do
                    lines[i].Color = activeBoxColor
                end

                lines[1].From = Vector2.new(boxX, boxY) lines[1].To = Vector2.new(boxX + lengthX, boxY) lines[1].Color = outlineColor lines[1].Thickness = 3
                lines[2].From = Vector2.new(boxX, boxY) lines[2].To = Vector2.new(boxX + lengthX, boxY) lines[2].Color = activeBoxColor lines[2].Thickness = 1.25
                lines[3].From = Vector2.new(boxX, boxY) lines[3].To = Vector2.new(boxX, boxY + lengthY) lines[3].Color = outlineColor lines[3].Thickness = 3
                lines[4].From = Vector2.new(boxX, boxY) lines[4].To = Vector2.new(boxX, boxY + lengthY) lines[4].Color = activeBoxColor lines[4].Thickness = 1.25

                lines[5].From = Vector2.new(boxX + boxWidth, boxY) lines[5].To = Vector2.new(boxX + boxWidth - lengthX, boxY) lines[5].Color = outlineColor lines[5].Thickness = 3
                lines[6].From = Vector2.new(boxX + boxWidth, boxY) lines[6].To = Vector2.new(boxX + boxWidth - lengthX, boxY) lines[6].Color = activeBoxColor lines[6].Thickness = 1.25
                lines[7].From = Vector2.new(boxX + boxWidth, boxY) lines[7].To = Vector2.new(boxX + boxWidth, boxY + lengthY) lines[7].Color = outlineColor lines[7].Thickness = 3
                lines[8].From = Vector2.new(boxX + boxWidth, boxY) lines[8].To = Vector2.new(boxX + boxWidth, boxY + lengthY) lines[8].Color = activeBoxColor lines[8].Thickness = 1.25

                lines[9].From = Vector2.new(boxX, boxY + boxHeight) lines[9].To = Vector2.new(boxX + lengthX, boxY + boxHeight) lines[9].Color = outlineColor lines[9].Thickness = 3
                lines[10].From = Vector2.new(boxX, boxY + boxHeight) lines[10].To = Vector2.new(boxX + lengthX, boxY + boxHeight) lines[10].Color = activeBoxColor lines[10].Thickness = 1.25
                lines[11].From = Vector2.new(boxX, boxY + boxHeight) lines[11].To = Vector2.new(boxX, boxY + boxHeight - lengthY) lines[11].Color = outlineColor lines[11].Thickness = 3
                lines[12].From = Vector2.new(boxX, boxY + boxHeight) lines[12].To = Vector2.new(boxX, boxY + boxHeight - lengthY) lines[12].Color = activeBoxColor lines[12].Thickness = 1.25

                lines[13].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[13].To = Vector2.new(boxX + boxWidth - lengthX, boxY + boxHeight) lines[13].Color = outlineColor lines[13].Thickness = 3
                lines[14].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[14].To = Vector2.new(boxX + boxWidth - lengthX, boxY + boxHeight) lines[14].Color = activeBoxColor lines[14].Thickness = 1.25
                lines[15].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[15].To = Vector2.new(boxX + boxWidth, boxY + boxHeight - lengthY) lines[15].Color = outlineColor lines[15].Thickness = 3
                lines[16].From = Vector2.new(boxX + boxWidth, boxY + boxHeight) lines[16].To = Vector2.new(boxX + boxWidth, boxY + boxHeight - lengthY) lines[16].Color = activeBoxColor lines[16].Thickness = 1.25

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
            pData.DistanceTag.Text = math.floor(distance) .. "m"
            pData.DistanceTag.Size = ESP.Settings.DistanceSize or 12
            pData.DistanceTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY + boxHeight + 2)
            pData.DistanceTag.Color = ESP.Settings.DistanceColor
            pData.DistanceTag.Visible = true
        else
            pData.DistanceTag.Visible = false
        end

        if ESP.Settings.Weapon then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                pData.WeaponTag.Text = tool.Name
                pData.WeaponTag.Size = ESP.Settings.TextSize
                local offset = ESP.Settings.Distance and 16 or 2
                pData.WeaponTag.Position = Vector2.new(boxX + (boxWidth / 2), boxY + boxHeight + offset)
                pData.WeaponTag.Color = ESP.Settings.WeaponColor
                pData.WeaponTag.Visible = true
            else
                pData.WeaponTag.Visible = false
            end
        else
            pData.WeaponTag.Visible = false
        end

        if ESP.Settings.GazeLine then
            local head = character:FindFirstChild("Head")
            if head then
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                local lookEndPos, lookOnScreen = Camera:WorldToViewportPoint(head.Position + head.CFrame.LookVector * ESP.Settings.GazeLineLength)
                if headOnScreen and lookOnScreen then
                    pData.GazeLine.From = Vector2.new(headPos.X, headPos.Y)
                    pData.GazeLine.To = Vector2.new(lookEndPos.X, lookEndPos.Y)
                    pData.GazeLine.Color = ESP.Settings.GazeLineColor
                    pData.GazeLine.Visible = true
                else
                    pData.GazeLine.Visible = false
                end
            else
                pData.GazeLine.Visible = false
            end
        else
            pData.GazeLine.Visible = false
        end

        if ESP.Settings.Tracers then
            pData.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            pData.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            pData.Tracer.Color = ESP.Settings.TracerColor
            pData.Tracer.Visible = true
        else
            pData.Tracer.Visible = false
        end

        if ESP.Settings.Skeleton then
            local bones = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
            }
            for i, bone in ipairs(bones) do
                local p1 = character:FindFirstChild(bone[1])
                local p2 = character:FindFirstChild(bone[2])
                local line = pData.SkeletonLines[i]
                if p1 and p2 and line then
                    local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                    local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                    if vis1 or vis2 then
                        line.From = Vector2.new(pos1.X, pos1.Y)
                        line.To = Vector2.new(pos2.X, pos2.Y)
                        line.Color = ESP.Settings.SkeletonColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    if line then line.Visible = false end
                end
            end
        else
            for _, line in pairs(pData.SkeletonLines) do line.Visible = false end
        end
    end)

    player.AncestryChanged:Connect(function(_, parent)
        if not parent then removeESP(player) end
    end)
end

-- ==========================================
-- 3. Cleanup & Garbage Collection (Destroy Function)
-- ==========================================
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

-- ==========================================
-- 4. Public API Methods (ช่องทางติดต่อสื่อสารกับภายนอก)
-- ==========================================
function ESP:Init()
    for _, player in ipairs(Players:GetPlayers()) do
        addPlayer(player)
    end
    table.insert(Connections, Players.PlayerAdded:Connect(addPlayer))
    table.insert(Connections, Players.PlayerRemoving:Connect(removeESP))

    -- ปุ่มลัดปิดสคริปต์ฉุกเฉิน (กดปุ่ม Keypad 1)
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

-- เริ่มต้นการทำงานของโมดูล
ESP:Init()
getgenv().ESP = ESP
return ESP
