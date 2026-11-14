--[[
    VisionUI (Refactored)
    A lightweight Roblox UI library
    Version: 2.0.3 (Fixed CoreGui bug)
]]

local Services = {
    Workspace        = game:GetService("Workspace"),
    Players          = game:GetService("Players"),
    UserInput        = game:GetService("UserInputService"),
    TextService      = game:GetService("TextService"),
    TweenService     = game:GetService("TweenService"),
    RunService       = game:GetService("RunService"),
    CoreGui          = game:GetService("CoreGui"),
    ContentProvider  = game:GetService("ContentProvider"),
    TeleportService  = game:GetService("TeleportService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui") -- FIX: Use PlayerGui instead of CoreGui
local Mouse       = LocalPlayer:GetMouse()

-- ==========================================================
-- CONFIGURATION CONSTANTS
-- ==========================================================

local THEME = {
    PanelDark      = Color3.fromRGB(34, 34, 34),
    PanelDarker    = Color3.fromRGB(28, 28, 28),
    BorderLight    = Color3.fromRGB(60, 60, 60),
    BorderMid      = Color3.fromRGB(50, 50, 50),
    TextPrimary    = Color3.fromRGB(198, 198, 198),
    TextSecondary  = Color3.fromRGB(190, 190, 190),
    TextMuted      = Color3.fromRGB(140, 140, 140),
    TextDim        = Color3.fromRGB(90, 90, 90),
    TextActive     = Color3.fromRGB(170, 170, 170),
    Accent         = Color3.fromRGB(27, 27, 27),
}

local STATUS_COLORS = {
    notification = Color3.fromRGB(27, 27, 27),
    alert        = Color3.fromRGB(255, 246, 112),
    error        = Color3.fromRGB(176, 0, 3),
    success      = Color3.fromRGB(39, 212, 0),
    information  = Color3.fromRGB(90, 90, 90),
}

local DEFAULTS = {
    Font        = Enum.Font.Code,
    TextSize    = 14,
    HoverSpeed  = 0.16,
    DragSpeed   = 0.04,
    PanelWidth  = 592,
    PanelHeight = 404,
}

-- ==========================================================
-- ANIMATION SYSTEM
-- ==========================================================

local Anim = {}

function Anim:Register(name, speed, style, direction, loop, reverse, delay)
    Anim[name] = TweenInfo.new(
        speed or 0.17,
        style or Enum.EasingStyle.Sine,
        direction or Enum.EasingDirection.InOut,
        loop or 0,
        reverse or false,
        delay or 0
    )
end

Anim:Register("default", 0.17)
Anim:Register("hover", 0.16)
Anim:Register("fade", 0.13)
Anim:Register("instant", 0.08)

function Anim:Play(instance, tweenName, properties)
    Services.TweenService:Create(instance, Anim[tweenName] or Anim.default, properties):Play()
end

-- ==========================================================
-- DRAG SYSTEM
-- ==========================================================

local Draggable = {}

function Draggable:Attach(frame, smoothness)
    local isDragging = false
    local dragStart  = nil
    local originPos  = nil
    local activeInput = nil
    local smoothTime = smoothness or 0.06

    local function moveTo(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            originPos.X.Scale, originPos.X.Offset + delta.X,
            originPos.Y.Scale, originPos.Y.Offset + delta.Y
        )
        Services.TweenService:Create(frame, TweenInfo.new(smoothTime), { Position = newPos }):Play()
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart  = input.Position
            originPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            activeInput = input
        end
    end)

    Services.UserInput.InputChanged:Connect(function(input)
        if input == activeInput and isDragging then
            moveTo(input)
        end
    end)
end

-- ==========================================================
-- HELPER FUNCTIONS
-- ==========================================================

local Helper = {}

function Helper:Round(num, decimals)
    return tonumber(string.format("%." .. (decimals or 0) .. "f", num))
end

function Helper:MeasureText(text, font, size, width)
    return Services.TextService:GetTextSize(
        text, size or DEFAULTS.TextSize, font or DEFAULTS.Font,
        Vector2.new(width or math.huge, math.huge)
    )
end

function Helper:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 2)
    corner.Parent = parent
    return corner
end

function Helper:CreateGradient(parent, topColor, bottomColor, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, topColor or THEME.PanelDark),
        ColorSequenceKeypoint.new(1, bottomColor or THEME.PanelDarker),
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

function Helper:Pad(parent, l, t, r, b)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft   = UDim.new(0, l or 0)
    padding.PaddingTop    = UDim.new(0, t or 0)
    padding.PaddingRight  = UDim.new(0, r or 0)
    padding.PaddingBottom = UDim.new(0, b or 0)
    padding.Parent = parent
    return padding
end

-- ==========================================================
-- LIBRARY TABLE
-- ==========================================================

local Library = {
    version = "2.0.3",
    fps     = 0,
    rank    = "private",
    keybind = Enum.KeyCode.RightShift,
    notifications = nil,
}

Services.RunService.RenderStepped:Connect(function(dt)
    Library.fps = math.round(1 / dt)
end)

-- ==========================================================
-- UTILITY METHODS
-- ==========================================================

function Library:GetUsername() return LocalPlayer.Name end
function Library:GetUserId()   return LocalPlayer.UserId end
function Library:GetPlaceId()  return game.PlaceId end
function Library:GetJobId()    return game.JobId end

function Library:IsLoaded()
    return game:IsLoaded()
end

function Library:Rejoin()
    Services.TeleportService:TeleportToPlaceInstance(
        self:GetPlaceId(), self:GetJobId(), self:GetUserId()
    )
end

function Library:Copy(text)
    if syn and syn.write_clipboard then
        syn.write_clipboard(text)
    end
end

function Library:SetFpsCap(value)
    if syn and setfpscap then
        setfpscap(value)
    end
end

-- ==========================================================
-- DATE / TIME HELPERS
-- ==========================================================

local DateUtil = {}

function DateUtil:Day(format)
    local map = { word = "%A", short = "%a", month = "%d", year = "%j" }
    return format and os.date(map[format]) or nil
end

function DateUtil:Time(format)
    local map = {
        ["24h"] = "%H", ["12h"] = "%I", minute = "%M",
        half = "%p", second = "%S", full = "%X",
        ISO = "%z", zone = "%Z",
    }
    return format and os.date(map[format]) or nil
end

function DateUtil:Month(format)
    local map = { word = "%B", short = "%b", digit = "%m" }
    return format and os.date(map[format]) or nil
end

function DateUtil:Week(format)
    local map = { year_S = "%U", day = "%w", year_M = "%W" }
    return format and os.date(map[format]) or nil
end

function DateUtil:Year(format)
    local map = { digits = "%y", full = "%Y" }
    return format and os.date(map[format]) or nil
end

Library.Date = DateUtil

-- ==========================================================
-- NOTIFICATION SYSTEM
-- ==========================================================

