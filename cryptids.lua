local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer

local Cfg = {
    ESP = false, Chams = false, Tracers = false, Boxes = false, Names = false, Dist = false,
    MinD = 0, MaxD = 5000,
    ColChams = Color3.fromRGB(170, 0, 255), ColTracer = Color3.fromRGB(170, 0, 255),
    ColBox = Color3.fromRGB(170, 0, 255), ColText = Color3.fromRGB(220, 150, 255),
    ThickTracer = 1, ThickBox = 1, SizeText = 14,
    RbwChams = false, RbwTracers = false, RbwBoxes = false, RbwText = false
}

local Objs = {}
local UIRefs = {}
local S = { Running = true, Connections = {} }
local WinRef

local function track(c)
    table.insert(S.Connections, c)
    return c
end

local function getRainbow()
    return Color3.fromHSV((tick() * 0.5) % 1, 1, 1)
end

local function checkName(n)
    return string.find(string.lower(n), "cryptid", 1, true) ~= nil
end

local function getTargetModel(obj)
    if obj:IsA("Model") then return obj end
    local m = obj:FindFirstAncestorOfClass("Model")
    return m or obj
end

local function isTarget(v)
    if not (v:IsA("Model") or v:IsA("BasePart")) then return false end
    if not checkName(v.Name) then return false end
    if v:IsA("BasePart") then
        local p = v.Parent
        if p and p:IsA("Model") and checkName(p.Name) then return false end
    end
    return true
end

local function setup(obj)
    if Objs[obj] then return end
    local model = getTargetModel(obj)
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head") or (model.PrimaryPart) or (model:IsA("BasePart") and model)
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Name = "c_hl"
    hl.Parent = Camera
    hl.Adornee = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Cfg.ColChams
    hl.FillTransparency = 0.5
    hl.OutlineColor = Cfg.ColChams
    hl.OutlineTransparency = 0
    hl.Enabled = false

    local bb = Instance.new("BillboardGui")
    bb.Name = "c_bb"
    bb.Size = UDim2.fromOffset(200, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = math.huge
    bb.Adornee = root
    bb.Enabled = false
    bb.Parent = model

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

    Objs[obj] = { hl = hl, bb = bb, txt = txt, tr = tr, bx = bx, root = root, model = model }
end

local function cleanup(obj)
    local d = Objs[obj]
    if not d then return end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.bb then pcall(function() d.bb:Destroy() end) end
    if d.tr then pcall(function() d.tr:Remove() end) end
    if d.bx then pcall(function() d.bx:Remove() end) end
    Objs[obj] = nil
end

local function initialScanChunked()
    local queue = {Workspace}
    local i = 1
    local count = 0
    while i <= #queue and S.Running do
        local cur = queue[i]
        i = i + 1
        for _, child in ipairs(cur:GetChildren()) do
            if isTarget(child) then setup(child) end
            table.insert(queue, child)
            count = count + 1
            if count % 500 == 0 then
                task.wait()
            end
        end
    end
end

task.spawn(initialScanChunked)

track(Workspace.DescendantAdded:Connect(function(v)
    if S.Running and isTarget(v) then
        task.defer(function()
            if v and v.Parent and S.Running then setup(v) end
        end)
    end
end))

track(RunService.RenderStepped:Connect(function()
    if not S.Running then return end

    if not Cfg.ESP and not Cfg.Chams then
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
        if not root or not root.Parent or not obj.Parent then
            cleanup(obj)
            continue
        end

        if Cfg.ESP then
            for _, p in ipairs(obj:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.LocalTransparencyModifier = 0
                    if p.Transparency > 0.5 then p.Transparency = 0.5 end
                end
            end
        end

        local sp, onScr = Camera:WorldToViewportPoint(root.Position)
        local dist = math.max(1, math.floor((hrp.Position - root.Position).Magnitude))
        local inRange = dist >= Cfg.MinD and dist <= Cfg.MaxD

        if Cfg.Chams and inRange then
            d.hl.Enabled = true
            local cc = Cfg.RbwChams and rbw or Cfg.ColChams
            d.hl.FillColor = cc
            d.hl.OutlineColor = cc
        else
            d.hl.Enabled = false
        end

        if Cfg.ESP and inRange then
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

            if onScr and sp.Z > 0 then
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
            end
        else
            d.bb.Enabled = false
            d.tr.Visible = false
            d.bx.Visible = false
        end
    end
end))

local function unloadScript()
    S.Running = false
    for _, conn in ipairs(S.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(S.Connections)
    for obj, d in pairs(Objs) do
        if d.hl then pcall(function() d.hl:Destroy() end) end
        if d.bb then pcall(function() d.bb:Destroy() end) end
        if d.tr then pcall(function() d.tr:Remove() end) end
        if d.bx then pcall(function() d.bx:Remove() end) end
    end
    table.clear(Objs)
    pcall(function() if WindUI and WinRef then WinRef:Destroy() end end)
    if getgenv then
        pcall(function() getgenv().CryptidESP_Unload = nil end)
    end
end

getgenv().CryptidESP_Unload = unloadScript

local Win = WindUI:CreateWindow({
    Title = "Ink Game",
    Icon = "eye",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 480),
    OpenButton = {
        Title = "CRYPTID",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 4,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        }),
        Enabled = true,
    }
})
WinRef = Win

