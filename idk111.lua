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
-- Якщо екзекутор дозволяє, поміщаємо в CoreGui для прихованості, інакше в PlayerGui
local successCore = pcall(function() gui.Parent = CoreGui end)
if not successCore then gui.Parent = playerGui end

-- Головне вікно
local container = Instance.new("Frame")
container.Name = "MainFrame"
container.Size = UDim2.new(0, 320, 0, 360)
container.Position = UDim2.new(0.5, -160, 0.5, -180)
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
searchInput.PlaceholderText = "Пошук назви кнопки..."
searchInput.Size = UDim2.new(1, -20, 0, 32)
searchInput.Position = UDim2.new(0, 10, 0, 50)
searchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
searchInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
searchInput.Font = Enum.Font.Gotham
searchInput.TextSize = 13
searchInput.BorderSizePixel = 0
searchInput.Parent = container

-- Лейбл обраної кнопки
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Text = "Обрано: немає"
selectedLabel.Size = UDim2.new(1, -20, 0, 20)
selectedLabel.Position = UDim2.new(0, 10, 0, 85)
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Font = Enum.Font.GothamMedium
selectedLabel.TextSize = 12
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = container

-- Список результатів пошуку (ScrollingFrame)
local resultsList = Instance.new("ScrollingFrame")
resultsList.Size = UDim2.new(1, -20, 0, 130)
resultsList.Position = UDim2.new(0, 10, 0, 110)
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
intervalInput.Position = UDim2.new(0, 10, 0, 250)
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
toggleButton.Position = UDim2.new(0, 10, 0, 295)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 15
toggleButton.BorderSizePixel = 0
toggleButton.Parent = container

-- Логіка вибору та кліку
local targetButton = nil
local isRunning = false

-- Функція емуляції натискання кнопки
local function clickButton(btn)
    if not btn or not btn.Parent then return end
    
    -- Використання спеціальних методів екзекуторів
    if firesignal then
        firesignal(btn.MouseButton1Down)
        firesignal(btn.MouseButton1Click)
        firesignal(btn.MouseButton1Up)
    elseif btn:FindFirstChildOfClass("ClickDetector") then
        fireclickdetector(btn:FindFirstChildOfClass("ClickDetector"))
    else
        -- Запасний варіант (працює якщо скрипт всередині контексту гри)
        pcall(function()
            for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                conn:Fire()
            end
        end)
    end
end

-- Функція оновлення списку знайдених кнопок
local function searchButtons(query)
    -- Очищаємо попередні результати
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
    -- Шукаємо всі кнопки в PlayerGui
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and not obj:IsDescendantOf(gui) then
            local nameMatch = string.find(string.lower(obj.Name), string.lower(query), 1, true)
            local textMatch = false
            if obj:IsA("TextButton") then
                textMatch = string.find(string.lower(obj.Text), string.lower(query), 1, true)
            end

            if nameMatch or textMatch then
                count = count + 1
                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 0, 26)
                itemBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
                itemBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                itemBtn.Font = Enum.Font.Gotham
                itemBtn.TextSize = 11
                itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                itemBtn.BorderSizePixel = 0
                
                local display = obj.Name
                if obj:IsA("TextButton") and obj.Text ~= "" then
                    display = display .. " [Текст: " .. obj.Text .. "]"
                end
                itemBtn.Text = "  " .. display
                itemBtn.Parent = resultsList

                -- Вибір кнопки при кліку зі списку
                itemBtn.MouseButton1Click:Connect(function()
                    targetButton = obj
                    selectedLabel.Text = "Обрано: " .. obj.Name
                    selectedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                end)
            end
        end
    end

    resultsList.CanvasSize = UDim2.new(0, 0, 0, count * 28)
end

-- Подія введення тексту в пошук
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
            selectedLabel.Text = "Помилка: Виберіть кнопку!"
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

        -- Фоновий цикл натискання
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
