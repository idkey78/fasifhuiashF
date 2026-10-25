-- ========================================================
-- Services & Core Setup
-- ========================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Захист від повторного запуску
if playerGui:FindFirstChild("UniversalHubGui") then
    playerGui.UniversalHubGui:Destroy()
end

-- ========================================================
-- Settings & States
-- ========================================================
local FARM_RADIUS = 150
local FLY_SPEED = 75 -- Швидкість плавного польоту ( studs/sec )
local isFarming = false
local noclipEnabled = false
local infJumpEnabled = false
local isBossPhase = false
local isMoving = false

-- ========================================================
-- GUI Creation
-- ========================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalHubGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999

local successCore = pcall(function() screenGui.Parent = CoreGui end)
if not successCore then screenGui.Parent = playerGui end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 460)
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 1.5
frameStroke.Color = Color3.fromRGB(120, 60, 180)
frameStroke.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(34, 34, 40)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topTitle = Instance.new("TextLabel")
topTitle.Size = UDim2.new(1, -50, 1, 0)
topTitle.Position = UDim2.new(0, 12, 0, 0)
topTitle.BackgroundTransparency = 1
topTitle.Text = "Custom Game Hub | Bypass AntiCheat"
topTitle.TextColor3 = Color3.fromRGB(225, 205, 255)
topTitle.TextSize = 13
topTitle.Font = Enum.Font.GothamBold
topTitle.TextXAlignment = Enum.TextXAlignment.Left
topTitle.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.Text = "—"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local scrollContent = Instance.new("ScrollingFrame")
scrollContent.Size = UDim2.new(1, -16, 1, -50)
scrollContent.Position = UDim2.new(0, 8, 0, 44)
scrollContent.BackgroundTransparency = 1
scrollContent.BorderSizePixel = 0
scrollContent.ScrollBarThickness = 3
scrollContent.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollContent

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
end)

-- Перетягування вікна
local isDragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local isMinimized = false
closeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame:TweenSize(UDim2.new(0, 320, 0, 38), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        scrollContent.Visible = false
    else
        mainFrame:TweenSize(UDim2.new(0, 320, 0, 460), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        task.wait(0.15)
        scrollContent.Visible = true
    end
end)

-- ========================================================
-- Конструктори елементів меню
-- ========================================================
local function createCategory(name)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. string.upper(name) .. " —"
    lbl.TextColor3 = Color3.fromRGB(150, 150, 170)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Parent = scrollContent
end

local function createToggle(name, defaultState, callback)
    local state = defaultState or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = state and Color3.fromRGB(46, 180, 87) or Color3.fromRGB(180, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = name .. ": " .. (state and "УВІМК" or "ВИМК")
    btn.BorderSizePixel = 0
    btn.Parent = scrollContent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(46, 180, 87) or Color3.fromRGB(180, 50, 50)
        btn.Text = name .. ": " .. (state and "УВІМК" or "ВИМК")
        task.spawn(callback, state)
    end)
    return btn
end

local function createButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Text = name
    btn.BorderSizePixel = 0
    btn.Parent = scrollContent

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)
    return btn
end

local function createInput(placeholder, defaultVal, callback)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 34)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.PlaceholderText = placeholder
    box.Text = tostring(defaultVal or "")
    box.BorderSizePixel = 0
    box.Parent = scrollContent

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = box

    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
    return box
end

-- ========================================================
-- Система плавного польоту (Байпас Античита)
-- ========================================================
local function flyTo(targetCFrame)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    isMoving = true

    -- Створюємо підтримку гравця у повітрі
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Parent = root

    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / FLY_SPEED
    if duration < 0.2 then duration = 0.2 end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()

    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    isMoving = false
end

-- ========================================================
-- Пошук об'єктів гри
-- ========================================================
local function getBossPlinth()
    local plaza = Workspace:FindFirstChild("PumpkinPlaza", true)
    if plaza then
        local plinth = plaza:FindFirstChild("PlinthTop")
        if plinth and plinth:IsA("BasePart") then
            return plinth
        end
    end
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part.Name == "PlinthTop" and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function getFarmGround()
    local farmPlot = Workspace:FindFirstChild("GraveyardFarmPlot", true)
    if farmPlot then
        local ground = farmPlot:FindFirstChild("FarmGround")
        if ground and ground:IsA("BasePart") then
            return ground
        end
    end
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part.Name == "FarmGround" and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function getPumpkinBoss()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "HalloweenPumpkinBoss" and obj:IsA("Model") then
            local hp = obj:GetAttribute("HP")
            if hp == nil or hp > 0 then
                return obj
            end
        end
    end
    return nil
end

local function clickTarget(model)
    local detector = model:FindFirstChildWhichIsA("ClickDetector", true)
    if typeof(fireclickdetector) == "function" and detector then
        fireclickdetector(detector)
        return true
    end

    local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not targetPart then return false end

    camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
    task.wait(0.04)

    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
    if onScreen then
        VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, game, 0)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, game, 0)
        return true
    end
    return false
end

