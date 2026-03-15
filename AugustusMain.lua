local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local Library = { Options = {}, Toggles = {}, _Window = nil }
Library.__index = Library

local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

local SaveManager, ThemeManager = {}, {}
SaveManager.__index, ThemeManager.__index = SaveManager, ThemeManager

local Themes = {
    Augustus = {
        Window = Color3.fromRGB(23,24,28), Window2 = Color3.fromRGB(26,28,33),
        Top = Color3.fromRGB(18,19,23), Panel = Color3.fromRGB(26,28,33), Panel2 = Color3.fromRGB(32,35,40),
        Border = Color3.fromRGB(60,64,73), BorderSoft = Color3.fromRGB(48,52,60),
        Text = Color3.fromRGB(228,231,238), DimText = Color3.fromRGB(146,154,166),
        Accent = Color3.fromRGB(108,170,255), Accent2 = Color3.fromRGB(64,118,196),
        Good = Color3.fromRGB(95,189,120), Bad = Color3.fromRGB(204,87,87), Blur = 14,
    },
    Mono = {
        Window = Color3.fromRGB(26,26,28), Window2 = Color3.fromRGB(30,30,33),
        Top = Color3.fromRGB(18,18,20), Panel = Color3.fromRGB(31,31,34), Panel2 = Color3.fromRGB(36,36,40),
        Border = Color3.fromRGB(67,67,74), BorderSoft = Color3.fromRGB(52,52,58),
        Text = Color3.fromRGB(232,232,235), DimText = Color3.fromRGB(150,150,156),
        Accent = Color3.fromRGB(188,188,188), Accent2 = Color3.fromRGB(122,122,122),
        Good = Color3.fromRGB(106,180,112), Bad = Color3.fromRGB(198,91,91), Blur = 10,
    },
    Crimson = {
        Window = Color3.fromRGB(24,22,27), Window2 = Color3.fromRGB(29,25,31),
        Top = Color3.fromRGB(17,15,19), Panel = Color3.fromRGB(33,28,35), Panel2 = Color3.fromRGB(41,34,43),
        Border = Color3.fromRGB(77,60,70), BorderSoft = Color3.fromRGB(58,46,54),
        Text = Color3.fromRGB(235,227,233), DimText = Color3.fromRGB(165,148,158),
        Accent = Color3.fromRGB(255,110,138), Accent2 = Color3.fromRGB(188,69,98),
        Good = Color3.fromRGB(98,181,120), Bad = Color3.fromRGB(204,86,86), Blur = 12,
    },
}

local function copy(t)
    local o = {}
    for k,v in pairs(t or {}) do o[k] = v end
    return o
end

local function create(className, props)
    local obj = Instance.new(className)
    for k,v in pairs(props or {}) do obj[k] = v end
    return obj
end

local function corner(p, px)
    local c = create("UICorner", {CornerRadius = UDim.new(0, px)})
    c.Parent = p
    return c
end

