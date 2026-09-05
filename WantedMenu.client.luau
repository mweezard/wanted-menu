-- WANTED / TEST PANEL
-- Установка: StarterPlayer > StarterPlayerScripts > LocalScript.
-- Самостоятельное меню для своего плейса / разрешённой тестовой копии.
-- Специфичные для Wanted игровые функции подключаются отдельно.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("WantedTestMenu")
if old then old:Destroy() end

local colors = {
    background = Color3.fromRGB(15, 18, 25),
    panel = Color3.fromRGB(24, 29, 39),
    muted = Color3.fromRGB(150, 162, 180),
    text = Color3.fromRGB(239, 244, 252),
    accent = Color3.fromRGB(100, 222, 185),
}
local connections = {}
local animations = true
local notifications = true
local accentObjects = {}
local stopFlight = function() end
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function create(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, object)
end
local function accent(object, property)
    table.insert(accentObjects, {object, property})
    object[property] = colors.accent
end
local function animate(object, properties)
    if animations then
        TweenService:Create(object, TweenInfo.new(0.18, Enum.EasingStyle.Quad), properties):Play()
    else
        for key, value in pairs(properties) do object[key] = value end
    end
end
local function label(parent, text, position, size, fontSize, color)
    return create("TextLabel", {
        BackgroundTransparency = 1, Position = position, Size = size,
        Text = text, TextColor3 = color or colors.text, TextSize = fontSize or 14,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, parent)
end
local function button(parent, text, position, size)
    local object = create("TextButton", {
        Position = position, Size = size, BackgroundColor3 = colors.panel,
        Text = text, TextColor3 = colors.text, TextSize = 13,
        Font = Enum.Font.GothamBold, AutoButtonColor = false,
    }, parent)
    round(object, 10)
    connect(object.MouseEnter, function() animate(object, {BackgroundColor3 = Color3.fromRGB(39, 48, 61)}) end)
    connect(object.MouseLeave, function() animate(object, {BackgroundColor3 = colors.panel}) end)
    return object
end

local gui = create("ScreenGui", {
    Name = "WantedTestMenu", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 20,
}, playerGui)
gui.Destroying:Connect(function()
    stopFlight()
    for _, connection in ipairs(connections) do connection:Disconnect() end
end)
local root = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, gui)
local window = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(700, 450), BackgroundColor3 = colors.background,
    ClipsDescendants = true,
}, root)
round(window, 18)
create("UIStroke", {Color = Color3.fromRGB(57, 68, 85), Thickness = 1}, window)
local scale = create("UIScale", {Scale = 1}, window)
local function resize()
    local available = root.AbsoluteSize
    scale.Scale = math.min(1, math.max(0.1, (available.X - 24) / 700), math.max(0.1, (available.Y - 24) / 450))
    window.Position = UDim2.fromScale(0.5, 0.5)
end
connect(root:GetPropertyChangedSignal("AbsoluteSize"), resize)
task.defer(resize)

local dragBar = create("Frame", {
    Size = UDim2.new(1, -65, 0, 76), BackgroundTransparency = 1, Active = true,
}, window)
local title = label(dragBar, "WANTED", UDim2.fromOffset(24, 14), UDim2.fromOffset(170, 30), 25)
title.Font = Enum.Font.GothamBlack
accent(title, "TextColor3")
label(dragBar, "TEST PANEL  /  v1.2", UDim2.fromOffset(25, 47), UDim2.fromOffset(230, 18), 10, colors.muted)
local close = button(window, "×", UDim2.new(1, -52, 0, 20), UDim2.fromOffset(32, 32))
close.TextSize = 24
local divider = create("Frame", {
    Position = UDim2.fromOffset(20, 78), Size = UDim2.new(1, -40, 0, 1),
    BackgroundColor3 = Color3.fromRGB(42, 49, 62), BorderSizePixel = 0,
}, window)
local sidebar = create("Frame", {Position = UDim2.fromOffset(20, 96), Size = UDim2.fromOffset(150, 280), BackgroundTransparency = 1}, window)
create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = create("Frame", {Position = UDim2.fromOffset(190, 96), Size = UDim2.fromOffset(490, 305), BackgroundTransparency = 1}, window)
label(window, "LOCAL SESSION  •  " .. player.DisplayName, UDim2.fromOffset(24, 413), UDim2.fromOffset(470, 20), 11, colors.muted)
label(window, "Right Shift — меню", UDim2.fromOffset(522, 413), UDim2.fromOffset(158, 20), 11, colors.muted)

