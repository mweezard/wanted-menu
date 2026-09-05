-- BLADE BALL / MENU
-- Autoparry: экспериментальная совместимость по доступной структуре мяча.
-- Требуется доступный синтетический ввод; успешное отбивание не гарантировано.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Стабильный идентификатор позволяет заменять меню даже после смены названия.
-- Узнаём ранние версии по структуре и подписи, пока у них ещё нет атрибута.
local function isPreviousPanel(candidate)
    if not candidate:IsA("ScreenGui") then return false end
    if candidate:GetAttribute("CodexTestPanel") == true or candidate.Name == "BladeBallTestMenu" then return true end
    if candidate.DisplayOrder ~= 20 or candidate.ResetOnSpawn then return false end
    local oldRoot = candidate:FindFirstChildOfClass("Frame")
    local oldWindow = oldRoot and oldRoot:FindFirstChildOfClass("Frame")
    if not oldWindow or oldWindow.Size ~= UDim2.fromOffset(700, 450) then return false end
    local hasShortcut = false
    for _, child in ipairs(oldWindow:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == "Right Shift — меню" then hasShortcut = true end
    end
    if not hasShortcut then return false end
    local oldHeader = oldWindow:FindFirstChildOfClass("Frame")
    if not oldHeader then return false end
    for _, child in ipairs(oldHeader:GetChildren()) do
        if child:IsA("TextLabel") and string.match(child.Text, "^TEST PANEL  /  v1%.[012]$") then return true end
    end
    return false
end
for _, candidate in ipairs(playerGui:GetChildren()) do
    if isPreviousPanel(candidate) then candidate:Destroy() end
end

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
local stopSliderDrag = function() end
local stopAutoParry = function() end
local menuActionName = "BladeBallToggleMenu_" .. game:GetService("HttpService"):GenerateGUID(false)
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
    Name = "BladeBallTestMenu", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 20,
}, playerGui)
gui:SetAttribute("CodexTestPanel", true)
gui.Destroying:Connect(function()
    ContextActionService:UnbindAction(menuActionName)
    stopSliderDrag()
    stopAutoParry()
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
local title = label(dragBar, "Blade ball", UDim2.fromOffset(24, 14), UDim2.fromOffset(250, 30), 25)
title.Font = Enum.Font.GothamBlack
accent(title, "TextColor3")
label(dragBar, "v1.6", UDim2.fromOffset(25, 47), UDim2.fromOffset(230, 18), 10, colors.muted)
local close = button(window, "×", UDim2.new(1, -52, 0, 20), UDim2.fromOffset(32, 32))
close.TextSize = 24
local divider = create("Frame", {
    Position = UDim2.fromOffset(20, 78), Size = UDim2.new(1, -40, 0, 1),
    BackgroundColor3 = Color3.fromRGB(42, 49, 62), BorderSizePixel = 0,
}, window)
local sidebar = create("Frame", {Position = UDim2.fromOffset(20, 96), Size = UDim2.fromOffset(150, 280), BackgroundTransparency = 1}, window)
create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = create("Frame", {Position = UDim2.fromOffset(190, 96), Size = UDim2.fromOffset(490, 305), BackgroundTransparency = 1}, window)
label(window, player.DisplayName, UDim2.fromOffset(24, 413), UDim2.fromOffset(470, 20), 11, colors.muted)

local reopen = button(root, "BB", UDim2.new(0, 16, 0.5, -22), UDim2.fromOffset(44, 44))
accent(reopen, "TextColor3")
reopen.Visible = false
local function setVisible(visible)
    if not visible then stopSliderDrag() end
    window.Visible = visible
    reopen.Visible = not visible
end
connect(close.Activated, function() setVisible(false) end)
connect(reopen.Activated, function() setVisible(true) end)
ContextActionService:BindActionAtPriority(menuActionName, function(_, inputState)
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if inputState == Enum.UserInputState.Begin then
        setVisible(not window.Visible)
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 1, Enum.KeyCode.Backspace)

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
    stopSliderDrag()
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
local function card(parent, heading, index)
    local frame = create("Frame", {Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = colors.panel, LayoutOrder = index}, parent)
    round(frame)
    label(frame, heading, UDim2.fromOffset(16, 29), UDim2.new(1, -165, 0, 25), 14)
    return frame
end
local function action(parent, heading, caption, index, callback)
    local frame = card(parent, heading, index)
    local control = button(frame, caption, UDim2.new(1, -126, 0.5, -18), UDim2.fromOffset(110, 36))
    accent(control, "TextColor3")
    connect(control.Activated, function()
        local ok, err = pcall(callback)
        if not ok then warn("BladeBallMenu: " .. tostring(err)); notify("Ошибка функции.") end
    end)
end
local function toggle(parent, heading, initial, index, callback)
    local frame = card(parent, heading, index)
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
local parryPage = page("02   Autoparry", 2)
local settings = page("03   Настройки", 3)

-- Полёт для тестовой сессии. Сервер плейса может ограничивать перемещение.
local flight = nil
local flightSpeed = 60
local minFlightSpeed, maxFlightSpeed = 30, 120
local focused = true
local flightKeys = {}
local acceptedKeys = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
}
local flightCard = card(home, "полет", 1)
local flightButton = create("TextButton", {
    Name = "FlightToggle", BackgroundTransparency = 1, Text = "",
    Position = UDim2.new(1, -104, 0, 20), Size = UDim2.fromOffset(88, 44),
    AutoButtonColor = false,
}, flightCard)
local flightTrack = create("Frame", {
    Position = UDim2.fromOffset(16, 8), Size = UDim2.fromOffset(56, 28),
    BackgroundColor3 = Color3.fromRGB(57, 68, 85), BorderSizePixel = 0,
}, flightButton)
round(flightTrack, 14)
local flightThumb = create("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
    Size = UDim2.fromOffset(20, 20), BackgroundColor3 = colors.text, BorderSizePixel = 0,
}, flightTrack)
round(flightThumb, 10)
local flightStatus = label(flightCard, "ВЫКЛ", UDim2.new(1, -104, 0, 60), UDim2.fromOffset(88, 16), 10, colors.muted)
flightStatus.TextXAlignment = Enum.TextXAlignment.Center
local function renderFlight()
    flightStatus.Text = flight and "ВКЛ" or "ВЫКЛ"
    flightStatus.TextColor3 = flight and colors.accent or colors.muted
    animate(flightTrack, {BackgroundColor3 = flight and colors.accent or Color3.fromRGB(57, 68, 85)})
    animate(flightThumb, {Position = UDim2.new(0, flight and 32 or 4, 0.5, 0)})
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
        notify("Персонаж недоступен.")
        return
    end
    if humanoid.Sit or humanoid.PlatformStand or characterRoot.Anchored then
        notify("Полёт сейчас недоступен.")
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
        object.Name = "BladeBallFlight" .. class
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
        warn("Blade ball flight: " .. tostring(err))
        notify("Не удалось включить полёт.")
        return
    end
    if focused and not UserInputService:GetFocusedTextBox() then
        for key in pairs(acceptedKeys) do
            if UserInputService:IsKeyDown(key) then flightKeys[key] = true end
        end
    end
    renderFlight()
    notify("полет включён.")
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
    -- Полное направление камеры позволяет набирать/снижать высоту через W/S.
    local direction = camera.CFrame.RightVector * (held(Enum.KeyCode.D) - held(Enum.KeyCode.A))
        + look * (held(Enum.KeyCode.W) - held(Enum.KeyCode.S))
    if direction.Magnitude > 1 then direction = direction.Unit end
    session.velocity.VectorVelocity = direction * flightSpeed
    -- Всё тело повторяет поворот и наклон камеры, включая взгляд вверх/вниз.
    session.orientation.CFrame = camera.CFrame.Rotation
