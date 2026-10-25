-- Сервіси
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Захист від повторного запуску
if playerGui:FindFirstChild("AutoClickerGUI") then
    playerGui.AutoClickerGUI:Destroy()
end

-- Основний екран GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoClickerGUI"
local successCore = pcall(function() gui.Parent = CoreGui end)
if not successCore then gui.Parent = playerGui end

-- Головне вікно
local container = Instance.new("Frame")
container.Name = "MainFrame"
container.Size = UDim2.new(0, 340, 0, 390)
container.Position = UDim2.new(0.5, -170, 0.5, -195)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
container.BorderSizePixel = 0
container.Active = true
container.ClipsDescendants = true
container.Parent = gui

-- Закруглення кутів
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

-- Заголовок
local title = Instance.new("TextLabel")
title.Text = "UI Auto Clicker"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = container

-- Плавне перетягування вікна (Drag)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Поле пошуку кнопки
local searchInput = Instance.new("TextBox")
searchInput.PlaceholderText = "Пошук назви або парента..."
searchInput.Size = UDim2.new(1, -20, 0, 32)
searchInput.Position = UDim2.new(0, 10, 0, 50)
searchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
searchInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
searchInput.Font = Enum.Font.Gotham
searchInput.TextSize = 13
searchInput.BorderSizePixel = 0
searchInput.Parent = container

-- Лейбл обраної кнопки (з інформацією про Parent)
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Text = "Обрано: немає\nParent: немає"
selectedLabel.Size = UDim2.new(1, -20, 0, 35)
selectedLabel.Position = UDim2.new(0, 10, 0, 85)
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Font = Enum.Font.GothamMedium
selectedLabel.TextSize = 11
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.TextYAlignment = Enum.TextYAlignment.Top
selectedLabel.Parent = container

-- Список результатів пошуку (ScrollingFrame)
local resultsList = Instance.new("ScrollingFrame")
resultsList.Size = UDim2.new(1, -20, 0, 135)
resultsList.Position = UDim2.new(0, 10, 0, 125)
resultsList.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
resultsList.BorderSizePixel = 0
resultsList.ScrollBarThickness = 4
resultsList.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = resultsList
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)

-- Поле введення інтервалу / затримки (Cooldown)
local intervalInput = Instance.new("TextBox")
intervalInput.PlaceholderText = "Затримка в сек (напр: 0.1)"
intervalInput.Text = "0.5"
intervalInput.Size = UDim2.new(1, -20, 0, 32)
intervalInput.Position = UDim2.new(0, 10, 0, 270)
intervalInput.TextColor3 = Color3.fromRGB(255, 255, 255)
intervalInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
intervalInput.Font = Enum.Font.Gotham
intervalInput.TextSize = 13
intervalInput.BorderSizePixel = 0
intervalInput.Parent = container

-- Кнопка старт/стоп
local toggleButton = Instance.new("TextButton")
toggleButton.Text = "Увімкнути"
toggleButton.Size = UDim2.new(1, -20, 0, 36)
toggleButton.Position = UDim2.new(0, 10, 0, 312)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 15
toggleButton.BorderSizePixel = 0
toggleButton.Parent = container

-- Логіка кліку
local targetButton = nil
local isRunning = false

local function clickButton(btn)
    if not btn or not btn.Parent then return end
    
    if firesignal then
        firesignal(btn.MouseButton1Down)
        firesignal(btn.MouseButton1Click)
        firesignal(btn.MouseButton1Up)
    elseif btn:FindFirstChildOfClass("ClickDetector") then
        fireclickdetector(btn:FindFirstChildOfClass("ClickDetector"))
    else
        pcall(function()
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
        end)
    end
end

-- Функція пошуку
local function searchButtons(query)
    for _, child in ipairs(resultsList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if query == "" then 
        resultsList.CanvasSize = UDim2.new(0, 0, 0, 0)
        return 
    end

    local count = 0
    local qLower = string.lower(query)

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and not obj:IsDescendantOf(gui) then
            local parentName = obj.Parent and obj.Parent.Name or "None"
            local nameMatch = string.find(string.lower(obj.Name), qLower, 1, true)
            local parentMatch = string.find(string.lower(parentName), qLower, 1, true)
            local textMatch = false
            if obj:IsA("TextButton") then
                textMatch = string.find(string.lower(obj.Text), qLower, 1, true)
            end

            if nameMatch or textMatch or parentMatch then
                count = count + 1
                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 0, 30)
                itemBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
                itemBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.TextSize = 11
                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                itemBtn.BorderSizePixel = 0
                
                -- Формуємо інформативний напис: назва, текст та його parent
                local display = obj.Name
                if obj:IsA("TextButton") and obj.Text ~= "" then
                    display = display .. " [" .. obj.Text .. "]"
                end
                itemBtn.Text = "  " .. display .. " | Parent: " .. parentName
                itemBtn.Parent = resultsList

                -- Вибір при кліку зі списку
                itemBtn.MouseButton1Click:Connect(function()
                    targetButton = obj
                    local fullParent = obj.Parent and obj.Parent:GetFullName() or "Немає"
                    selectedLabel.Text = "Обрано: " .. obj.Name .. "\nParent: " .. fullParent
                    selectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                end)
            end
        end
    end

    resultsList.CanvasSize = UDim2.new(0, 0, 0, count * 32)
end

-- Реакція на введення тексту в пошук
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
    searchButtons(searchInput.Text)
end)

-- Перемикач автокліку
toggleButton.MouseButton1Click:Connect(function()
    if isRunning then
        isRunning = false
        toggleButton.Text = "Увімкнути"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
    else
        if not targetButton or not targetButton.Parent then
            selectedLabel.Text = "Помилка: Виберіть кнопку зі списку!"
            selectedLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end

        local cd = tonumber(intervalInput.Text)
        if not cd or cd < 0.01 then
            cd = 0.1
            intervalInput.Text = "0.1"
        end

        isRunning = true
        toggleButton.Text = "Зупинити"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

        task.spawn(function()
            while isRunning do
                if targetButton and targetButton.Parent then
                    clickButton(targetButton)
                else
                    isRunning = false
                    toggleButton.Text = "Увімкнути"
                    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
                    selectedLabel.Text = "Кнопка зникла з гри!"
                    selectedLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                    break
                end
                task.wait(cd)
            end
        end)
    end
end)