local reopen = button(root, "W", UDim2.new(0, 16, 0.5, -22), UDim2.fromOffset(44, 44))
accent(reopen, "TextColor3")
reopen.Visible = false
local function setVisible(visible)
    window.Visible = visible
    reopen.Visible = not visible
end
connect(close.Activated, function() setVisible(false) end)
connect(reopen.Activated, function() setVisible(true) end)
connect(UserInputService.InputBegan, function(input, processed)
    if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.RightShift then
        setVisible(not window.Visible)
    end
end)

local dragInput, dragStart, startPosition
connect(dragBar.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput, dragStart, startPosition = input, input.Position, window.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if not dragInput then return end
    if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if dragInput.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end
    local delta = input.Position - dragStart
    local bounds = root.AbsoluteSize
    local half = window.AbsoluteSize / 2
    local x = startPosition.X.Scale * bounds.X + startPosition.X.Offset + delta.X
    local y = startPosition.Y.Scale * bounds.Y + startPosition.Y.Offset + delta.Y
    window.Position = UDim2.fromOffset(math.clamp(x, half.X, math.max(half.X, bounds.X - half.X)), math.clamp(y, half.Y, math.max(half.Y, bounds.Y - half.Y)))
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragInput then dragInput = nil end
end)

local toast = create("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18),
    Size = UDim2.new(0.85, 0, 0, 54), BackgroundColor3 = colors.panel,
    TextColor3 = colors.text, Font = Enum.Font.GothamMedium, TextSize = 13,
    TextWrapped = true, Visible = false, ZIndex = 10,
}, root)
create("UISizeConstraint", {MaxSize = Vector2.new(420, 54)}, toast)
round(toast)
local toastVersion = 0
local function notify(message)
    if not notifications then return end
    toastVersion += 1
    local version = toastVersion
    toast.Text, toast.Visible = message, true
    task.delay(3, function()
        if gui.Parent and version == toastVersion then toast.Visible = false end
    end)
end

local pages, tabs = {}, {}
local function selectTab(name)
    for key, page in pairs(pages) do
        page.Visible = key == name
        tabs[key].TextColor3 = key == name and colors.accent or colors.muted
    end
end
local function page(name, index)
    local body = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = colors.muted,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
    }, content)
    create("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    local tab = button(sidebar, name, UDim2.new(), UDim2.new(1, 0, 0, 44))
    tab.LayoutOrder = index
    pages[name], tabs[name] = body, tab
    connect(tab.Activated, function() selectTab(name) end)
    return body
end
local function card(parent, heading, description, index)
    local frame = create("Frame", {Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = colors.panel, LayoutOrder = index}, parent)
    round(frame)
    label(frame, heading, UDim2.fromOffset(16, 10), UDim2.new(1, -165, 0, 25), 14)
    label(frame, description, UDim2.fromOffset(16, 37), UDim2.new(1, -165, 0, 38), 11, colors.muted)
    return frame
end
local function action(parent, heading, description, caption, index, callback)
    local frame = card(parent, heading, description, index)
    local control = button(frame, caption, UDim2.new(1, -126, 0.5, -18), UDim2.fromOffset(110, 36))
    accent(control, "TextColor3")
    connect(control.Activated, function()
        local ok, err = pcall(callback)
        if not ok then warn("WantedMenu: " .. tostring(err)); notify("Ошибка функции. Смотри Output.") end
    end)
end
local function toggle(parent, heading, description, initial, index, callback)
    local frame = card(parent, heading, description, index)
    local enabled = initial
    local control = button(frame, "", UDim2.new(1, -104, 0.5, -18), UDim2.fromOffset(88, 36))
    local function render()
        control.Text = enabled and "ON  ●" or "OFF  ○"
        control.TextColor3 = enabled and colors.accent or colors.muted
    end
    connect(control.Activated, function() enabled = not enabled; render(); callback(enabled) end)
    -- Обновление цвета включённых переключателей при смене темы.
    table.insert(accentObjects, {control, "toggle", render})
    render()
end

local home = page("01   Главная", 1)
local settings = page("02   Настройки", 2)
action(home, "Панель готова", "Интерфейс для тестирования своего плейса.", "Проверить", 3, function() notify("Всё работает. Добро пожаловать, " .. player.DisplayName .. "!") end)
local stats = card(home, "Производительность", "FPS: измерение…", 2)
local statsLabel = stats:GetChildren()
local fpsLabel
for _, object in ipairs(statsLabel) do
    if object:IsA("TextLabel") and string.find(object.Text, "FPS", 1, true) then fpsLabel = object end
end
label(stats, "LIVE", UDim2.new(1, -75, 0, 30), UDim2.fromOffset(60, 24), 13, colors.accent)
action(home, "Текущая сессия", "Показать идентификатор плейса.", "Показать", 4, function() notify("PlaceId: " .. tostring(game.PlaceId)) end)

-- Полёт для тестовой сессии. Сервер плейса может ограничивать перемещение.
local flight = nil
local flightSpeed = 60
local flightSpeeds = {30, 60, 90, 120}
local speedIndex = 2
local focused = true
local flightKeys = {}
local acceptedKeys = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
}
local flightCard = card(home, "полет", "W/S — по направлению камеры\nA/D — в стороны. Смотри вверх, чтобы набрать высоту.", 1)
local flightButton = button(flightCard, "OFF  ○", UDim2.new(1, -104, 0.5, -18), UDim2.fromOffset(88, 36))
local function renderFlight()
    flightButton.Text = flight and "ON  ●" or "OFF  ○"
    flightButton.TextColor3 = flight and colors.accent or colors.muted