end)
local speedCard = create("Frame", {
    Name = "FlightSpeed", Size = UDim2.new(1, -8, 0, 112),
    BackgroundColor3 = colors.panel, LayoutOrder = 2,
}, home)
round(speedCard)
label(speedCard, "Скорость полёта", UDim2.fromOffset(16, 12), UDim2.fromOffset(280, 24), 14)
local speedValue = label(speedCard, "60 studs/s", UDim2.new(1, -156, 0, 12), UDim2.fromOffset(140, 24), 14)
speedValue.TextXAlignment = Enum.TextXAlignment.Right
accent(speedValue, "TextColor3")
local speedTrack = create("Frame", {
    Position = UDim2.fromOffset(26, 61), Size = UDim2.new(1, -52, 0, 6),
    BackgroundColor3 = Color3.fromRGB(57, 68, 85), BorderSizePixel = 0,
}, speedCard)
round(speedTrack, 3)
local speedFill = create("Frame", {
    Size = UDim2.fromScale(0, 1), BorderSizePixel = 0,
}, speedTrack)
round(speedFill, 3)
accent(speedFill, "BackgroundColor3")
local speedThumb = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
    Size = UDim2.fromOffset(18, 18), BackgroundColor3 = colors.text, BorderSizePixel = 0,
}, speedTrack)
round(speedThumb, 9)
local speedHitArea = create("TextButton", {
    Name = "FlightSpeedSlider", Position = UDim2.fromOffset(16, 42),
    Size = UDim2.new(1, -32, 0, 44), Text = "", BackgroundTransparency = 1,
    AutoButtonColor = false, Selectable = false, ZIndex = 3,
}, speedCard)
label(speedCard, tostring(minFlightSpeed), UDim2.fromOffset(16, 90), UDim2.fromOffset(70, 16), 10, colors.muted)
local maxSpeedLabel = label(speedCard, tostring(maxFlightSpeed), UDim2.new(1, -86, 0, 90), UDim2.fromOffset(70, 16), 10, colors.muted)
maxSpeedLabel.TextXAlignment = Enum.TextXAlignment.Right
local function setFlightSpeed(value)
    flightSpeed = math.clamp(math.floor(value + 0.5), minFlightSpeed, maxFlightSpeed)
    local alpha = (flightSpeed - minFlightSpeed) / (maxFlightSpeed - minFlightSpeed)
    speedValue.Text = tostring(flightSpeed) .. " studs/s"
    speedFill.Size = UDim2.fromScale(alpha, 1)
    speedThumb.Position = UDim2.fromScale(alpha, 0.5)