local function stroke(p, color, th, tr)
    local s = create("UIStroke", {
        Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    s.Parent = p
    return s
end

local function padding(p, l,r,t,b)
    local pad = create("UIPadding", {
        PaddingLeft = UDim.new(0,l), PaddingRight = UDim.new(0,r),
        PaddingTop = UDim.new(0,t), PaddingBottom = UDim.new(0,b)
    })
    pad.Parent = p
    return pad
end

local function tween(obj, dur, props)
    local tw = TweenService:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function clamp01(x) return math.clamp(x, 0, 1) end

local function placeGui(gui)
    local ok = pcall(function() gui.Parent = gethui and gethui() or CoreGui end)
    if not ok or not gui.Parent then gui.Parent = CoreGui end
end

local function control(kind, flag, default, callback)
    local self = {Type = kind, Flag = flag, Value = default, _callbacks = {}, _display = nil}
    function self:OnChanged(fn)
        table.insert(self._callbacks, fn)
        return self
    end
    function self:_emit(v)
        self.Value = v
        if callback then task.spawn(callback, v) end
        for _,fn in ipairs(self._callbacks) do task.spawn(fn, v) end
    end
    function self:Set(v) self:_emit(v) end
    function self:SetValue(v) self:Set(v) end
    function self:Get() return self.Value end
    function self:GetValue() return self.Value end
    return self
end

local function bindTheme(window, fn)
    table.insert(window._themeBinds, fn)
    fn(window.Theme)
end

local function hsvToColor(h, s, v)
    return Color3.fromHSV(h, s, v)
end

local function colorToHSV(c)
    return Color3.toHSV(c)
end

function Window:_applyTheme(theme)
    self.Theme = theme
    for _,fn in ipairs(self._themeBinds) do fn(theme) end
end

function Window:_register(flag, obj)
    self._controls[flag] = obj
    Library.Options[flag] = obj
    if obj.Type == "Toggle" then
        Library.Toggles[flag] = obj
    end
end

function Window:SetTheme(name)
    if Themes[name] then
        self.ThemeName = name
        self:_applyTheme(Themes[name])
    end
end

function Window:_create()
    local gui = create("ScreenGui", {
        Name = self.Options.Name or "AugustusUI",
        IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    placeGui(gui)
    self.Gui = gui

    if self.Options.Blur then
        pcall(function()
            local old = Lighting:FindFirstChild("AugustusUI_Blur")
            if old then old:Destroy() end
        end)
        self.Blur = create("BlurEffect", {
            Name = "AugustusUI_Blur", Parent = Lighting,
            Enabled = self.Options.AutoShow ~= false, Size = self.Theme.Blur
        })
    end

    local main = create("Frame", {
        Parent = gui, Name = "Main", AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(900, 470), BackgroundColor3 = self.Theme.Window,
        BackgroundTransparency = .10, BorderSizePixel = 0
    })
    corner(main, 6); stroke(main, self.Theme.Border, 1)
    self.Main = main

    local top = create("Frame", {
        Parent = main, Size = UDim2.new(1,0,0,28),
        BackgroundColor3 = self.Theme.Top, BackgroundTransparency = .04, BorderSizePixel = 0
    })
    corner(top, 6)
    create("Frame", {
        Parent = top, Position = UDim2.new(0,0,1,-6), Size = UDim2.new(1,0,0,6),
        BackgroundColor3 = self.Theme.Top, BorderSizePixel = 0
    })
    stroke(top, self.Theme.BorderSoft, 1)

    self.TitleLabel = create("TextLabel", {
        Parent = top, BackgroundTransparency = 1, Position = UDim2.fromOffset(8,0), Size = UDim2.new(.35,0,1,0),
        Font = Enum.Font.Code, Text = self.Options.Title or "Augustus", TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Theme.Text
    })
    self.SubtitleLabel = create("TextLabel", {
        Parent = top, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-8,0,0),
        Size = UDim2.new(.45,0,1,0), Font = Enum.Font.Code, Text = self.Options.Subtitle or "v6",
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Theme.DimText
    })

    local tabBar = create("Frame", {Parent = main, BackgroundTransparency = 1, Position = UDim2.fromOffset(10,30), Size = UDim2.new(1,-20,0,24)})
    self.TabBar = tabBar
    create("UIListLayout", {Parent = tabBar, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12)})

    local pages = create("Frame", {Parent = main, BackgroundTransparency = 1, Position = UDim2.fromOffset(10,56), Size = UDim2.new(1,-20,1,-66)})
    self.PageArea = pages

    local manager = create("Frame", {
        Parent = gui, Name = "Manager", AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-18,0,74),
        Size = UDim2.fromOffset(258, 300), BackgroundColor3 = self.Theme.Window2,
        BackgroundTransparency = .08, BorderSizePixel = 0
    })
    corner(manager, 6); stroke(manager, self.Theme.Border, 1)
    self.Manager = manager

    local mt = create("Frame", {
        Parent = manager, Size = UDim2.new(1,0,0,26), BackgroundColor3 = self.Theme.Top,
        BackgroundTransparency = .04, BorderSizePixel = 0
    })
    corner(mt, 6)
    create("Frame", {Parent = mt, Position = UDim2.new(0,0,1,-6), Size = UDim2.new(1,0,0,6), BackgroundColor3 = self.Theme.Top, BorderSizePixel = 0})

    self.ManagerTitle = create("TextLabel", {
        Parent = mt, BackgroundTransparency = 1, Position = UDim2.fromOffset(8,0), Size = UDim2.new(1,-16,1,0),
        Font = Enum.Font.Code, Text = "Manager", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Theme.Text
    })

    self.ManagerContent = create("Frame", {Parent = manager, BackgroundTransparency = 1, Position = UDim2.fromOffset(8,32), Size = UDim2.new(1,-16,1,-40)})

    local binds = create("Frame", {
        Parent = gui, Name = "BindList", AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,18,1,-18),
        Size = UDim2.fromOffset(220, 220), BackgroundTransparency = 1, Visible = false
    })
    self.BindList = binds
    local bindCard = create("Frame", {
        Parent = binds, Size = UDim2.fromScale(1,1), BackgroundColor3 = self.Theme.Window2,
        BackgroundTransparency = .08, BorderSizePixel = 0
    })
    corner(bindCard, 6); stroke(bindCard, self.Theme.Border, 1)
    local bindTop = create("TextLabel", {
        Parent = bindCard, Position = UDim2.fromOffset(8,6), Size = UDim2.new(1,-16,0,16),
        BackgroundTransparency = 1, Font = Enum.Font.Code, Text = "Bind List", TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Theme.Text
    })
    local bindHolder = create("ScrollingFrame", {
        Parent = bindCard, Position = UDim2.fromOffset(8,26), Size = UDim2.new(1,-16,1,-34),
        BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0
    })
    create("UIListLayout", {Parent = bindHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})
    self.BindHolder = bindHolder

    local notif = create("Frame", {
        Parent = gui, Name = "Notifications", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,1),
        Position = UDim2.new(1,-18,1,-18), Size = UDim2.fromOffset(320,220)
    })
    self.NotificationHolder = notif
    create("UIListLayout", {
        Parent = notif, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0,8)
    })

    bindTheme(self, function(theme)
        main.BackgroundColor3 = theme.Window
        manager.BackgroundColor3 = theme.Window2
        mt.BackgroundColor3 = theme.Top
        top.BackgroundColor3 = theme.Top
        bindCard.BackgroundColor3 = theme.Window2
        bindTop.TextColor3 = theme.Text
        self.TitleLabel.TextColor3 = theme.Text
        self.SubtitleLabel.TextColor3 = theme.DimText
        self.ManagerTitle.TextColor3 = theme.Text
    end)
