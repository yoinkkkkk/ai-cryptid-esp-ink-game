--[[
    Ink Game — Cryptid ESP (ONLY Cryptids)
    - Ищет строго по слову "Cryptid" в Workspace.
    - Подсвечивает фиолетовым.
    - Показывает дистанцию.
    - Без GUI.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
while not LP do task.wait(0.1) LP = Players.LocalPlayer end

-- ===== НАСТРОЙКИ =====
local HIGHLIGHT_COLOR = Color3.fromRGB(170, 0, 255) -- Фиолетовый
local TEXT_COLOR = Color3.fromRGB(220, 150, 255)

-- ===== ХРАНИЛИЩА =====
local tracked = {}

-- ===== УТИЛИТЫ =====
local function isCryptid(obj)
    if not obj or (not obj:IsA("Model") and not obj:IsA("BasePart")) then return false end
    -- Ищем строго "Cryptid" (без учета регистра)
    return string.lower(obj.Name):find("cryptid", 1, true) ~= nil
end

local function getRootPart(obj)
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
end

-- ===== СОЗДАНИЕ ESP =====
local function createESP(model)
    if tracked[model] then return end
    local root = getRootPart(model)
    if not root then return end

    -- 1. Highlight (Фиолетовый контур)
    local highlight = Instance.new("Highlight")
    highlight.Name = "CryptidESP_HL"
    highlight.FillColor = HIGHLIGHT_COLOR
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = HIGHLIGHT_COLOR
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model

    -- 2. Billboard (Дистанция)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CryptidESP_BB"
    billboard.Size = UDim2.fromOffset(150, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = root
    billboard.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = TEXT_COLOR
    label.TextStrokeTransparency = 0.5
    label.Text = "..."
    label.Parent = billboard

    tracked[model] = { highlight = highlight, billboard = billboard, label = label, root = root }
end

local function removeESP(model)
    if not tracked[model] then return end
    local data = tracked[model]
    if data.highlight then data.highlight:Destroy() end
    if data.billboard then data.billboard:Destroy() end
    tracked[model] = nil
end

-- ===== СКАНЕР =====
local function scanForCryptids()
    -- Удаляем мёртвых
    for model, data in pairs(tracked) do
        if not model.Parent or not data.root or not data.root.Parent then
            removeESP(model)
        end
    end

    -- Ищем новых
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCryptid(obj) and not tracked[obj] then
            createESP(obj)
        end
    end
end

-- ===== ОБНОВЛЕНИЕ ДИСТАНЦИИ =====
local function updateDistances()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for model, data in pairs(tracked) do
        if data.label and data.root and data.root.Parent then
            local dist = math.floor((hrp.Position - data.root.Position).Magnitude)
            data.label.Text = string.format("%s [%d studs]", model.Name, dist)
        end
    end
end

-- ===== ЦИКЛЫ =====
-- Сканирование каждые 0.5 сек
task.spawn(function()
    while task.wait(0.5) do
        pcall(scanForCryptids)
    end
end)

-- Обновление дистанции каждый кадр
RunService.RenderStepped:Connect(function()
    pcall(updateDistances)
end)

print("[Cryptid ESP] Loaded. Searching for Cryptids ONLY...")