end
local sliderInput = nil
local previousScrolling = true
stopSliderDrag = function()
    if not sliderInput then return end
    sliderInput = nil
    home.ScrollingEnabled = previousScrolling
end
local function updateSpeedFromPointer(input)
    local width = speedTrack.AbsoluteSize.X
    if width <= 0 then return end
    local alpha = math.clamp((input.Position.X - speedTrack.AbsolutePosition.X) / width, 0, 1)
    setFlightSpeed(minFlightSpeed + alpha * (maxFlightSpeed - minFlightSpeed))
end
connect(speedHitArea.InputBegan, function(input)
    if sliderInput or not window.Visible or not home.Visible or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    sliderInput = input
    previousScrolling = home.ScrollingEnabled
    home.ScrollingEnabled = false
    updateSpeedFromPointer(input)
end)
connect(UserInputService.InputChanged, function(input)
    if not sliderInput then return end
    if sliderInput.UserInputType == Enum.UserInputType.Touch then
        if input ~= sliderInput then return end
    elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
        return
    end
    updateSpeedFromPointer(input)
end)
connect(UserInputService.InputEnded, function(input)
    if input == sliderInput then stopSliderDrag() end
end)
connect(UserInputService.WindowFocusReleased, stopSliderDrag)
connect(UserInputService.TextBoxFocused, stopSliderDrag)
setFlightSpeed(flightSpeed)
renderFlight()