end

function Window:_wire()
    if self.Options.ToggleKey ~= nil then
        local key = self.Options.ToggleKey or Enum.KeyCode.RightShift
        table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
                self:SetOpen(not self.Open)
            end
        end))
    end
end

function Window:SetOpen(state)
    self.Open = state
    local dur = tonumber(self.Options.FadeTime) or 0.18
    local roots = {self.Main, self.Manager, self.BindList}
    if state then
        self.Gui.Enabled = true
        for _,r in ipairs(roots) do
            if r then
                r.Visible = (r ~= self.BindList) or self.Options.ShowBindList == true
                if r ~= self.BindList then
                    r.BackgroundTransparency = 1
                    tween(r, dur, {BackgroundTransparency = (r == self.Manager and .08 or .10)})
                end
            end
        end
        if self.Blur then
            self.Blur.Enabled = true
            tween(self.Blur, dur, {Size = self.Theme.Blur})
        end
    else
        for _,r in ipairs(roots) do
            if r and r ~= self.BindList then tween(r, dur, {BackgroundTransparency = 1}) end
        end
        if self.Blur then tween(self.Blur, dur, {Size = 0}) end
        task.delay(dur, function()
            if not self.Open then
                for _,r in ipairs(roots) do if r then r.Visible = false end end
                if self.Gui then self.Gui.Enabled = false end
                if self.Blur then self.Blur.Enabled = false end
            end
        end)
    end
end

function Window:Notify(title, text, duration)
    duration = duration or 2.4
    local card = create("Frame", {
        Parent = self.NotificationHolder, BackgroundColor3 = self.Theme.Panel,
        BackgroundTransparency = .08, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.fromOffset(280, 0)
    })
    corner(card, 6); stroke(card, self.Theme.BorderSoft, 1); padding(card, 10,10,8,8)
    create("Frame", {Parent = card, BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Position = UDim2.fromOffset(0,0), Size = UDim2.new(0,2,1,0)})
    create("UIListLayout", {Parent = card, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3)})
    create("TextLabel", {
        Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(6,0), Size = UDim2.new(1,-10,0,16),
        Font = Enum.Font.Code, Text = tostring(title or "Augustus"), TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Theme.Text
    })
    create("TextLabel", {
        Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(6,0), Size = UDim2.new(1,-10,0,0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, Font = Enum.Font.Code,
        Text = tostring(text or ""), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = self.Theme.DimText
    })
    card.BackgroundTransparency = 1
    tween(card, .12, {BackgroundTransparency = .08})
    task.delay(duration, function()
        if card.Parent then
            tween(card, .12, {BackgroundTransparency = 1})
            task.delay(.15, function() if card.Parent then card:Destroy() end end)
        end
    end)
end

function Window:_refreshBindList()
    for _,c in ipairs(self.BindHolder:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local count = 0
    for _,obj in pairs(self._controls) do
        if obj.Type == "KeyPicker" then
            count += 1
            local row = create("Frame", {Parent = self.BindHolder, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18)})
            create("TextLabel", {
                Parent = row, BackgroundTransparency = 1, Size = UDim2.new(.65,0,1,0), Font = Enum.Font.Code,
                Text = obj._displayName or obj.Flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = self.Theme.Text
            })
            create("TextLabel", {
                Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
                Size = UDim2.new(.35,0,1,0), Font = Enum.Font.Code, Text = tostring(obj.Value or "None"),
                TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Theme.Accent
            })
        end
    end
    self.BindList.Visible = self.Options.ShowBindList == true and self.Open and count > 0
end

function Window:AddBindList()
    self.Options.ShowBindList = true
    self:_refreshBindList()
    return self.BindList
end

function Window:AddTab(name)
    local tab = setmetatable({Window = self, Name = name, Sections = {}}, Tab)

    local button = create("TextButton", {
        Parent = self.TabBar, AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.fromOffset(86, 22), Font = Enum.Font.Code, Text = string.upper(name),
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Theme.DimText
    })
    local underline = create("Frame", {
        Parent = button, BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0,
        Visible = false, Position = UDim2.new(0,0,1,-1), Size = UDim2.new(1,0,0,1)
    })

    local page = create("Frame", {Parent = self.PageArea, BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Visible = false})
    local left = create("ScrollingFrame", {
        Parent = page, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(.5,-6,1,0),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0
    })
    create("UIListLayout", {Parent = left, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})
    local right = create("ScrollingFrame", {
        Parent = page, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(.5,6,0,0), Size = UDim2.new(.5,-6,1,0),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0
    })
    create("UIListLayout", {Parent = right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})

    tab.Button, tab.Underline, tab.Page, tab.LeftColumn, tab.RightColumn = button, underline, page, left, right
    button.MouseButton1Click:Connect(function() self:_selectTab(tab) end)

    bindTheme(self, function(theme)
        button.TextColor3 = self.CurrentTab == tab and theme.Text or theme.DimText
        underline.BackgroundColor3 = theme.Accent
    end)

    table.insert(self.Tabs, tab)
    if not self.CurrentTab then self:_selectTab(tab) end
    return tab
end

function Window:_selectTab(tab)
    self.CurrentTab = tab
    for _,t in ipairs(self.Tabs) do
        t.Page.Visible = (t == tab)
        t.Underline.Visible = (t == tab)
        t.Button.TextColor3 = (t == tab) and self.Theme.Text or self.Theme.DimText
    end
end

function Tab:_section(name, side)
    local s = setmetatable({Tab = self, Window = self.Window, Name = name, Side = side}, Section)
    local holder = create("Frame", {
        Parent = side == "Right" and self.RightColumn or self.LeftColumn,
        BackgroundColor3 = self.Window.Theme.Panel, BackgroundTransparency = .06, BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,30), AutomaticSize = Enum.AutomaticSize.Y
    })
    corner(holder, 6); stroke(holder, self.Window.Theme.BorderSoft, 1); padding(holder,10,10,8,8)
    local title = create("TextLabel", {
        Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,18), Font = Enum.Font.Code,
        Text = name, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    create("Frame", {Parent = holder, BackgroundColor3 = self.Window.Theme.BorderSoft, BorderSizePixel = 0, Size = UDim2.new(1,0,0,1)})
    local body = create("Frame", {Parent = holder, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y})
    create("UIListLayout", {Parent = holder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})

    s.Holder, s.Title, s.Body = holder, title, body
    bindTheme(self.Window, function(theme)
        holder.BackgroundColor3 = theme.Panel
        title.TextColor3 = theme.Text
    end)
    return s
end

function Tab:AddSection(name) return self:_section(name, "Left") end
function Tab:AddLeftGroupbox(name) return self:_section(name, "Left") end
function Tab:AddRightGroupbox(name) return self:_section(name, "Right") end

function Section:_row(h)
    return create("Frame", {Parent = self.Body, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,h or 22)})
