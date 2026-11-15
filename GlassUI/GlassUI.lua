--[[
	GlassUI - glassmorphism UI library
	Usage: see example.lua
]]

local Library = {}
local WindowClass = {}
WindowClass.__index = WindowClass
local TabClass = {}
TabClass.__index = TabClass

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ROW_H, OPT_H, MAX_VISIBLE = 40, 28, 6

local C = {
	white = Color3.fromRGB(255, 255, 255),
	text = Color3.fromRGB(242, 242, 244),
	muted = Color3.fromRGB(166, 166, 173),
	accent = Color3.fromRGB(190, 190, 198),
	accent2 = Color3.fromRGB(120, 120, 128),
	green = Color3.fromRGB(74, 222, 128),
	red = Color3.fromRGB(255, 92, 115),
	amber = Color3.fromRGB(255, 193, 69),
	gray = Color3.fromRGB(150, 150, 158),
	blue = Color3.fromRGB(235, 235, 240),
}
Library.Colors = C

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------

local function new(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, transparency, thickness)
	return new("UIStroke", {
		Color = color,
		Transparency = transparency,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function gradient(parent, c0, c1, rotation)
	return new("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rotation or 0, Parent = parent })
end

local function ti(time, style, dir)
	return TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
end

local function tween(inst, info, goal)
	local t = TweenService:Create(inst, info, goal)
	t:Play()
	return t
end

local function label(props)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in pairs(props) do
		p[k] = v
	end
	return new("TextLabel", p)
end

local function interactive(btn)
	local press = btn:FindFirstChild("Press")
	btn.MouseEnter:Connect(function()
		tween(btn, ti(0.15), { BackgroundTransparency = btn:GetAttribute("Hover") })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, ti(0.25), { BackgroundTransparency = btn:GetAttribute("Idle") })
		if press then
			tween(press, ti(0.15), { Scale = 1 })
		end
	end)
	btn.MouseButton1Down:Connect(function()
		if press then
			tween(press, ti(0.1), { Scale = 0.95 })
		end
	end)
	btn.MouseButton1Up:Connect(function()
		if press then
			tween(press, ti(0.3, Enum.EasingStyle.Back), { Scale = 1 })
		end
	end)
end

local function fire(cb, ...)
	if type(cb) == "function" then
		task.spawn(cb, ...)
	end
end

local function chevron(props)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 9),
		BackgroundTransparency = 1,
	})
	local function arm(x, rot)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, 4.5),
			Size = UDim2.fromOffset(8, 2),
			Rotation = rot,
			BackgroundColor3 = C.muted,
			BorderSizePixel = 0,
			Parent = holder,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	end
	arm(4.15, 45)
	arm(9.85, -45)
	for k, v in pairs(props or {}) do
		holder[k] = v
	end
	return holder
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

----------------------------------------------------------------------
-- window
----------------------------------------------------------------------