-- Runtime compatibility adapter; current Blade ball internals are not guaranteed.
local function newAutoParryController(options)
    options = options or {}
    local player = options.player or game:GetService("Players").LocalPlayer
    local runService = options.RunService or game:GetService("RunService")
    local inputService = options.UserInputService or game:GetService("UserInputService")
    local guiService = options.GuiService or game:GetService("GuiService")
    local world = workspace
    local connections, containerConnections, characterConnections, records = {}, {}, {}, {}
    local enabled, destroyed, focused = false, false, true
    local sender, syntheticDown = nil, false
    local status, container
    local clock, lastPingAt, oneWayPing, lastReleaseAttempt = 0, -math.huge, 0, -math.huge
    -- Timing estimates, not the game's server rules or a guarantee of a successful block.
    local LEAD_TIME, MAX_ONE_WAY_PING = 0.11, 0.15
    local MIN_CLOSING_SPEED, MIN_APPROACH_COSINE, REARM_AWAY_SECONDS = 2, 0.35, 0.06

    local function setStatus(value)
        if status ~= value then
            status = value
            if options.onStatus then options.onStatus(value) end
        end
    end
    local function setEnabledState(value)
        if enabled ~= value then
            enabled = value
            if options.onEnabled then options.onEnabled(value) end
        end
    end
    local function watch(signal, callback, list)
        local connection = signal:Connect(callback)
        table.insert(list or connections, connection)
        return connection
    end
    local function disconnectAll(list)
        for _, connection in ipairs(list) do connection:Disconnect() end
        table.clear(list)
    end
    local function resetSamples()
        for _, record in pairs(records) do
            record.lastPosition = nil
            record.awayTime = 0
        end
    end
    local function releaseKey()
        if not syntheticDown then return true end
        lastReleaseAttempt = clock
        local ok = pcall(sender, false)
        if ok then syntheticDown = false end
        return ok
    end
    local function inputFailure(message)
        setEnabledState(false)
        releaseKey()
        setStatus(message)
    end
    local function resolveInput()
        local ok, virtualInput = pcall(function() return inputService:CreateVirtualInput() end)
        if ok and virtualInput then
            local supported, sendKey = pcall(function() return virtualInput.SendKey end)
            if supported and type(sendKey) == "function" then
                return function(down) virtualInput:SendKey(down, Enum.KeyCode.F, false) end
            end
        end
        local fallbackOK, manager = pcall(function() return game:GetService("VirtualInputManager") end)
        if fallbackOK and manager then
            local supported, sendKeyEvent = pcall(function() return manager.SendKeyEvent end)
            if supported and type(sendKeyEvent) == "function" then
                return function(down) manager:SendKeyEvent(down, Enum.KeyCode.F, false, game) end
            end
        end
        return nil
    end
    local function pauseReason()
        if not focused then return "Пауза: окно неактивно" end
        if inputService:GetFocusedTextBox() then return "Пауза: ввод текста" end
        if guiService.MenuIsOpen then return "Пауза: меню Roblox" end
        local selected = guiService.SelectedObject
        if selected then
            local ok, inCoreGui = pcall(function()
                return selected:IsDescendantOf(game:GetService("CoreGui"))
            end)
            if ok and inCoreGui then return "Пауза: меню Roblox" end
        end
        return nil
    end
    local function pauseNow(message)
        resetSamples()
        if not releaseKey() then
            inputFailure("Ошибка отпускания F")
        elseif enabled then
            setStatus(message)
        end
    end
    local function removeBall(ball)
        local record = records[ball]
        if record then
            disconnectAll(record.connections)
            records[ball] = nil
        end
    end
    local function addBall(ball)
        if records[ball] or not ball:IsA("BasePart") then return end
        local record = {
            target = ball:GetAttribute("target"),
            real = ball:GetAttribute("realBall") == true,
            fired = false, awayTime = 0, connections = {},
        }
        records[ball] = record
        watch(ball:GetAttributeChangedSignal("target"), function()
            local nextTarget = ball:GetAttribute("target")
            if nextTarget ~= record.target then
                record.target, record.fired, record.awayTime = nextTarget, false, 0
                record.lastPosition = nil
            end
        end, record.connections)
        watch(ball:GetAttributeChangedSignal("realBall"), function()
            record.real = ball:GetAttribute("realBall") == true
            record.fired, record.awayTime, record.lastPosition = false, 0, nil
        end, record.connections)
    end
    local function bindContainer()
        local nextContainer = world:FindFirstChild("Balls")
        if container == nextContainer then return end
        disconnectAll(containerConnections)
        for ball in pairs(records) do removeBall(ball) end
        container = nextContainer
        if container then
            watch(container.ChildAdded, addBall, containerConnections)
            watch(container.ChildRemoved, removeBall, containerConnections)
            for _, ball in ipairs(container:GetChildren()) do addBall(ball) end
        end
    end
    local function bindCharacter(character)
        disconnectAll(characterConnections)
        pauseNow("Ожидание персонажа")
        for _, record in pairs(records) do record.fired = false end
        if character then
            local function watchHumanoid(child)
                if child:IsA("Humanoid") then
                    watch(child.Died, function() pauseNow("Ожидание персонажа") end, characterConnections)
                end
            end
            watch(character.ChildAdded, watchHumanoid, characterConnections)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then watchHumanoid(humanoid) end
        end
    end
    local function ballVelocity(ball, record, deltaTime)
        local position = ball.Position
        local measured = record.lastPosition and (position - record.lastPosition) / deltaTime
        record.lastPosition = position
        local velocity = ball.AssemblyLinearVelocity
        local mover = ball:FindFirstChild("zoomies")
        if mover and mover:IsA("LinearVelocity")
            and mover.RelativeTo == Enum.ActuatorRelativeTo.World
            and mover.VelocityConstraintMode == Enum.VelocityConstraintMode.Vector then
            velocity = mover.VectorVelocity
        end
        if measured and measured.Magnitude > 0.5
            and (velocity.Magnitude < 0.5 or (measured - velocity).Magnitude > math.max(10, measured.Magnitude * 0.5)) then
            velocity = measured
        end
        return velocity
    end
    local function pressParry(record)
        if syntheticDown or inputService:IsKeyDown(Enum.KeyCode.F) then return false end
        syntheticDown = true
        local ok = pcall(sender, true)
        if not ok then
            inputFailure("Ввод F недоступен в этой среде")
            return false
        end
        record.fired, record.awayTime = true, 0
        -- Keep down/up together: no delayed callback can release a later physical F press.
        if not releaseKey() then
            inputFailure("Ошибка отпускания F")
            return false
        end
        return true
    end

    watch(world.ChildAdded, function(child) if child.Name == "Balls" then bindContainer() end end)
    watch(world.ChildRemoved, function(child) if child == container then bindContainer() end end)
    watch(player.CharacterAdded, bindCharacter)
    watch(player.CharacterRemoving, function() bindCharacter(nil) end)
    watch(inputService.WindowFocusReleased, function() focused = false; pauseNow("Пауза: окно неактивно") end)
    watch(inputService.WindowFocused, function() focused = true end)
    watch(inputService.TextBoxFocused, function() pauseNow("Пауза: ввод текста") end)
    watch(guiService.MenuOpened, function() pauseNow("Пауза: меню Roblox") end)
    watch(runService.Heartbeat, function(deltaTime)
        if destroyed then return end
        clock += deltaTime
        if not enabled then
            if syntheticDown and clock - lastReleaseAttempt >= 0.25 and not pauseReason() then releaseKey() end
            return
        end
        local paused = pauseReason()
        if paused then pauseNow(paused); return end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
            pauseNow("Ожидание персонажа")
            return
        end
        if clock - lastPingAt >= 1 then
            lastPingAt = clock
            local ok, ping = pcall(function() return player:GetNetworkPing() end)
            if ok and type(ping) == "number" and ping == ping then oneWayPing = math.clamp(ping * 0.5, 0, MAX_ONE_WAY_PING) end
        end
        if deltaTime <= 0 or deltaTime > 0.25 then resetSamples(); return end
        local selected, earliest, hasRealBall, isTargeted = nil, math.huge, false, false
        for ball, record in pairs(records) do
            if record.real then
                hasRealBall = true
                local velocity = ballVelocity(ball, record, deltaTime)
                if record.target == player.Name then
                    isTargeted = true
                    local offset = ball.Position - root.Position
                    local distance = offset.Magnitude
                    local relativeVelocity = velocity - root.AssemblyLinearVelocity
                    local speed = relativeVelocity.Magnitude
                    local closing = distance > 0.01 and -offset:Dot(relativeVelocity) / distance or 0
                    if closing < -MIN_CLOSING_SPEED then
                        record.awayTime += deltaTime
                        if record.awayTime >= REARM_AWAY_SECONDS then record.fired = false end
                    else
                        record.awayTime = 0
                    end
                    if not record.fired and speed > MIN_CLOSING_SPEED and closing > MIN_CLOSING_SPEED
                        and closing / speed >= MIN_APPROACH_COSINE then
                        local radius = ball.Size.Magnitude * 0.5 + root.Size.Magnitude * 0.5 + 2
                        local closestTime = math.max(0, -offset:Dot(relativeVelocity) / (speed * speed))
                        local missDistance = (offset + relativeVelocity * closestTime).Magnitude
                        local curveAllowance = math.min(8, speed * 0.025)
                        local timeToContact = math.max(0, (distance - radius) / closing)
                        local lead = LEAD_TIME + oneWayPing + math.min(deltaTime, 1 / 30)
                        if missDistance <= radius + curveAllowance and timeToContact <= lead and timeToContact < earliest then
                            earliest, selected = timeToContact, record
                        end
                    end
                end
            else
                record.lastPosition = nil
            end
        end
        if not container or not hasRealBall then setStatus("Ожидание мяча")
        elseif not isTargeted then setStatus("Ожидание наведения")
        elseif inputService:IsKeyDown(Enum.KeyCode.F) and not syntheticDown then setStatus("Пауза: F удерживается")
        else setStatus("Отслеживание мяча") end
        if selected then pressParry(selected) end
    end)
    bindContainer()
    bindCharacter(player.Character)
    setStatus("Выключено")

    local controller = {}
    function controller:SetEnabled(value)
        if destroyed then return false, "Контроллер удалён" end
        if value then
            if enabled then return true end
            if syntheticDown and not releaseKey() then
                setStatus("Ошибка отпускания F")
                return false, "Не удалось отпустить F"
            end
            sender = resolveInput()
            if not sender then
                setStatus("Ввод недоступен в этой среде")
                return false, "Среда не предоставляет виртуальный ввод"
            end
            for _, record in pairs(records) do record.fired = false end
            resetSamples()
            setEnabledState(true)
            setStatus(pauseReason() or "Ожидание мяча")
            return true
        end
        setEnabledState(false)
        resetSamples()
        if not releaseKey() then
            setStatus("Ошибка отпускания F")
            return false, "Не удалось отпустить F"
        end
        setStatus("Выключено")
        return true
    end
    function controller:Destroy()
        if destroyed then return end
        setEnabledState(false)
        if not releaseKey() then setStatus("Ошибка отпускания F") end
        destroyed = true
        disconnectAll(connections)
        disconnectAll(containerConnections)
        disconnectAll(characterConnections)
        for ball in pairs(records) do removeBall(ball) end
        sender = nil
    end
    return controller
