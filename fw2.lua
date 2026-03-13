--!strict
-- AugustusLikeUI.lua
-- Roblox UI Library inspired by the provided clickgui style.
-- Features:
-- - Window / Tabs / Sections
-- - Label / Button / Toggle / Slider
-- - Theme Manager
-- - Save Manager
-- - Notifications
-- - Minimal acrylic-like dark style with cyan accents
--
-- Example usage is at the bottom of this file.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local AugustusLikeUI = {}
AugustusLikeUI.__index = AugustusLikeUI

local DEFAULT_THEME = {
	Background = Color3.fromRGB(20, 22, 27),
	Background2 = Color3.fromRGB(24, 27, 33),
	Surface = Color3.fromRGB(31, 35, 42),
	Surface2 = Color3.fromRGB(37, 41, 48),
	Border = Color3.fromRGB(56, 63, 74),
	Text = Color3.fromRGB(220, 226, 235),
	TextDim = Color3.fromRGB(130, 140, 154),
	Accent = Color3.fromRGB(76, 175, 255),
	AccentDark = Color3.fromRGB(46, 122, 184),
	Success = Color3.fromRGB(85, 170, 127),
	Danger = Color3.fromRGB(200, 78, 78),
	Shadow = Color3.fromRGB(0, 0, 0),
}

local THEMES = {
	Default = DEFAULT_THEME,
	Crimson = {
		Background = Color3.fromRGB(22, 20, 24),
		Background2 = Color3.fromRGB(28, 24, 30),
		Surface = Color3.fromRGB(37, 32, 40),
		Surface2 = Color3.fromRGB(43, 36, 47),
		Border = Color3.fromRGB(74, 58, 67),
		Text = Color3.fromRGB(232, 228, 236),
		TextDim = Color3.fromRGB(157, 147, 162),
		Accent = Color3.fromRGB(255, 94, 122),
		AccentDark = Color3.fromRGB(186, 57, 84),
		Success = Color3.fromRGB(88, 172, 122),
		Danger = Color3.fromRGB(209, 84, 84),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	Emerald = {
		Background = Color3.fromRGB(18, 22, 20),
		Background2 = Color3.fromRGB(22, 28, 24),
		Surface = Color3.fromRGB(31, 38, 34),
		Surface2 = Color3.fromRGB(37, 46, 41),
		Border = Color3.fromRGB(62, 78, 68),
		Text = Color3.fromRGB(225, 234, 229),
		TextDim = Color3.fromRGB(136, 150, 142),
		Accent = Color3.fromRGB(72, 213, 156),
		AccentDark = Color3.fromRGB(46, 149, 109),
		Success = Color3.fromRGB(97, 195, 136),
		Danger = Color3.fromRGB(209, 84, 84),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
}

local function create(className: string, props: {[string]: any}?, children: {Instance}?)
	local object = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			object[key] = value
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = object
		end
	end
	return object
end

local function corner(radius: number)
	return create("UICorner", {CornerRadius = UDim.new(0, radius)})
end

local function stroke(color: Color3, thickness: number, transparency: number?)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function pad(l: number, r: number, t: number, b: number)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r),
		PaddingTop = UDim.new(0, t),
		PaddingBottom = UDim.new(0, b),
	})
end

local function tween(obj: Instance, ti: TweenInfo, props: {[string]: any})
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