function Library:CreateWindow(opts)
	if type(opts) == "string" then
		opts = { Title = opts }
	end
	opts = opts or {}

	local title = opts.Title or "Window"
	local subtitle = opts.Subtitle or ""
	local WIDTH, HEIGHT, HEADER = opts.Width or 820, opts.Height or 620, 60
	local toggleKey = opts.Keybind or Enum.KeyCode.RightShift
	local guiName = opts.Name or "GlassUI"

	local Window = setmetatable({
		Tabs = {},
		Accent = opts.Accent or C.white,
		_conns = {},
		_toastOrder = 0,
		_tabBtns = {},
	}, WindowClass)

	function Window:_connect(c)
		table.insert(self._conns, c)
		return c
	end

	-- gui root
	local gui = new("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	local okParent = pcall(function()
		local hui = gethui and gethui()
		local parent = hui or game:GetService("CoreGui")
		local old = parent:FindFirstChild(guiName)
		if old then
			old:Destroy()
		end
		gui.Parent = parent
	end)
	if not okParent or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	Window.Gui = gui

	local camera = Workspace.CurrentCamera
	local function fitScale()
		local v = camera and camera.ViewportSize or Vector2.new(1280, 720)
		return math.clamp(math.min((v.X - 32) / WIDTH, (v.Y - 32) / HEIGHT), 0.5, 1)
	end
	local baseScale = fitScale()

	local window = new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = gui,
	}, { corner(22) })
	Window.Frame = window

	local scale = new("UIScale", { Scale = baseScale * 0.9, Parent = window })
	gradient(window, Color3.fromRGB(56, 56, 61), Color3.fromRGB(12, 12, 14), 58)
	local windowStroke = stroke(C.white, 0.5, 1.2)
	windowStroke.Parent = window
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.45, 0.75),
			NumberSequenceKeypoint.new(1, 0.25),
		}),
		Rotation = 45,
		Parent = windowStroke,
	})

	local function glow(x, y, size, color)
		local holder = new("Frame", {
			Name = "Glow",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(size, size),
			Parent = window,
		})
		local layers = 32
		for i = 1, layers do
			local sz = size * (1 - ((i - 1) / layers) ^ 0.8)
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = color,
				BackgroundTransparency = 0.99,
				BorderSizePixel = 0,
				Parent = holder,
			}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		end
	end
	glow(0, 0, 380, Color3.fromRGB(215, 215, 222))
	glow(WIDTH - 380, HEIGHT - 380, 380, Color3.fromRGB(150, 150, 158))

	local sheen = new("Frame", {
		Name = "Sheen",
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 200),
		Parent = window,
	}, { corner(22) })
	new("UIGradient", { Transparency = NumberSequence.new(0.9, 1), Rotation = 90, Parent = sheen })

	-- header
	local header = new("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER),
		Parent = window,
	})
	new("Frame", {
		Name = "Divider",
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = header,
	})

	local logo = new("Frame", {
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Parent = header,
	}, { corner(10) })
	gradient(logo, C.accent, C.accent2, 45)
	local logoLbl = label({
		Size = UDim2.fromScale(1, 1),
		Text = title:sub(1, 1):upper(),
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.white,
		Parent = logo,
	})

	local titleLbl = label({
		Position = UDim2.fromOffset(64, 11),
		Size = UDim2.fromOffset(360, 20),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		Parent = header,
	})
	local subLbl = label({
		Position = UDim2.fromOffset(64, 31),
		Size = UDim2.fromOffset(380, 16),
		TextSize = 12,
		TextColor3 = C.muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	local function refreshSub()
		subLbl.Text = (subtitle ~= "" and (subtitle .. "  |  ") or "") .. toggleKey.Name .. " to toggle"
	end
	refreshSub()

	local controls = new("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})

	local function iconButton(icon, order, hoverColor)
		local b = new("TextButton", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = C.white,
			BackgroundTransparency = 0.93,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
			Parent = controls,
		}, { corner(14), new("UIScale", { Name = "Press" }) })
		local function bar(rot, w)
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(w, 2),
				Rotation = rot,
				BackgroundColor3 = C.text,
				BorderSizePixel = 0,
				Parent = b,
			}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		end
		if icon == "min" then
			bar(0, 10)
		else
			bar(45, 12)
			bar(-45, 12)
		end
		b:SetAttribute("Idle", 0.93)
		b:SetAttribute("Hover", 0.8)
		interactive(b)
		b.MouseEnter:Connect(function()
			tween(b, ti(0.15), { BackgroundColor3 = hoverColor })
		end)
		b.MouseLeave:Connect(function()
			tween(b, ti(0.25), { BackgroundColor3 = C.white })
		end)
		return b
	end
	local minBtn = iconButton("min", 1, C.white)
	local closeBtn = iconButton("close", 2, C.white)

	-- body
	local body = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER + 1),
		Size = UDim2.new(1, 0, 0, HEIGHT - (HEADER + 1)),
		Parent = window,
	}, {
		new("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),
	})

	local sidebar = new("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 168, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = body,
	}, {
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
	})
	new("Frame", {
		Position = UDim2.fromOffset(180, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = body,
	})
	local pagesHolder = new("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(196, 0),
		Size = UDim2.new(1, -196, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	Window._tabBar = sidebar
	Window._pages = pagesHolder
	Window.Active = nil

	-- toast holder
	local toasts = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(300, 600),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})
	Window._toasts = toasts

	-- show / hide / minimize
	local shown, minimized = true, false

	function Window:SetVisible(v)
		shown = v
		if v then
			window.Visible = true
			tween(scale, ti(0.5, Enum.EasingStyle.Back), { Scale = baseScale })
			tween(window, ti(0.35), { BackgroundTransparency = 0.1 })
		else
			tween(scale, ti(0.25), { Scale = baseScale * 0.92 })
			tween(window, ti(0.25), { BackgroundTransparency = 1 })
			task.delay(0.26, function()
				if not shown then
					window.Visible = false
				end
			end)
		end
	end

	function Window:Toggle()
		self:SetVisible(not shown)
	end

	function Window:SetMinimized(m)
		if m == minimized then
			return
		end
		minimized = m
		local delta = (HEIGHT - HEADER) / 2
		local p = window.Position
		if m then
			tween(window, ti(0.4), {
				Size = UDim2.fromOffset(WIDTH, HEADER),
				Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - delta),
			})
			task.delay(0.4, function()
				if minimized then
					body.Visible = false
				end
			end)
		else
			body.Visible = true
			tween(window, ti(0.4), {
				Size = UDim2.fromOffset(WIDTH, HEIGHT),
				Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + delta),
			})
		end
	end

	function Window:Destroy()
		for _, c in ipairs(self._conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		tween(scale, ti(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = baseScale * 0.85 })
		tween(window, ti(0.25), { BackgroundTransparency = 1 })
		task.delay(0.3, function()
			gui:Destroy()
		end)
	end

	function Window:Subtitle(text)
		subtitle = tostring(text or "")
		refreshSub()
		return self
	end

	function Window:SetTitle(text)
		title = tostring(text or "")
		titleLbl.Text = title
		logoLbl.Text = title:sub(1, 1):upper()
		return self
	end

	function Window:SetKeybind(key)
		toggleKey = key
		refreshSub()
	end

	minBtn.MouseButton1Click:Connect(function()
		Window:SetMinimized(not minimized)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		Window:Destroy()
	end)

	-- dragging
	local dragging, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	Window:_connect(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMove(input) then
			local d = input.Position - dragStart
			tween(window, TweenInfo.new(0.08, Enum.EasingStyle.Sine), {
				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y),
			})
		end
	end))
	Window:_connect(UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and not Window._listening and input.KeyCode == toggleKey then
			Window:Toggle()
		end
	end))
	if camera then
		Window:_connect(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			baseScale = fitScale()
			if shown then
				scale.Scale = baseScale
			end
		end))
	end

	-- custom drag helper (sliders / color bars)
	function Window:_drag(hit, onMove)
		local active = false
		hit.InputBegan:Connect(function(input)
			if isPress(input) then
				active = true
				onMove(input.Position.X)
			end
		end)
		self:_connect(UserInputService.InputChanged:Connect(function(input)
			if active and isMove(input) then
				onMove(input.Position.X)
			end
		end))
		self:_connect(UserInputService.InputEnded:Connect(function(input)
			if isPress(input) then
				active = false
			end
		end))
	end

	Window:SetVisible(true)
	return Window