end
table.insert(accentObjects, {flightButton, "toggle", renderFlight})

stopFlight = function()
    local previous = flight
    flight = nil
    table.clear(flightKeys)
    if previous then
        if previous.died then previous.died:Disconnect() end
        for _, object in ipairs(previous.objects) do object:Destroy() end
        local humanoid = previous.humanoid
        if humanoid.Parent then
            humanoid.AutoRotate = previous.autoRotate
            humanoid.PlatformStand = previous.platformStand
            if humanoid.Health > 0 and not previous.platformStand then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        if previous.root.Parent then
            previous.root.AssemblyLinearVelocity = Vector3.zero
            previous.root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    renderFlight()
end

local function startFlight()
    if flight then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local characterRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not characterRoot or humanoid.Health <= 0 then
        notify("Дождись появления персонажа.")
        return
    end
    if humanoid.Sit or humanoid.PlatformStand or characterRoot.Anchored then
        notify("Для полёта выйди из транспорта и встань на ноги.")
        return
    end
    flight = {
        humanoid = humanoid, root = characterRoot, character = character,
        autoRotate = humanoid.AutoRotate, platformStand = humanoid.PlatformStand,
        objects = {},
    }
    local session = flight
    -- Регистрируем объекты сразу, чтобы убрать их даже при ошибке настройки.
    local function flightObject(class)
        local object = Instance.new(class)
        table.insert(session.objects, object)
        object.Name = "WantedFlight" .. class
        return object
    end
    local ok, err = pcall(function()
        local attachment = flightObject("Attachment")
        attachment.Parent = characterRoot
        local velocity = flightObject("LinearVelocity")
        velocity.Attachment0 = attachment
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        velocity.ForceLimitsEnabled = false
        velocity.VectorVelocity = Vector3.zero
        velocity.Parent = characterRoot
        local orientation = flightObject("AlignOrientation")
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Attachment0 = attachment
        orientation.MaxTorque = 1000000
        orientation.MaxAngularVelocity = 20
        orientation.Responsiveness = 25
        orientation.CFrame = characterRoot.CFrame.Rotation
        orientation.Parent = characterRoot
        session.velocity, session.orientation = velocity, orientation
        humanoid.AutoRotate = false
        humanoid.PlatformStand = true
        session.died = humanoid.Died:Connect(stopFlight)
    end)
    if not ok then
        stopFlight()
        warn("Wanted flight: " .. tostring(err))
        notify("Не удалось включить полёт. Смотри Output.")
        return
    end
    if focused and not UserInputService:GetFocusedTextBox() then
        for key in pairs(acceptedKeys) do
            if UserInputService:IsKeyDown(key) then flightKeys[key] = true end
        end
    end
    renderFlight()
    notify("полет включён. Управляй WASD и направлением камеры.")