local function setVisibleRecursive(instance: Instance, state: boolean)
	for _, child in ipairs(instance:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.Visible = state
		end
	end
	if instance:IsA("GuiObject") then
		instance.Visible = state
	end
end

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(library)
	return setmetatable({
		Library = library,
		Folder = "AugustusLikeUI",
		Ignore = {},
	}, SaveManager)
end

function SaveManager:SetFolder(folderName: string)
	self.Folder = folderName
end

function SaveManager:IgnoreKey(flag: string)
	self.Ignore[flag] = true
end

function SaveManager:BuildConfig()
	local config = {
		Theme = self.Library.ThemeName,
		Flags = {},
	}
	for key, value in pairs(self.Library.Flags) do
		if not self.Ignore[key] then
			config.Flags[key] = value
		end
	end
	return config
end

function SaveManager:Save(name: string)
	if not writefile or not isfolder then
		warn("SaveManager requires exploit file APIs")
		return false
	end
	if not isfolder(self.Folder) then
		makefolder(self.Folder)
	end
	local payload = HttpService:JSONEncode(self:BuildConfig())
	writefile(string.format("%s/%s.json", self.Folder, name), payload)
	return true
end

function SaveManager:Load(name: string)
	if not readfile or not isfile then
		warn("SaveManager requires exploit file APIs")
		return false
	end
	local path = string.format("%s/%s.json", self.Folder, name)
	if not isfile(path) then
		return false
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end
	if decoded.Theme and THEMES[decoded.Theme] then
		self.Library:SetTheme(decoded.Theme)
	end
	if decoded.Flags then
		for flag, value in pairs(decoded.Flags) do
			self.Library:SetFlag(flag, value)
		end
	end
	return true
end

function SaveManager:GetConfigs()
	if not listfiles or not isfolder then
		return {}
	end
	if not isfolder(self.Folder) then
		makefolder(self.Folder)
	end
	local out = {}
	for _, file in ipairs(listfiles(self.Folder)) do
		local name = file:match("([^/\\]+)%.json$")
		if name then
			table.insert(out, name)
		end
	end
	table.sort(out)
	return out
end

local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new(library)
	return setmetatable({
		Library = library,
		BuiltInThemes = THEMES,
	}, ThemeManager)
end

function ThemeManager:SetTheme(name: string)
	self.Library:SetTheme(name)
end

function ThemeManager:GetThemes()
	local out = {}
	for name in pairs(self.BuiltInThemes) do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

function AugustusLikeUI.new(options)
	options = options or {}

	local self = setmetatable({}, AugustusLikeUI)
	self.ThemeName = options.Theme or "Default"
	self.Theme = THEMES[self.ThemeName] or DEFAULT_THEME
	self.Flags = {}
	self.Registry = {}
	self.Tabs = {}
	self.CurrentTab = nil
	self._connections = {}

	local gui = create("ScreenGui", {
		Name = options.Name or "AugustusLikeUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	pcall(function()
		gui.Parent = gethui and gethui() or CoreGui
	end)
	if not gui.Parent then
		gui.Parent = CoreGui
	end

	self.Gui = gui

	local root = create("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(900, 560),
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
	}, {
		corner(8),
		stroke(self.Theme.Border, 1),
	})
	root.Parent = gui
	self.Root = root

	local shadow = create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 42, 1, 42),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
	})
	shadow.Parent = root

	local titleBar = create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = self.Theme.Background2,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, {
		corner(8),
		stroke(self.Theme.Border, 1),
	})
	titleBar.Parent = root

	create("Frame", {
		BackgroundColor3 = self.Theme.Background2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		ZIndex = 2,
	}).Parent = titleBar

	local title = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.55, 0, 1, 0),
		Font = Enum.Font.Code,
		Text = options.Title or "Augustus UI",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = self.Theme.Text,
		ZIndex = 3,
	})
	title.Parent = titleBar
	self.TitleLabel = title

	local subTitle = create("TextLabel", {
		Name = "SubTitle",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.35, 0, 1, 0),
		Font = Enum.Font.Code,
		Text = options.SubTitle or "roblox ui library",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = self.Theme.TextDim,
		ZIndex = 3,
	})
	subTitle.Parent = titleBar
	self.SubTitleLabel = subTitle

	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 1, -34),
		BackgroundTransparency = 1,
	})
	body.Parent = root

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 170, 1, 0),
		BackgroundColor3 = self.Theme.Background2,
		BorderSizePixel = 0,
	}, {
		stroke(self.Theme.Border, 1),
	})
	sidebar.Parent = body
	self.Sidebar = sidebar

	local accentLine = create("Frame", {
		Name = "AccentLine",
		Size = UDim2.new(0, 2, 1, 0),
		Position = UDim2.new(1, -2, 0, 0),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
	})
	accentLine.Parent = sidebar
	self.AccentLine = accentLine

	local tabButtons = create("ScrollingFrame", {
		Name = "TabButtons",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
	})
	tabButtons.Parent = sidebar
	self.TabButtons = tabButtons

	local tabList = create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	tabList.Parent = tabButtons

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(170, 0),
		Size = UDim2.new(1, -170, 1, 0),
		BackgroundTransparency = 1,
	})
	content.Parent = body
	self.Content = content

	local notifHolder = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(280, 220),
	})
	notifHolder.Parent = gui
	self.NotificationHolder = notifHolder
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}).Parent = notifHolder

	self:ApplyDragging(titleBar)
	self.ThemeManager = ThemeManager.new(self)
	self.SaveManager = SaveManager.new(self)

	if options.Keybind then
		table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == options.Keybind then
				self:SetVisible(not self.Root.Visible)
			end
		end))
	end

	return self