end

function Section:AddDivider(text)
    local row = self:_row(16)
    if text and text ~= "" then
        local lbl = create("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Size = UDim2.new(0,130,1,0), Font = Enum.Font.Code,
            Text = text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.DimText
        })
        create("Frame", {
            Parent = row, BackgroundColor3 = self.Window.Theme.BorderSoft, BorderSizePixel = 0,
            Position = UDim2.new(0,136,.5,0), AnchorPoint = Vector2.new(0,.5), Size = UDim2.new(1,-136,0,1)
        })
        return lbl
    else
        return create("Frame", {
            Parent = row, BackgroundColor3 = self.Window.Theme.BorderSoft, BorderSizePixel = 0,
            Position = UDim2.new(0,0,.5,0), AnchorPoint = Vector2.new(0,.5), Size = UDim2.new(1,0,0,1)
        })
    end
end

function Section:AddLabel(text)
    local row = self:_row(18)
    local lbl = create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Font = Enum.Font.Code,
        Text = tostring(text or ""), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.DimText
    })
    local helper = {__section = self}
    function helper:Set(v) lbl.Text = tostring(v) end
    function helper:AddColorPicker(flag, options) return self.__section:AddColorPicker(flag, options, row) end
    function helper:AddKeyPicker(flag, options) return self.__section:AddKeyPicker(flag, options, row) end
    return helper
end

function Section:AddButton(options)
    options = options or {}
    local row = self:_row(22)
    local btn = create("TextButton", {Parent = row, BackgroundTransparency = 1, AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1,0,1,0), Text = ""})
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(.7,0,1,0), Font = Enum.Font.Code,
        Text = options.Text or "Button", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.new(.3,0,1,0),
        Font = Enum.Font.Code, Text = options.RightText or "", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Window.Theme.Accent
    })
    btn.MouseButton1Click:Connect(function() if options.Callback then options.Callback() end end)
    return btn
end

