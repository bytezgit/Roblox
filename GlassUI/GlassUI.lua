--[[
	Universal Hub
	Module 1: ESP + Aimbot
]]

local Lib = loadstring(readfile("GlassUI.lua"))()

if not Drawing then
	warn("[Universal Hub] Your executor does not support the Drawing library.")
	return
end

if getgenv().UniversalHubUnload then
	pcall(getgenv().UniversalHubUnload)
end

----------------------------------------------------------------------
-- services
----------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local floor, max, min, abs, clamp = math.floor, math.max, math.min, math.abs, math.clamp
local BLACK = Color3.fromRGB(0, 0, 0)

----------------------------------------------------------------------
-- settings
----------------------------------------------------------------------

local S = {
	Enabled = false,
	TeamCheck = true,
	UseTeamColor = false,
	VisibleCheck = false,
	VisibleColor = Color3.fromRGB(235, 235, 240),
	HiddenColor = Color3.fromRGB(120, 120, 128),
	MaxDistance = 2000,
	Font = "UI",
	TextSize = 13,

	Box = {
		Enabled = true,
		Style = "Full",
		Color = Color3.fromRGB(255, 255, 255),
		Outline = true,
		Fill = false,
		FillOpacity = 0.15,
		CornerLength = 0.25,
	},
	Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), DisplayName = true },
	Distance = { Enabled = true, Color = Color3.fromRGB(190, 190, 198), Units = "Studs" },
	Tool = { Enabled = false, Color = Color3.fromRGB(190, 190, 198) },
	Health = {
		Bar = true,
		Text = false,
		High = Color3.fromRGB(120, 255, 160),
		Low = Color3.fromRGB(255, 90, 100),
	},
	Tracers = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Origin = "Bottom", Thickness = 1 },
	Skeleton = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1 },
	HeadDot = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Filled = false },
	Arrows = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Radius = 200, Size = 14 },
	Chams = {
		Enabled = false,
		Fill = Color3.fromRGB(255, 255, 255),
		FillTransparency = 0.6,
		Outline = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0,
		VisibleOnly = false,
	},
	Aimbot = {
		Enabled = false,
		Key = Enum.KeyCode.E,
		TeamCheck = true,
		VisibleCheck = true,
		MaxDistance = 500,
		FOV = 120,
		Smoothing = 0.25,
		Part = "Head",
		ShowFOV = true,
		FOVColor = Color3.fromRGB(255, 255, 255),
		FOVTransparency = 0.5,
	},
}

----------------------------------------------------------------------
-- drawing helpers
----------------------------------------------------------------------

local function new(class, props)
	local d = Drawing.new(class)
	for k, v in pairs(props or {}) do
		d[k] = v
	end
	return d
end

local function group(list, v)
	for i = 1, #list do
		list[i].Visible = v
	end
end

