local Lib = loadstring(readfile("GlassUI.lua"))()

local Window = Lib:CreateWindow("My Hub")
Window:Subtitle("v1.0")

local Main = Window:CreateTab("Main")
local Visuals = Window:CreateTab("Visuals", Lib.Colors.green)
local Settings = Window:CreateTab("Settings", Lib.Colors.amber)

Main:CreateSection("Basics")

Main:CreateToggle("God mode", false, function(on)
	print("God mode", on)
end)

Main:CreateButton("Say hi", function()
	Window:Notify("Hello", "Button was clicked", 3, Lib.Colors.green)
end)

Main:CreateSlider("Walk speed", 16, 200, 16, function(v)
	print("Speed", v)
end)

Main:CreateSlider("Gravity", 0, 2, 1, function(v)
	print("Gravity", v)
end, 0.1)

Main:CreateSection("Selection")

Main:CreateDropdown("Mode", { "Easy", "Normal", "Hard" }, "Normal", function(v)
	print("Mode", v)
end)

Main:CreateMultiDropdown("Targets", { "Players", "NPCs", "Items", "Chests" }, { "Players" }, function(list)
	print("Targets", table.concat(list, ", "))
end)

Visuals:CreateColorPicker("Accent color", Color3.fromRGB(110, 168, 255), function(c)
	print("Color", c)
end)

Visuals:CreateParagraph("Info", "Paragraphs wrap automatically and grow with their content.")

Settings:CreateTextbox("Name", "", "Enter name…", function(text, enter)
	print("Name", text, enter)
end)

Settings:CreateKeybind("Menu key", Enum.KeyCode.RightShift, function() end, function(key)
	if key then
		Window:SetKeybind(key)
	end
end)

Settings:CreateLabel("Plain text label.")

Window:Notify("Loaded", "GlassUI ready", 4)