end
local function toggleFlight()
    if flight then stopFlight() else startFlight() end
end
connect(flightButton.Activated, toggleFlight)
connect(player.CharacterRemoving, stopFlight)
connect(player.CharacterAdded, stopFlight)
connect(UserInputService.InputBegan, function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if flight and acceptedKeys[input.KeyCode] then flightKeys[input.KeyCode] = true end
end)
local function resetFlightInput()
    table.clear(flightKeys)
end
connect(UserInputService.InputEnded, function(input)
    flightKeys[input.KeyCode] = nil
end)
connect(UserInputService.TextBoxFocused, resetFlightInput)
connect(UserInputService.WindowFocusReleased, function() focused = false; resetFlightInput() end)
connect(UserInputService.WindowFocused, function() focused = true end)
local function held(key) return flightKeys[key] and 1 or 0 end
connect(RunService.PreSimulation, function()
    local session = flight
    if not session then return end
    if player.Character ~= session.character or not session.root:IsDescendantOf(workspace)
        or session.humanoid.Health <= 0 or session.humanoid.Sit or session.root.Anchored
        or not session.velocity.Parent or not session.orientation.Parent then
        stopFlight()
        return
    end
    local camera = workspace.CurrentCamera
    if not camera or not focused or UserInputService:GetFocusedTextBox() then
        session.velocity.VectorVelocity = Vector3.zero
        return
    end
    local look = camera.CFrame.LookVector
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < 0.01 then
        local right = camera.CFrame.RightVector
        forward = Vector3.new(right.Z, 0, -right.X)
    end
    forward = forward.Unit
    -- Полное направление камеры позволяет набирать/снижать высоту через W/S.
    -- forward выше используется только для вертикального положения персонажа.
    local direction = camera.CFrame.RightVector * (held(Enum.KeyCode.D) - held(Enum.KeyCode.A))
        + look * (held(Enum.KeyCode.W) - held(Enum.KeyCode.S))
    if direction.Magnitude > 1 then direction = direction.Unit end
    session.velocity.VectorVelocity = direction * flightSpeed
    session.orientation.CFrame = CFrame.lookAt(Vector3.zero, forward)
end)
local speedCard = card(settings, "Скорость полёта", "30 / 60 / 90 / 120 studs в секунду.", 1)
local speedButton = button(speedCard, "60 studs/s", UDim2.new(1, -126, 0.5, -18), UDim2.fromOffset(110, 36))
accent(speedButton, "TextColor3")
connect(speedButton.Activated, function()
    speedIndex = speedIndex % #flightSpeeds + 1
    flightSpeed = flightSpeeds[speedIndex]
    speedButton.Text = tostring(flightSpeed) .. " studs/s"
end)
renderFlight()
toggle(settings, "Показывать FPS", "Локальный счётчик на главной вкладке.", true, 2, function(enabled)
    fpsLabel.Visible = enabled
end)

toggle(settings, "Анимации", "Плавное изменение оформления кнопок.", true, 3, function(enabled) animations = enabled end)
toggle(settings, "Уведомления", "Всплывающие сообщения внизу экрана.", true, 4, function(enabled)
    notifications = enabled
    if not enabled then toast.Visible = false end
end)
local themes = {colors.accent, Color3.fromRGB(161, 147, 255), Color3.fromRGB(255, 188, 105)}
local themeIndex = 1
action(settings, "Акцентный цвет", "Мятный / лавандовый / янтарный.", "Сменить", 5, function()
    themeIndex = themeIndex % #themes + 1
    colors.accent = themes[themeIndex]
    for _, entry in ipairs(accentObjects) do
        if entry[2] == "toggle" then entry[3]() else entry[1][entry[2]] = colors.accent end
    end
    for name, body in pairs(pages) do if body.Visible then selectTab(name); break end end
end)

local elapsed, frames = 0, 0
connect(RunService.RenderStepped, function(dt)
    elapsed += dt
    frames += 1
    if elapsed >= 0.75 then
        fpsLabel.Text = string.format("FPS: %d  •  клиентская сессия", math.floor(frames / elapsed + 0.5))
        elapsed, frames = 0, 0
    end
end)
selectTab("01   Главная")