local holder
do
	local ok = pcall(function()
		holder = Instance.new("Folder")
		holder.Name = "UniversalHubChams"
		holder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok then
		holder = Instance.new("Folder")
		holder.Name = "UniversalHubChams"
		holder.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local R15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6 = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

----------------------------------------------------------------------
-- per-player object
----------------------------------------------------------------------

local objects = {}

local function createObject()
	local o = { all = {}, hidden = false, skelPairs = {}, skelTime = 0 }
	local function reg(d)
		o.all[#o.all + 1] = d
		return d
	end
	local function text()
		return reg(new("Text", { Center = true, Outline = true, OutlineColor = BLACK, Size = 13, ZIndex = 6 }))
	end

	o.BoxFill = reg(new("Square", { Filled = true, ZIndex = 1 }))
	o.BoxOutline = reg(new("Square", { Filled = false, Thickness = 3, Color = BLACK, ZIndex = 2 }))
	o.Box = reg(new("Square", { Filled = false, Thickness = 1, ZIndex = 3 }))
	o.boxGroup = { o.BoxFill, o.BoxOutline, o.Box }

	o.cl, o.clo = {}, {}
	for i = 1, 8 do
		o.clo[i] = reg(new("Line", { Thickness = 3, Color = BLACK, ZIndex = 2 }))
		o.cl[i] = reg(new("Line", { Thickness = 1, ZIndex = 3 }))
	end

	o.HealthOutline = reg(new("Square", { Filled = true, Color = BLACK, ZIndex = 2 }))
	o.HealthBar = reg(new("Square", { Filled = true, ZIndex = 3 }))
	o.HealthText = reg(new("Text", { Center = false, Outline = true, OutlineColor = BLACK, Size = 11, ZIndex = 6 }))
	o.healthGroup = { o.HealthOutline, o.HealthBar }

	o.NameText = text()
	o.DistText = text()
	o.ToolText = text()

	o.TracerOutline = reg(new("Line", { Color = BLACK, ZIndex = 2 }))
	o.Tracer = reg(new("Line", { ZIndex = 3 }))
	o.tracerGroup = { o.TracerOutline, o.Tracer }

	o.HeadOutline = reg(new("Circle", { Color = BLACK, NumSides = 24, Thickness = 3, ZIndex = 2 }))
	o.Head = reg(new("Circle", { NumSides = 24, Thickness = 1, ZIndex = 3 }))
	o.headGroup = { o.HeadOutline, o.Head }

	o.skel = {}
	for i = 1, 14 do
		o.skel[i] = reg(new("Line", { Thickness = 1, ZIndex = 3 }))
	end

	o.ArrowOutline = reg(new("Triangle", { Filled = false, Thickness = 3, Color = BLACK, ZIndex = 3 }))
	o.Arrow = reg(new("Triangle", { Filled = true, ZIndex = 4 }))
	o.arrowGroup = { o.ArrowOutline, o.Arrow }

	for _, d in ipairs(o.all) do
		d.Visible = false
	end
	return o
end

local function hide(o)
	if o.hidden then
		return
	end
	o.hidden = true
	for _, d in ipairs(o.all) do
		d.Visible = false
	end
	if o.Highlight then
		o.Highlight.Enabled = false
	end
end

local function destroyObject(o)
	for _, d in ipairs(o.all) do
		pcall(function()
			d:Remove()
		end)
	end
	if o.Highlight then
		o.Highlight:Destroy()
	end
end

----------------------------------------------------------------------
-- color picking
----------------------------------------------------------------------

local function pick(player, base, visible)
	if S.VisibleCheck then
		return visible and S.VisibleColor or S.HiddenColor
	end
	if S.UseTeamColor and player.Team then
		return player.TeamColor.Color
	end
	return base
end

----------------------------------------------------------------------
-- update
----------------------------------------------------------------------

local function setCorners(o, x, y, w, h, l, color, outline)
	local corners = {
		{ x, y, 1, 1 },
		{ x + w, y, -1, 1 },
		{ x, y + h, 1, -1 },
		{ x + w, y + h, -1, -1 },
	}
	for i, c in ipairs(corners) do
		local cx, cy, dx, dy = c[1], c[2], c[3], c[4]
		local hi, vi = i * 2 - 1, i * 2

		local hl, vl = o.cl[hi], o.cl[vi]
		hl.From, hl.To = Vector2.new(cx, cy), Vector2.new(cx + dx * l, cy)
		vl.From, vl.To = Vector2.new(cx, cy), Vector2.new(cx, cy + dy * l)
		hl.Color, vl.Color = color, color
		hl.Visible, vl.Visible = true, true

		local ho, vo = o.clo[hi], o.clo[vi]
		ho.From, ho.To = Vector2.new(cx - dx, cy), Vector2.new(cx + dx * (l + 1), cy)
		vo.From, vo.To = Vector2.new(cx, cy - dy), Vector2.new(cx, cy + dy * (l + 1))
		ho.Visible, vo.Visible = outline, outline
	end
end

local function update(player, o, camera, vp, camPos)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local head = char and char:FindFirstChild("Head")

	if not (hum and root and head) or hum.Health <= 0 then
		return hide(o)
	end
	if S.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
		return hide(o)
	end

	local dist = (camPos - root.Position).Magnitude
	if dist > S.MaxDistance then
		return hide(o)
	end
	o.hidden = false

	-- visibility
	local visible = true
	if S.VisibleCheck then
		local now = os.clock()
		if now - (o.lastRay or 0) > 0.05 then
			o.lastRay = now
			rayParams.FilterDescendantsInstances = { LocalPlayer.Character, char }
			o.visible = Workspace:Raycast(camPos, head.Position - camPos, rayParams) == nil
		end
		visible = o.visible ~= false
	end

	-- projection
	local hip = hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight
	local topPos = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0)
	local botPos = root.Position - Vector3.new(0, root.Size.Y / 2 + hip, 0)
	local top = camera:WorldToViewportPoint(topPos)
	local bot = camera:WorldToViewportPoint(botPos)
	local front = top.Z > 0 and bot.Z > 0

	local bx, by, w, h, cx
	if front then
		h = floor(abs(bot.Y - top.Y) + 0.5)
		if h % 2 == 1 then
			h += 1
		end
		w = floor(h * 0.55 + 0.5)
		if w % 2 == 1 then
			w += 1
		end
		w, h = max(w, 4), max(h, 4)
		bx = floor((top.X + bot.X) / 2 - w / 2 + 0.5)
		by = floor(min(top.Y, bot.Y) + 0.5)
		cx = bx + w / 2
	end

	local fontId = Drawing.Fonts[S.Font] or Drawing.Fonts.UI
	local size = S.TextSize

	-- box
	local boxColor = pick(player, S.Box.Color, visible)
	local showBox = front and S.Box.Enabled
	if showBox and S.Box.Style == "Full" then
		local pos, sz = Vector2.new(bx, by), Vector2.new(w, h)
		o.Box.Position, o.Box.Size, o.Box.Color, o.Box.Visible = pos, sz, boxColor, true
		o.BoxOutline.Position, o.BoxOutline.Size, o.BoxOutline.Visible = pos, sz, S.Box.Outline
		group(o.cl, false)
		group(o.clo, false)
	elseif showBox then
		o.Box.Visible, o.BoxOutline.Visible = false, false
		local l = max(4, floor(min(w, h) * S.Box.CornerLength + 0.5))
		setCorners(o, bx, by, w, h, l, boxColor, S.Box.Outline)
	else
		group(o.boxGroup, false)
		group(o.cl, false)
		group(o.clo, false)
	end
	if showBox and S.Box.Fill then
		o.BoxFill.Position, o.BoxFill.Size = Vector2.new(bx, by), Vector2.new(w, h)
		o.BoxFill.Color, o.BoxFill.Transparency, o.BoxFill.Visible = boxColor, S.Box.FillOpacity, true
	else
		o.BoxFill.Visible = false
	end

	-- health
	local hp = clamp(hum.Health / max(hum.MaxHealth, 1), 0, 1)
	local fillH = floor(h and (h * hp + 0.5) or 0)
	if front and S.Health.Bar then
		o.HealthOutline.Position, o.HealthOutline.Size = Vector2.new(bx - 7, by - 1), Vector2.new(4, h + 2)
		o.HealthBar.Position, o.HealthBar.Size = Vector2.new(bx - 6, by + h - fillH), Vector2.new(2, fillH)
		o.HealthBar.Color = S.Health.Low:Lerp(S.Health.High, hp)
		group(o.healthGroup, true)
	else
		group(o.healthGroup, false)
	end
	if front and S.Health.Text then
		local t = o.HealthText
		t.Text, t.Font, t.Size, t.Color = tostring(floor(hum.Health)), fontId, max(size - 2, 8), S.Health.High:Lerp(S.Health.Low, 1 - hp)
		local tb = t.TextBounds
		local off = S.Health.Bar and 10 or 4
		t.Position = Vector2.new(bx - off - tb.X, clamp(by + h - fillH - floor(tb.Y / 2), by - 2, by + h - tb.Y + 2))
		t.Visible = true
	else
		o.HealthText.Visible = false
	end

	-- name
	if front and S.Name.Enabled then
		local t = o.NameText
		t.Text = S.Name.DisplayName and player.DisplayName or player.Name
		t.Font, t.Size, t.Color = fontId, size, S.Name.Color
		t.Position = Vector2.new(cx, by - size - 3)
		t.Visible = true
	else
		o.NameText.Visible = false
	end

	-- distance / tool (stacked below the box)
	local y = front and (by + h + 3) or 0
	if front and S.Distance.Enabled then
		local t = o.DistText
		local n = S.Distance.Units == "Meters" and floor(dist * 0.28) or floor(dist)
		t.Text = "[" .. n .. (S.Distance.Units == "Meters" and "m" or " studs") .. "]"
		t.Font, t.Size, t.Color = fontId, size, S.Distance.Color
		t.Position = Vector2.new(cx, y)
		t.Visible = true
		y += size + 1
	else
		o.DistText.Visible = false
	end
	local tool = char:FindFirstChildOfClass("Tool")
	if front and S.Tool.Enabled and tool then
		local t = o.ToolText
		t.Text = tool.Name
		t.Font, t.Size, t.Color = fontId, size, S.Tool.Color
		t.Position = Vector2.new(cx, y)
		t.Visible = true
	else
		o.ToolText.Visible = false
	end

	-- tracer
	if front and S.Tracers.Enabled then
		local origin
		local mode = S.Tracers.Origin
		if mode == "Center" then
			origin = Vector2.new(floor(vp.X / 2), floor(vp.Y / 2))
		elseif mode == "Top" then
			origin = Vector2.new(floor(vp.X / 2), 0)
		elseif mode == "Mouse" then
			local m = UserInputService:GetMouseLocation()
			origin = Vector2.new(floor(m.X), floor(m.Y))
		else
			origin = Vector2.new(floor(vp.X / 2), floor(vp.Y))
		end
		local target = Vector2.new(cx, by + h)
		o.TracerOutline.From, o.TracerOutline.To = origin, target
		o.TracerOutline.Thickness = S.Tracers.Thickness + 2
		o.Tracer.From, o.Tracer.To = origin, target
		o.Tracer.Thickness = S.Tracers.Thickness
		o.Tracer.Color = pick(player, S.Tracers.Color, visible)
		group(o.tracerGroup, true)
	else
		group(o.tracerGroup, false)
	end

	-- head dot
	local hp3 = camera:WorldToViewportPoint(head.Position)
	if S.HeadDot.Enabled and hp3.Z > 0 then
		local up = camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2, 0))
		local r = max(2, floor(abs(up.Y - hp3.Y) + 0.5))
		local p = Vector2.new(floor(hp3.X + 0.5), floor(hp3.Y + 0.5))
		o.Head.Position, o.Head.Radius, o.Head.Filled = p, r, S.HeadDot.Filled
		o.Head.Color = pick(player, S.HeadDot.Color, visible)
		o.HeadOutline.Position, o.HeadOutline.Radius = p, r
		group(o.headGroup, true)
	else
		group(o.headGroup, false)
	end

	-- skeleton
	if S.Skeleton.Enabled then
		if o.skelChar ~= char or os.clock() - o.skelTime > 1 then
			o.skelChar, o.skelTime, o.skelPairs = char, os.clock(), {}
			for _, d in ipairs(hum.RigType == Enum.HumanoidRigType.R6 and R6 or R15) do
				local a, b = char:FindFirstChild(d[1]), char:FindFirstChild(d[2])
				if a and b then
					o.skelPairs[#o.skelPairs + 1] = { a, b }
				end
			end
		end
		local color = pick(player, S.Skeleton.Color, visible)
		for i = 1, 14 do
			local line, pair = o.skel[i], o.skelPairs[i]
			local shown = false
			if pair and pair[1].Parent and pair[2].Parent then
				local pa = camera:WorldToViewportPoint(pair[1].Position)
				local pb = camera:WorldToViewportPoint(pair[2].Position)
				if pa.Z > 0 and pb.Z > 0 then
					line.From = Vector2.new(floor(pa.X + 0.5), floor(pa.Y + 0.5))
					line.To = Vector2.new(floor(pb.X + 0.5), floor(pb.Y + 0.5))
					line.Color, line.Thickness = color, S.Skeleton.Thickness
					shown = true
				end
			end
			line.Visible = shown
		end
	else
		group(o.skel, false)
	end

	-- off-screen arrow
	local inView = front and cx >= 0 and cx <= vp.X and by + h / 2 >= 0 and by + h / 2 <= vp.Y
	if S.Arrows.Enabled and not inView then
		local rel = camera.CFrame:PointToObjectSpace(root.Position)
		local dir = Vector2.new(rel.X, -rel.Y)
		dir = dir.Magnitude > 1e-4 and dir.Unit or Vector2.new(0, 1)
		local perp = Vector2.new(-dir.Y, dir.X)
		local pos = Vector2.new(floor(vp.X / 2), floor(vp.Y / 2)) + dir * S.Arrows.Radius
		local s = S.Arrows.Size
		local function snap(v)
			return Vector2.new(floor(v.X + 0.5), floor(v.Y + 0.5))
		end
		local a = snap(pos + dir * s)
		local b = snap(pos - dir * s * 0.6 + perp * s * 0.7)
		local c = snap(pos - dir * s * 0.6 - perp * s * 0.7)
		o.Arrow.PointA, o.Arrow.PointB, o.Arrow.PointC = a, b, c
		o.ArrowOutline.PointA, o.ArrowOutline.PointB, o.ArrowOutline.PointC = a, b, c
		o.Arrow.Color = pick(player, S.Arrows.Color, visible)
		group(o.arrowGroup, true)
	else
		group(o.arrowGroup, false)
	end

	-- chams
	if S.Chams.Enabled then
		local hl = o.Highlight
		if not hl then
			hl = Instance.new("Highlight")
			hl.Parent = holder
			o.Highlight = hl
		end
		if hl.Adornee ~= char then
			hl.Adornee = char
		end
		hl.FillColor = pick(player, S.Chams.Fill, visible)
		hl.OutlineColor = pick(player, S.Chams.Outline, visible)
		hl.FillTransparency = S.Chams.FillTransparency
		hl.OutlineTransparency = S.Chams.OutlineTransparency
		hl.DepthMode = S.Chams.VisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
		hl.Enabled = true
	elseif o.Highlight then
		o.Highlight.Enabled = false
	end
end

----------------------------------------------------------------------
-- players + render loop
----------------------------------------------------------------------

local connections = {}

local function addPlayer(p)
	if p ~= LocalPlayer and not objects[p] then
		objects[p] = createObject()
	end
end

local function removePlayer(p)
	if objects[p] then
		destroyObject(objects[p])
		objects[p] = nil
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	addPlayer(p)
end
table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
table.insert(connections, Players.PlayerRemoving:Connect(removePlayer))

table.insert(connections, RunService.RenderStepped:Connect(function()
	if not S.Enabled then
		for _, o in pairs(objects) do
			hide(o)
		end
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local vp, camPos = camera.ViewportSize, camera.CFrame.Position
	for p, o in pairs(objects) do
		local ok, err = pcall(update, p, o, camera, vp, camPos)
		if not ok then
			warn("[Universal Hub] ESP error: " .. tostring(err))
		end
	end
end))

----------------------------------------------------------------------
-- aimbot
----------------------------------------------------------------------

local aimbotFOV = new("Circle", {
	Visible = false,
	Thickness = 1,
	NumSides = 64,
	Color = Color3.fromRGB(255, 255, 255),
	Transparency = 0.5,
	Filled = false,
	ZIndex = 2,
})

local aimbotConnection = nil

local function findAimbotTarget(camera, vp, camPos)
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local fovRadius = S.Aimbot.FOV / 2
	local best, bestDist = nil, math.huge

	rayParams.FilterDescendantsInstances = { LocalPlayer.Character }

	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then
			continue
		end
		if S.Aimbot.TeamCheck and p.Team and p.Team == LocalPlayer.Team then
			continue
		end

		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local part = char and char:FindFirstChild(S.Aimbot.Part)
		if not (hum and part) or hum.Health <= 0 then
			continue
		end

		local dist = (camPos - part.Position).Magnitude
		if dist > S.Aimbot.MaxDistance then
			continue
		end

		local sp = camera:WorldToViewportPoint(part.Position)
		if sp.Z <= 0 then
			continue
		end

		local screenDist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
		if screenDist > fovRadius then
			continue
		end

		if S.Aimbot.VisibleCheck then
			rayParams.FilterDescendantsInstances = { LocalPlayer.Character, char }
			if Workspace:Raycast(camPos, part.Position - camPos, rayParams) then
				continue
			end
		end

		if screenDist < bestDist then
			best, bestDist = part, screenDist
		end
	end

	return best, center
end

table.insert(connections, RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)

	-- FOV circle
	if S.Aimbot.Enabled and S.Aimbot.ShowFOV then
		aimbotFOV.Position = center
		aimbotFOV.Radius = S.Aimbot.FOV / 2
		aimbotFOV.Color = S.Aimbot.FOVColor
		aimbotFOV.Transparency = S.Aimbot.FOVTransparency
		aimbotFOV.Visible = true
	else
		aimbotFOV.Visible = false
	end

	-- aim logic (only when enabled + key held + not typing)
	if not S.Aimbot.Enabled then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end

	local keyDown = S.Aimbot.Key and UserInputService:IsKeyDown(S.Aimbot.Key)
	if not keyDown then
		return
	end

	local camPos = camera.CFrame.Position
	local target = findAimbotTarget(camera, vp, camPos)
	if not target then
		return
	end

	local targetCFrame = CFrame.new(camera.CFrame.Position, target.Position)
	local alpha = clamp(S.Aimbot.Smoothing, 0, 1)
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, alpha)
end))