function Section:AddToggle(flag, options)
    options = options or {}
    local row = self:_row(22)
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,-52,1,0), Font = Enum.Font.Code,
        Text = options.Text or flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    local track = create("Frame", {
        Parent = row, AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,0,.5,0), Size = UDim2.fromOffset(36,16),
        BackgroundColor3 = self.Window.Theme.Panel2, BorderSizePixel = 0
    })
    corner(track, 99)
    local knob = create("Frame", {Parent = track, Position = UDim2.fromOffset(2,2), Size = UDim2.fromOffset(12,12), BackgroundColor3 = self.Window.Theme.DimText, BorderSizePixel = 0})
    corner(knob, 99)
    local btn = create("TextButton", {Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "", AutoButtonColor = false})
    local obj = control("Toggle", flag, options.Default == true, options.Callback)
    self.Window:_register(flag, obj)

    local function render(v)
        obj.Value = v
        tween(track, .12, {BackgroundColor3 = v and self.Window.Theme.Accent2 or self.Window.Theme.Panel2})
        tween(knob, .12, {
            Position = v and UDim2.fromOffset(22,2) or UDim2.fromOffset(2,2),
            BackgroundColor3 = v and self.Window.Theme.Accent or self.Window.Theme.DimText
        })
    end
    function obj:Set(v) render(v); obj:_emit(v) end
    function obj:SetValue(v) obj:Set(v) end
    function obj:AddKeyPicker(kflag, kopt) return self:AddKeyPicker(kflag, kopt) end

    btn.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
    render(obj.Value)
    return obj
end

