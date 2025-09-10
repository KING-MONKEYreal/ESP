-- esp.lua
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Cache = {}

--// Bones for Skeleton ESP
local Bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

--// Settings
local ESP_SETTINGS = {
    Enabled = false,
    Teamcheck = false,
    WallCheck = false,

    -- Box
    ShowBox = false,
    BoxType = "2D", -- "2D" or "Corner Box Esp"
    BoxColor = Color3.new(1, 1, 1),
    BoxOutlineColor = Color3.new(0, 0, 0),

    -- Name
    ShowName = false,
    NameColor = Color3.new(1, 1, 1),

    -- Health
    ShowHealth = false,
    HealthOutlineColor = Color3.new(0, 0, 0),
    HealthHighColor = Color3.new(0, 1, 0),
    HealthLowColor = Color3.new(1, 0, 0),

    -- Distance
    ShowDistance = false,

    -- Skeletons
    ShowSkeletons = false,
    SkeletonsColor = Color3.new(1, 1, 1),

    -- Tracers
    ShowTracer = false,
    TracerColor = Color3.new(1, 1, 1),
    TracerThickness = 2,
    TracerPosition = "Bottom", -- "Top", "Middle", "Bottom"
}

--// Utility
local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

--// Wall Check
local function isBehindWall(rootPart, character)
    if not rootPart then return false end
    local ray = Ray.new(Camera.CFrame.Position, (rootPart.Position - Camera.CFrame.Position).Unit * (rootPart.Position - Camera.CFrame.Position).Magnitude)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, character})
    return hit and hit:IsA("BasePart")
end

--// ESP Creation
local function createEsp(player)
    if Cache[player] then return end

    local esp = {
        name = create("Text", {Size = 13, Outline = true, Center = true, Visible = false}),
        distance = create("Text", {Size = 12, Outline = true, Center = true, Visible = false}),
        box = create("Square", {Thickness = 1, Filled = false, Visible = false}),
        boxOutline = create("Square", {Thickness = 3, Filled = false, Visible = false}),
        health = create("Line", {Thickness = 1, Visible = false}),
        healthOutline = create("Line", {Thickness = 3, Visible = false}),
        tracer = create("Line", {Thickness = ESP_SETTINGS.TracerThickness, Transparency = 1, Visible = false}),
        boxLines = {},
        skeletonLines = {}
    }

    Cache[player] = esp
end

--// ESP Removal
local function removeEsp(player)
    local esp = Cache[player]
    if not esp then return end
    for _, obj in pairs(esp) do
        if typeof(obj) == "table" then
            for _, line in pairs(obj) do
                if line.Remove then line:Remove() end
            end
        elseif obj.Remove then
            obj:Remove()
        end
    end
    Cache[player] = nil
end