end

local parryCard = card(parryPage, "autoparry", 1)
local parryButton = create("TextButton", {
    Name = "AutoParryToggle", BackgroundTransparency = 1, Text = "",
    Position = UDim2.new(1, -104, 0, 20), Size = UDim2.fromOffset(88, 44),
    AutoButtonColor = false,
}, parryCard)
local parryTrack = create("Frame", {
    Position = UDim2.fromOffset(16, 8), Size = UDim2.fromOffset(56, 28),
    BackgroundColor3 = Color3.fromRGB(57, 68, 85), BorderSizePixel = 0,
}, parryButton)
round(parryTrack, 14)
local parryThumb = create("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
    Size = UDim2.fromOffset(20, 20), BackgroundColor3 = colors.text, BorderSizePixel = 0,
}, parryTrack)
round(parryThumb, 10)
local parryState = label(parryCard, "ВЫКЛ", UDim2.new(1, -104, 0, 60), UDim2.fromOffset(88, 16), 10, colors.muted)
parryState.TextXAlignment = Enum.TextXAlignment.Center
local parryStatusCard = create("Frame", {
    Name = "AutoParryStatus", Size = UDim2.new(1, -8, 0, 84), BackgroundColor3 = colors.panel, LayoutOrder = 2,
}, parryPage)
round(parryStatusCard)
label(parryStatusCard, "Состояние", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 24), 14)
local parryStatusLabel = label(parryStatusCard, "Выключено", UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 28), 12, colors.muted)
local parryEnabled = false
local function renderAutoParry()
    parryState.Text = parryEnabled and "ВКЛ" or "ВЫКЛ"
    parryState.TextColor3 = parryEnabled and colors.accent or colors.muted
    animate(parryTrack, {BackgroundColor3 = parryEnabled and colors.accent or Color3.fromRGB(57, 68, 85)})
    animate(parryThumb, {Position = UDim2.new(0, parryEnabled and 32 or 4, 0.5, 0)})