end

function AugustusLikeUI:ApplyDragging(handle: GuiObject)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = self.Root.Position

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self.Root.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			self.Root.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function AugustusLikeUI:SetVisible(state: boolean)
	self.Root.Visible = state
end

function AugustusLikeUI:Notify(titleText: string, bodyText: string, duration: number?)
	duration = duration or 3.5
	local card = create("Frame", {
		BackgroundColor3 = self.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(280, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.05,
	}, {
		corner(8),
		stroke(self.Theme.Border, 1),
		pad(10, 10, 10, 10),
	})
	card.Parent = self.NotificationHolder

	create("Frame", {
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 3, 1, 0),
		Position = UDim2.fromOffset(0, 0),
	}).Parent = card

	local layout = create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	})
	layout.Parent = card

	local nTitle = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 18),
		Position = UDim2.fromOffset(8, 0),
		Font = Enum.Font.Code,
		Text = titleText,
		TextColor3 = self.Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	nTitle.Parent = card

	local nBody = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.fromOffset(8, 0),
		Font = Enum.Font.Code,
		TextWrapped = true,
		Text = bodyText,
		TextColor3 = self.Theme.TextDim,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	nBody.Parent = card

	card.BackgroundTransparency = 1
	card.Size = UDim2.fromOffset(280, card.AbsoluteSize.Y)
	tween(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.05})

	task.delay(duration, function()
		if card.Parent then
			tween(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
			task.wait(0.22)
			card:Destroy()
		end
	end)
end

function AugustusLikeUI:SetTheme(name: string)
	local theme = THEMES[name]
	if not theme then return end
	self.ThemeName = name
	self.Theme = theme

	self.Root.BackgroundColor3 = theme.Background
	self.Sidebar.BackgroundColor3 = theme.Background2
	self.TitleLabel.TextColor3 = theme.Text
	self.SubTitleLabel.TextColor3 = theme.TextDim
	self.AccentLine.BackgroundColor3 = theme.Accent

	for _, entry in ipairs(self.Registry) do
		entry(self.Theme)
	end
end

function AugustusLikeUI:RegisterThemeCallback(callback)
	table.insert(self.Registry, callback)
	callback(self.Theme)
end

function AugustusLikeUI:SetFlag(flag: string, value: any)
	self.Flags[flag] = value
	local callback = self.Flags[flag .. "__callback"]
	if callback then
		callback(value)
	end
	local setter = self.Flags[flag .. "__setter"]
	if setter then
		setter(value)
	end
end

function AugustusLikeUI:_bindFlag(flag: string, default: any, callback, setter)
	self.Flags[flag] = default
	self.Flags[flag .. "__callback"] = callback
	self.Flags[flag .. "__setter"] = setter
end

function Window.new(library, options)
	local self = setmetatable({}, Window)
	self.Library = library
	self.Options = options or {}
	return self
end

function AugustusLikeUI:CreateWindow(options)
	return Window.new(self, options or {})
end

function Window:CreateTab(name: string, iconText: string?)
	local tab = setmetatable({}, Tab)
	tab.Library = self.Library
	tab.Name = name
	tab.Sections = {}

	local button = create("TextButton", {
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = self.Library.Theme.Surface,
		BorderSizePixel = 0,
		Text = "",
	}, {
		corner(6),
		stroke(self.Library.Theme.Border, 1),
	})
	button.Parent = self.Library.TabButtons
	tab.Button = button

	local icon = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.fromOffset(16, 34),
		Font = Enum.Font.Code,
		Text = iconText or ">",
		TextSize = 15,
		TextColor3 = self.Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	icon.Parent = button
	tab.Icon = icon

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Font = Enum.Font.Code,
		Text = name,
		TextSize = 14,
		TextColor3 = self.Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	label.Parent = button
	tab.Label = label

	local page = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self.Library.Theme.Accent,
		Visible = false,
		BorderSizePixel = 0,
	})
	page.Parent = self.Library.Content
	tab.Page = page

	local grid = create("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellPadding = UDim2.fromOffset(10, 10),
		CellSize = UDim2.new(0.5, -5, 0, 260),
	})
	grid.Parent = page
	tab.Grid = grid

	self.Library:RegisterThemeCallback(function(theme)
		button.BackgroundColor3 = theme.Surface
		label.TextColor3 = self.Library.CurrentTab == tab and theme.Text or theme.TextDim
		icon.TextColor3 = self.Library.CurrentTab == tab and theme.Accent or theme.TextDim
		button.UIStroke.Color = self.Library.CurrentTab == tab and theme.AccentDark or theme.Border
		page.ScrollBarImageColor3 = theme.Accent
	end)

	button.MouseButton1Click:Connect(function()
		for _, other in ipairs(self.Library.Tabs) do
			other.Page.Visible = false
			other.Label.TextColor3 = self.Library.Theme.TextDim
			other.Icon.TextColor3 = self.Library.Theme.TextDim
			other.Button.UIStroke.Color = self.Library.Theme.Border
		end
		self.Library.CurrentTab = tab
		page.Visible = true
		label.TextColor3 = self.Library.Theme.Text
		icon.TextColor3 = self.Library.Theme.Accent
		button.UIStroke.Color = self.Library.Theme.AccentDark
	end)

	table.insert(self.Library.Tabs, tab)
	if not self.Library.CurrentTab then
		button:Activate()
		self.Library.CurrentTab = tab
		page.Visible = true
		label.TextColor3 = self.Library.Theme.Text
		icon.TextColor3 = self.Library.Theme.Accent
		button.UIStroke.Color = self.Library.Theme.AccentDark
	end

	return tab