----------------------------------------------------------------------
-- gui
----------------------------------------------------------------------

local Window = Lib:CreateWindow({
	Title = "Universal Hub",
	Name = "UniversalHub",
})

local function toggle(tab, name, tbl, key, cb)
	return tab:CreateToggle(name, tbl[key], function(v)
		tbl[key] = v
		if cb then
			cb(v)
		end
	end)
end
local function slider(tab, name, lo, hi, tbl, key, step)
	return tab:CreateSlider(name, lo, hi, tbl[key], function(v)
		tbl[key] = v
	end, step)
end
local function color(tab, name, tbl, key)
	return tab:CreateColorPicker(name, tbl[key], function(c)
		tbl[key] = c
	end)
end
local function dropdown(tab, name, options, tbl, key)
	return tab:CreateDropdown(name, options, tbl[key], function(v)
		tbl[key] = v
	end)
end

local ESP = Window:CreateTab("ESP")

ESP:CreateSection("General")
toggle(ESP, "Enable ESP", S, "Enabled")
toggle(ESP, "Team check", S, "TeamCheck")
toggle(ESP, "Use team colors", S, "UseTeamColor")
toggle(ESP, "Visible check", S, "VisibleCheck")
color(ESP, "Visible color", S, "VisibleColor")
color(ESP, "Hidden color", S, "HiddenColor")
slider(ESP, "Max distance", 100, 10000, S, "MaxDistance", 50)