end
table.insert(accentObjects, {parryButton, "toggle", renderAutoParry})
local autoParry = newAutoParryController({
    player = player,
    onStatus = function(message) if gui.Parent then parryStatusLabel.Text = message end end,
    onEnabled = function(enabled)
        parryEnabled = enabled
        if gui.Parent then renderAutoParry() end
    end,
})
stopAutoParry = function() autoParry:Destroy() end
connect(parryButton.Activated, function()
    local ok, reason = autoParry:SetEnabled(not parryEnabled)
    if not ok and reason then notify(reason) end
end)
renderAutoParry()

toggle(settings, "Анимации", true, 1, function(enabled) animations = enabled end)
toggle(settings, "Уведомления", true, 2, function(enabled)
    notifications = enabled
    if not enabled then toast.Visible = false end
end)
local themes = {colors.accent, Color3.fromRGB(161, 147, 255), Color3.fromRGB(255, 188, 105)}
local themeIndex = 1
action(settings, "Акцентный цвет", "Сменить", 3, function()
    themeIndex = themeIndex % #themes + 1
    colors.accent = themes[themeIndex]
    for _, entry in ipairs(accentObjects) do
        if entry[2] == "toggle" then entry[3]() else entry[1][entry[2]] = colors.accent end
    end
    for name, body in pairs(pages) do if body.Visible then selectTab(name); break end end
end)

selectTab("01   Главная")