end

function Tab:CreateSection(titleText: string)
	local section = setmetatable({}, Section)
	section.Library = self.Library
	section.Tab = self
	section.Title = titleText
	section.Elements = {}

	local card = create("Frame", {
		BackgroundColor3 = self.Library.Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 260),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		corner(8),
		stroke(self.Library.Theme.Border, 1),
		pad(10, 10, 10, 10),
	})
	card.Parent = self.Page
	section.Card = card

	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.Code,
		Text = titleText,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = self.Library.Theme.Text,
	})
	title.Parent = card
	section.Header = title

	local divider = create("Frame", {
		BackgroundColor3 = self.Library.Theme.Border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
	})
	divider.Parent = card
	section.Divider = divider

	local holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	holder.Parent = card
	section.Holder = holder

	local list = create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	list.Parent = card

	self.Library:RegisterThemeCallback(function(theme)
		card.BackgroundColor3 = theme.Surface
		card.UIStroke.Color = theme.Border
		title.TextColor3 = theme.Text
		divider.BackgroundColor3 = theme.Border
	end)

	return section
end

function Section:_elementFrame(height: number?)
	local frame = create("Frame", {
		BackgroundColor3 = self.Library.Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height or 34),
	}, {
		corner(6),
		stroke(self.Library.Theme.Border, 1),
	})
	frame.Parent = self.Holder
	self.Library:RegisterThemeCallback(function(theme)
		frame.BackgroundColor3 = theme.Surface2
		frame.UIStroke.Color = theme.Border
	end)
	return frame
end

function Section:AddLabel(text: string)
	local frame = self:_elementFrame(30)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Enum.Font.Code,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		TextColor3 = self.Library.Theme.TextDim,
	})
	label.Parent = frame
	self.Library:RegisterThemeCallback(function(theme)
		label.TextColor3 = theme.TextDim
	end)
	return {
		Set = function(_, newText)
			label.Text = newText
		end,
	}