function Section:AddSlider(flag, options)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    local decimals = options.Decimals
    if decimals == nil and options.Rounding ~= nil then decimals = options.Rounding end
    decimals = decimals or 0

    local row = self:_row(34)
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,-70,0,14), Font = Enum.Font.Code,
        Text = options.Text or flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    local valueLabel = create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.fromOffset(62,14),
        Font = Enum.Font.Code, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Window.Theme.DimText
    })
    local bar = create("Frame", {
        Parent = row, Position = UDim2.fromOffset(0,20), Size = UDim2.new(1,0,0,8), BackgroundColor3 = self.Window.Theme.Panel2, BorderSizePixel = 0
    })
    corner(bar, 99)
    local fill = create("Frame", {Parent = bar, Size = UDim2.new(0,0,1,0), BackgroundColor3 = self.Window.Theme.Accent, BorderSizePixel = 0})
    corner(fill, 99)
    local knob = create("Frame", {Parent = bar, AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(0,0,.5,0), Size = UDim2.fromOffset(10,10), BackgroundColor3 = self.Window.Theme.Text, BorderSizePixel = 0})
    corner(knob, 99)

    local obj = control("Slider", flag, options.Default or min, options.Callback)
    self.Window:_register(flag, obj)
    local dragging = false

    local function round(n)
        local f = 10 ^ decimals
        return math.floor(n * f + .5) / f
    end
    local function render(v)
        v = math.clamp(round(v), min, max)
        obj.Value = v
        local alpha = (v - min) / ((max - min) == 0 and 1 or (max - min))
        fill.Size = UDim2.new(alpha,0,1,0)
        knob.Position = UDim2.new(alpha,0,.5,0)
        valueLabel.Text = tostring(v)
    end
    function obj:Set(v) render(v); obj:_emit(obj.Value) end
    function obj:SetValue(v) obj:Set(v) end

    local function fromX(x)
        local alpha = clamp01((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
        obj:Set(min + ((max - min) * alpha))
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; fromX(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    render(obj.Value)
    return obj
end

function Section:AddTextbox(flag, options)
    options = options or {}
    local row = self:_row(24)
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(.38,0,1,0), Font = Enum.Font.Code,
        Text = options.Text or flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    local box = create("TextBox", {
        Parent = row, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.new(.58,0,1,0),
        BackgroundColor3 = self.Window.Theme.Panel2, BorderSizePixel = 0, ClearTextOnFocus = false,
        Text = tostring(options.Default or ""), PlaceholderText = tostring(options.Placeholder or ""),
        Font = Enum.Font.Code, TextSize = 13, TextColor3 = self.Window.Theme.Text, PlaceholderColor3 = self.Window.Theme.DimText,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    corner(box, 4); padding(box, 6,6,0,0)
    local obj = control("Textbox", flag, box.Text, options.Callback)
    self.Window:_register(flag, obj)
    function obj:Set(v)
        box.Text = tostring(v)
        obj:_emit(box.Text)
    end
    function obj:SetValue(v) obj:Set(v) end
    box.FocusLost:Connect(function()
        obj:_emit(box.Text)
    end)
    return obj
end

function Section:AddDropdown(flag, options)
    options = options or {}
    local values = copy(options.Values or {})
    local multi = options.Multi == true

    local row = self:_row(22)
    create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,-120,1,0), Font = Enum.Font.Code,
        Text = options.Text or flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
    })
    local valueLabel = create("TextLabel", {
        Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.fromOffset(114,22),
        Font = Enum.Font.Code, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Window.Theme.Accent
    })
    local click = create("TextButton", {Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "", AutoButtonColor = false})

    local drop = create("Frame", {
        Parent = row, BackgroundColor3 = self.Window.Theme.Panel2, BackgroundTransparency = .06, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0,24), Size = UDim2.new(1,0,0,0), ClipsDescendants = true, Visible = false
    })
    corner(drop, 5); stroke(drop, self.Window.Theme.BorderSoft, 1)

    local search = create("TextBox", {
        Parent = drop, BackgroundColor3 = self.Window.Theme.Panel, BorderSizePixel = 0, Position = UDim2.fromOffset(6,6), Size = UDim2.new(1,-12,0,22),
        ClearTextOnFocus = false, Text = "", PlaceholderText = "search...", Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = self.Window.Theme.Text, PlaceholderColor3 = self.Window.Theme.DimText, TextXAlignment = Enum.TextXAlignment.Left
    })
    corner(search, 4); padding(search, 6,6,0,0)

    local scroller = create("ScrollingFrame", {
        Parent = drop, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0,34), Size = UDim2.new(1,0,1,-34),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2, ScrollBarImageColor3 = self.Window.Theme.Accent
    })
    padding(scroller, 6,6,2,6)
    create("UIListLayout", {Parent = scroller, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4)})

    local default = multi and (type(options.Default) == "table" and copy(options.Default) or {}) or
        (type(options.Default) == "number" and values[options.Default] or (options.Default or values[1]))

    local obj = control("Dropdown", flag, default, options.Callback)
    self.Window:_register(flag, obj)

    local open = false
    local function summary(v)
        if multi then
            local picked = {}
            for _,choice in ipairs(values) do if v[choice] then table.insert(picked, tostring(choice)) end end
            if #picked == 0 then return "none" end
            if #picked <= 2 then return table.concat(picked, ", ") end
            return tostring(#picked) .. " selected"
        end
        return tostring(v or "none")
    end
    local function render(v) obj.Value = v; valueLabel.Text = summary(v) end
    local function setOpen(state)
        open = state
        drop.Visible = state
        local h = state and 186 or 0
        drop.Size = UDim2.new(1,0,0,h)
        row.Size = UDim2.new(1,0,0,22 + (state and 192 or 0))
        valueLabel.TextColor3 = state and self.Window.Theme.Accent or self.Window.Theme.DimText
    end

    local function visibleChoices()
        local q = string.lower(search.Text or "")
        local out = {}
        for _,choice in ipairs(values) do
            if q == "" or string.find(string.lower(tostring(choice)), q, 1, true) then
                table.insert(out, choice)
            end
        end
        return out
    end

    local function rebuild()
        for _,c in ipairs(scroller:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        for _,choice in ipairs(visibleChoices()) do
            local item = create("TextButton", {
                Parent = scroller, BackgroundColor3 = self.Window.Theme.Panel, BackgroundTransparency = .08, BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,20), AutoButtonColor = false, Text = ""
            })
            corner(item, 4)
            local st = stroke(item, self.Window.Theme.BorderSoft, 1)
            local txt = create("TextLabel", {
                Parent = item, BackgroundTransparency = 1, Position = UDim2.fromOffset(6,0), Size = UDim2.new(1,-30,1,0), Font = Enum.Font.Code,
                Text = tostring(choice), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
            })
            local mark = create("TextLabel", {
                Parent = item, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-6,0,0), Size = UDim2.fromOffset(18,20),
                Font = Enum.Font.Code, Text = "", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = self.Window.Theme.Accent
            })

            local function paint()
                local selected = multi and obj.Value[choice] or obj.Value == choice
                st.Color = selected and self.Window.Theme.Accent or self.Window.Theme.BorderSoft
                txt.TextColor3 = selected and self.Window.Theme.Text or self.Window.Theme.DimText
                mark.Text = selected and "✓" or ""
            end

            item.MouseButton1Click:Connect(function()
                if multi then
                    local nv = copy(obj.Value)
                    nv[choice] = not nv[choice]
                    render(nv)
                    obj:_emit(nv)
                else
                    render(choice)
                    obj:_emit(choice)
                    setOpen(false)
                end
                paint()
            end)
            paint()
        end
    end

    function obj:Set(v)
        render(v)
        obj:_emit(v)
        rebuild()
    end
    function obj:SetValue(v) obj:Set(v) end
    function obj:SetValues(newValues)
        values = copy(newValues or {})
        if multi then
            local keep = {}
            for _,choice in ipairs(values) do if obj.Value[choice] then keep[choice] = true end end
            obj.Value = keep
        else
            if table.find(values, obj.Value) == nil then obj.Value = values[1] end
        end
        render(obj.Value)
        rebuild()
    end

    click.MouseButton1Click:Connect(function() setOpen(not open) end)
    search:GetPropertyChangedSignal("Text"):Connect(rebuild)

    render(default)
    rebuild()
    setOpen(false)
    return obj
end