local NotificationSystem = {}

function NotificationSystem:Create()
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name == "Notifications" then
            child:Destroy()
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Notifications"
    gui.Parent = PlayerGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false

    local layout = Instance.new("UIListLayout")
    layout.Parent = gui
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)

    local padding = Instance.new("UIPadding")
    padding.Parent = gui
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingTop  = UDim.new(0, 18)

    local API = {}

    function API:Notify(text, duration, notifyType, callback)
        text        = text or "please wait."
        duration    = duration or 5
        notifyType  = notifyType or "notification"
        callback    = callback or function() end

        local edge = Instance.new("Frame")
        edge.Name = "edge"
        edge.Parent = gui
        edge.BackgroundColor3 = THEME.BorderLight
        edge.BackgroundTransparency = 1
        edge.Size = UDim2.new(0, 0, 0, 26)
        Helper:CreateCorner(edge, 2)

        local bg = Instance.new("Frame")
        bg.Name = "background"
        bg.Parent = edge
        bg.AnchorPoint = Vector2.new(0.5, 0.5)
        bg.BackgroundTransparency = 1
        bg.ClipsDescendants = true
        bg.Position = UDim2.new(0.5, 0, 0.5, 0)
        bg.Size = UDim2.new(0, 0, 0, 24)
        Helper:CreateCorner(bg, 2)
        Helper:CreateGradient(bg)

        local barFolder = Instance.new("Folder")
        barFolder.Name = "barFolder"
        barFolder.Parent = bg

        local bar = Instance.new("Frame")
        bar.Name = "bar"
        bar.Parent = barFolder
        bar.BackgroundColor3 = STATUS_COLORS[notifyType] or STATUS_COLORS.notification
        bar.BackgroundTransparency = 0.2
        bar.Size = UDim2.new(0, 0, 0, 1)
        Helper:CreateCorner(bar, 2)

        local barLayout = Instance.new("UIListLayout")
        barLayout.Name = "barLayout"
        barLayout.Parent = barFolder
        barLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "notifText"
        textLabel.Parent = bg
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(0, 230, 0, 26)
        textLabel.Font = DEFAULTS.Font
        textLabel.Text = text
        textLabel.TextColor3 = THEME.TextPrimary
        textLabel.TextSize = DEFAULTS.TextSize
        textLabel.TextTransparency = 1
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.RichText = true
        Helper:Pad(textLabel, 4, 4, 4, 4)

        local bgLayout = Instance.new("UIListLayout")
        bgLayout.Name = "backgroundLayout"
        bgLayout.Parent = bg
        bgLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bgLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local measured = Helper:MeasureText(text, DEFAULTS.Font, DEFAULTS.TextSize)
        local isRunning = false

        coroutine.wrap(function()
            isRunning = true
            Anim:Play(edge, "default", { BackgroundTransparency = 0 })
            Anim:Play(bg, "default", { BackgroundTransparency = 0 })
            Anim:Play(textLabel, "default", { TextTransparency = 0 })
            Anim:Play(edge, "default", { Size = UDim2.new(0, measured.X + 10, 0, 26) })
            Anim:Play(bg, "default", { Size = UDim2.new(0, measured.X + 8, 0, 24) })
            Anim:Play(textLabel, "default", { Size = UDim2.new(0, measured.X + 8, 0, 24) })
            task.wait()
            Anim:Play(bar, "default", { Size = UDim2.new(0, measured.X + 8, 0, 1) })
            repeat task.wait() until bar.Size == UDim2.new(0, measured.X + 8, 0, 1)
            isRunning = false
            Anim:Play(edge, "default", { BackgroundTransparency = 1 })
            Anim:Play(bg, "default", { BackgroundTransparency = 1 })
            Anim:Play(textLabel, "default", { TextTransparency = 1 })
            Anim:Play(bar, "default", { BackgroundTransparency = 1 })
            Anim:Play(edge, "default", { Size = UDim2.new(0, 0, 0, 26) })
            Anim:Play(bg, "default", { Size = UDim2.new(0, 0, 0, 24) })
            Anim:Play(textLabel, "default", { Size = UDim2.new(0, 0, 0, 24) })
            Anim:Play(bar, "default", { Size = UDim2.new(0, 0, 0, 1) })
            task.wait(0.2)
            edge:Destroy()
            callback()
        end)()

        return {
            UpdateText = function(newText)
                textLabel.Text = newText or text
                local newSize = Helper:MeasureText(textLabel.Text, DEFAULTS.Font, DEFAULTS.TextSize)
                if isRunning then
                    Anim:Play(edge, "default", { Size = UDim2.new(0, newSize.X + 10, 0, 26) })
                    Anim:Play(bg, "default", { Size = UDim2.new(0, newSize.X + 8, 0, 24) })
                    Anim:Play(textLabel, "default", { Size = UDim2.new(0, newSize.X + 8, 0, 24) })
                    task.wait()
                    Anim:Play(bar, "default", { Size = UDim2.new(0, 0, 0, 1) })
                    task.wait(0.4)
                    Anim:Play(bar, "default", { Size = UDim2.new(0, newSize.X + 8, 0, 1) })
                end
            end,
        }
    end

    return API
end

function Library:Notify(text, duration, notifyType, callback)
    if not self.notifications then
        self.notifications = NotificationSystem:Create()
    end
    return self.notifications:Notify(text, duration, notifyType, callback)
end

-- ==========================================================
-- WINDOW CREATION
-- ==========================================================