end

function Section:AddButton(options)
	options = options or {}
	local frame = self:_elementFrame(34)
	local button = create("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
	})
	button.Parent = frame

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Enum.Font.Code,
		Text = options.Text or "Button",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		TextColor3 = self.Library.Theme.Text,
	})
	label.Parent = frame

	button.MouseButton1Click:Connect(function()
		tween(frame, TweenInfo.new(0.08), {BackgroundColor3 = self.Library.Theme.AccentDark})
		task.delay(0.08, function()
			if frame.Parent then
				tween(frame, TweenInfo.new(0.12), {BackgroundColor3 = self.Library.Theme.Surface2})
			end
		end)
		if options.Callback then
			options.Callback()
		end
	end)

	self.Library:RegisterThemeCallback(function(theme)
		label.TextColor3 = theme.Text
	end)

	return button
end

function Section:AddToggle(options)
	options = options or {}
	local flag = options.Flag or options.Text or tostring(math.random())
	local value = options.Default == true
	local frame = self:_elementFrame(36)

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Font = Enum.Font.Code,
		Text = options.Text or "Toggle",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = self.Library.Theme.Text,
	})
	label.Parent = frame

	local box = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(36, 18),
		BackgroundColor3 = self.Library.Theme.Background,
		BorderSizePixel = 0,
	}, {
		corner(999),
		stroke(self.Library.Theme.Border, 1),
	})
	box.Parent = frame

	local knob = create("Frame", {
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = self.Library.Theme.TextDim,
		BorderSizePixel = 0,
	}, {
		corner(999),
	})
	knob.Parent = box

	local button = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		AutoButtonColor = false,
	})
	button.Parent = frame

	local function render(state: boolean)
		value = state
		tween(box, TweenInfo.new(0.15), {
			BackgroundColor3 = state and self.Library.Theme.AccentDark or self.Library.Theme.Background,
		})
		tween(knob, TweenInfo.new(0.15), {
			Position = state and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
			BackgroundColor3 = state and self.Library.Theme.Accent or self.Library.Theme.TextDim,
		})
	end

	button.MouseButton1Click:Connect(function()
		self.Library:SetFlag(flag, not value)
	end)

	self.Library:_bindFlag(flag, value, options.Callback, function(newValue)
		render(newValue)
	end)
	render(value)

	self.Library:RegisterThemeCallback(function(theme)
		label.TextColor3 = theme.Text
		box.UIStroke.Color = theme.Border
		if value then
			box.BackgroundColor3 = theme.AccentDark
			knob.BackgroundColor3 = theme.Accent
		else
			box.BackgroundColor3 = theme.Background
			knob.BackgroundColor3 = theme.TextDim
		end
	end)

	return {
		Set = function(_, newValue)
			self.Library:SetFlag(flag, newValue)
		end,
		Get = function()
			return value
		end,
	}
end

function Section:AddSlider(options)
	options = options or {}
	local min = options.Min or 0
	local max = options.Max or 100
	local decimals = options.Decimals or 0
	local flag = options.Flag or options.Text or tostring(math.random())
	local value = options.Default or min
	local dragging = false

	local frame = self:_elementFrame(52)
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -20, 0, 18),
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		TextColor3 = self.Library.Theme.Text,
	})
	label.Parent = frame

	local bar = create("Frame", {
		Position = UDim2.new(0, 10, 0, 30),
		Size = UDim2.new(1, -20, 0, 8),
		BackgroundColor3 = self.Library.Theme.Background,
		BorderSizePixel = 0,
	}, {
		corner(999),
		stroke(self.Library.Theme.Border, 1),
	})
	bar.Parent = frame

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = self.Library.Theme.Accent,
		BorderSizePixel = 0,
	}, {
		corner(999),
	})
	fill.Parent = bar

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = self.Library.Theme.Text,
		BorderSizePixel = 0,
	}, {
		corner(999),
	})
	knob.Parent = bar

	local function round(num)
		local factor = 10 ^ decimals
		return math.floor(num * factor + 0.5) / factor
	end

	local function render(newValue)
		value = math.clamp(round(newValue), min, max)
		local alpha = (value - min) / (max - min)
		label.Text = string.format("%s [%s]", options.Text or "Slider", tostring(value))
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end

	local function setFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local newValue = min + (max - min) * alpha
		self.Library:SetFlag(flag, newValue)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	self.Library:_bindFlag(flag, value, options.Callback, function(newValue)
		render(newValue)
	end)
	render(value)

	self.Library:RegisterThemeCallback(function(theme)
		label.TextColor3 = theme.Text
		bar.BackgroundColor3 = theme.Background
		bar.UIStroke.Color = theme.Border
		fill.BackgroundColor3 = theme.Accent
		knob.BackgroundColor3 = theme.Text
	end)

	return {
		Set = function(_, newValue)
			self.Library:SetFlag(flag, newValue)
		end,
		Get = function()
			return value
		end,
	}
