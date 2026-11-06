local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer

local Config = {
    ESP = false,
    Tracers = false,
    Boxes = false,
    Chams = false,
    Names = false,
    Distance = false,
    MinDist = 0,
    MaxDist = 5000,
    TracerColor = Color3.fromRGB(170, 0, 255),
    BoxColor = Color3.fromRGB(170, 0, 255),
    ChamsColor = Color3.fromRGB(170, 0, 255),
    TextColor = Color3.fromRGB(220, 150, 255),
    TracerThickness = 1,
    BoxThickness = 1,
    TextSize = 14
}

local tracked = {}

local function isCryptid(obj)
    if not obj or (not obj:IsA("Model") and not obj:IsA("BasePart")) then return false end
    return string.find(string.lower(obj.Name), "cryptid", 1, true) ~= nil
end

local function getRootPart(obj)
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
end

local function createESP(model)
    if tracked[model] then return end
    local root = getRootPart(model)
    if not root then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CryptidESP_HL"
    highlight.FillColor = Config.ChamsColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Config.ChamsColor
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Enabled = Config.Chams
    highlight.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CryptidESP_BB"
    billboard.Size = UDim2.fromOffset(200, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Adornee = root
    billboard.Enabled = Config.Names or Config.Distance
    billboard.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = Config.TextSize
    label.TextColor3 = Config.TextColor
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Text = ""
    label.Parent = billboard

    local tracer = Drawing.new("Line")
    tracer.Color = Config.TracerColor
    tracer.Thickness = Config.TracerThickness
    tracer.Transparency = 1
    tracer.Visible = false

    local box = Drawing.new("Square")
    box.Color = Config.BoxColor
    box.Thickness = Config.BoxThickness
    box.Filled = false
    box.Transparency = 1
    box.Visible = false

    tracked[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
        tracer = tracer,
        box = box,
        root = root
    }
end

local function removeESP(model)
    local data = tracked[model]
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    if data.tracer then data.tracer:Remove() end
    if data.box then data.box:Remove() end
    tracked[model] = nil
end

local function initialScan()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCryptid(obj) then
            createESP(obj)
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if isCryptid(obj) then
        task.defer(function()
            if obj and obj.Parent then
                createESP(obj)
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        for model, data in pairs(tracked) do
            if not model.Parent or not data.root or not data.root.Parent then
                removeESP(model)
            end
        end
    end
end)

local function updateVisuals()
    if not Config.ESP then
        for _, data in pairs(tracked) do
            if data.tracer then data.tracer.Visible = false end
            if data.box then data.box.Visible = false end
            if data.billboard then data.billboard.Enabled = false end
            if data.highlight then data.highlight.Enabled = false end
        end
        return
    end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for model, data in pairs(tracked) do
        local root = data.root
        if not root or not root.Parent then
            removeESP(model)
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local dist = math.floor((hrp.Position - root.Position).Magnitude)

        if onScreen and dist >= Config.MinDist and dist <= Config.MaxDist then
            local textStr = ""
            if Config.Names then textStr = model.Name end
            if Config.Distance then
                if textStr ~= "" then textStr = textStr .. " " end
                textStr = textStr .. "[" .. dist .. "]"
            end

            if textStr ~= "" then
                data.billboard.Enabled = true
                data.label.Text = textStr
                data.label.TextColor3 = Config.TextColor
                data.label.TextSize = Config.TextSize
            else
                data.billboard.Enabled = false
            end

            if Config.Chams then
                data.highlight.Enabled = true
                data.highlight.FillColor = Config.ChamsColor
                data.highlight.OutlineColor = Config.ChamsColor
            else
                data.highlight.Enabled = false
            end

            if Config.Tracers then
                data.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                data.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                data.tracer.Color = Config.TracerColor
                data.tracer.Thickness = Config.TracerThickness
                data.tracer.Visible = true
            else
                data.tracer.Visible = false
            end

            if Config.Boxes then
                local height = (Camera.ViewportSize.Y / dist) * 3
                local width = height / 2
                data.box.Size = Vector2.new(width, height)
                data.box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                data.box.Color = Config.BoxColor
                data.box.Thickness = Config.BoxThickness
                data.box.Visible = true
            else
                data.box.Visible = false
            end
        else
            data.tracer.Visible = false
            data.box.Visible = false
            data.billboard.Enabled = false
            data.highlight.Enabled = false
        end
    end
end

RunService.RenderStepped:Connect(updateVisuals)

local Window = WindUI:CreateWindow({
    Title = "Ink Game",
    Icon = "eye",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 450)
})

local Tab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local ESPGroup = Tab:Section({ Title = "ESP Options" })

ESPGroup:Toggle({
    Title = "Master ESP",
    Value = false,
    Callback = function(state)
        Config.ESP = state
    end
})

ESPGroup:Toggle({
    Title = "Chams",
    Value = false,
    Callback = function(state)
        Config.Chams = state
    end
})

ESPGroup:Toggle({
    Title = "Tracers",
    Value = false,
    Callback = function(state)
        Config.Tracers = state
    end
})

ESPGroup:Toggle({
    Title = "Boxes",
    Value = false,
    Callback = function(state)
        Config.Boxes = state
    end
})

ESPGroup:Toggle({
    Title = "Names",
    Value = false,
    Callback = function(state)
        Config.Names = state
    end
})

ESPGroup:Toggle({
    Title = "Distance",
    Value = false,
    Callback = function(state)
        Config.Distance = state
    end
})

local DistGroup = Tab:Section({ Title = "Distance Filter" })

DistGroup:Slider({
    Title = "Min Distance",
    Value = { Min = 0, Max = 5000, Default = 0 },
    Callback = function(value)
        Config.MinDist = value
    end
})

DistGroup:Slider({
    Title = "Max Distance",
    Value = { Min = 0, Max = 5000, Default = 5000 },
    Callback = function(value)
        Config.MaxDist = value
    end
})

local StyleGroup = Tab:Section({ Title = "Colors & Thickness" })

StyleGroup:Colorpicker({
    Title = "Chams Color",
    Default = Config.ChamsColor,
    Callback = function(color)
        Config.ChamsColor = color
    end
})

StyleGroup:Colorpicker({
    Title = "Tracer Color",
    Default = Config.TracerColor,
    Callback = function(color)
        Config.TracerColor = color
    end
})

StyleGroup:Colorpicker({
    Title = "Box Color",
    Default = Config.BoxColor,
    Callback = function(color)
        Config.BoxColor = color
    end
})

StyleGroup:Colorpicker({
    Title = "Text Color",
    Default = Config.TextColor,
    Callback = function(color)
        Config.TextColor = color
    end
})

StyleGroup:Slider({
    Title = "Tracer Thickness",
    Value = { Min = 1, Max = 5, Default = Config.TracerThickness },
    Callback = function(value)
        Config.TracerThickness = value
    end
})

StyleGroup:Slider({
    Title = "Box Thickness",
    Value = { Min = 1, Max = 5, Default = Config.BoxThickness },
    Callback = function(value)
        Config.BoxThickness = value
    end
})

StyleGroup:Slider({
    Title = "Text Size",
    Value = { Min = 10, Max = 24, Default = Config.TextSize },
    Callback = function(value)
        Config.TextSize = value
    end
})

initialScan()