function Library:CreateWindow(titleText, toggleKey)
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name == "screen" then
            child:Destroy()
        end
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "screen"
    screen.Parent = PlayerGui
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.ResetOnSpawn = false

    local edge = Instance.new("Frame")
    edge.Name = "edge"
    edge.Parent = screen
    edge.AnchorPoint = Vector2.new(0.5, 0.5)
    edge.BackgroundColor3 = THEME.BorderLight
    edge.Position = UDim2.new(0.5, 0, 0.5, 0)
    edge.Size = UDim2.new(0, DEFAULTS.PanelWidth + 2, 0, DEFAULTS.PanelHeight + 2)
    Helper:CreateCorner(edge, 2)
    Draggable:Attach(edge, DEFAULTS.DragSpeed)

    local visibilityToggle = toggleKey or self.keybind or Enum.KeyCode.RightShift
    Services.UserInput.InputBegan:Connect(function(input)
        if input.KeyCode == visibilityToggle then
            edge.Visible = not edge.Visible
        end
    end)

    local bg = Instance.new("Frame")
    bg.Name = "background"
    bg.Parent = edge
    bg.AnchorPoint = Vector2.new(0.5, 0.5)
    bg.Position = UDim2.new(0.5, 0, 0.5, 0)
    bg.Size = UDim2.new(0, DEFAULTS.PanelWidth, 0, DEFAULTS.PanelHeight)
    bg.ClipsDescendants = true
    Helper:CreateCorner(bg, 2)
    Helper:CreateGradient(bg)

    local header = Instance.new("TextLabel")
    header.Name = "headerLabel"
    header.Parent = bg
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(0, DEFAULTS.PanelWidth, 0, 38)
    header.Font = DEFAULTS.Font
    header.Text = titleText or "VisionUI"
    header.TextColor3 = THEME.TextPrimary
    header.TextSize = 16
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.RichText = true
    Helper:Pad(header, 12, 6, 6, 6)

    local barFolder = Instance.new("Folder")
    barFolder.Name = "barFolder"
    barFolder.Parent = bg

    local bar = Instance.new("Frame")
    bar.Name = "bar"
    bar.Parent = barFolder
    bar.BackgroundColor3 = THEME.Accent
    bar.BackgroundTransparency = 0.2
    bar.Size = UDim2.new(0, DEFAULTS.PanelWidth, 0, 1)
    bar.BorderSizePixel = 0
    Helper:CreateCorner(bar, 2)

    local barLayout = Instance.new("UIListLayout")
    barLayout.Name = "barLayout"
    barLayout.Parent = barFolder
    barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    barLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Parent = bg
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -10, 0, 2)
    closeBtn.Text = ""
    closeBtn.Font = DEFAULTS.Font

    local closeLabel = Instance.new("TextLabel")
    closeLabel.Name = "buttonLabel"
    closeLabel.Parent = closeBtn
    closeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    closeLabel.BackgroundTransparency = 1
    closeLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeLabel.Size = UDim2.new(0, 22, 0, 22)
    closeLabel.Font = DEFAULTS.Font
    closeLabel.Text = "x"
    closeLabel.TextXAlignment = Enum.TextXAlignment.Center
    closeLabel.TextColor3 = THEME.TextPrimary
    closeLabel.TextSize = 21

    closeBtn.MouseButton1Click:Connect(function()
        edge.Visible = false
        Library:Notify("Press " .. visibilityToggle.Name .. " to bring back the UI", 3, "information")
    end)

    local tabPanelEdge = Instance.new("Frame")
    tabPanelEdge.Name = "tabButtonsEdge"
    tabPanelEdge.Parent = bg
    tabPanelEdge.AnchorPoint = Vector2.new(0.5, 0.5)
    tabPanelEdge.BackgroundColor3 = THEME.BorderMid
    tabPanelEdge.Position = UDim2.new(0.1435, 0, 0.536, 0)
    tabPanelEdge.Size = UDim2.new(0, 152, 0, 360)
    Helper:CreateCorner(tabPanelEdge, 2)

    local tabPanel = Instance.new("Frame")
    tabPanel.Name = "tabButtons"
    tabPanel.Parent = tabPanelEdge
    tabPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    tabPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    tabPanel.Size = UDim2.new(0, 150, 0, 358)
    tabPanel.ClipsDescendants = true
    Helper:CreateCorner(tabPanel, 2)
    Helper:CreateGradient(tabPanel)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Name = "tabButtonLayout"
    tabLayout.Parent = tabPanel
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    Helper:Pad(tabPanel, 4, 4, 4, 4)

    local contentEdge = Instance.new("Frame")
    contentEdge.Name = "containerEdge"
    contentEdge.Parent = bg
    contentEdge.AnchorPoint = Vector2.new(0.5, 0.5)
    contentEdge.BackgroundColor3 = THEME.BorderMid
    contentEdge.Position = UDim2.new(0.637, 0, 0.536, 0)
    contentEdge.Size = UDim2.new(0, 414, 0, 360)
    Helper:CreateCorner(contentEdge, 2)

    local content = Instance.new("Frame")
    content.Name = "container"
    content.Parent = contentEdge
    content.AnchorPoint = Vector2.new(0.5, 0.5)
    content.Position = UDim2.new(0.5, 0, 0.5, 0)
    content.Size = UDim2.new(0, 412, 0, 358)
    Helper:CreateCorner(content, 2)
    Helper:CreateGradient(content)

    local Tabs = { isFirst = true, current = "" }

    function Tabs:CreateTab(tabTitle)
        tabTitle = tabTitle or "tab"

        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "tabButton"
        tabBtn.Parent = tabPanel
        tabBtn.BackgroundTransparency = 1
        tabBtn.Size = UDim2.new(0, 150, 0, 22)
        tabBtn.AutoButtonColor = false
        tabBtn.Font = DEFAULTS.Font
        tabBtn.Text = tabTitle
        tabBtn.TextColor3 = THEME.TextDim
        tabBtn.TextSize = 15
        tabBtn.RichText = true

        local page = Instance.new("ScrollingFrame")
        page.Name = "page"
        page.Parent = content
        page.Active = true
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.new(0, 412, 0, 358)
        page.BottomImage = "rbxassetid://3062506202"
        page.MidImage = "rbxassetid://3062506202"
        page.TopImage = "rbxassetid://3062506202"
        page.ScrollBarThickness = 1
        page.ScrollBarImageColor3 = THEME.Accent
        page.Visible = false

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Name = "pageLayout"
        pageLayout.Parent = page
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 4)

        Helper:Pad(page, 6, 6, 6, 6)

        if Tabs.isFirst then
            page.Visible = true
            tabBtn.TextColor3 = THEME.TextActive
            Tabs.current = tabTitle
        end

        tabBtn.MouseButton1Click:Connect(function()
            Tabs.current = tabTitle
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end
            page.Visible = true

            for _, child in ipairs(tabPanel:GetChildren()) do
                if child:IsA("TextButton") then
                    Anim:Play(child, "hover", { TextColor3 = THEME.TextDim })
                end
            end
            Anim:Play(tabBtn, "hover", { TextColor3 = THEME.TextActive })
        end)

        local function refreshSize()
            local size = pageLayout.AbsoluteContentSize
            page.CanvasSize = UDim2.new(0, size.X + 13, 0, size.Y + 13)
        end
        page.ChildAdded:Connect(refreshSize)
        page.ChildRemoved:Connect(refreshSize)

        Tabs.isFirst = false

        local Components = {}

        -- ---- LABEL ----
        function Components:Label(text, align)
            text  = text or "label"
            align = align or "left"

            local label = Instance.new("TextLabel")
            label.Name = "label"
            label.Parent = page
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0, 396, 0, 24)
            label.Font = DEFAULTS.Font
            label.Text = text
            label.TextColor3 = THEME.TextSecondary
            label.TextSize = DEFAULTS.TextSize
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.RichText = true
            Helper:Pad(label, 12, 6, 6, 6)

            local function applyAlign(a)
                if a:lower():find("le") then
                    label.TextXAlignment = Enum.TextXAlignment.Left
                elseif a:lower():find("cent") then
                    label.TextXAlignment = Enum.TextXAlignment.Center
                elseif a:lower():find("ri") then
                    label.TextXAlignment = Enum.TextXAlignment.Right
                end
            end
            applyAlign(align)
            refreshSize()

            return {
                SetText = function(t)
                    label.Text = t or "new label text"
                    return Components
                end,
                Hide = function()
                    label.Visible = false
                    refreshSize()
                end,
                Show = function()
                    label.Visible = true
                    refreshSize()
                end,
                Align = applyAlign,
                Destroy = function() label:Destroy() end,
            }
        end

        -- ---- BUTTON ----
        function Components:Button(text, callback)
            callback = callback or function() end

            local frame = Instance.new("Frame")
            frame.Name = "buttonFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(0, 396, 0, 24)

            local frameLayout = Instance.new("UIListLayout")
            frameLayout.Parent = frame
            frameLayout.FillDirection = Enum.FillDirection.Horizontal
            frameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            frameLayout.SortOrder = Enum.SortOrder.LayoutOrder
            frameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            frameLayout.Padding = UDim.new(0, 4)

            local function makeButton(btnText, btnCallback)
                local btn = Instance.new("TextButton")
                btn.Name = "button"
                btn.Parent = frame
                btn.BackgroundColor3 = THEME.BorderMid
                btn.Size = UDim2.new(0, 396, 0, 24)
                btn.AutoButtonColor = false
                btn.Font = Enum.Font.SourceSans
                btn.Text = ""
                Helper:CreateCorner(btn, 2)

                local btnBg = Instance.new("Frame")
                btnBg.Name = "buttonBackground"
                btnBg.Parent = btn
                btnBg.AnchorPoint = Vector2.new(0.5, 0.5)
                btnBg.Position = UDim2.new(0.5, 0, 0.5, 0)
                btnBg.Size = UDim2.new(0, 394, 0, 22)
                Helper:CreateCorner(btnBg, 2)
                Helper:CreateGradient(btnBg)

                local btnLabel = Instance.new("TextLabel")
                btnLabel.Name = "buttonLabel"
                btnLabel.Parent = btnBg
                btnLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                btnLabel.BackgroundTransparency = 1
                btnLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                btnLabel.Size = UDim2.new(0, 394, 0, 22)
                btnLabel.Font = DEFAULTS.Font
                btnLabel.Text = " " .. btnText
                btnLabel.TextColor3 = THEME.TextSecondary
                btnLabel.TextSize = DEFAULTS.TextSize
                btnLabel.TextXAlignment = Enum.TextXAlignment.Left
                btnLabel.RichText = true

                btn.MouseEnter:Connect(function()
                    Anim:Play(btn, "hover", { BackgroundColor3 = THEME.BorderLight })
                end)
                btn.MouseLeave:Connect(function()
                    Anim:Play(btn, "hover", { BackgroundColor3 = THEME.BorderMid })
                end)
                btn.MouseButton1Down:Connect(function()
                    Anim:Play(btnLabel, "hover", { TextColor3 = THEME.Accent })
                end)
                btn.MouseButton1Up:Connect(function()
                    Anim:Play(btnLabel, "hover", { TextColor3 = THEME.TextSecondary })
                end)
                btn.MouseButton1Click:Connect(btnCallback)

                return btn, btnLabel
            end

            local primaryBtn, primaryLabel = makeButton(text, callback)

            local addCount = 0
            local function resizeAll()
                local children = {}
                for _, c in ipairs(frame:GetChildren()) do
                    if c:IsA("TextButton") then table.insert(children, c) end
                end
                local count = #children
                if count == 0 then return end
                local newW = (396 / count) - (count / 2)
                for _, c in ipairs(children) do
                    c.Size = UDim2.new(0, newW, 0, 24)
                    for _, d in ipairs(c:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("Frame") then
                            d.Size = UDim2.new(0, newW - 2, 0, 22)
                        end
                    end
                end
            end
            frame.ChildAdded:Connect(resizeAll)
            frame.ChildRemoved:Connect(resizeAll)
            refreshSize()

            local api = {}
            function api:AddButton(t, cb)
                addCount = addCount + 1
                if addCount > 4 then
                    warn("Max 4 additional buttons per row")
                    return api
                end
                local b, lbl = makeButton(t or "Button", cb or function() end)
                resizeAll()
                refreshSize()
                return {
                    Fire = function() cb() end,
                    Hide = function() b.Visible = false end,
                    Show = function() b.Visible = true end,
                    SetText = function(nt) lbl.Text = nt end,
                    Destroy = function() b:Destroy() end,
                    SetFunction = function(f) cb = f end,
                }
            end
            function api:Fire()      callback() end
            function api:Hide()      primaryBtn.Visible = false end
            function api:Show()      primaryBtn.Visible = true end
            function api:SetText(t)  primaryLabel.Text = t or "button new text" end
            function api:Destroy()   primaryBtn:Destroy() end
            function api:SetFunction(f) callback = f or function() end end
            return api
        end

        -- ---- SECTION HEADER ----
        function Components:Section(text)
            text = text or "section"

            local frame = Instance.new("Frame")
            frame.Name = "sectionFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, 0, 18)

            local layout = Instance.new("UIListLayout")
            layout.Parent = frame
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            layout.Padding = UDim.new(0, 4)

            local label = Instance.new("TextLabel")
            label.Name = "sectionLabel"
            label.Parent = frame
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0, 0, 0, 18)
            label.Font = DEFAULTS.Font
            label.LineHeight = 1
            label.Text = text
            label.TextColor3 = THEME.TextSecondary
            label.TextSize = DEFAULTS.TextSize
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.RichText = true

            local divider = Instance.new("Frame")
            divider.Name = "rightBar"
            divider.Parent = frame
            divider.BackgroundColor3 = THEME.BorderLight
            divider.BorderSizePixel = 0
            divider.Size = UDim2.new(0, 403, 0, 1)

            local sz = Helper:MeasureText(label.Text, DEFAULTS.Font, DEFAULTS.TextSize)
            label.Size = UDim2.new(0, sz.X, 0, 18)
            refreshSize()

            return {
                SetText = function(t)
                    label.Text = t or text
                    local s = Helper:MeasureText(label.Text, DEFAULTS.Font, DEFAULTS.TextSize)
                    label.Size = UDim2.new(0, s.X, 0, 18)
                end,
                Hide = function() frame.Visible = false end,
                Show = function() frame.Visible = true end,
                Destroy = function() frame:Destroy() end,
            }
        end

        -- ---- TOGGLE ----
        function Components:Toggle(text, default, callback)
            text     = text or "toggle"
            default  = default or false
            callback = callback or function() end

            local btn = Instance.new("TextButton")
            btn.Name = "toggleButton"
            btn.Parent = page
            btn.BackgroundTransparency = 1
            btn.ClipsDescendants = false
            btn.Size = UDim2.new(0, 396, 0, 22)
            btn.Font = DEFAULTS.Font
            btn.Text = ""

            local btnLayout = Instance.new("UIListLayout")
            btnLayout.Parent = btn
            btnLayout.FillDirection = Enum.FillDirection.Horizontal
            btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
            btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center

            local cbEdge = Instance.new("Frame")
            cbEdge.Name = "toggleEdge"
            cbEdge.Parent = btn
            cbEdge.BackgroundColor3 = THEME.BorderMid
            cbEdge.Size = UDim2.new(0, 18, 0, 18)
            Helper:CreateCorner(cbEdge, 2)

            local cb = Instance.new("Frame")
            cb.Name = "toggle"
            cb.Parent = cbEdge
            cb.AnchorPoint = Vector2.new(0.5, 0.5)
            cb.Position = UDim2.new(0.5, 0, 0.5, 0)
            cb.Size = UDim2.new(0, 16, 0, 16)
            Helper:CreateCorner(cb, 2)
            Helper:CreateGradient(cb)

            local cbFill = Instance.new("Frame")
            cbFill.Name = "toggleDesign"
            cbFill.Parent = cb
            cbFill.AnchorPoint = Vector2.new(0.5, 0.5)
            cbFill.BackgroundColor3 = THEME.TextSecondary
            cbFill.BackgroundTransparency = 1
            cbFill.Position = UDim2.new(0.5, 0, 0.5, 0)
            cbFill.Size = UDim2.new(0, 0, 0, 0)
            Helper:CreateCorner(cbFill, 2)

            local lbl = Instance.new("TextLabel")
            lbl.Name = "toggleLabel"
            lbl.Parent = btn
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0.045, 0, 0, 0)
            lbl.Size = UDim2.new(0, 377, 0, 22)
            lbl.Font = DEFAULTS.Font
            lbl.LineHeight = 1.15
            lbl.Text = text
            lbl.TextColor3 = THEME.TextSecondary
            lbl.TextSize = DEFAULTS.TextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.RichText = true
            Helper:Pad(lbl, 6, 0, 0, 0)

            local extras = Instance.new("Folder")
            extras.Name = "Extras"
            extras.Parent = btn

            local extrasLayout = Instance.new("UIListLayout")
            extrasLayout.Parent = extras
            extrasLayout.FillDirection = Enum.FillDirection.Horizontal
            extrasLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            extrasLayout.SortOrder = Enum.SortOrder.LayoutOrder
            extrasLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            extrasLayout.Padding = UDim.new(0, 2)

            local mSize = Helper:MeasureText(lbl.Text, DEFAULTS.Font, DEFAULTS.TextSize)
            lbl.Size = UDim2.new(0, mSize.X + 6, 0, 22)

            btn.MouseEnter:Connect(function()
                Anim:Play(lbl, "hover", { TextColor3 = Color3.fromRGB(210, 210, 210) })
            end)
            btn.MouseLeave:Connect(function()
                Anim:Play(lbl, "hover", { TextColor3 = THEME.TextSecondary })
            end)

            local isOn = default
            local function setVisual(state)
                Anim:Play(cbFill, "fade", {
                    Size = state and UDim2.new(0, 12, 0, 12) or UDim2.new(0, 0, 0, 0),
                })
                Anim:Play(cbFill, "fade", { BackgroundTransparency = state and 0 or 1 })
            end

            btn.MouseButton1Click:Connect(function()
                isOn = not isOn
                setVisual(isOn)
                callback(isOn)
            end)

            local toggleApi = {
                SetText = function(t) lbl.Text = t or text end,
                Hide = function() btn.Visible = false end,
                Show = function() btn.Visible = true end,
                Toggle = function()
                    isOn = not isOn
                    setVisual(isOn)
                    callback(isOn)
                end,
                Set = function(v)
                    isOn = v
                    setVisual(isOn)
                    callback(isOn)
                end,
                Destroy = function() btn:Destroy() end,
                SetFunction = function(f) callback = f or function() end end,
            }

            toggleApi.AddKeybind = function(defaultKey)
                defaultKey = defaultKey or Enum.KeyCode.P

                local kbBtn = Instance.new("TextButton")
                kbBtn.Name = "keybind"
                kbBtn.Parent = extras
                kbBtn.BackgroundColor3 = THEME.BorderMid
                kbBtn.Size = UDim2.new(0, 87, 0, 22)
                kbBtn.AutoButtonColor = false
                kbBtn.Font = Enum.Font.SourceSans
                kbBtn.Text = ""
                kbBtn.Active = false
                Helper:CreateCorner(kbBtn, 2)

                local kbBg = Instance.new("Frame")
                kbBg.Parent = kbBtn
                kbBg.AnchorPoint = Vector2.new(0.5, 0.5)
                kbBg.Position = UDim2.new(0.5, 0, 0.5, 0)
                kbBg.Size = UDim2.new(0, 85, 0, 20)
                Helper:CreateCorner(kbBg, 2)
                Helper:CreateGradient(kbBg)

                local kbLabel = Instance.new("TextLabel")
                kbLabel.Parent = kbBg
                kbLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                kbLabel.BackgroundTransparency = 1
                kbLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                kbLabel.Size = UDim2.new(0, 85, 0, 20)
                kbLabel.Font = DEFAULTS.Font
                kbLabel.TextColor3 = THEME.TextSecondary
                kbLabel.TextSize = DEFAULTS.TextSize
                kbLabel.RichText = true

                local shortcuts = { Return = "enter" }
                local chosenKey = defaultKey.Name
                local keyCallback = callback

                local function refreshKeySize()
                    local s = Helper:MeasureText(kbLabel.Text, DEFAULTS.Font, DEFAULTS.TextSize)
                    kbLabel.Size = UDim2.new(0, s.X + 6, 0, 20)
                    kbBg.Size = UDim2.new(0, s.X + 6, 0, 20)
                    kbBtn.Size = UDim2.new(0, s.X + 8, 0, 22)
                end

                kbLabel.Text = shortcuts[defaultKey.Name] or defaultKey.Name
                refreshKeySize()
                kbLabel:GetPropertyChangedSignal("Text"):Connect(refreshKeySize)

                kbBtn.MouseButton1Click:Connect(function()
                    kbLabel.Text = ". . ."
                    local inp = Services.UserInput.InputBegan:Wait()
                    if inp.KeyCode.Name ~= "Unknown" then
                        kbLabel.Text = shortcuts[inp.KeyCode.Name] or inp.KeyCode.Name
                        chosenKey = inp.KeyCode.Name
                    end
                end)

                Services.UserInput.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.KeyCode.Name == chosenKey then
                        local chat = LocalPlayer.PlayerGui:FindFirstChild("Chat")
                        local chatBox = chat and chat:FindFirstChild("Frame")
                        if chatBox and chatBox:FindFirstChild("ChatBarParentFrame") then
                            local box = chatBox.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar
                            if box and box:IsFocused() then return end
                        end
                        isOn = not isOn
                        setVisual(isOn)
                        keyCallback(isOn)
                    end
                end)

                return {
                    SetKey = function(k)
                        chosenKey = k.Name
                        kbLabel.Text = k.Name
                    end,
                    Fire = function() keyCallback(chosenKey) end,
                    SetFunction = function(f) keyCallback = f or function() end end,
                }
            end

            if default then
                cbFill.Size = UDim2.new(0, 12, 0, 12)
                cbFill.BackgroundTransparency = 0
                callback(true)
            end

            refreshSize()
            return toggleApi
        end

        -- ---- KEYBIND (standalone) ----
        function Components:Keybind(text, defaultKey, callback)
            text       = text or "keybind"
            defaultKey = defaultKey or Enum.KeyCode.P
            callback   = callback or function() end

            local frame = Instance.new("Frame")
            frame.Name = "keybindFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, 0, 24)

            local label = Instance.new("TextLabel")
            label.Name = "keybindLabel"
            label.Parent = frame
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(0, 396, 0, 24)
            label.Font = DEFAULTS.Font
            label.Text = text
            label.TextColor3 = THEME.TextSecondary
            label.TextSize = DEFAULTS.TextSize
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.RichText = true
            Helper:Pad(label, 2, 6, 6, 6)

            local kbBtn = Instance.new("TextButton")
            kbBtn.Name = "keybind"
            kbBtn.Parent = frame
            kbBtn.AnchorPoint = Vector2.new(1, 0.5)
            kbBtn.BackgroundColor3 = THEME.BorderMid
            kbBtn.Position = UDim2.new(1, -6, 0.5, 0)
            kbBtn.Size = UDim2.new(0, 87, 0, 22)
            kbBtn.AutoButtonColor = false
            kbBtn.Font = Enum.Font.SourceSans
            kbBtn.Text = ""
            kbBtn.Active = false
            Helper:CreateCorner(kbBtn, 2)

            local kbBg = Instance.new("Frame")
            kbBg.Parent = kbBtn
            kbBg.AnchorPoint = Vector2.new(0.5, 0.5)
            kbBg.Position = UDim2.new(0.5, 0, 0.5, 0)
            kbBg.Size = UDim2.new(0, 85, 0, 20)
            Helper:CreateCorner(kbBg, 2)
            Helper:CreateGradient(kbBg)

            local kbLabel = Instance.new("TextLabel")
            kbLabel.Parent = kbBg
            kbLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            kbLabel.BackgroundTransparency = 1
            kbLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            kbLabel.Size = UDim2.new(0, 85, 0, 20)
            kbLabel.Font = DEFAULTS.Font
            kbLabel.TextColor3 = THEME.TextSecondary
            kbLabel.TextSize = DEFAULTS.TextSize
            kbLabel.RichText = true

            local shortcuts = { Return = "enter" }
            local chosenKey = defaultKey.Name

            local function refreshSize()
                local s = Helper:MeasureText(kbLabel.Text, DEFAULTS.Font, DEFAULTS.TextSize)
                kbLabel.Size = UDim2.new(0, s.X + 6, 0, 20)
                kbBg.Size = UDim2.new(0, s.X + 6, 0, 20)
                kbBtn.Size = UDim2.new(0, s.X + 8, 0, 22)
            end

            kbLabel.Text = shortcuts[defaultKey.Name] or defaultKey.Name
            refreshSize()
            kbLabel:GetPropertyChangedSignal("Text"):Connect(refreshSize)

            kbBtn.MouseButton1Click:Connect(function()
                kbLabel.Text = ". . ."
                local inp = Services.UserInput.InputBegan:Wait()
                if inp.KeyCode.Name ~= "Unknown" then
                    kbLabel.Text = shortcuts[inp.KeyCode.Name] or inp.KeyCode.Name
                    chosenKey = inp.KeyCode.Name
                end
            end)

            Services.UserInput.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.KeyCode.Name == chosenKey then
                    callback(chosenKey)
                end
            end)

            refreshSize()

            return {
                Fire = function() callback(chosenKey) end,
                SetFunction = function(f) callback = f or function() end end,
                SetKey = function(k) chosenKey = k.Name; kbLabel.Text = k.Name end,
                SetText = function(t) label.Text = t or text end,
                Hide = function() frame.Visible = false end,
                Show = function() frame.Visible = true end,
            }
        end

        -- ---- TEXTBOX ----
        function Components:Textbox(text, default, placeholder, format, size, autoExec, autoClear, callback)
            text        = text or "text box"
            default     = default or ""
            placeholder = placeholder or ""
            format      = format or "all"
            size        = size or "small"
            autoExec    = autoExec ~= false
            autoClear   = autoClear or false
            callback    = callback or function() end

            local isSmall  = size == "small"
            local isMedium = size == "medium"
            local isLarge  = size == "large"

            local frame = Instance.new("Frame")
            frame.Name = "textboxFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, isSmall and 24 or isMedium and 46 or 142)

            local lbl = Instance.new("TextLabel")
            lbl.Name = "textboxLabel"
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(0, 396, 0, 24)
            lbl.Font = DEFAULTS.Font
            lbl.Text = text
            lbl.TextColor3 = THEME.TextSecondary
            lbl.TextSize = DEFAULTS.TextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.RichText = true
            Helper:Pad(lbl, 2, 6, 6, 6)

            local inputHolder = Instance.new("Frame")
            inputHolder.Parent = frame
            inputHolder.BackgroundColor3 = THEME.BorderLight
            inputHolder.AnchorPoint = isSmall and Vector2.new(1, 1) or Vector2.new(0.5, 1)
            inputHolder.Position = isSmall and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, 0, 1, 0)
            inputHolder.Size = isSmall and UDim2.new(0, 133, 0, 22) or UDim2.new(0, 396, isMedium and 22 or 118)
            Helper:CreateCorner(inputHolder, 2)

            local inputBg = Instance.new("Frame")
            inputBg.Parent = inputHolder
            inputBg.AnchorPoint = Vector2.new(0.5, 0.5)
            inputBg.Position = UDim2.new(0.5, 0, 0.5, 0)
            inputBg.Size = isSmall and UDim2.new(0, 131, 0, 20) or UDim2.new(0, 394, isMedium and 20 or 116)
            Helper:CreateCorner(inputBg, 2)
            Helper:CreateGradient(inputBg)

            local textBox = Instance.new("TextBox")
            textBox.Parent = inputBg
            textBox.BackgroundTransparency = 1
            textBox.Size = inputBg.Size
            textBox.Font = DEFAULTS.Font
            textBox.PlaceholderColor3 = THEME.TextMuted
            textBox.PlaceholderText = placeholder
            textBox.Text = default
            textBox.TextColor3 = THEME.TextSecondary
            textBox.TextSize = DEFAULTS.TextSize
            textBox.ClearTextOnFocus = autoClear
            textBox.TextXAlignment = isSmall and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
            if isLarge then
                textBox.TextWrapped = true
                textBox.TextYAlignment = Enum.TextYAlignment.Top
            end
            Helper:Pad(textBox, isSmall and 6 or 4, 6, isSmall and 4 or 6, 6)

            textBox:GetPropertyChangedSignal("Text"):Connect(function()
                if format == "numbers" then
                    textBox.Text = textBox.Text:gsub("%D+", "")
                elseif format == "lower" then
                    textBox.Text = textBox.Text:lower()
                elseif format == "upper" then
                    textBox.Text = textBox.Text:upper()
                end
            end)

            frame.MouseEnter:Connect(function()
                Anim:Play(lbl, "instant", { TextColor3 = Color3.fromRGB(210, 210, 210) })
            end)
            frame.MouseLeave:Connect(function()
                Anim:Play(lbl, "instant", { TextColor3 = THEME.TextSecondary })
            end)
            textBox.Focused:Connect(function()
                Anim:Play(inputHolder, "instant", { BackgroundColor3 = THEME.Accent })
            end)
            textBox.FocusLost:Connect(function(enter)
                Anim:Play(inputHolder, "instant", { BackgroundColor3 = THEME.BorderLight })
                if autoExec or enter then
                    callback(textBox.Text)
                end
            end)

            refreshSize()

            return {
                Fire = function() callback(textBox.Text) end,
                SetFunction = function(f) callback = f or function() end end,
                SetText = function(t) lbl.Text = t or text end,
                Hide = function() frame.Visible = false end,
                Show = function() frame.Visible = true end,
                SetPlaceholder = function(p) textBox.PlaceholderText = p or placeholder end,
                Destroy = function() frame:Destroy() end,
            }
        end

        -- ---- SELECTOR (dropdown) ----
        function Components:Selector(text, default, options, callback)
            text     = text or "selector"
            default  = default or ". . ."
            options  = options or {}
            callback = callback or function() end

            local frame = Instance.new("Frame")
            frame.Name = "selectorFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, 0, 46)

            local lbl = Instance.new("TextLabel")
            lbl.Name = "selectorLabel"
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(0, 396, 0, 24)
            lbl.Font = DEFAULTS.Font
            lbl.Text = text
            lbl.TextColor3 = THEME.TextSecondary
            lbl.TextSize = DEFAULTS.TextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.RichText = true
            Helper:Pad(lbl, 2, 6, 6, 6)

            local selBtn = Instance.new("TextButton")
            selBtn.Name = "selector"
            selBtn.Parent = frame
            selBtn.BackgroundColor3 = THEME.BorderLight
            selBtn.ClipsDescendants = true
            selBtn.Position = UDim2.new(0, 0, 0, 24)
            selBtn.Size = UDim2.new(0, 396, 0, 21)
            selBtn.AutoButtonColor = false
            selBtn.Text = ""
            Helper:CreateCorner(selBtn, 2)

            local selBg = Instance.new("Frame")
            selBg.Parent = selBtn
            selBg.BackgroundColor3 = THEME.BorderLight
            selBg.ClipsDescendants = true
            selBg.Position = UDim2.new(0.0025, 0, 0, 0)
            selBg.Size = UDim2.new(0, 394, 0, 20)
            Helper:CreateCorner(selBg, 2)
            Helper:CreateGradient(selBg)

            local current = Instance.new("TextLabel")
            current.Name = "selectorText"
            current.Parent = selBg
            current.BackgroundTransparency = 1
            current.Size = UDim2.new(0, 394, 0, 20)
            current.Font = DEFAULTS.Font
            current.LineHeight = 1.15
            current.TextColor3 = Color3.fromRGB(160, 160, 160)
            current.TextSize = DEFAULTS.TextSize
            current.TextXAlignment = Enum.TextXAlignment.Left
            current.Text = default
            Helper:Pad(current, 6, 6, 6, 6)

            local optionContainer = Instance.new("Frame")
            optionContainer.Name = "selectorContainer"
            optionContainer.Parent = selBg
            optionContainer.BackgroundTransparency = 1
            optionContainer.Size = UDim2.new(0, 394, 0, 20)

            local optLayout = Instance.new("UIListLayout")
            optLayout.Parent = optionContainer
            optLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder

            Anim:Register("selector", 0.08)

            local listHeight = 0
            local function calcHeight()
                listHeight = (#options * 20) + 20
                optionContainer.Size  = UDim2.new(0, 394, 0, listHeight)
                selBg.Size            = UDim2.new(0, 394, 0, listHeight)
                selBtn.Size           = UDim2.new(0, 396, 0, listHeight + 2)
                frame.Size            = UDim2.new(0, 396, 0, listHeight + 26)
            end

            local function makeOption(optText, optCallback)
                local opt = Instance.new("TextButton")
                opt.Name = "optionButton"
                opt.Parent = optionContainer
                opt.BackgroundTransparency = 1
                opt.Size = UDim2.new(0, 394, 0, 20)
                opt.AutoButtonColor = false
                opt.Font = DEFAULTS.Font
                opt.Text = optText
                opt.TextColor3 = Color3.fromRGB(160, 160, 160)
                opt.TextSize = DEFAULTS.TextSize

                if optText == default then
                    opt.TextColor3 = THEME.Accent
                    optCallback(current.Text)
                end

                opt.MouseButton1Click:Connect(function()
                    for _, c in ipairs(optionContainer:GetChildren()) do
                        if c:IsA("TextButton") then
                            Anim:Play(c, "selector", { TextColor3 = Color3.fromRGB(160, 160, 160) })
                        end
                    end
                    Anim:Play(opt, "selector", { TextColor3 = THEME.Accent })
                    current.Text = opt.Text
                    optCallback(opt.Text)
                end)
            end

            for _, optText in ipairs(options) do
                makeOption(optText, callback)
            end
            calcHeight()
            refreshSize()

            return {
                AddOption = function(optText, cb)
                    table.insert(options, optText)
                    makeOption(optText, cb or callback)
                    calcHeight()
                    refreshSize()
                end,
                RemoveOption = function(optText)
                    for i, v in ipairs(options) do
                        if v == optText then table.remove(options, i) break end
                    end
                    for _, c in ipairs(optionContainer:GetChildren()) do
                        if c:IsA("TextButton") and c.Text == optText then
                            c:Destroy()
                            break
                        end
                    end
                    calcHeight()
                    refreshSize()
                end,
                SetFunction = function(f) callback = f or function() end end,
                SetText = function(t) lbl.Text = t or text end,
                Hide = function() frame.Visible = false end,
                Show = function() frame.Visible = true end,
                Destroy = function() frame:Destroy() end,
            }
        end

        -- ---- SLIDER ----
        function Components:Slider(text, suffix, showMax, compareSign, range, callback)
            suffix      = suffix or ""
            showMax     = showMax or false
            compareSign = compareSign or "/"
            range = range or { min = 0, max = 100, default = 0 }
            callback = callback or function() end
            range.max = range.max + 1

            local frame = Instance.new("Frame")
            frame.Name = "sliderFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, 0, 40)

            local lbl = Instance.new("TextLabel")
            lbl.Name = "sliderLabel"
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(0, 396, 0, 24)
            lbl.Font = DEFAULTS.Font
            lbl.Text = text
            lbl.TextColor3 = THEME.TextSecondary
            lbl.TextSize = DEFAULTS.TextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.RichText = true
            Helper:Pad(lbl, 2, 6, 6, 6)

            local valueLbl = Instance.new("TextLabel")
            valueLbl.Name = "sliderValue"
            valueLbl.Parent = lbl
            valueLbl.BackgroundTransparency = 1
            valueLbl.AnchorPoint = Vector2.new(1, 0)
            valueLbl.Position = UDim2.new(1, 0, 0, 0)
            valueLbl.Size = UDim2.new(0, 169, 0, 15)
            valueLbl.Font = DEFAULTS.Font
            valueLbl.TextColor3 = THEME.TextMuted
            valueLbl.TextSize = DEFAULTS.TextSize
            valueLbl.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("TextButton")
            track.Name = "sliderButton"
            track.Parent = frame
            track.BackgroundColor3 = THEME.BorderLight
            track.AnchorPoint = Vector2.new(0.5, 1)
            track.Position = UDim2.new(0.5, 0, 1, 0)
            track.Size = UDim2.new(0, 396, 0, 16)
            track.AutoButtonColor = false
            track.Text = ""
            Helper:CreateCorner(track, 2)

            local trackBg = Instance.new("Frame")
            trackBg.Parent = track
            trackBg.AnchorPoint = Vector2.new(0.5, 0.5)
            trackBg.Position = UDim2.new(0.5, 0, 0.5, 0)
            trackBg.Size = UDim2.new(0, 394, 0, 14)
            trackBg.ClipsDescendants = true
            Helper:CreateCorner(trackBg, 2)
            Helper:CreateGradient(trackBg)

            local fill = Instance.new("Frame")
            fill.Name = "sliderIndicator"
            fill.Parent = trackBg
            fill.AnchorPoint = Vector2.new(0, 0.5)
            fill.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
            fill.Position = UDim2.new(0, 0, 0.5, 0)
            fill.Size = UDim2.new(0, 0, 0, 12)
            Helper:CreateCorner(fill, 2)

            local rangeSize = range.max - range.min
            local defaultRatio = (range.default - range.min) / rangeSize
            local fillW = defaultRatio * trackBg.AbsoluteSize.X
            fill.Size = UDim2.new(0, fillW, 0, 12)

            local display = showMax and range.default .. compareSign .. tostring(range.max - 1) .. suffix or range.default .. suffix
            valueLbl.Text = display

            local currentValue = range.default
            local moveConn, releaseConn

            local function updateFromMouse()
                Anim:Register("sliderDrag", 0.008)
                Anim:Play(fill, "sliderDrag", {
                    Size = UDim2.new(0, math.clamp(Mouse.X - fill.AbsolutePosition.X, 0, trackBg.AbsoluteSize.X), 0, 12)
                })
                currentValue = math.floor(((rangeSize) / trackBg.AbsoluteSize.X) * fill.AbsoluteSize.X + range.min)
                local txt = showMax and currentValue .. compareSign .. tostring(range.max - 1) .. suffix or currentValue .. suffix
                valueLbl.Text = txt
                pcall(callback, currentValue)
            end

            track.MouseButton1Down:Connect(function()
                updateFromMouse()
                moveConn = Mouse.Move:Connect(function()
                    if not Services.UserInput.WindowFocused then
                        if moveConn then moveConn:Disconnect() end
                        return
                    end
                    updateFromMouse()
                end)
                releaseConn = Services.UserInput.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        updateFromMouse()
                        if moveConn then moveConn:Disconnect() end
                        if releaseConn then releaseConn:Disconnect() end
                    end
                end)
            end)

            refreshSize()

            local api = {}
            function api:SetValue(v)
                local ratio = (v - range.min) / rangeSize
                fill.Size = UDim2.new(0, ratio * trackBg.AbsoluteSize.X, 0, 12)
                valueLbl.Text = showMax and v .. compareSign .. tostring(range.max - 1) .. suffix or v .. suffix
            end
            function api:SetMax(v)
                range.max = (v or range.max) + 1
            end
            function api:SetMin(v)
                range.min = v or range.min
            end
            function api:SetFunction(f) callback = f or function() end end
            function api:SetText(t) lbl.Text = t or text end
            function api:Hide() frame.Visible = false end
            function api:Show() frame.Visible = true end
            function api:Destroy() frame:Destroy() end
            return api
        end

        -- ---- SEPARATOR ----
        function Components:Separator()
            local frame = Instance.new("Frame")
            frame.Name = "sectionFrame"
            frame.Parent = page
            frame.BackgroundTransparency = 1
            frame.ClipsDescendants = true
            frame.Size = UDim2.new(0, 396, 0, 12)

            local line = Instance.new("Frame")
            line.Name = "rightBar"
            line.Parent = frame
            line.BackgroundColor3 = THEME.BorderLight
            line.BorderSizePixel = 0
            line.Size = UDim2.new(0, 396, 0, 1)
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.Position = UDim2.new(0.5, 0, 0.5, 0)

            refreshSize()

            return {
                Hide = function() frame.Visible = false end,
                Show = function() frame.Visible = true end,
                Destroy = function() frame:Destroy() end,
            }
        end

        -- ---- TAB CONTROL ----
        function Components:Open()
            Tabs.current = tabTitle
            for _, c in ipairs(content:GetChildren()) do
                if c:IsA("ScrollingFrame") then c.Visible = false end
            end
            page.Visible = true
            for _, c in ipairs(tabPanel:GetChildren()) do
                if c:IsA("TextButton") then
                    Anim:Play(c, "hover", { TextColor3 = THEME.TextActive })
                end
            end
            Anim:Play(tabBtn, "hover", { TextColor3 = THEME.Accent })
        end

        function Components:Destroy()
            tabBtn:Destroy()
            page:Destroy()
        end

        function Components:Hide()
            tabBtn.Visible = false
            page.Visible = false
        end

        function Components:Show()
            tabBtn.Visible = true
        end

        function Components:SetText(t)
            tabBtn.Text = t or "new text"
        end

        return Components
    end

    function Tabs:Destroy()
        screen:Destroy()
    end

    function Tabs:SetTitle(t)
        header.Text = t or "new text"
    end

    function Tabs:SetKeybind(key)
        visibilityToggle = key or visibilityToggle
    end

    return Tabs
end

return Library