ESP:CreateSection("Box")
toggle(ESP, "Box", S.Box, "Enabled")
dropdown(ESP, "Box style", { "Full", "Corner" }, S.Box, "Style")
color(ESP, "Box color", S.Box, "Color")
toggle(ESP, "Box outline", S.Box, "Outline")
slider(ESP, "Corner length", 0.1, 0.5, S.Box, "CornerLength", 0.05)
toggle(ESP, "Box fill", S.Box, "Fill")
slider(ESP, "Fill opacity", 0, 1, S.Box, "FillOpacity", 0.05)

ESP:CreateSection("Info")
toggle(ESP, "Names", S.Name, "Enabled")
toggle(ESP, "Use display names", S.Name, "DisplayName")
color(ESP, "Name color", S.Name, "Color")
toggle(ESP, "Distance", S.Distance, "Enabled")
dropdown(ESP, "Distance units", { "Studs", "Meters" }, S.Distance, "Units")
color(ESP, "Distance color", S.Distance, "Color")
toggle(ESP, "Held tool", S.Tool, "Enabled")
color(ESP, "Tool color", S.Tool, "Color")

ESP:CreateSection("Health")
toggle(ESP, "Health bar", S.Health, "Bar")
toggle(ESP, "Health text", S.Health, "Text")
color(ESP, "Full health color", S.Health, "High")
color(ESP, "Low health color", S.Health, "Low")

