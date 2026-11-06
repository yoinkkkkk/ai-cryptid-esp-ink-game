local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer

local Cfg = {
    ESP = false, Chams = false, Tracers = false, Boxes = false, Names = false, Dist = false,
    ForceVis = true, MinD = 0, MaxD = 5000,
    ColChams = Color3.fromRGB(170, 0, 255), ColTracer = Color3.fromRGB(170, 0, 255),
    ColBox = Color3.fromRGB(170, 0, 255), ColText = Color3.fromRGB(220, 150, 255),
    ThickTracer = 1, ThickBox = 1, SizeText = 14,
    RbwChams = false, RbwTracers = false, RbwBoxes = false, RbwText = false,
    ScanRate = 1
}

local Objs = {}
local UIRefs = {}

local function getRainbow()
    return Color3.fromHSV((tick() * 0.5) % 1, 1, 1)
end

local function getRoot(obj)
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
end

local function setup(obj)
    if Objs[obj] then return end
    local root = getRoot(obj)
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.FillColor = Cfg.ColChams
    hl.FillTransparency = 0.5
    hl.OutlineColor = Cfg.ColChams
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Enabled = Cfg.Chams
    hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(200, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.Adornee = root
    bb.Enabled = Cfg.Names or Cfg.Dist
    bb.Parent = obj

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.fromScale(1, 1)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = Cfg.SizeText
    txt.TextColor3 = Cfg.ColText
    txt.TextStrokeTransparency = 0.4
    txt.TextStrokeColor3 = Color3.new(0, 0, 0)
    txt.Parent = bb

    local tr = Drawing.new("Line")
    tr.Color = Cfg.ColTracer
    tr.Thickness = Cfg.ThickTracer
    tr.Transparency = 1
    tr.Visible = false

    local bx = Drawing.new("Square")
    bx.Color = Cfg.ColBox
    bx.Thickness = Cfg.ThickBox
    bx.Filled = false
    bx.Transparency = 1
    bx.Visible = false

    Objs[obj] = { hl = hl, bb = bb, txt = txt, tr = tr, bx = bx, root = root }
end

local function cleanup(obj)
    local d = Objs[obj]
    if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
    if d.tr then d.tr:Remove() end
    if d.bx then d.bx:Remove() end
    Objs[obj] = nil
end

local function checkName(n)
    return string.find(string.lower(n), "cryptid", 1, true) ~= nil
end

local function doScan()
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and checkName(v.Name) and not Objs[v] then
            setup(v)
        end
    end
    for obj, d in pairs(Objs) do
        if not obj.Parent or not d.root or not d.root.Parent then
            cleanup(obj)
        end
    end
end

doScan()

Workspace.DescendantAdded:Connect(function(v)
    if (v:IsA("Model") or v:IsA("BasePart")) and checkName(v.Name) then
        task.defer(function()
            if v and v.Parent then setup(v) end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(Cfg.ScanRate)
        doScan()
    end
end)

RunService.RenderStepped:Connect(function()
    if not Cfg.ESP then
        for _, d in pairs(Objs) do
            if d.tr then d.tr.Visible = false end
            if d.bx then d.bx.Visible = false end
            if d.bb then d.bb.Enabled = false end
            if d.hl then d.hl.Enabled = false end
        end
        return
    end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local rbw = getRainbow()

    for obj, d in pairs(Objs) do
        local root = d.root
        if not root or not root.Parent then
            cleanup(obj)
            continue
        end

        if Cfg.ForceVis then
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.LocalTransparencyModifier = 0
                    if p.Transparency > 0.5 then
                        p.Transparency = 0.5
                    end
                end
            end
        end

        local sp, onScr = Camera:WorldToViewportPoint(root.Position)
        local dist = math.floor((hrp.Position - root.Position).Magnitude)

        if onScr and dist >= Cfg.MinD and dist <= Cfg.MaxD then
            local tStr = ""
            if Cfg.Names then tStr = obj.Name end
            if Cfg.Dist then
                if tStr ~= "" then tStr = tStr .. " " end
                tStr = tStr .. "[" .. dist .. "]"
            end

            if tStr ~= "" then
                d.bb.Enabled = true
                d.txt.Text = tStr
                d.txt.TextColor3 = Cfg.RbwText and rbw or Cfg.ColText
                d.txt.TextSize = Cfg.SizeText
            else
                d.bb.Enabled = false
            end

            if Cfg.Chams then
                d.hl.Enabled = true
                local cc = Cfg.RbwChams and rbw or Cfg.ColChams
                d.hl.FillColor = cc
                d.hl.OutlineColor = cc
            else
                d.hl.Enabled = false
            end

            if Cfg.Tracers then
                d.tr.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.tr.To = Vector2.new(sp.X, sp.Y)
                d.tr.Color = Cfg.RbwTracers and rbw or Cfg.ColTracer
                d.tr.Thickness = Cfg.ThickTracer
                d.tr.Visible = true
            else
                d.tr.Visible = false
            end

            if Cfg.Boxes then
                local h = (Camera.ViewportSize.Y / dist) * 3
                local w = h / 2
                d.bx.Size = Vector2.new(w, h)
                d.bx.Position = Vector2.new(sp.X - w / 2, sp.Y - h / 2)
                d.bx.Color = Cfg.RbwBoxes and rbw or Cfg.ColBox
                d.bx.Thickness = Cfg.ThickBox
                d.bx.Visible = true
            else
                d.bx.Visible = false
            end
        else
            d.tr.Visible = false
            d.bx.Visible = false
            d.bb.Enabled = false
            d.hl.Enabled = false
        end
    end
end)

local Win = WindUI:CreateWindow({
    Title = "Ink Game",
    Icon = "eye",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 480),
    OpenButton = {
        Title = "C R Y P T I D",
        CornerRadius = UDim.new(1, 0),
        OutlineThickness = 3,
        OutlineColor = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        RainbowOutline = true,
        Enabled = true,
    }
})

local T1 = Win:Tab({ Title = "Visuals", Icon = "eye" })
local S1 = T1:Section({ Title = "Main" })

UIRefs.ESP = S1:Toggle({ Title = "Master ESP", Value = false, Callback = function(v) Cfg.ESP = v end })
UIRefs.ForceVis = S1:Toggle({ Title = "Force Visibility (Anti-Hide)", Value = true, Callback = function(v) Cfg.ForceVis = v end })
UIRefs.Chams = S1:Toggle({ Title = "Chams", Value = false, Callback = function(v) Cfg.Chams = v end })
UIRefs.Tracers = S1:Toggle({ Title = "Tracers", Value = false, Callback = function(v) Cfg.Tracers = v end })
UIRefs.Boxes = S1:Toggle({ Title = "Boxes", Value = false, Callback = function(v) Cfg.Boxes = v end })
UIRefs.Names = S1:Toggle({ Title = "Names", Value = false, Callback = function(v) Cfg.Names = v end })
UIRefs.Dist = S1:Toggle({ Title = "Distance", Value = false, Callback = function(v) Cfg.Dist = v end })

local S2 = T1:Section({ Title = "Filters & Scan" })

UIRefs.MinD = S2:Slider({ Title = "Min Distance", Value = { Min = 0, Max = 5000, Default = 0 }, Callback = function(v) Cfg.MinD = v end })
UIRefs.MaxD = S2:Slider({ Title = "Max Distance", Value = { Min = 0, Max = 5000, Default = 5000 }, Callback = function(v) Cfg.MaxD = v end })
UIRefs.ScanRate = S2:Slider({ Title = "Check Time (sec)", Value = { Min = 0.3, Max = 5, Default = 1 }, Callback = function(v) Cfg.ScanRate = v end })

local S3 = T1:Section({ Title = "Colors & Sizes" })

UIRefs.ColChams = S3:Colorpicker({ Title = "Chams Color", Default = Cfg.ColChams, Callback = function(c) Cfg.ColChams = c end })
UIRefs.ColTracer = S3:Colorpicker({ Title = "Tracer Color", Default = Cfg.ColTracer, Callback = function(c) Cfg.ColTracer = c end })
UIRefs.ColBox = S3:Colorpicker({ Title = "Box Color", Default = Cfg.ColBox, Callback = function(c) Cfg.ColBox = c end })
UIRefs.ColText = S3:Colorpicker({ Title = "Text Color", Default = Cfg.ColText, Callback = function(c) Cfg.ColText = c end })

UIRefs.ThickTracer = S3:Slider({ Title = "Tracer Thickness", Value = { Min = 1, Max = 5, Default = 1 }, Callback = function(v) Cfg.ThickTracer = v end })
UIRefs.ThickBox = S3:Slider({ Title = "Box Thickness", Value = { Min = 1, Max = 5, Default = 1 }, Callback = function(v) Cfg.ThickBox = v end })
UIRefs.SizeText = S3:Slider({ Title = "Text Size", Value = { Min = 10, Max = 24, Default = 14 }, Callback = function(v) Cfg.SizeText = v end })

local S4 = T1:Section({ Title = "Rainbow" })

UIRefs.RbwChams = S4:Toggle({ Title = "Rainbow Chams", Value = false, Callback = function(v) Cfg.RbwChams = v end })
UIRefs.RbwTracers = S4:Toggle({ Title = "Rainbow Tracers", Value = false, Callback = function(v) Cfg.RbwTracers = v end })
UIRefs.RbwBoxes = S4:Toggle({ Title = "Rainbow Boxes", Value = false, Callback = function(v) Cfg.RbwBoxes = v end })
UIRefs.RbwText = S4:Toggle({ Title = "Rainbow Text", Value = false, Callback = function(v) Cfg.RbwText = v end })

local T3 = Win:Tab({ Title = "Configs", Icon = "save" })
local S6 = T3:Section({ Title = "Config Manager" })

local NameBox = S6:Input({ Title = "Config Name", Value = "default", Placeholder = "Name..." })

S6:Button({
    Title = "Save",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        local d = {}
        for k, v in pairs(Cfg) do
            if typeof(v) == "Color3" then
                d[k] = {v.R, v.G, v.B}
            else
                d[k] = v
            end
        end
        if writefile then
            if not isfolder("CryptidCfg") then makefolder("CryptidCfg") end
            writefile("CryptidCfg/" .. n .. ".json", game:GetService("HttpService"):JSONEncode(d))
            Win:Notify({ Title = "Saved", Content = n, Duration = 2 })
        end
    end
})

S6:Button({
    Title = "Load",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        local p = "CryptidCfg/" .. n .. ".json"
        if isfile and isfile(p) then
            local s, d = pcall(function()
                return game:GetService("HttpService"):JSONDecode(readfile(p))
            end)
            if s and d then
                for k, v in pairs(d) do
                    if type(v) == "table" and #v == 3 then
                        Cfg[k] = Color3.new(v[1], v[2], v[3])
                    else
                        Cfg[k] = v
                    end
                end
                for k, v in pairs(Cfg) do
                    if UIRefs[k] and UIRefs[k].Set then
                        pcall(function() UIRefs[k]:Set(v) end)
                    end
                end
                Win:Notify({ Title = "Loaded", Content = n, Duration = 2 })
            end
        end
    end
})
