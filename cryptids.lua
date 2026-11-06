local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer

local Cfg = {
    ESP = false, Chams = false, Tracers = false, Boxes = false, Names = false, Dist = false,
    MinD = 0, MaxD = 5000,
    ColChams = Color3.fromRGB(170, 0, 255), 
    ColChamsOutline = Color3.fromRGB(255, 255, 255),
    ChamsOutlineTransparency = 0,
    ColTracer = Color3.fromRGB(170, 0, 255),
    ColBox = Color3.fromRGB(170, 0, 255), ColText = Color3.fromRGB(220, 150, 255),
    ThickTracer = 1, ThickBox = 1, SizeText = 14, BoxScale = 1,
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
    hl.OutlineColor = Cfg.ColChamsOutline
    hl.OutlineTransparency = Cfg.ChamsOutlineTransparency
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

    if not Cfg.ESP and not Cfg.Chams and not Cfg.Tracers then
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
    local vp = Camera.ViewportSize
    local oX = vp.X / 2
    local oY = vp.Y / 2

    for obj, d in pairs(Objs) do
        local root = d.root
        if not root or not root.Parent or not obj.Parent then
            cleanup(obj)
            continue
        end

        if Cfg.ESP or Cfg.Chams then
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
            local oc = Cfg.RbwChams and rbw or Cfg.ColChamsOutline
            d.hl.FillColor = cc
            d.hl.OutlineColor = oc
            d.hl.OutlineTransparency = Cfg.ChamsOutlineTransparency
        else
            d.hl.Enabled = false
        end

        if Cfg.ESP and inRange then
            local tStr = ""
            if Cfg.Names then tStr = obj.Name end
            if Cfg.Dist then
                if tStr ~= "" then tStr = tStr .. " " end
                tStr = tStr .. "[" .. dist .. "m]"
            end
            if tStr ~= "" then
                d.bb.Enabled = true
                d.txt.Text = tStr
                d.txt.TextColor3 = Cfg.RbwText and rbw or Cfg.ColText
                d.txt.TextSize = Cfg.SizeText
            else
                d.bb.Enabled = false
            end

            if Cfg.Boxes and onScr and sp.Z > 0 then
                local baseH = (vp.Y / dist) * 3
                local h = baseH * Cfg.BoxScale
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
            d.bb.Enabled = false
            d.bx.Visible = false
        end

        if Cfg.Tracers then
            local dx = sp.X - oX
            local dy = sp.Y - oY
            local bh = (sp.Z < 0)
            
            if bh then 
                dx = -dx 
                dy = -dy 
            end
            
            local tx, ty
            
            if onScr and not bh then
                tx = sp.X
                ty = sp.Y
            else
                local rl = math.sqrt(dx*dx + dy*dy)
                local ux, uy
                
                if rl < 0.01 then 
                    ux, uy = 0, 1 
                else 
                    ux = dx / rl 
                    uy = dy / rl 
                end
                
                local tL = math.huge
                if ux > 0 then tL = math.min(tL, (vp.X - oX) / ux)
                elseif ux < 0 then tL = math.min(tL, -oX / ux) end
                
                if uy > 0 then tL = math.min(tL, (vp.Y - oY) / uy)
                elseif uy < 0 then tL = math.min(tL, -oY / uy) end
                
                if tL == math.huge or tL < 1 then tL = 1 end
                
                tx = oX + ux * tL
                ty = oY + uy * tL
            end
            
            if tx ~= tx then tx = oX end
            if ty ~= ty then ty = oY + 100 end
            
            tx = math.clamp(tx, 0, vp.X)
            ty = math.clamp(ty, 0, vp.Y)
            
            d.tr.From = Vector2.new(oX, oY)
            d.tr.To = Vector2.new(tx, ty)
            d.tr.Color = Cfg.RbwTracers and rbw or Cfg.ColTracer
            d.tr.Thickness = math.max(1, Cfg.ThickTracer)
            d.tr.Visible = true
        else
            d.tr.Visible = false
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
        pcall(function() getgenv().CryptidWin = nil end)
    end
end

getgenv().CryptidESP_Unload = unloadScript

local Win = WindUI:CreateWindow({
    Title = "cryptids esp inkk",
    Icon = "eye",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 520),
    ToggleKey = Enum.KeyCode.RightShift,
    OpenButton = {
        Title = "cryptids esp inkk",
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

if getgenv then
    getgenv().CryptidWin = Win
end

local function toggleWindow()
    pcall(function()
        if Win.Toggle then
            Win:Toggle()
        elseif Win.Main and Win.Main.Visible then
            Win:Close()
        else
            Win:Open()
        end
    end)
end

UIS.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not gp or (UIS:GetFocusedTextBox() == nil) then
            toggleWindow()
        end
    end
end)

local CONFIG_DIR = "CryptidCfg/"
local AUTOLOAD_FILE = CONFIG_DIR .. "_autoload.txt"

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
    local ok = pcall(writefile, CONFIG_DIR .. name .. ".json", HttpService:JSONEncode(d))
    return ok
end

local function loadCfgFrom(name)
    if not isfile or not readfile then return false end
    local p = CONFIG_DIR .. name .. ".json"
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

local function getConfigList()
    local list = {}
    if not listfiles or not isfolder then return list end
    ensureDir()
    local ok, files = pcall(listfiles, "CryptidCfg")
    if ok and type(files) == "table" then
        for _, f in ipairs(files) do
            local n = string.match(f, "([^/\\]+)%.json$")
            if n then table.insert(list, n) end
        end
    end
    table.sort(list)
    return list
end

local T1 = Win:Tab({ Title = "Visuals", Icon = "eye" })
local S1 = T1:Section({ Title = "ESP Options" })

UIRefs.ESP = S1:Toggle({ Title = "Enable Master ESP (Text/Boxes)", Value = false, Callback = function(v) Cfg.ESP = v end })
UIRefs.Chams = S1:Toggle({ Title = "Enable Chams (Highlight)", Value = false, Callback = function(v) Cfg.Chams = v end })
UIRefs.Tracers = S1:Toggle({ Title = "Enable Tracers (Lines)", Value = false, Callback = function(v) Cfg.Tracers = v end })
UIRefs.Boxes = S1:Toggle({ Title = "Show 2D Boxes", Value = false, Callback = function(v) Cfg.Boxes = v end })
UIRefs.Names = S1:Toggle({ Title = "Show Name", Value = false, Callback = function(v) Cfg.Names = v end })
UIRefs.Dist = S1:Toggle({ Title = "Show Distance", Value = false, Callback = function(v) Cfg.Dist = v end })

local S2 = T1:Section({ Title = "Distance Filters" })

UIRefs.MinD = S2:Slider({ Title = "Min Distance (Studs)", Value = { Min = 0, Max = 5000, Default = 0 }, Callback = function(v) Cfg.MinD = v end })
UIRefs.MaxD = S2:Slider({ Title = "Max Distance (Studs)", Value = { Min = 0, Max = 5000, Default = 5000 }, Callback = function(v) Cfg.MaxD = v end })

local S3 = T1:Section({ Title = "Colors & Sizes" })

UIRefs.ColChams = S3:Colorpicker({ Title = "Chams Fill Color", Default = Cfg.ColChams, Callback = function(c) Cfg.ColChams = c end })
UIRefs.ColChamsOutline = S3:Colorpicker({ Title = "Chams Outline Color", Default = Cfg.ColChamsOutline, Callback = function(c) Cfg.ColChamsOutline = c end })
UIRefs.ChamsOutlineTransparency = S3:Slider({ Title = "Chams Outline Transparency", Value = { Min = 0, Max = 1, Default = 0 }, Callback = function(v) Cfg.ChamsOutlineTransparency = v end })

UIRefs.ColTracer = S3:Colorpicker({ Title = "Tracer Color", Default = Cfg.ColTracer, Callback = function(c) Cfg.ColTracer = c end })
UIRefs.ColBox = S3:Colorpicker({ Title = "Box Color", Default = Cfg.ColBox, Callback = function(c) Cfg.ColBox = c end })
UIRefs.ColText = S3:Colorpicker({ Title = "Text Color", Default = Cfg.ColText, Callback = function(c) Cfg.ColText = c end })

UIRefs.ThickTracer = S3:Slider({ Title = "Tracer Thickness", Value = { Min = 1, Max = 10, Default = 1 }, Callback = function(v) Cfg.ThickTracer = v end })
UIRefs.ThickBox = S3:Slider({ Title = "Box Thickness", Value = { Min = 1, Max = 10, Default = 1 }, Callback = function(v) Cfg.ThickBox = v end })
UIRefs.SizeText = S3:Slider({ Title = "Text Size", Value = { Min = 1, Max = 50, Default = 14 }, Callback = function(v) Cfg.SizeText = v end })
UIRefs.BoxScale = S3:Slider({ Title = "Box Scale", Value = { Min = 0.1, Max = 5, Default = 1 }, Callback = function(v) Cfg.BoxScale = v end })

local S4 = T1:Section({ Title = "Rainbow Effects" })

UIRefs.RbwChams = S4:Toggle({ Title = "Rainbow Chams", Value = false, Callback = function(v) Cfg.RbwChams = v end })
UIRefs.RbwTracers = S4:Toggle({ Title = "Rainbow Tracers", Value = false, Callback = function(v) Cfg.RbwTracers = v end })
UIRefs.RbwBoxes = S4:Toggle({ Title = "Rainbow Boxes", Value = false, Callback = function(v) Cfg.RbwBoxes = v end })
UIRefs.RbwText = S4:Toggle({ Title = "Rainbow Text", Value = false, Callback = function(v) Cfg.RbwText = v end })

-- Вкладка Configs
local T2 = Win:Tab({ Title = "Configs", Icon = "save" })
local S5 = T2:Section({ Title = "Config Manager" })

local NameBox = S5:Input({ Title = "Config Name", Value = "default", Placeholder = "Enter name..." })

S5:Button({
    Title = "Save Config",
    Callback = function()
        local n = NameBox.Value
        if n == "" then n = "default" end
        if saveCfgTo(n) then
            Win:Notify({ Title = "Saved", Content = n, Duration = 2 })
            if UIRefs.Dropdown then
                UIRefs.Dropdown:Refresh(getConfigList(), true)
            end
        else
            Win:Notify({ Title = "Error", Content = "writefile missing", Duration = 2 })
        end
    end
})

local currentList = getConfigList()
if #currentList == 0 then currentList = {"None"} end

UIRefs.Dropdown = S5:Dropdown({
    Title = "Select Config",
    Values = currentList,
    Default = 1,
    Callback = function(selected)
        UIRefs.SelectedConfig = selected
    end
})

S5:Button({
    Title = "Refresh Config List",
    Callback = function()
        local list = getConfigList()
        if #list == 0 then list = {"None"} end
        UIRefs.Dropdown:Refresh(list, true)
        Win:Notify({ Title = "Configs", Content = "List refreshed", Duration = 2 })
    end
})

S5:Button({
    Title = "Load Selected Config",
    Callback = function()
        local sel = UIRefs.SelectedConfig or (currentList[1] ~= "None" and currentList[1])
        if not sel or sel == "None" then
            Win:Notify({ Title = "Error", Content = "No config selected", Duration = 2 })
            return
        end
        if loadCfgFrom(sel) then
            Win:Notify({ Title = "Loaded", Content = sel, Duration = 2 })
        else
            Win:Notify({ Title = "Error", Content = "Failed to load", Duration = 2 })
        end
    end
})

S5:Button({
    Title = "Delete Selected Config",
    Callback = function()
        local sel = UIRefs.SelectedConfig or (currentList[1] ~= "None" and currentList[1])
        if not sel or sel == "None" then return end
        if delfile then
            pcall(delfile, CONFIG_DIR .. sel .. ".json")
            Win:Notify({ Title = "Deleted", Content = sel, Duration = 2 })
            local list = getConfigList()
            if #list == 0 then list = {"None"} end
            UIRefs.Dropdown:Refresh(list, true)
        end
    end
})

local S6 = T2:Section({ Title = "Autoload" })

local autoloadStatus = S6:Paragraph({
    Title = "Status",
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

S6:Button({
    Title = "Set Selected as Autoload",
    Callback = function()
        local sel = UIRefs.SelectedConfig or (currentList[1] ~= "None" and currentList[1])
        if not sel or sel == "None" then return end
        if setAutoloadName(sel) then
            refreshAutoloadText()
            Win:Notify({ Title = "Autoload set", Content = sel, Duration = 2 })
        end
    end
})

S6:Button({
    Title = "Clear Autoload",
    Callback = function()
        setAutoloadName("")
        refreshAutoloadText()
        Win:Notify({ Title = "Autoload cleared", Content = "ok", Duration = 2 })
    end
})

S6:Button({
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