ESP:CreateSection("Tracers")
toggle(ESP, "Tracers", S.Tracers, "Enabled")
dropdown(ESP, "Tracer origin", { "Bottom", "Center", "Top", "Mouse" }, S.Tracers, "Origin")
color(ESP, "Tracer color", S.Tracers, "Color")
slider(ESP, "Tracer thickness", 1, 3, S.Tracers, "Thickness", 1)

ESP:CreateSection("Skeleton")
toggle(ESP, "Skeleton", S.Skeleton, "Enabled")
color(ESP, "Skeleton color", S.Skeleton, "Color")
slider(ESP, "Skeleton thickness", 1, 3, S.Skeleton, "Thickness", 1)

ESP:CreateSection("Head dot")
toggle(ESP, "Head dot", S.HeadDot, "Enabled")
toggle(ESP, "Filled", S.HeadDot, "Filled")
color(ESP, "Head dot color", S.HeadDot, "Color")

ESP:CreateSection("Off-screen arrows")
toggle(ESP, "Arrows", S.Arrows, "Enabled")
color(ESP, "Arrow color", S.Arrows, "Color")
slider(ESP, "Arrow radius", 50, 500, S.Arrows, "Radius", 5)
slider(ESP, "Arrow size", 8, 30, S.Arrows, "Size", 1)