end

----------------------------------------------------------------------
-- notifications
----------------------------------------------------------------------

function WindowClass:Notify(title, text, duration, color)
	if type(title) == "table" then
		local o = title
		title, text, duration, color = o.Title, o.Text or o.Content, o.Duration, o.Color
	end
	title, text = tostring(title or ""), tostring(text or "")
	duration = duration or 4
	color = color or C.accent

	local bounds = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(250, 10000))
	local h = 16 + 18 + (text ~= "" and (bounds.Y + 4) or 0) + 14

	self._toastOrder += 1
	local wrapper = new("Frame", {
		LayoutOrder = self._toastOrder,
		Size = UDim2.new(1, 0, 0, h),
		BackgroundTransparency = 1,
		Parent = self._toasts,
	})
	local card = new("Frame", {
		Position = UDim2.new(1, 40, 0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(24, 24, 27),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Parent = wrapper,
	}, { corner(14), stroke(color, 0.5) })
	new("Frame", {
		Position = UDim2.fromOffset(10, 12),
		Size = UDim2.new(0, 3, 1, -24),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = card,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	label({
		Position = UDim2.fromOffset(24, 12),
		Size = UDim2.new(1, -36, 0, 18),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	if text ~= "" then
		label({
			Position = UDim2.fromOffset(24, 32),
			Size = UDim2.new(1, -36, 0, bounds.Y),
			Text = text,
			TextSize = 12,
			TextColor3 = C.muted,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = card,
		})
	end

	tween(card, ti(0.5, Enum.EasingStyle.Back), { Position = UDim2.new(0, 0, 0, 0) })
	task.delay(duration, function()
		if wrapper.Parent then
			tween(card, ti(0.4), { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
			task.delay(0.45, function()
				wrapper:Destroy()
			end)
		end
	end)
end

----------------------------------------------------------------------
-- tabs
----------------------------------------------------------------------

function WindowClass:_styleTabs()
	for _, t in ipairs(self.Tabs) do
		local active = self.Active == t
		tween(t.Button, ti(0.25), {
			BackgroundTransparency = active and 0.92 or 1,
			TextColor3 = active and C.white or C.muted,
		})
		tween(t.Button.Bar, ti(0.3, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(3, active and 16 or 0) })
		t.Page.Visible = active
	end
end

function WindowClass:SelectTab(tab)
	if type(tab) == "string" then
		for _, t in ipairs(self.Tabs) do
			if t.Name == tab then
				tab = t
				break
			end
		end
	end
	if type(tab) ~= "table" then
		return
	end
	self.Active = tab
	self:_styleTabs()
end

function WindowClass:CreateTab(name, color)
	local tab = setmetatable({
		Name = name,
		Window = self,
		Color = color or self.Accent,
		_order = 0,
	}, TabClass)

	local b = new("TextButton", {
		LayoutOrder = #self.Tabs + 1,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		Parent = self._tabBar,
	}, {
		corner(10),
		new("UIPadding", { PaddingLeft = UDim.new(0, 16) }),
	})
	new("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -10, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Parent = b,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	b.MouseEnter:Connect(function()
		if self.Active ~= tab then
			tween(b, ti(0.15), { BackgroundTransparency = 0.95, TextColor3 = C.text })
		end
	end)
	b.MouseLeave:Connect(function()
		if self.Active ~= tab then
			tween(b, ti(0.25), { BackgroundTransparency = 1, TextColor3 = C.muted })
		end
	end)
	b.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)
	tab.Button = b
	tab.Page = new("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.white,
		ScrollBarImageTransparency = 0.7,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = self._pages,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 4) }),
	})

	table.insert(self.Tabs, tab)
	if not self.Active then
		self:SelectTab(tab)
	else
		self:_styleTabs()
	end
	return tab
end

----------------------------------------------------------------------
-- element plumbing
----------------------------------------------------------------------

local function baseRow(tab, height)
	tab._order += 1
	local wrapper = new("Frame", {
		LayoutOrder = tab._order,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = tab.Page,
	})
	local card = new("Frame", {
		Name = "Card",
		Size = height and UDim2.fromScale(1, 1) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		Parent = wrapper,
	}, { corner(10), stroke(C.white, 0.93) })
	return wrapper, card
end

local function hitButton(card, height)
	local hit = new("TextButton", {
		Name = "Hit",
		Size = height and UDim2.new(1, 0, 0, height) or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = card,
	})
	hit.MouseEnter:Connect(function()
		tween(card, ti(0.15), { BackgroundTransparency = 0.92 })
	end)
	hit.MouseLeave:Connect(function()
		tween(card, ti(0.25), { BackgroundTransparency = 0.95 })
	end)
	return hit
end

local function nameLabel(card, text, width)
	return label({
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, width or -90, 0, ROW_H),
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
end

local function decorate(obj, wrapper, nameLbl)
	function obj:SetText(t)
		if nameLbl then
			nameLbl.Text = tostring(t)
		end
	end
	function obj:SetVisible(v)
		wrapper.Visible = v
	end
	function obj:Destroy()
		wrapper:Destroy()
	end
	return obj
end

----------------------------------------------------------------------
-- elements
----------------------------------------------------------------------

function TabClass:CreateSection(name)
	self._order += 1
	local wrapper = new("Frame", {
		LayoutOrder = self._order,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = self.Page,
	})
	local lbl = label({
		Position = UDim2.fromOffset(4, 8),
		Size = UDim2.new(1, -8, 0, 14),
		Text = string.upper(name),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.muted,
		Parent = wrapper,
	})
	new("Frame", {
		Position = UDim2.new(0, 4, 1, -2),
		Size = UDim2.new(1, -8, 0, 1),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Parent = wrapper,
	})
	return decorate({}, wrapper, lbl)
end

function TabClass:CreateLabel(text)
	local wrapper, card = baseRow(self, nil)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = card,
	})
	local lbl = label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(text),
		TextWrapped = true,
		Parent = card,
	})
	return decorate({}, wrapper, lbl)