end

function Section:AddParagraph(titleText: string, bodyText: string)
	local frame = self:_elementFrame(70)
	local title = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.Code,
		Text = titleText,
		TextSize = 14,
		TextColor3 = self.Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	title.Parent = frame

	local body = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 24),
		Size = UDim2.new(1, -20, 1, -28),
		Font = Enum.Font.Code,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = bodyText,
		TextSize = 13,
		TextColor3 = self.Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	body.Parent = frame

	self.Library:RegisterThemeCallback(function(theme)
		title.TextColor3 = theme.Text
		body.TextColor3 = theme.TextDim
	end)
end

function Section:AddThemeManager()
	self:AddLabel("Theme Manager")
	for _, themeName in ipairs(self.Library.ThemeManager:GetThemes()) do
		self:AddButton({
			Text = "Load Theme: " .. themeName,
			Callback = function()
				self.Library.ThemeManager:SetTheme(themeName)
				self.Library:Notify("Theme", themeName .. " loaded", 2)
			end,
		})
	end
end

function Section:AddSaveManager()
	self:AddLabel("Save Manager")
	self:AddButton({
		Text = "Save Config: default",
		Callback = function()
			local ok = self.Library.SaveManager:Save("default")
			self.Library:Notify("Config", ok and "Saved default config" or "Save failed", 2.5)
		end,
	})
	self:AddButton({
		Text = "Load Config: default",
		Callback = function()
			local ok = self.Library.SaveManager:Load("default")
			self.Library:Notify("Config", ok and "Loaded default config" or "Load failed", 2.5)
		end,
	})
	self:AddParagraph("Available configs", table.concat(self.Library.SaveManager:GetConfigs(), ", "))
end

function AugustusLikeUI:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self.Gui:Destroy()
end

--[[
	========================
	Example Usage
	========================

	local Library = loadstring(readfile("AugustusLikeUI.lua"))()
	local Window = Library:CreateWindow({})

	local Combat = Window:CreateTab("Combat", "C")
	local Main = Combat:CreateSection("Main")

	Main:AddLabel("Augustus-like visual styling")
	Main:AddToggle({
		Text = "KillAura",
		Flag = "KillAura",
		Default = false,
		Callback = function(v)
			print("KillAura:", v)
		end,
	})

	Main:AddSlider({
		Text = "Range",
		Flag = "Range",
		Min = 1,
		Max = 8,
		Default = 4,
		Callback = function(v)
			print("Range:", v)
		end,
	})

	Main:AddButton({
		Text = "Test Notification",
		Callback = function()
			Library:Notify("Hello", "This library matches the clickgui mood.")
		end,
	})

	local Visuals = Window:CreateTab("Visuals", "V")
	local Themes = Visuals:CreateSection("Theme / Saves")
	Themes:AddThemeManager()
	Themes:AddSaveManager()

	return Library
]]

return AugustusLikeUI.new({
	Name = "AugustusLikeUI",
	Title = "Augustus",
	SubTitle = "clickgui-inspired roblox library",
	Theme = "Default",
	Keybind = Enum.KeyCode.RightShift,
})