function Section:AddColorPicker(flag, options, anchorRow)
    options = options or {}
    local row = anchorRow or self:_row(22)
    local swatchBtn = create("TextButton", {
        Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
        Size = UDim2.fromOffset(26,22), Text = "", AutoButtonColor = false
    })
    local swatch = create("Frame", {
        Parent = row, AnchorPoint = Vector2.new(1,.5), Position = UDim2.new(1,0,.5,0), Size = UDim2.fromOffset(16,16),
        BackgroundColor3 = options.Default or self.Window.Theme.Accent, BorderSizePixel = 0
    })
    corner(swatch, 4)

    local picker = create("Frame", {
        Parent = row, BackgroundColor3 = self.Window.Theme.Panel2, BackgroundTransparency = .06, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0,24), Size = UDim2.new(1,0,0,0), Visible = false, ClipsDescendants = true
    })
    corner(picker, 5); stroke(picker, self.Window.Theme.BorderSoft, 1)

    local satval = create("ImageLabel", {
        Parent = picker, BackgroundColor3 = Color3.fromRGB(255,0,0), BorderSizePixel = 0,
        Position = UDim2.fromOffset(8,8), Size = UDim2.fromOffset(148,148),
        Image = "rbxassetid://4155801252", ScaleType = Enum.ScaleType.Stretch
    })
    corner(satval, 4)

    local hue = create("ImageLabel", {
        Parent = picker, BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
        Position = UDim2.fromOffset(164,8), Size = UDim2.fromOffset(14,148),
        Image = "rbxassetid://3641079629", ScaleType = Enum.ScaleType.Stretch
    })
    corner(hue, 4)

    local preview = create("Frame", {
        Parent = picker, BackgroundColor3 = options.Default or self.Window.Theme.Accent,
        BorderSizePixel = 0, Position = UDim2.fromOffset(184,8), Size = UDim2.new(1,-192,24)
    })
    corner(preview, 4)

    local rgb = create("TextLabel", {
        Parent = picker, BackgroundTransparency = 1, Position = UDim2.fromOffset(184,38), Size = UDim2.new(1,-192,40),
        Font = Enum.Font.Code, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        TextSize = 12, TextColor3 = self.Window.Theme.DimText, TextXAlignment = Enum.TextXAlignment.Left
    })

    local obj = control("ColorPicker", flag, options.Default or self.Window.Theme.Accent, options.Callback)
    self.Window:_register(flag, obj)

    local open, draggingSV, draggingH = false, false, false
    local h,s,v = colorToHSV(obj.Value)

    local function updateText(c)
        rgb.Text = string.format("R:%d\nG:%d\nB:%d", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
    end

    local function apply()
        local c = hsvToColor(h,s,v)
        obj.Value = c
        swatch.BackgroundColor3 = c
        preview.BackgroundColor3 = c
        satval.BackgroundColor3 = hsvToColor(h,1,1)
        updateText(c)
    end

    function obj:Set(c)
        h,s,v = colorToHSV(c)
        apply()
        obj:_emit(obj.Value)
    end
    function obj:SetValue(c) obj:Set(c) end

    local function setOpen(state)
        open = state
        picker.Visible = state
        local ph = state and 164 or 0
        picker.Size = UDim2.new(1,0,0,ph)
        row.Size = UDim2.new(1,0,0,22 + (state and 170 or 0))
    end

    local function setSV(x,y)
        s = clamp01((x - satval.AbsolutePosition.X) / satval.AbsoluteSize.X)
        v = 1 - clamp01((y - satval.AbsolutePosition.Y) / satval.AbsoluteSize.Y)
        apply(); obj:_emit(obj.Value)
    end

    local function setHue(y)
        h = clamp01((y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y)
        apply(); obj:_emit(obj.Value)
    end

    satval.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true; setSV(i.Position.X, i.Position.Y) end end)
    hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingH = true; setHue(i.Position.Y) end end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if draggingSV then setSV(i.Position.X, i.Position.Y) end
            if draggingH then setHue(i.Position.Y) end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false; draggingH = false end
    end)

    swatchBtn.MouseButton1Click:Connect(function() setOpen(not open) end)
    apply()
    setOpen(false)
    return obj
end

function Section:AddKeyPicker(flag, options, anchorRow)
    options = options or {}
    local row = anchorRow or self:_row(22)
    local textLabel = nil
    for _,c in ipairs(row:GetChildren()) do if c:IsA("TextLabel") then textLabel = c break end end
    if not textLabel then
        textLabel = create("TextLabel", {
            Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1,-82,1,0), Font = Enum.Font.Code,
            Text = options.Text or flag, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = self.Window.Theme.Text
        })
    else
        textLabel.Size = UDim2.new(1,-82,1,0)
    end

    local display = create("TextButton", {
        Parent = row, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.fromOffset(76,22),
        Font = Enum.Font.Code, Text = tostring(options.Default or "None"), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = self.Window.Theme.Accent, AutoButtonColor = false
    })

    local obj = control("KeyPicker", flag, options.Default or "None", options.Callback)
    obj._displayName = options.Text or flag
    self.Window:_register(flag, obj)
    self.Window:_refreshBindList()

    local listening = false
    display.MouseButton1Click:Connect(function()
        listening = true
        display.Text = "..."
    end)

    table.insert(self.Window._connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if listening then
            listening = false
            if input.UserInputType == Enum.UserInputType.Keyboard then
                obj.Value = input.KeyCode.Name
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                obj.Value = "LMB"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                obj.Value = "RMB"
            else
                obj.Value = obj.Value
            end
            display.Text = tostring(obj.Value)
            obj:_emit(obj.Value)
            self.Window:_refreshBindList()
        end
    end))

    return obj
end