--// ESP Update Loop
local function updateEsp()
    if not ESP_SETTINGS.Enabled then
        for _, esp in pairs(Cache) do
            for _, obj in pairs(esp) do
                if obj.Visible ~= nil then obj.Visible = false end
            end
        end
        return
    end

    for player, esp in pairs(Cache) do
        local character = player.Character
        local team = player.Team
        if not character then continue end
        if ESP_SETTINGS.Teamcheck and team == LocalPlayer.Team then
            for _, obj in pairs(esp) do
                if obj.Visible ~= nil then obj.Visible = false end
            end
            continue
        end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (hrp and head and humanoid) then continue end

        if ESP_SETTINGS.WallCheck and isBehindWall(hrp, character) then
            for _, obj in pairs(esp) do
                if obj.Visible ~= nil then obj.Visible = false end
            end
            continue
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _, obj in pairs(esp) do
                if obj.Visible ~= nil then obj.Visible = false end
            end
            continue
        end

        -- Box size/pos
        local charSize = (Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y -
                         Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.6, 0)).Y) / 2
        local boxSize = Vector2.new(math.floor(charSize * 1.8), math.floor(charSize * 1.9))
        local boxPos = Vector2.new(math.floor(pos.X - boxSize.X / 2), math.floor(pos.Y - boxSize.Y / 2))

        -- Name ESP
        if ESP_SETTINGS.ShowName then
            esp.name.Visible = true
            esp.name.Text = player.Name
            esp.name.Color = ESP_SETTINGS.NameColor
            esp.name.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y - 16)
        else
            esp.name.Visible = false
        end

        -- Distance ESP
        if ESP_SETTINGS.ShowDistance then
            local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
            esp.distance.Visible = true
            esp.distance.Text = string.format("%.1f studs", distance)
            esp.distance.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y + 5)
        else
            esp.distance.Visible = false
        end

        -- Health ESP
        if ESP_SETTINGS.ShowHealth then
            local hpPercent = humanoid.Health / humanoid.MaxHealth
            esp.healthOutline.Visible = true
            esp.health.Visible = true
            esp.healthOutline.From = Vector2.new(boxPos.X - 6, boxPos.Y + boxSize.Y)
            esp.healthOutline.To = Vector2.new(boxPos.X - 6, boxPos.Y)
            esp.health.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y)
            esp.health.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxSize.Y - (hpPercent * boxSize.Y))
            esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, hpPercent)
        else
            esp.health.Visible = false
            esp.healthOutline.Visible = false
        end

        -- Tracer ESP
        if ESP_SETTINGS.ShowTracer then
            esp.tracer.Visible = true
            local tracerY = ESP_SETTINGS.TracerPosition == "Top" and 0
                         or ESP_SETTINGS.TracerPosition == "Middle" and Camera.ViewportSize.Y / 2
                         or Camera.ViewportSize.Y
            esp.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, tracerY)
            esp.tracer.To = Vector2.new(pos.X, pos.Y)
            esp.tracer.Color = ESP_SETTINGS.TracerColor
        else
            esp.tracer.Visible = false
        end

        -- Box ESP (2D or Corner)
        if ESP_SETTINGS.ShowBox then
            esp.box.Visible = true
            esp.boxOutline.Visible = true
            esp.box.Size = boxSize
            esp.box.Position = boxPos
            esp.box.Color = ESP_SETTINGS.BoxColor
            esp.boxOutline.Size = boxSize
            esp.boxOutline.Position = boxPos
            esp.boxOutline.Color = ESP_SETTINGS.BoxOutlineColor
        else
            esp.box.Visible = false
            esp.boxOutline.Visible = false
        end

        -- Skeleton ESP
        if ESP_SETTINGS.ShowSkeletons then
            if #esp.skeletonLines == 0 then
                for _, bonePair in ipairs(Bones) do
                    local line = create("Line", {Thickness = 1, Color = ESP_SETTINGS.SkeletonsColor, Transparency = 1})
                    table.insert(esp.skeletonLines, {line, bonePair[1], bonePair[2]})
                end
            end
            for _, lineData in ipairs(esp.skeletonLines) do
                local line, pBone, cBone = lineData[1], lineData[2], lineData[3]
                local p = character:FindFirstChild(pBone)
                local c = character:FindFirstChild(cBone)
                if p and c then
                    local p2D = Camera:WorldToViewportPoint(p.Position)
                    local c2D = Camera:WorldToViewportPoint(c.Position)
                    line.Visible = true
                    line.From = Vector2.new(p2D.X, p2D.Y)
                    line.To = Vector2.new(c2D.X, c2D.Y)
                    line.Color = ESP_SETTINGS.SkeletonsColor
                else
                    line.Visible = false
                end
            end
        else
            for _, lineData in ipairs(esp.skeletonLines) do
                lineData[1].Visible = false
            end
        end
    end
end

--// Connections
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createEsp(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(removeEsp)
RunService.RenderStepped:Connect(updateEsp)

return ESP_SETTINGS