end

function TabClass:CreateParagraph(title, content)
	local wrapper, card = baseRow(self, nil)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = card,
	})
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	local t = label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = tostring(title),
		Font = Enum.Font.GothamBold,
		Parent = card,
	})
	local body = label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(content or ""),
		TextSize = 12,
		TextColor3 = C.muted,
		TextWrapped = true,
		Parent = card,
	})
	local obj = decorate({}, wrapper, t)
	function obj:SetContent(s)
		body.Text = tostring(s)
	end
	return obj
end

function TabClass:CreateButton(name, callback)
	local accent = self.Color
	local wrapper, card = baseRow(self, ROW_H)
	local nameLbl = nameLabel(card, name)
	chevron({ Rotation = -90, Position = UDim2.new(1, -24, 0, ROW_H / 2), Parent = card })
	local hit = hitButton(card)
	hit.MouseButton1Click:Connect(function()
		card.BackgroundColor3 = accent
		card.BackgroundTransparency = 0.7
		tween(card, ti(0.4), { BackgroundColor3 = C.white, BackgroundTransparency = 0.95 })
		fire(callback)
	end)
	local obj = {}
	function obj:Fire()
		fire(callback)
	end
	return decorate(obj, wrapper, nameLbl)
end

function TabClass:CreateToggle(name, default, callback)
	if type(default) == "function" then
		callback, default = default, false
	end
	local accent = self.Color
	local wrapper, card = baseRow(self, ROW_H)
	local nameLbl = nameLabel(card, name)

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = C.gray,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(11) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Parent = track,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })

	local obj = { Value = false }
	function obj:Set(v, silent)
		v = v and true or false
		self.Value = v
		tween(knob, ti(0.2, Enum.EasingStyle.Back), { Position = UDim2.new(0, v and 22 or 2, 0.5, 0) })
		tween(track, ti(0.2), {
			BackgroundColor3 = v and C.white or C.gray,
			BackgroundTransparency = v and 0.05 or 0.75,
		})
		tween(knob, ti(0.2), { BackgroundColor3 = v and Color3.fromRGB(24, 24, 27) or C.white })
		if not silent then
			fire(callback, v)
		end
	end
	function obj:Get()
		return self.Value
	end

	local hit = hitButton(card)
	hit.MouseButton1Click:Connect(function()
		obj:Set(not obj.Value)
	end)

	obj:Set(default, true)
	return decorate(obj, wrapper, nameLbl)