track(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.End then unloadScript() end
end))

local AUTOLOAD_FILE = "CryptidCfg/_autoload.txt"

local function ensureDir()
    if writefile and not isfolder("CryptidCfg") then
        pcall(makefolder, "CryptidCfg")
    end
end

local function saveCfgTo(name)
    if not writefile then return false end
    ensureDir()
    local d = {}
    for k, v in pairs(Cfg) do
        if typeof(v) == "Color3" then
            d[k] = {v.R, v.G, v.B}
        else
            d[k] = v
        end
    end
    local ok = pcall(writefile, "CryptidCfg/" .. name .. ".json", HttpService:JSONEncode(d))
    return ok
end

local function loadCfgFrom(name)
    if not isfile or not readfile then return false end
    local p = "CryptidCfg/" .. name .. ".json"
    if not isfile(p) then return false end
    local s, raw = pcall(readfile, p)
    if not s or not raw then return false end
    local ok, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(d) ~= "table" then return false end
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
    return true
end

local function getAutoloadName()
    if not isfile or not readfile then return nil end
    if not isfile(AUTOLOAD_FILE) then return nil end
    local ok, v = pcall(readfile, AUTOLOAD_FILE)
    if ok and v and v ~= "" then return v end
    return nil
end

local function setAutoloadName(name)
    if not writefile then return false end
    ensureDir()
    return pcall(writefile, AUTOLOAD_FILE, name or "")
end

local T1 = Win:Tab({ Title = "Visuals", Icon = "eye" })
local S1 = T1:Section({ Title = "Main" })

UIRefs.ESP = S1:Toggle({ Title = "Master ESP", Value = false, Callback = function(v) Cfg.ESP = v end })
UIRefs.Chams = S1:Toggle({ Title = "Chams", Value = false, Callback = function(v) Cfg.Chams = v end })
UIRefs.Tracers = S1:Toggle({ Title = "Tracers", Value = false, Callback = function(v) Cfg.Tracers = v end })
UIRefs.Boxes = S1:Toggle({ Title = "Boxes", Value = false, Callback = function(v) Cfg.Boxes = v end })
UIRefs.Names = S1:Toggle({ Title = "Names", Value = false, Callback = function(v) Cfg.Names = v end })
UIRefs.Dist = S1:Toggle({ Title = "Distance", Value = false, Callback = function(v) Cfg.Dist = v end })

S1:Button({
    Title = "PANIC UNLOAD (or END key)",
    Callback = function() unloadScript() end
})

local S2 = T1:Section({ Title = "Filters" })

UIRefs.MinD = S2:Slider({ Title = "Min Distance", Value = { Min = 0, Max = 5000, Default = 0 }, Callback = function(v) Cfg.MinD = v end })
UIRefs.MaxD = S2:Slider({ Title = "Max Distance", Value = { Min = 0, Max = 5000, Default = 5000 }, Callback = function(v) Cfg.MaxD = v end })

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

local T2 = Win:Tab({ Title = "Configs", Icon = "save" })
local S5 = T2:Section({ Title = "Config Manager" })

local NameBox = S5:Input({ Title = "Config Name", Value = "default", Placeholder = "Name..." })

S5:Button({
    Title = "Save Config",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        if saveCfgTo(n) then
            Win:Notify({ Title = "Saved", Content = n, Duration = 2 })
        else
            Win:Notify({ Title = "Error", Content = "writefile missing", Duration = 2 })
        end
    end
})

S5:Button({
    Title = "Load Config",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        if loadCfgFrom(n) then
            Win:Notify({ Title = "Loaded", Content = n, Duration = 2 })
        else
            Win:Notify({ Title = "Error", Content = "not found", Duration = 2 })
        end
    end
})

local autoloadStatus = S5:Paragraph({
    Title = "Autoload",
    Desc = "Disabled"
})

local function refreshAutoloadText()
    local n = getAutoloadName()
    if autoloadStatus and autoloadStatus.SetDesc then
        pcall(function()
            autoloadStatus:SetDesc(n and ("Enabled: " .. n) or "Disabled")
        end)
    end
end
refreshAutoloadText()

S5:Button({
    Title = "Set Current as Autoload",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        saveCfgTo(n)
        if setAutoloadName(n) then
            refreshAutoloadText()
            Win:Notify({ Title = "Autoload set", Content = n, Duration = 2 })
        end
    end
})

S5:Button({
    Title = "Clear Autoload",
    Callback = function()
        setAutoloadName("")
        refreshAutoloadText()
        Win:Notify({ Title = "Autoload cleared", Content = "ok", Duration = 2 })
    end
})

S5:Button({
    Title = "FULL UNLOAD (clean everything)",
    Callback = function()
        unloadScript()
    end
})

local autoName = getAutoloadName()
if autoName then
    task.defer(function()
        loadCfgFrom(autoName)
    end)
end