ESP:CreateSection("Chams")
toggle(ESP, "Chams", S.Chams, "Enabled")
color(ESP, "Fill color", S.Chams, "Fill")
slider(ESP, "Fill transparency", 0, 1, S.Chams, "FillTransparency", 0.05)
color(ESP, "Outline color", S.Chams, "Outline")
slider(ESP, "Outline transparency", 0, 1, S.Chams, "OutlineTransparency", 0.05)
toggle(ESP, "Visible only", S.Chams, "VisibleOnly")

ESP:CreateSection("Text")
dropdown(ESP, "Font", { "UI", "System", "Plex", "Monospace" }, S, "Font")
slider(ESP, "Text size", 10, 24, S, "TextSize", 1)

----------------------------------------------------------------------
-- aimbot tab
----------------------------------------------------------------------

local Aimbot = Window:CreateTab("Aimbot")

Aimbot:CreateSection("General")
toggle(Aimbot, "Enable aimbot", S.Aimbot, "Enabled")
toggle(Aimbot, "Team check", S.Aimbot, "TeamCheck")
toggle(Aimbot, "Visible check", S.Aimbot, "VisibleCheck")
dropdown(Aimbot, "Target part", { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }, S.Aimbot, "Part")
slider(Aimbot, "Max distance", 50, 2000, S.Aimbot, "MaxDistance", 25)
Aimbot:CreateKeybind("Aim key", S.Aimbot.Key, function() end, function(key)
	S.Aimbot.Key = key
end)