end

function TabClass:CreateSlider(name, min, max, default, callback, step)
	local accent = self.Color
	step = step or 1
	local decimals = #(tostring(step):match("%.(%d+)") or "")
	local function fmt(v)
		return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(v)
	end

	local wrapper, card = baseRow(self, 56)
	local nameLbl = label({
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -110, 0, 18),
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	local valueLbl = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 8),
		Size = UDim2.fromOffset(80, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.muted,
		TextSize = 12,
		Parent = card,
	})
	local track = new("Frame", {
		Position = UDim2.fromOffset(16, 36),
		Size = UDim2.new(1, -32, 0, 4),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(3) })
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Parent = track,
	}, { corner(3) })
	gradient(fill, accent, C.accent2, 0)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })

	local obj = { Value = min }
	function obj:Set(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		v = math.floor((v - min) / step + 0.5) * step + min
		v = tonumber(string.format("%." .. math.max(decimals, 0) .. "f", v))
		v = math.clamp(v, min, max)
		local changed = v ~= self.Value
		self.Value = v
		local a = (max > min) and (v - min) / (max - min) or 0
		tween(fill, ti(0.08), { Size = UDim2.fromScale(a, 1) })
		tween(knob, ti(0.08), { Position = UDim2.fromScale(a, 0.5) })
		valueLbl.Text = fmt(v)
		if changed and not silent then
			fire(callback, v)
		end
	end
	function obj:Get()
		return self.Value
	end

	local hit = new("TextButton", {
		Position = UDim2.new(0, 0, 0.5, -11),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "",
		Parent = track,
	})
	self.Window:_drag(hit, function(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		obj:Set(min + (max - min) * a)
	end)

	obj.Value = nil
	obj:Set(default or min, true)
	return decorate(obj, wrapper, nameLbl)
end

function TabClass:CreateTextbox(name, default, placeholder, callback)
	if type(default) == "function" then
		callback, default, placeholder = default, "", nil
	elseif type(placeholder) == "function" then
		callback, placeholder = placeholder, nil
	end
	local accent = self.Color
	local wrapper, card = baseRow(self, ROW_H)
	local nameLbl = nameLabel(card, name, -210)

	local wrap = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(180, 28),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(8) })
	local st = stroke(C.white, 0.85)
	st.Parent = wrap
	local box = new("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Text = default or "",
		PlaceholderText = placeholder or "Type here...",
		PlaceholderColor3 = C.muted,
		TextColor3 = C.text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = wrap,
	})
	box.Focused:Connect(function()
		tween(st, ti(0.2), { Color = accent, Transparency = 0.2 })
		tween(wrap, ti(0.2), { BackgroundTransparency = 0.85 })
	end)
	box.FocusLost:Connect(function(enter)
		tween(st, ti(0.25), { Color = C.white, Transparency = 0.85 })
		tween(wrap, ti(0.25), { BackgroundTransparency = 0.9 })
		fire(callback, box.Text, enter)
	end)

	local obj = {}
	function obj:Set(t)
		box.Text = tostring(t)
	end
	function obj:Get()
		return box.Text
	end
	return decorate(obj, wrapper, nameLbl)