function Window:Destroy()
    for _,c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    if self.Blur then pcall(function() self.Blur:Destroy() end) end
    if self.Gui then self.Gui:Destroy() end
    Library._Window = nil
end

function Window:Unload() self:Destroy() end

function SaveManager:SetFolder(name) self.Folder = name end
function SaveManager:SetLibrary(window) self.Window = window end
function SaveManager:IgnoreKey(flag) self.Ignore[flag] = true end

function SaveManager:GetConfigs()
    if not listfiles or not isfolder or not makefolder then return {"default"} end
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    local out = {}
    for _,file in ipairs(listfiles(self.Folder)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then table.insert(out, name) end
    end
    table.sort(out)
    return out
end

function SaveManager:BuildConfig()
    local out = {Theme = self.Window.ThemeName, Flags = {}}
    for flag,obj in pairs(self.Window._controls) do
        if not self.Ignore[flag] then out.Flags[flag] = obj:GetValue() end
    end
    return out
end

function SaveManager:Save(name)
    name = name or "default"
    if not writefile or not makefolder or not isfolder then return false end
    if not isfolder(self.Folder) then makefolder(self.Folder) end
    writefile(self.Folder .. "/" .. name .. ".json", HttpService:JSONEncode(self:BuildConfig()))
    self.Selected = name
    return true
end

function SaveManager:Load(name)
    name = name or "default"
    if not readfile or not isfile then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return false end
    if data.Theme then self.Window:SetTheme(data.Theme) end
    for flag,value in pairs(data.Flags or {}) do
        local c = self.Window._controls[flag]
        if c then c:SetValue(value) end
    end
    self.Selected = name
    return true
end

function SaveManager:Delete(name)
    name = name or "default"
    if not delfile or not isfile then return false end
    local path = self.Folder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    delfile(path)
    return true
end

function SaveManager:BuildConfigSection(tab)
    local s = tab:AddLeftGroupbox("Manager")
    local selected = self.Selected or "default"
    local chooser = s:AddDropdown("__manager_config_select", {Text = "Config", Values = self:GetConfigs(), Default = 1})
    chooser:OnChanged(function(v) selected = v or selected end)
    local nameBox = s:AddTextbox("__manager_config_name", {Text = "Name", Default = "default", Placeholder = "config name"})
    s:AddButton({
        Text = "Refresh Configs", RightText = "refresh",
        Callback = function() chooser:SetValues(self:GetConfigs()); self.Window:Notify("Manager", "config list refreshed", 2) end
    })
    s:AddButton({
        Text = "Save name", RightText = "save",
        Callback = function()
            local name = tostring(nameBox:GetValue() or "default")
            if self:Save(name) then chooser:SetValues(self:GetConfigs()); self.Window:Notify("Manager", "saved " .. name, 2) end
        end
    })
    s:AddButton({
        Text = "Load selected", RightText = "load",
        Callback = function() if self:Load(selected or "default") then self.Window:Notify("Manager", "loaded " .. tostring(selected), 2) end end
    })
    s:AddButton({
        Text = "Delete selected", RightText = "delete",
        Callback = function() if self:Delete(selected or "default") then chooser:SetValues(self:GetConfigs()); self.Window:Notify("Manager", "deleted " .. tostring(selected), 2) end end
    })
    return s
end

function ThemeManager:SetFolder(name) self.Folder = name end
function ThemeManager:SetLibrary(window) self.Window = window end
function ThemeManager:GetThemes()
    local out = {}
    for name in pairs(Themes) do table.insert(out, name) end
    table.sort(out)
    return out
end
function ThemeManager:SetTheme(name) self.Window:SetTheme(name) end
function ThemeManager:ApplyToTab(tab)
    local s = tab:AddRightGroupbox("Manager")
    for _,name in ipairs(self:GetThemes()) do
        s:AddButton({
            Text = "Load " .. name, RightText = "theme",
            Callback = function() self:SetTheme(name); self.Window:Notify("Manager", name .. " loaded", 2) end
        })
    end
    return s
end

function Library:Notify(title, text, duration) if self._Window then self._Window:Notify(title, text, duration) end end
function Library:Unload() if self._Window then self._Window:Destroy() end end

function Library:CreateWindow(options)
    options = copy(options or {})
    local w = setmetatable({
        Options = options,
        ThemeName = options.Theme or "Augustus",
        Theme = Themes[options.Theme or "Augustus"] or Themes.Augustus,
        Tabs = {}, CurrentTab = nil, _themeBinds = {}, _connections = {}, _controls = {},
        Open = options.AutoShow ~= false,
    }, Window)

    w.SaveManager = setmetatable({Folder = options.ConfigFolder or "AugustusConfigs", Ignore = {}, Window = w, Selected = "default"}, SaveManager)
    w.ThemeManager = setmetatable({Window = w, Folder = options.ThemeFolder or "AugustusThemes"}, ThemeManager)

    w:_create()
    w:_wire()
    w:SetOpen(options.AutoShow ~= false)
    Library._Window = w
    return w
end

return Library