Aimbot:CreateSection("FOV")
slider(Aimbot, "FOV radius", 20, 400, S.Aimbot, "FOV", 5)
toggle(Aimbot, "Show FOV circle", S.Aimbot, "ShowFOV")
color(Aimbot, "FOV color", S.Aimbot, "FOVColor")
slider(Aimbot, "FOV transparency", 0, 1, S.Aimbot, "FOVTransparency", 0.05)

Aimbot:CreateSection("Smoothing")
slider(Aimbot, "Smoothing", 0.05, 1, S.Aimbot, "Smoothing", 0.05)
Aimbot:CreateLabel("Lower = snappier. Higher = smoother.")

----------------------------------------------------------------------
-- settings tab
----------------------------------------------------------------------

local Settings = Window:CreateTab("Settings")
Settings:CreateSection("Menu")
Settings:CreateKeybind("Menu key", Enum.KeyCode.RightShift, function() end, function(key)
	if key then
		Window:SetKeybind(key)
	end
end)

local function unload()
	if aimbotConnection then
		pcall(function()
			aimbotConnection:Disconnect()
		end)
		aimbotConnection = nil
	end
	pcall(function()
		aimbotFOV:Remove()
	end)
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	for p in pairs(objects) do
		removePlayer(p)
	end
	pcall(function()
		holder:Destroy()
	end)
	pcall(function()
		Window:Destroy()
	end)
	getgenv().UniversalHubUnload = nil
end
getgenv().UniversalHubUnload = unload

Settings:CreateButton("Unload hub", unload)

----------------------------------------------------------------------
-- load notification
----------------------------------------------------------------------

task.defer(function()
	Window:Notify("Universal Hub", "Loaded successfully. ESP and Aimbot are ready.", 4)
end)
