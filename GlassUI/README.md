# GlassUI

A clean, dark, glass-style UI library for Roblox. Sidebar tabs, smooth animations, and all the elements you'd normally need: buttons, toggles, sliders, dropdowns, multi dropdowns, textboxes, keybinds, color pickers, labels, paragraphs and notifications.

This README walks through everything from "I just downloaded this" to "I know every function it has". Read it top to bottom once and you'll be set.

---

## Table of contents

1. [What you get](#1-what-you-get)
2. [Loading the library](#2-loading-the-library)
3. [Your first window](#3-your-first-window)
4. [Window options](#4-window-options)
5. [Window functions](#5-window-functions)
6. [Tabs](#6-tabs)
7. [Elements](#7-elements)
   - [Section](#section)
   - [Label](#label)
   - [Paragraph](#paragraph)
   - [Button](#button)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [Textbox](#textbox)
   - [Keybind](#keybind)
   - [Dropdown](#dropdown)
   - [Multi dropdown](#multi-dropdown)
   - [Color picker](#color-picker)
8. [Notifications](#8-notifications)
9. [Things every element can do](#9-things-every-element-can-do)
10. [Colors](#10-colors)
11. [Full example](#11-full-example)
12. [Tips and good habits](#12-tips-and-good-habits)
13. [Troubleshooting](#13-troubleshooting)
14. [Quick reference cheat sheet](#14-quick-reference-cheat-sheet)

---

## 1. What you get

Two files:

| File | What it is |
| --- | --- |
| `GlassUI.lua` | The library itself. This is the only file you actually need. |
| `example.lua` | A small script that uses most of the features. Great for copy-pasting from. |

Features at a glance:

- Draggable window with a minimize button, a close button, and a toggle key
- Left sidebar with as many tabs as you want
- Smooth hover and press animations everywhere
- Notifications that slide in from the bottom right
- Automatically scales down on small screens
- No external dependencies, no images, no weird unicode characters (everything is drawn with shapes so you never get a blank square)

---

## 2. Loading the library

The library is a single Lua file that returns a table. How you load it depends on where you keep it.

**From your executor's workspace folder** (put `GlassUI.lua` in there):

```lua
local Lib = loadstring(readfile("GlassUI.lua"))()
```

**From a URL** (GitHub raw link, your own host, whatever):

```lua
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bytezgit/Roblox/refs/heads/main/GlassUI/GlassUI.lua"))()
```

**Pasted straight into your script:** just paste the whole file at the top, and replace the final `return Library` with `local Lib = Library`.

From now on in this README, `Lib` means the loaded library.

> The library tries to put its GUI in `gethui()` first, then `CoreGui`, and falls back to `PlayerGui` if neither is available. That means it works on basically any executor, and it still works in plain Studio testing (it just ends up in PlayerGui).

---

## 3. Your first window

This is the smallest thing that does something:

```lua
local Lib = loadstring(readfile("GlassUI.lua"))()

local Window = Lib:CreateWindow("My Hub")
local Tab = Window:CreateTab("Main")

Tab:CreateButton("Say hello", function()
	print("hello")
end)
```

Run that and you get a window titled "My Hub" with one tab and one button. Press **RightShift** to hide and show it. Drag the top bar to move it around.

Here's what's going on:

1. `Lib:CreateWindow("My Hub")` makes the window and returns a **Window object**.
2. `Window:CreateTab("Main")` adds a tab to the sidebar and returns a **Tab object**.
3. `Tab:CreateButton(...)` adds an element to that tab.

Everything in the library follows this pattern: **Library makes Windows, Windows make Tabs, Tabs make Elements.**

> Important: call functions with a colon, not a dot. `Window:CreateTab("x")`, not `Window.CreateTab("x")`.

---

## 4. Window options

`CreateWindow` takes either a plain string (the title) or a table with options.

```lua
local Window = Lib:CreateWindow({
	Title = "My Hub",
	Subtitle = "v1.0",
	Width = 820,
	Height = 620,
	Keybind = Enum.KeyCode.RightShift,
	Name = "MyHubGui",
	Accent = Lib.Colors.white,
})
```

| Option | Type | Default | What it does |
| --- | --- | --- | --- |
| `Title` | string | `"Window"` | The big text at the top. The first letter is also used for the little logo badge. |
| `Subtitle` | string | `""` | The small gray text under the title. |
| `Width` | number | `820` | Window width in pixels. |
| `Height` | number | `620` | Window height in pixels. |
| `Keybind` | `Enum.KeyCode` | `RightShift` | The key that shows and hides the window. |
| `Name` | string | `"GlassUI"` | The name of the ScreenGui. If a GUI with this name already exists, it gets removed first, so re-running your script doesn't stack windows. |
| `Accent` | Color3 | white | The default accent color for tabs. Almost always fine to leave alone. |

You don't have to use a table at all. This works too, and is how most people will use it:

```lua
local Window = Lib:CreateWindow("My Hub")
Window:Subtitle("v1.0")
```

The subtitle line always shows your toggle key after it, for example `v1.0 | RightShift to toggle`, so users never forget how to bring the menu back.

If the player's screen is smaller than the window, the whole thing scales down automatically so it always fits.

---

## 5. Window functions

Once you have a Window object, these are the things you can do with it.

### `Window:Subtitle(text)`
Changes the small text under the title.

```lua
Window:Subtitle("Connected")
```

### `Window:SetTitle(text)`
Changes the title (and the logo letter).

```lua
Window:SetTitle("Better Hub")
```

### `Window:SetKeybind(keyCode)`
Changes the key that toggles the window. The subtitle updates itself.

```lua
Window:SetKeybind(Enum.KeyCode.Insert)
```

### `Window:Toggle()`
Shows the window if it's hidden, hides it if it's showing.

### `Window:SetVisible(bool)`
Forces it shown (`true`) or hidden (`false`) with the open/close animation.

```lua
Window:SetVisible(false)
```

### `Window:SetMinimized(bool)`
Rolls the window up to just its header (`true`) or back down (`false`). Same thing the minimize button does.

### `Window:SelectTab(tabOrName)`
Switches to a tab. Pass the tab object or its name as a string.

```lua
Window:SelectTab("Settings")
```

### `Window:Notify(title, text, duration, color)`
Pops up a notification. Covered fully in [section 8](#8-notifications).

### `Window:Destroy()`
Closes the window with an animation and disconnects everything the library connected. This is also what the X button does. Use it when your script unloads.

### Extra properties
- `Window.Gui` is the ScreenGui.
- `Window.Frame` is the main window frame.
- `Window.Tabs` is a list of all tab objects.

---

## 6. Tabs

Tabs show up in the sidebar on the left. The first tab you create is selected automatically.

```lua
local Main = Window:CreateTab("Main")
local Visuals = Window:CreateTab("Visuals")
local Settings = Window:CreateTab("Settings")
```

`CreateTab(name, color)` also accepts an optional second argument, a Color3, that tints a few small details inside that tab (the slider fill, the focus outline on textboxes, the button press flash, and the keybind "listening" highlight). The default is a clean white and honestly looks best, so most of the time you can skip it.

```lua
local Visuals = Window:CreateTab("Visuals", Color3.fromRGB(220, 220, 230))
```

Each tab has its own scrolling page. Elements are added from top to bottom in the order you create them, so write your script in the order you want things to appear.

If you have a lot of tabs, the sidebar scrolls.

---

## 7. Elements

Elements are the actual controls. You create them on a **Tab object**. Every `Create...` function returns an object you can keep and use later (to read values, change them, hide them, etc.).

A rule that holds for everything: **default values never trigger your callback when the element is created.** Callbacks only fire when the user interacts, or when *you* call `Set` without the `silent` flag.

### Section

A small label with a thin line under it, for grouping things.

```lua
Main:CreateSection("Movement")
```

Returns an object with `SetText`, `SetVisible`, `Destroy`.

---

### Label

A line of plain text. It wraps and grows automatically if it's long.

```lua
local info = Main:CreateLabel("Everything here is optional.")

info:SetText("Updated text!")
```

---

### Paragraph

Like a label, but with a bold title and a smaller gray body underneath. Good for explanations or changelogs.

```lua
local p = Main:CreateParagraph("How it works", "Pick a mode below, then flip the toggle to start.")

p:SetText("New title")
p:SetContent("New body text")
```

---

### Button

Runs a function when clicked. The button flashes briefly when pressed.

```lua
local btn = Main:CreateButton("Rejoin", function()
	print("Rejoining...")
end)
```

Extra function:

- `btn:Fire()` runs the callback from code, as if the user clicked it.

---

### Toggle

An on/off switch.

```lua
local godMode = Main:CreateToggle("God mode", false, function(enabled)
	print("God mode is now", enabled)
end)
```

Arguments: `CreateToggle(name, default, callback)`

- `name` (string): the label.
- `default` (boolean): starting state. Defaults to `false`. You can skip it and write `CreateToggle("Name", callback)`.
- `callback(enabled)`: called with `true` or `false` every time it changes.

Functions:

```lua
godMode:Set(true)          -- turn on and fire the callback
godMode:Set(true, true)    -- turn on silently (no callback)
print(godMode:Get())       -- true / false
print(godMode.Value)       -- same thing
```

---

### Slider

Drag to pick a number in a range.

```lua
local speed = Main:CreateSlider("Walk speed", 16, 200, 16, function(value)
	print("Speed:", value)
end)
```

Arguments: `CreateSlider(name, min, max, default, callback, step)`

- `min` / `max`: the range.
- `default`: the starting value.
- `callback(value)`: fires only when the value actually changes, so dragging in place won't spam it.
- `step` (optional): how much the value jumps. Defaults to `1`.

The step also decides how many decimals are shown. A step of `0.1` shows one decimal place, `0.01` shows two, `5` makes it jump in fives.

```lua
Main:CreateSlider("Gravity", 0, 2, 1, function(v) print(v) end, 0.1)
Main:CreateSlider("Distance", 0, 500, 100, function(v) print(v) end, 5)
```

Functions:

```lua
speed:Set(100)          -- move it and fire the callback
speed:Set(100, true)    -- move it silently
print(speed:Get())
```

Values you pass to `Set` are clamped to the range and rounded to the step automatically.

---

### Textbox

A single-line input.

```lua
local nameBox = Main:CreateTextbox("Username", "", "Type a name...", function(text, enterPressed)
	print("Typed:", text, "Enter?", enterPressed)
end)
```

Arguments: `CreateTextbox(name, default, placeholder, callback)`

- `default`: text already in the box.
- `placeholder`: the faded hint text when empty.
- `callback(text, enterPressed)`: fires when the user **clicks away or presses Enter** (not on every keystroke). The second value tells you if they pressed Enter.

Shorter forms work too:

```lua
Main:CreateTextbox("Name", function(text) print(text) end)
```

Functions:

```lua
nameBox:Set("Bob")
print(nameBox:Get())
```

---

### Keybind

Lets the user pick a key.

```lua
local aimKey = Main:CreateKeybind("Aim key", Enum.KeyCode.E, function(key)
	print("Pressed", key.Name)
end, function(newKey)
	print("Rebound to", newKey and newKey.Name or "nothing")
end)
```

Arguments: `CreateKeybind(name, default, onPress, onChanged)`

- `default`: an `Enum.KeyCode`, or a string like `"E"`. Use `nil` for no key.
- `onPress(key)`: fires when the user presses the bound key during normal play (not while typing in a textbox, not while rebinding).
- `onChanged(key)`: fires when the user picks a new key. `key` is `nil` if they cleared it.

How the user interacts with it:

1. Click the key button. It shows `...`.
2. Press any keyboard key to bind it.
3. Press **Escape** to cancel and keep the old key.
4. Press **Backspace** to clear the bind (shows `None`).

Functions:

```lua
aimKey:Set(Enum.KeyCode.Q)         -- rebinds and fires onChanged
aimKey:Set(Enum.KeyCode.Q, true)   -- rebinds silently
print(aimKey:Get())                -- the KeyCode, or nil
```

**Rebinding the menu key.** This is a really common use, and it works out of the box:

```lua
Settings:CreateKeybind("Menu key", Enum.KeyCode.RightShift, function() end, function(key)
	if key then
		Window:SetKeybind(key)
	end
end)
```

While a keybind is waiting for a key, the window's toggle key is ignored, so picking a new menu key won't instantly close the menu.

---

### Dropdown

Pick **one** option from a list.

```lua
local mode = Main:CreateDropdown("Mode", { "Easy", "Normal", "Hard" }, "Normal", function(choice)
	print("Mode:", choice)
end)
```

Arguments: `CreateDropdown(name, options, default, callback)`

- `options`: a list of strings (anything else gets turned into a string).
- `default`: which option starts selected. Leave it out and the box says `Select...`.
- `callback(choice)`: called with the chosen string.

How it behaves: click the row to open it, hover the options (they light up), click one. The selection highlights, and a split second later the list closes by itself. If there are more than 6 options, the list scrolls.

Functions:

```lua
mode:Set("Hard")                      -- select and fire callback
mode:Set("Hard", true)                -- select silently
print(mode:Get())                     -- "Hard"
mode:Open()                           -- open from code
mode:Close()                          -- close from code
mode:Refresh({ "A", "B", "C" })       -- replace the whole option list
mode:Refresh({ "A", "B", "C" }, true) -- replace the list but keep the current pick if it still exists
```

`Refresh` is what you use for dynamic lists, like a list of players:

```lua
local function playerNames()
	local names = {}
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		table.insert(names, p.Name)
	end
	return names
end

local target = Main:CreateDropdown("Target", playerNames(), nil, function(name)
	print("Target:", name)
end)

game:GetService("Players").PlayerAdded:Connect(function()
	target:Refresh(playerNames(), true)
end)
game:GetService("Players").PlayerRemoving:Connect(function()
	task.wait()
	target:Refresh(playerNames(), true)
end)
```

---

### Multi dropdown

Same idea, but the user can pick **several** options. It stays open while they click so they can pick more, and closes when they click the row header again.

```lua
local targets = Main:CreateMultiDropdown("Targets", { "Players", "NPCs", "Items", "Chests" }, { "Players" }, function(list)
	print("Selected:", table.concat(list, ", "))
end)
```

Arguments: `CreateMultiDropdown(name, options, defaults, callback)`

- `defaults`: a list of options that start selected.
- `callback(list)`: receives a **list** of everything currently selected (in the same order as `options`).

The row shows the picked names. With one or two selections it lists them, with more it says `3 selected`, and with none it says `None`.

Functions work like the normal dropdown, except they use lists:

```lua
targets:Set({ "NPCs", "Items" })
targets:Set({}, true)                 -- clear silently
for _, name in ipairs(targets:Get()) do
	print(name)
end
targets:Refresh({ "New1", "New2" })
```

---

### Color picker

Click the row to expand three bars (hue, saturation, value). Drag them to pick a color. The little swatch on the right shows the current color.

```lua
local espColor = Visuals:CreateColorPicker("ESP color", Color3.fromRGB(200, 200, 205), function(color)
	print(color)
end)
```

Arguments: `CreateColorPicker(name, default, callback)`

- `default`: a `Color3`. Defaults to white.
- `callback(color)`: fires continuously while dragging, so apply it directly for a live preview.

Functions:

```lua
espColor:Set(Color3.fromRGB(255, 0, 0))        -- fires callback
espColor:Set(Color3.fromRGB(255, 0, 0), true)  -- silent
print(espColor:Get())                          -- Color3
```

---

## 8. Notifications

Small cards that slide in from the bottom right, stay a few seconds, then slide away. Multiple notifications stack neatly.

```lua
Window:Notify("Saved", "Your settings were saved.", 4)
```

Arguments: `Notify(title, text, duration, color)`

- `title`: bold first line.
- `text`: smaller gray text underneath. It wraps, and the card grows to fit. Can be empty.
- `duration`: seconds on screen. Defaults to `4`.
- `color`: color of the thin bar on the left side. Defaults to light gray.

You can also pass a table if you prefer named fields:

```lua
Window:Notify({
	Title = "Warning",
	Text = "Something looks off.",
	Duration = 6,
	Color = Lib.Colors.amber,
})
```

(`Content` works as an alias for `Text`.)

---

## 9. Things every element can do

Every element you create (including sections, labels and paragraphs) comes with these:

| Function | What it does |
| --- | --- |
| `element:SetText(text)` | Changes the name/label of the element. |
| `element:SetVisible(bool)` | Hides or shows the element. The rest of the page closes the gap. |
| `element:Destroy()` | Removes the element completely. |

Example, hiding an option until a toggle is on:

```lua
local advanced = Main:CreateSlider("Advanced value", 0, 100, 50, function() end)
advanced:SetVisible(false)

Main:CreateToggle("Show advanced", false, function(on)
	advanced:SetVisible(on)
end)
```

And an element-specific summary of what else they have:

| Element | Extra functions |
| --- | --- |
| Button | `Fire()` |
| Toggle | `Set(v, silent)`, `Get()`, `.Value` |
| Slider | `Set(v, silent)`, `Get()` |
| Textbox | `Set(text)`, `Get()` |
| Keybind | `Set(key, silent)`, `Get()` |
| Dropdown | `Set(v, silent)`, `Get()`, `Refresh(list, keep)`, `Open()`, `Close()` |
| Multi dropdown | same as dropdown, but with lists |
| Color picker | `Set(color, silent)`, `Get()` |
| Paragraph | `SetContent(text)` |

---

## 10. Colors

The library ships with a small color table in case you want matching colors for notifications or other bits:

```lua
Lib.Colors.white
Lib.Colors.text
Lib.Colors.muted
Lib.Colors.accent
Lib.Colors.accent2
Lib.Colors.gray
Lib.Colors.green
Lib.Colors.red
Lib.Colors.amber
Lib.Colors.blue    -- kept for compatibility, it's a light gray now
```

The look of the UI itself is deliberately all gray and white. The green/red/amber colors are there for when *you* want to flag something, like a green "Success" notification or a red "Error" one.

---

## 11. Full example

This one uses basically everything. Read it, run it, then tear it apart.

```lua
local Lib = loadstring(readfile("GlassUI.lua"))()

local Window = Lib:CreateWindow({
	Title = "My Hub",
	Subtitle = "v1.0",
	Keybind = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main")
local Visuals = Window:CreateTab("Visuals")
local Settings = Window:CreateTab("Settings")

-- MAIN -------------------------------------------------------------
Main:CreateSection("Basics")

Main:CreateToggle("God mode", false, function(on)
	print("God mode", on)
end)

Main:CreateButton("Say hi", function()
	Window:Notify("Hello", "Button was clicked", 3)
end)

Main:CreateSlider("Walk speed", 16, 200, 16, function(v)
	local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = v
	end
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

-- VISUALS ----------------------------------------------------------
Visuals:CreateColorPicker("Accent color", Color3.fromRGB(200, 200, 205), function(c)
	print("Color", c)
end)

Visuals:CreateParagraph("Info", "Paragraphs wrap automatically and grow with their content.")

-- SETTINGS ---------------------------------------------------------
Settings:CreateTextbox("Name", "", "Enter name...", function(text, enter)
	print("Name", text, enter)
end)

Settings:CreateKeybind("Menu key", Enum.KeyCode.RightShift, function() end, function(key)
	if key then
		Window:SetKeybind(key)
	end
end)

Settings:CreateLabel("Plain text label.")

Settings:CreateButton("Unload", function()
	Window:Destroy()
end)

Window:Notify("Loaded", "My Hub is ready", 4)
```

---

## 12. Tips and good habits

- **Order matters.** Elements appear in the order you create them. Plan your layout like you'd write a list.
- **Use sections.** A `CreateSection` every few elements makes a tab much easier to scan.
- **Keep the objects you'll need later.** If you only need a toggle's value inside its own callback, you don't need to store it. If another part of your script needs it, save the return value in a variable.
- **Use `silent` when loading configs.** If you load saved settings and call `Set(value)` on each element, every callback fires. Pass `true` as the last argument if you only want the visuals updated, then apply the values yourself.
- **Don't put symbols in names.** The font used (Gotham) doesn't have every unicode character. Fancy arrows, emojis, or special symbols in an element's name can show up as empty squares. Plain letters, numbers and normal punctuation are always safe.
- **Callbacks run in their own thread.** That means a slow callback (or one that waits) won't freeze the UI. It also means errors inside a callback print to the console but don't break the library.
- **One window name per script.** If you want two completely separate windows at once, give them different `Name` values. If you re-run a script with the same name, the old window is replaced.
- **Clean up on unload.** Call `Window:Destroy()` in your unload logic so the library disconnects its input listeners.

---

## 13. Troubleshooting

**Nothing shows up at all.**
Check that the file loaded (`loadstring(...)` returned something, not nil). Make sure you're calling `Lib:CreateWindow(...)` with a colon. If you ran it twice quickly, check the console for errors from the first run.

**The window is there but I can't bring it back after hiding.**
Press your toggle key (`RightShift` by default). If you changed it, remember the new one. You can always call `Window:SetVisible(true)` from code.

**I see empty squares instead of text.**
You're using a unicode character the font doesn't support. Replace it with plain text.

**A callback isn't firing when I call `Set`.**
You probably passed `true` as the silent flag, or you're calling `Set` with the same value the slider already has (sliders only fire on a change).

**Dropdown shows `Select...` even though I gave a default.**
The default has to match one of the options exactly, including capital letters. `"normal"` is not `"Normal"`.

**Multi dropdown `Get()` returns a table, but I expected a string.**
That's by design. Multi dropdowns always give you a list. Use `table.concat(list, ", ")` to print it.

**The window is too big for my screen.**
Pass smaller `Width` and `Height` in the options. It also scales down automatically on small screens.

**Another script's UI has the same name and got removed.**
Give your window a unique `Name` in the options.

---

## 14. Quick reference cheat sheet

```lua
-- Library
Lib:CreateWindow(titleOrOptions)
Lib.Colors

-- Window
Window:Subtitle(text)
Window:SetTitle(text)
Window:SetKeybind(keyCode)
Window:Toggle()
Window:SetVisible(bool)
Window:SetMinimized(bool)
Window:SelectTab(tabOrName)
Window:Notify(title, text, duration, color)
Window:CreateTab(name, color)
Window:Destroy()

-- Tab
Tab:CreateSection(name)
Tab:CreateLabel(text)
Tab:CreateParagraph(title, content)
Tab:CreateButton(name, callback)
Tab:CreateToggle(name, default, callback)
Tab:CreateSlider(name, min, max, default, callback, step)
Tab:CreateTextbox(name, default, placeholder, callback)
Tab:CreateKeybind(name, default, onPress, onChanged)
Tab:CreateDropdown(name, options, default, callback)
Tab:CreateMultiDropdown(name, options, defaults, callback)
Tab:CreateColorPicker(name, default, callback)

-- Every element
element:SetText(text)
element:SetVisible(bool)
element:Destroy()
```

That's everything. If you want a new element type (a progress bar, a tab icon, a config saver, anything), the code is organized so adding one is just a new `TabClass:CreateSomething` function that follows the same pattern as the existing ones.