end

function TabClass:CreateKeybind(name, default, callback, changed)
	if type(default) == "string" then
		default = Enum.KeyCode[default]
	elseif type(default) == "function" then
		callback, default = default, nil
	end
	local accent = self.Color
	local wrapper, card = baseRow(self, ROW_H)
	local nameLbl = nameLabel(card, name, -130)

	local pill = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.white,
		BackgroundTransparency = 0.9,
		AutoButtonColor = false,
		Text = "None",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = C.text,
		BorderSizePixel = 0,
		Parent = card,
	}, {
		corner(8),
		stroke(C.white, 0.85),
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		new("UIScale", { Name = "Press" }),
	})
	pill:SetAttribute("Idle", 0.9)
	pill:SetAttribute("Hover", 0.82)
	interactive(pill)

	local obj = { Value = nil }
	local listening = false

	function obj:Set(key, silent)
		self.Value = key
		pill.Text = key and key.Name or "None"
		if not silent then
			fire(changed, key)
		end
	end
	function obj:Get()
		return self.Value
	end

	pill.MouseButton1Click:Connect(function()
		listening = true
		self.Window._listening = true
		pill.Text = "..."
		tween(pill, ti(0.2), { BackgroundColor3 = accent })
	end)

	self.Window:_connect(UserInputService.InputBegan:Connect(function(input, gpe)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				local win = self.Window
				task.delay(0.2, function()
					win._listening = false
				end)
				tween(pill, ti(0.2), { BackgroundColor3 = C.white })
				if input.KeyCode == Enum.KeyCode.Escape then
					pill.Text = obj.Value and obj.Value.Name or "None"
				elseif input.KeyCode == Enum.KeyCode.Backspace then
					obj:Set(nil)
				else
					obj:Set(input.KeyCode)
				end
			end
			return
		end
		if not gpe and obj.Value and input.KeyCode == obj.Value then
			fire(callback, obj.Value)
		end
	end))

	obj:Set(default, true)
	return decorate(obj, wrapper, nameLbl)
end