local function getTreesInRadius()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return {} end

    local myId = tostring(player.UserId)
    local foundTrees = {}

    local beaverProto = Workspace:FindFirstChild("BeaverPrototype")
    local treesFolder = beaverProto and beaverProto:FindFirstChild("Trees")
    local pool = treesFolder and treesFolder:GetChildren() or Workspace:GetDescendants()

    for _, item in ipairs(pool) do
        if item:IsA("Model") and string.find(item.Name, "Halloween") and item.Name ~= "HalloweenPumpkinBoss" then
            local detector = item:FindFirstChildWhichIsA("ClickDetector", true)
            if detector then
                local hp = item:GetAttribute("HP")
                if hp == nil or hp > 0 then
                    local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local distance = (part.Position - root.Position).Magnitude
                        if distance <= FARM_RADIUS then
                            local owner = tostring(item:GetAttribute("ForestOwner") or "")
                            local isMine = (owner == myId) or string.find(item.Name, myId) ~= nil

                            table.insert(foundTrees, {
                                model = item,
                                dist = distance,
                                mine = isMine
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(foundTrees, function(a, b)
        if a.mine ~= b.mine then return a.mine end
        return a.dist < b.dist
    end)

    local result = {}
    for _, entry in ipairs(foundTrees) do
        table.insert(result, entry.model)
    end
    return result
end

-- ========================================================
-- Основний цикл: Автофарм + Політ до Боса
-- ========================================================
local function startFarmingLoop()
    while isFarming do
        local boss = getPumpkinBoss()

        -- 1. Спавн Боса
        if boss and boss:IsDescendantOf(Workspace) then
            isBossPhase = true
            
            local plinth = getBossPlinth()
            if plinth then
                -- Летимо трохи вище п'єдесталу (+4 studs), щоб стати на нього
                flyTo(plinth.CFrame + Vector3.new(0, 4, 0))
            end
            task.wait(0.2)

            -- Клікаємо по босу, доки він існує
            while isFarming and boss:IsDescendantOf(Workspace) do
                local hp = boss:GetAttribute("HP")
                if hp and hp <= 0 then break end

                clickTarget(boss)
                task.wait(0.25)
            end

            -- Боса знищено -> летимо назад на FarmGround
            local ground = getFarmGround()
            if ground then
                flyTo(ground.CFrame + Vector3.new(0, 3.5, 0))
            end
            task.wait(0.5)

            isBossPhase = false
        end

        -- 2. Звичайний фарм дерев
        if not isBossPhase and not isMoving then
            local trees = getTreesInRadius()
            if #trees > 0 then
                local targetTree = trees[1]
                local startHp = targetTree:GetAttribute("HP") or 0
                local attempts = 0

                while isFarming and targetTree:IsDescendantOf(Workspace) do
                    if getPumpkinBoss() then break end

                    local currentHp = targetTree:GetAttribute("HP")
                    if not currentHp or currentHp <= 0 or (startHp > 0 and currentHp < startHp) then
                        break
                    end
                    clickTarget(targetTree)
                    attempts = attempts + 1
                    if attempts > 15 then break end
                    task.wait(0.25)
                end

                while isFarming and targetTree:IsDescendantOf(Workspace) do
                    if getPumpkinBoss() then break end
                    local currentHp = targetTree:GetAttribute("HP")
                    if not currentHp or currentHp <= 0 then break end
                    task.wait(0.25)
                end
            end
        end

        task.wait(0.5)
    end
end

-- ========================================================
-- Наповнення меню
-- ========================================================
createCategory("Halloween Event")

createToggle("Авто-фарм + Авто-Бос (Fly)", false, function(state)
    isFarming = state
    if isFarming then
        startFarmingLoop()
    end
end)

createInput("Швидкість польоту (FlySpeed)", FLY_SPEED, function(val)
    local num = tonumber(val)
    if num and num > 10 then
        FLY_SPEED = num
    end
end)

createButton("Полетіти до Боса (PlinthTop)", function()
    local plinth = getBossPlinth()
    if plinth then
        flyTo(plinth.CFrame + Vector3.new(0, 4, 0))
    end
end)

createButton("Полетіти на базу (FarmGround)", function()
    local ground = getFarmGround()
    if ground then
        flyTo(ground.CFrame + Vector3.new(0, 3.5, 0))
    end
end)

createCategory("Персонаж")

createInput("Швидкість (WalkSpeed)", "16", function(val)
    local num = tonumber(val)
    if num and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = num
    end
end)

createInput("Стрибок (JumpPower)", "50", function(val)
    local num = tonumber(val)
    if num and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.UseJumpPower = true
        player.Character.Humanoid.JumpPower = num
    end
end)

createToggle("Noclip (Крізь стіни)", false, function(state)
    noclipEnabled = state
end)

createToggle("Infinite Jump (Стрибки)", false, function(state)
    infJumpEnabled = state
end)

-- Noclip: активний при ввімкненому перемикачі АБО під час польоту
RunService.Stepped:Connect(function()
    if (noclipEnabled or isMoving) and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