local function buildDropdown(tab, name, options, default, callback, multi)
	local accent = tab.Color
	local wrapper, card = baseRow(tab, ROW_H)
	local nameLbl = nameLabel(card, name, -200)
	local valueLbl = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -38, 0, 0),
		Size = UDim2.fromOffset(170, ROW_H),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.muted,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	local arrow = chevron({ Position = UDim2.new(1, -22, 0, ROW_H / 2), Parent = card })
	local holder = new("ScrollingFrame", {
		Position = UDim2.fromOffset(10, ROW_H + 2),
		Size = UDim2.new(1, -20, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.white,
		ScrollBarImageTransparency = 0.7,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = card,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local hit = hitButton(card, ROW_H)

	local obj = { Options = {}, IsOpen = false }
	local selected, single, buttons = {}, nil, {}

	local function displayText()
		if multi then
			local list = {}
			for _, o in ipairs(obj.Options) do
				if selected[o] then
					list[#list + 1] = o
				end
			end
			if #list == 0 then
				return "None"
			elseif #list <= 2 then
				return table.concat(list, ", ")
			end
			return #list .. " selected"
		end
		return single or "Select..."
	end

	local function getValue()
		if multi then
			local list = {}
			for _, o in ipairs(obj.Options) do
				if selected[o] then
					list[#list + 1] = o
				end
			end
			return list
		end
		return single
	end

	local function paint()
		valueLbl.Text = displayText()
		for opt, b in pairs(buttons) do
			local on = multi and selected[opt] or (not multi and single == opt)
			tween(b, ti(0.15), { BackgroundTransparency = on and 0.82 or 0.95 })
			b.Check.Visible = on and true or false
		end
	end

	local function applySize(instant)
		local k = math.min(#obj.Options, MAX_VISIBLE)
		local h = k > 0 and (k * OPT_H + (k - 1) * 4) or 0
		holder.Size = UDim2.new(1, -20, 0, h)
		local goal = UDim2.new(1, 0, 0, obj.IsOpen and (ROW_H + 2 + h + 10) or ROW_H)
		if instant then
			wrapper.Size = goal
		else
			tween(wrapper, ti(0.3), { Size = goal })
		end
	end

	local function setOpen(v)
		obj.IsOpen = v
		tween(arrow, ti(0.25), { Rotation = v and 180 or 0 })
		applySize(false)
	end

	local function build()
		for _, b in pairs(buttons) do
			b:Destroy()
		end
		buttons = {}
		for i, opt in ipairs(obj.Options) do
			local b = new("TextButton", {
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, OPT_H),
				BackgroundColor3 = C.white,
				BackgroundTransparency = 0.94,
				AutoButtonColor = false,
				Text = opt,
				Font = Enum.Font.GothamMedium,
				TextSize = 12,
				TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0,
				Parent = holder,
			}, { corner(8), new("UIPadding", { PaddingLeft = UDim.new(0, 12) }) })
			new("Frame", {
				Name = "Check",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(6, 6),
				BackgroundColor3 = C.white,
				BorderSizePixel = 0,
				Visible = false,
				Parent = b,
			}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
			local function isOn()
				return multi and selected[opt] or (not multi and single == opt)
			end
			b.MouseEnter:Connect(function()
				tween(b, ti(0.15), { BackgroundTransparency = isOn() and 0.76 or 0.88, TextColor3 = C.white })
			end)
			b.MouseLeave:Connect(function()
				tween(b, ti(0.25), { BackgroundTransparency = isOn() and 0.82 or 0.95, TextColor3 = C.text })
			end)
			b.MouseButton1Click:Connect(function()
				if multi then
					selected[opt] = not selected[opt] or nil
					paint()
					fire(callback, getValue())
				else
					single = opt
					paint()
					fire(callback, single)
					task.delay(0.35, function()
						if obj.IsOpen then
							setOpen(false)
						end
					end)
				end
			end)
			buttons[opt] = b
		end
	end

	local function setOptions(list)
		obj.Options = {}
		for _, o in ipairs(list or {}) do
			obj.Options[#obj.Options + 1] = tostring(o)
		end
	end

	function obj:Set(v, silent)
		if multi then
			selected = {}
			for _, o in ipairs(type(v) == "table" and v or {}) do
				selected[tostring(o)] = true
			end
		else
			single = v ~= nil and tostring(v) or nil
		end
		paint()
		if not silent then
			fire(callback, getValue())
		end
	end
	function obj:Get()
		return getValue()
	end
	function obj:Refresh(list, keep)
		setOptions(list)
		local valid = {}
		for _, o in ipairs(obj.Options) do
			valid[o] = true
		end
		if keep then
			for k in pairs(selected) do
				if not valid[k] then
					selected[k] = nil
				end
			end
			if single and not valid[single] then
				single = nil
			end
		else
			selected, single = {}, nil
		end
		build()
		paint()
		applySize(true)
	end
	function obj:Open()
		setOpen(true)
	end
	function obj:Close()
		setOpen(false)
	end

	hit.MouseButton1Click:Connect(function()
		setOpen(not obj.IsOpen)
	end)

	setOptions(options)
	build()
	obj:Set(default, true)
	applySize(true)
	return decorate(obj, wrapper, nameLbl)
end

function TabClass:CreateDropdown(name, options, default, callback)
	if type(default) == "function" then
		callback, default = default, nil
	end
	return buildDropdown(self, name, options, default, callback, false)
end

function TabClass:CreateMultiDropdown(name, options, default, callback)
	if type(default) == "function" then
		callback, default = default, nil
	end
	return buildDropdown(self, name, options, default, callback, true)
end

function TabClass:CreateColorPicker(name, default, callback)
	if type(default) == "function" then
		callback, default = default, nil
	end
	default = default or C.white
	local h, s, v = default:ToHSV()

	local wrapper, card = baseRow(self, ROW_H)
	local nameLbl = nameLabel(card, name, -110)
	local swatch = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -42, 0, 12),
		Size = UDim2.fromOffset(36, 20),
		BackgroundColor3 = default,
		BorderSizePixel = 0,
		Parent = card,
	}, { corner(6), stroke(C.white, 0.7) })
	local arrow = chevron({ Position = UDim2.new(1, -22, 0, ROW_H / 2), Parent = card })
	local hit = hitButton(card, ROW_H)

	local obj = { Value = default, IsOpen = false }
	local FULL = ROW_H + 3 * 26 + 14

	local rainbow = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})

	local bars = {}
	local function makeBar(y, text, onChange)
		label({
			Position = UDim2.fromOffset(16, y - 2),
			Size = UDim2.fromOffset(30, 14),
			Text = text,
			TextSize = 11,
			TextColor3 = C.muted,
			Parent = card,
		})
		local track = new("Frame", {
			Position = UDim2.fromOffset(52, y),
			Size = UDim2.new(1, -68, 0, 10),
			BackgroundColor3 = C.white,
			BorderSizePixel = 0,
			Parent = card,
		}, { corner(5) })
		local grad = new("UIGradient", { Parent = track })
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = C.white,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(Color3.new(0, 0, 0), 0.6) })
		local barHit = new("TextButton", {
			Position = UDim2.new(0, 0, 0.5, -11),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = "",
			Parent = track,
		})
		self.Window:_drag(barHit, function(x)
			onChange(math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1))
		end)
		return { grad = grad, knob = knob }
	end

	local function refresh(silent)
		local color = Color3.fromHSV(h, s, v)
		obj.Value = color
		swatch.BackgroundColor3 = color
		bars.h.grad.Color = rainbow
		bars.s.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
		bars.v.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
		bars.h.knob.Position = UDim2.fromScale(h, 0.5)
		bars.s.knob.Position = UDim2.fromScale(s, 0.5)
		bars.v.knob.Position = UDim2.fromScale(v, 0.5)
		if not silent then
			fire(callback, color)
		end
	end

	bars.h = makeBar(ROW_H + 12, "Hue", function(a)
		h = a
		refresh()
	end)
	bars.s = makeBar(ROW_H + 38, "Sat", function(a)
		s = a
		refresh()
	end)
	bars.v = makeBar(ROW_H + 64, "Val", function(a)
		v = a
		refresh()
	end)

	function obj:Set(color, silent)
		h, s, v = color:ToHSV()
		refresh(silent)
	end
	function obj:Get()
		return self.Value
	end

	hit.MouseButton1Click:Connect(function()
		obj.IsOpen = not obj.IsOpen
		tween(arrow, ti(0.25), { Rotation = obj.IsOpen and 180 or 0 })
		tween(wrapper, ti(0.3), { Size = UDim2.new(1, 0, 0, obj.IsOpen and FULL or ROW_H) })
	end)

	refresh(true)
	return decorate(obj, wrapper, nameLbl)
end

return Library
