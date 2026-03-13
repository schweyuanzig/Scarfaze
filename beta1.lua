local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Scarfaze = {
    Active = true,
    Flags = {},
    Tabs = {},
    Addons = {},
    Theme = {
        Accent     = Color3.fromRGB(0, 255, 150),
        Background = Color3.fromRGB(10, 10, 10),
        Surface    = Color3.fromRGB(18, 18, 18),
        Surface2   = Color3.fromRGB(25, 25, 25),
        Surface3   = Color3.fromRGB(35, 35, 35),
        Text       = Color3.fromRGB(240, 240, 240),
        SubText    = Color3.fromRGB(150, 150, 150),
        Danger     = Color3.fromRGB(220, 60, 60),
        Warning    = Color3.fromRGB(255, 180, 0),
        Success    = Color3.fromRGB(0, 220, 120),
    },
    Presets = {
        ["Neon Green"]  = Color3.fromRGB(0, 255, 150),
        ["Neon Blue"]   = Color3.fromRGB(0, 150, 255),
        ["Neon Pink"]   = Color3.fromRGB(255, 50, 180),
        ["Neon Yellow"] = Color3.fromRGB(255, 230, 0),
        ["Neon Orange"] = Color3.fromRGB(255, 100, 0),
        ["Neon Purple"] = Color3.fromRGB(160, 0, 255),
        ["White"]       = Color3.fromRGB(255, 255, 255),
    }
}

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function Padding(parent, all)
    local p = Instance.new("UIPadding", parent)
    p.PaddingLeft   = UDim.new(0, all or 8)
    p.PaddingRight  = UDim.new(0, all or 8)
    p.PaddingTop    = UDim.new(0, all or 8)
    p.PaddingBottom = UDim.new(0, all or 8)
    return p
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or Color3.fromRGB(60, 60, 60)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    return s
end

local function AccentTint(color, factor)
    return Color3.fromRGB(
        math.floor(color.R * 255 * factor),
        math.floor(color.G * 255 * factor),
        math.floor(color.B * 255 * factor)
    )
end

local NotifyContainer

function Scarfaze:SaveConfig(name)
    local path = (name or "default") .. "_Scarfaze.json"
    local ok, err = pcall(function()
        writefile(path, HttpService:JSONEncode(self.Flags))
    end)
    if ok then
        self:Notify("Config Saved", "'" .. path .. "' saved successfully.", "Success", 4)
    else
        self:Notify("Error", tostring(err), "Danger", 4)
    end
end

function Scarfaze:LoadConfig(name)
    local path = (name or "default") .. "_Scarfaze.json"
    if isfile(path) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if ok and data then
            for k, v in pairs(data) do self.Flags[k] = v end
            self:Notify("Config Loaded", "'" .. path .. "' loaded successfully.", "Success", 4)
            return data
        end
    else
        self:Notify("Not Found", "Config file does not exist.", "Warning", 4)
    end
end

function Scarfaze:Notify(title, text, notifType, duration)
    if not NotifyContainer then return end
    notifType = notifType or "Info"
    duration  = duration or 3

    local colors = {
        Success = self.Theme.Success,
        Danger  = self.Theme.Danger,
        Warning = self.Theme.Warning,
        Info    = self.Theme.Accent,
    }
    local accentColor = colors[notifType] or self.Theme.Accent

    local N = Instance.new("Frame", NotifyContainer)
    N.Size = UDim2.new(1, 0, 0, 70)
    N.BackgroundColor3 = self.Theme.Surface
    N.BackgroundTransparency = 1
    N.AutomaticSize = Enum.AutomaticSize.Y
    N.ClipsDescendants = true
    Corner(N, 10)
    Stroke(N, accentColor, 1.5)

    local Bar = Instance.new("Frame", N)
    Bar.Size = UDim2.new(0, 4, 1, 0)
    Bar.BackgroundColor3 = accentColor
    Corner(Bar, 4)

    local Inner = Instance.new("Frame", N)
    Inner.Size = UDim2.new(1, -16, 1, 0)
    Inner.Position = UDim2.new(0, 14, 0, 0)
    Inner.BackgroundTransparency = 1
    Inner.AutomaticSize = Enum.AutomaticSize.Y

    local TitleLbl = Instance.new("TextLabel", Inner)
    TitleLbl.Size = UDim2.new(1, 0, 0, 22)
    TitleLbl.Position = UDim2.new(0, 0, 0, 8)
    TitleLbl.Text = title
    TitleLbl.TextColor3 = accentColor
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 15
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1

    local BodyLbl = Instance.new("TextLabel", Inner)
    BodyLbl.Size = UDim2.new(1, 0, 0, 0)
    BodyLbl.Position = UDim2.new(0, 0, 0, 32)
    BodyLbl.Text = text
    BodyLbl.TextColor3 = self.Theme.SubText
    BodyLbl.Font = Enum.Font.Gotham
    BodyLbl.TextSize = 13
    BodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    BodyLbl.TextWrapped = true
    BodyLbl.AutomaticSize = Enum.AutomaticSize.Y
    BodyLbl.BackgroundTransparency = 1

    local Prog = Instance.new("Frame", N)
    Prog.Size = UDim2.new(1, 0, 0, 2)
    Prog.Position = UDim2.new(0, 0, 1, -2)
    Prog.BackgroundColor3 = accentColor
    Prog.BorderSizePixel = 0

    Tween(N, { BackgroundTransparency = 0 }, 0.3)
    Tween(Prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        Tween(N, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        N:Destroy()
    end)
end

function Scarfaze:ApplyTheme(accentColor)
    self.Theme.Accent = accentColor
    if self._titleLabel then
        Tween(self._titleLabel, { TextColor3 = accentColor }, 0.3)
    end
    self:Notify("Theme Changed", "New accent color applied.", "Success", 3)
end

function Scarfaze:CreateWindow(config)
    config = config or {}
    local hubName   = config.Name      or "Scarfaze V3 Pro"
    local toggleKey = config.Key       or Enum.KeyCode.RightShift
    local watermark = config.Watermark ~= false

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Scarfaze_V3Pro"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end
    self.ScreenGui = ScreenGui

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 700, 0, 500)
    Main.Position = UDim2.new(0.5, -350, 0.5, -250)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Corner(Main, 14)
    Stroke(Main, Color3.fromRGB(40, 40, 40), 1.5)

    local Shadow = Instance.new("ImageLabel", Main)
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.Image = "rbxassetid://5028857084"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.BackgroundTransparency = 1
    Shadow.ZIndex = -1
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(24, 24, 276, 276)

    local dragging, dragStart, startPos
    local _sliderActive = false
    Scarfaze._sliderActive = _sliderActive

    local DragHandle = Instance.new("Frame", Main)
    DragHandle.Name = "DragHandle"
    DragHandle.Size = UDim2.new(1, 0, 0, 50)
    DragHandle.Position = UDim2.new(0, 0, 0, 0)
    DragHandle.BackgroundTransparency = 1
    DragHandle.ZIndex = 0

    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and not Scarfaze._sliderActive and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 200, 1, 0)
    Sidebar.BackgroundColor3 = self.Theme.Surface
    Sidebar.BorderSizePixel = 0
    Corner(Sidebar, 14)

    local LogoFrame = Instance.new("Frame", Sidebar)
    LogoFrame.Size = UDim2.new(1, 0, 0, 80)
    LogoFrame.BackgroundTransparency = 1

    local TitleLabel = Instance.new("TextLabel", LogoFrame)
    TitleLabel.Size = UDim2.new(1, 0, 0, 36)
    TitleLabel.Position = UDim2.new(0, 0, 0, 10)
    TitleLabel.Text = hubName
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextSize = 26
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.BackgroundTransparency = 1
    self._titleLabel = TitleLabel

    local SubLabel = Instance.new("TextLabel", LogoFrame)
    SubLabel.Size = UDim2.new(1, 0, 0, 16)
    SubLabel.Position = UDim2.new(0, 0, 0, 50)
    SubLabel.Text = "v3 pro edition"
    SubLabel.TextColor3 = self.Theme.SubText
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 12
    SubLabel.TextXAlignment = Enum.TextXAlignment.Center
    SubLabel.BackgroundTransparency = 1

    local Sep1 = Instance.new("Frame", Sidebar)
    Sep1.Size = UDim2.new(1, -30, 0, 1)
    Sep1.Position = UDim2.new(0, 15, 0, 80)
    Sep1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep1.BorderSizePixel = 0

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Size = UDim2.new(1, 0, 1, -170)
    TabList.Position = UDim2.new(0, 0, 0, 90)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 3
    TabList.ScrollBarImageColor3 = self.Theme.Accent
    TabList.BorderSizePixel = 0
    Padding(TabList, 10)
    local TabListLayout = Instance.new("UIListLayout", TabList)
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local BottomFrame = Instance.new("Frame", Sidebar)
    BottomFrame.Size = UDim2.new(1, 0, 0, 80)
    BottomFrame.Position = UDim2.new(0, 0, 1, -80)
    BottomFrame.BackgroundTransparency = 1

    local Sep2 = Instance.new("Frame", BottomFrame)
    Sep2.Size = UDim2.new(1, -30, 0, 1)
    Sep2.Position = UDim2.new(0, 15, 0, 0)
    Sep2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Sep2.BorderSizePixel = 0

    local UnloadBtn = Instance.new("TextButton", BottomFrame)
    UnloadBtn.Size = UDim2.new(1, -20, 0, 36)
    UnloadBtn.Position = UDim2.new(0, 10, 0, 10)
    UnloadBtn.Text = "⏻  Unload Hub"
    UnloadBtn.TextSize = 14
    UnloadBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
    UnloadBtn.TextColor3 = self.Theme.Danger
    UnloadBtn.Font = Enum.Font.GothamBold
    Corner(UnloadBtn, 8)
    Stroke(UnloadBtn, self.Theme.Danger, 1, 0.5)
    UnloadBtn.MouseEnter:Connect(function()
        Tween(UnloadBtn, { BackgroundColor3 = self.Theme.Danger, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
    end)
    UnloadBtn.MouseLeave:Connect(function()
        Tween(UnloadBtn, { BackgroundColor3 = Color3.fromRGB(60, 20, 20), TextColor3 = self.Theme.Danger }, 0.2)
    end)
    UnloadBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        self.Active = false
    end)

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, -215, 1, -15)
    ContentArea.Position = UDim2.new(0, 210, 0, 8)
    ContentArea.BackgroundTransparency = 1

    NotifyContainer = Instance.new("Frame", ScreenGui)
    NotifyContainer.Size = UDim2.new(0, 280, 1, 0)
    NotifyContainer.Position = UDim2.new(1, -295, 0, 0)
    NotifyContainer.BackgroundTransparency = 1
    local NotifyLayout = Instance.new("UIListLayout", NotifyContainer)
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.Padding = UDim.new(0, 8)
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    Padding(NotifyContainer, 12)

    if watermark then
        local WM = Instance.new("TextLabel", ScreenGui)
        WM.Size = UDim2.new(0, 220, 0, 28)
        WM.Position = UDim2.new(0, 12, 0, 12)
        WM.Text = hubName .. "  |  " .. LocalPlayer.Name
        WM.TextColor3 = self.Theme.Accent
        WM.Font = Enum.Font.GothamBold
        WM.TextSize = 13
        WM.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        WM.TextXAlignment = Enum.TextXAlignment.Left
        Corner(WM, 6)
        Padding(WM, 8)
        Stroke(WM, self.Theme.Accent, 1, 0.6)
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            Main.Visible = not Main.Visible
        end
    end)

    local Window = { _tabBtns = {}, _pages = {} }

    local function setActiveTab(page, btn)
        for _, p in pairs(Window._pages) do p.Visible = false end
        for _, b in pairs(Window._tabBtns) do
            Tween(b, { BackgroundColor3 = Scarfaze.Theme.Surface2, TextColor3 = Scarfaze.Theme.SubText }, 0.15)
        end
        page.Visible = true
        Tween(btn, { BackgroundColor3 = AccentTint(Scarfaze.Theme.Accent, 0.15), TextColor3 = Scarfaze.Theme.Accent }, 0.15)
    end

    function Window:AddTab(name, icon)
        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = false
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Scarfaze.Theme.Accent
        Page.BorderSizePixel = 0
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Padding(Page, 8)

        local TBtn = Instance.new("TextButton", TabList)
        TBtn.Size = UDim2.new(1, 0, 0, 40)
        TBtn.Text = (icon and icon .. "  " or "  ") .. name
        TBtn.TextSize = 15
        TBtn.BackgroundColor3 = Scarfaze.Theme.Surface2
        TBtn.TextColor3 = Scarfaze.Theme.SubText
        TBtn.Font = Enum.Font.GothamMedium
        TBtn.TextXAlignment = Enum.TextXAlignment.Left
        Corner(TBtn, 8)
        Padding(TBtn, 12)
        TBtn.MouseEnter:Connect(function()
            if Page.Visible then return end
            Tween(TBtn, { BackgroundColor3 = Scarfaze.Theme.Surface3 }, 0.15)
        end)
        TBtn.MouseLeave:Connect(function()
            if Page.Visible then return end
            Tween(TBtn, { BackgroundColor3 = Scarfaze.Theme.Surface2 }, 0.15)
        end)
        table.insert(Window._tabBtns, TBtn)
        table.insert(Window._pages, Page)
        TBtn.MouseButton1Click:Connect(function() setActiveTab(Page, TBtn) end)
        if #Window._pages == 1 then setActiveTab(Page, TBtn) end

        local Elements = {}

        function Elements:AddSection(title)
            local S = Instance.new("TextLabel", Page)
            S.Size = UDim2.new(1, 0, 0, 30)
            S.Text = "  " .. string.upper(title)
            S.TextColor3 = Scarfaze.Theme.Accent
            S.Font = Enum.Font.GothamBlack
            S.TextSize = 11
            S.TextXAlignment = Enum.TextXAlignment.Left
            S.BackgroundColor3 = AccentTint(Scarfaze.Theme.Accent, 0.08)
            Corner(S, 6)
            Stroke(S, Scarfaze.Theme.Accent, 1, 0.7)
            return S
        end

        function Elements:AddLabel(text)
            local L = Instance.new("TextLabel", Page)
            L.Size = UDim2.new(1, 0, 0, 36)
            L.Text = "  " .. text
            L.TextColor3 = Scarfaze.Theme.SubText
            L.Font = Enum.Font.Gotham
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left
            L.BackgroundColor3 = Scarfaze.Theme.Surface2
            L.TextWrapped = true
            Corner(L, 8)
            local obj = {}
            function obj:Set(newText) L.Text = "  " .. newText end
            return obj
        end

        function Elements:AddToggle(opts)
            opts = opts or {}
            local text     = opts.Text or "Toggle"
            local flag     = opts.Flag or text
            local default  = opts.Default or false
            local callback = opts.Callback or function() end
            local desc     = opts.Description

            local state = Scarfaze.Flags[flag]
            if state == nil then state = default end

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, desc and 62 or 48)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size = UDim2.new(1, -60, 0, 22)
            Lbl.Position = UDim2.new(0, 12, 0, desc and 8 or 13)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            if desc then
                local Desc = Instance.new("TextLabel", Row)
                Desc.Size = UDim2.new(1, -60, 0, 16)
                Desc.Position = UDim2.new(0, 12, 0, 32)
                Desc.Text = desc
                Desc.TextColor3 = Scarfaze.Theme.SubText
                Desc.Font = Enum.Font.Gotham
                Desc.TextSize = 12
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
            end

            local Track = Instance.new("Frame", Row)
            Track.Size = UDim2.new(0, 44, 0, 24)
            Track.Position = UDim2.new(1, -56, 0.5, -12)
            Track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Corner(Track, 12)

            local Knob = Instance.new("Frame", Track)
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = UDim2.new(0, 3, 0.5, -9)
            Knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
            Corner(Knob, 9)

            local function updateVisual()
                if state then
                    Tween(Track, { BackgroundColor3 = Scarfaze.Theme.Accent }, 0.2)
                    Tween(Knob, { Position = UDim2.new(1, -21, 0.5, -9), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.2)
                else
                    Tween(Track, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) }, 0.2)
                    Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -9), BackgroundColor3 = Color3.fromRGB(150, 150, 150) }, 0.2)
                end
                Scarfaze.Flags[flag] = state
                callback(state)
            end

            Row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    state = not state
                    updateVisual()
                end
            end)
            updateVisual()

            local obj = {}
            function obj:Set(val) state = val; updateVisual() end
            function obj:Get() return state end
            return obj
        end

        function Elements:AddButton(opts)
            opts = opts or {}
            local text     = opts.Text or "Button"
            local callback = opts.Callback or function() end
            local color    = opts.Color
            local desc     = opts.Description

            local Btn = Instance.new("TextButton", Page)
            Btn.Size = UDim2.new(1, 0, 0, desc and 62 or 46)
            Btn.BackgroundColor3 = color or Scarfaze.Theme.Surface3
            Btn.Text = ""
            Btn.BorderSizePixel = 0
            Corner(Btn, 10)
            Stroke(Btn, Color3.fromRGB(55, 55, 55), 1)

            local Lbl = Instance.new("TextLabel", Btn)
            Lbl.Size = UDim2.new(1, -20, 0, 22)
            Lbl.Position = UDim2.new(0, 12, 0, desc and 8 or 12)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamBold
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            if desc then
                local Desc = Instance.new("TextLabel", Btn)
                Desc.Size = UDim2.new(1, -20, 0, 16)
                Desc.Position = UDim2.new(0, 12, 0, 32)
                Desc.Text = desc
                Desc.TextColor3 = Scarfaze.Theme.SubText
                Desc.Font = Enum.Font.Gotham
                Desc.TextSize = 12
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
            end

            local Arrow = Instance.new("TextLabel", Btn)
            Arrow.Size = UDim2.new(0, 20, 1, 0)
            Arrow.Position = UDim2.new(1, -28, 0, 0)
            Arrow.Text = "›"
            Arrow.TextColor3 = Scarfaze.Theme.SubText
            Arrow.Font = Enum.Font.GothamBold
            Arrow.TextSize = 22
            Arrow.BackgroundTransparency = 1

            local origColor = color or Scarfaze.Theme.Surface3
            Btn.MouseEnter:Connect(function()
                Tween(Btn, { BackgroundColor3 = Color3.fromRGB(
                    math.min(origColor.R * 255 + 12, 255) / 255,
                    math.min(origColor.G * 255 + 12, 255) / 255,
                    math.min(origColor.B * 255 + 12, 255) / 255
                ) }, 0.15)
            end)
            Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = origColor }, 0.15) end)
            Btn.MouseButton1Down:Connect(function() Tween(Btn, { BackgroundColor3 = Scarfaze.Theme.Accent }, 0.1) end)
            Btn.MouseButton1Up:Connect(function() Tween(Btn, { BackgroundColor3 = origColor }, 0.15) end)
            Btn.MouseButton1Click:Connect(callback)
        end

        function Elements:AddSlider(opts)
            opts = opts or {}
            local text     = opts.Text or "Slider"
            local flag     = opts.Flag or text
            local min      = opts.Min or 0
            local max      = opts.Max or 100
            local default  = opts.Default or min
            local suffix   = opts.Suffix or ""
            local callback = opts.Callback or function() end

            local value = Scarfaze.Flags[flag] or default

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 68)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size = UDim2.new(0.6, 0, 0, 22)
            Lbl.Position = UDim2.new(0, 12, 0, 8)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local ValLbl = Instance.new("TextLabel", Row)
            ValLbl.Size = UDim2.new(0.35, 0, 0, 22)
            ValLbl.Position = UDim2.new(0.65, -12, 0, 8)
            ValLbl.Text = tostring(value) .. suffix
            ValLbl.TextColor3 = Scarfaze.Theme.Accent
            ValLbl.Font = Enum.Font.GothamBold
            ValLbl.TextSize = 15
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.BackgroundTransparency = 1

            local Track = Instance.new("Frame", Row)
            Track.Size = UDim2.new(1, -24, 0, 6)
            Track.Position = UDim2.new(0, 12, 0, 44)
            Track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            Corner(Track, 3)

            local Fill = Instance.new("Frame", Track)
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Scarfaze.Theme.Accent
            Corner(Fill, 3)

            local Handle = Instance.new("Frame", Track)
            Handle.Size = UDim2.new(0, 14, 0, 14)
            Handle.AnchorPoint = Vector2.new(0.5, 0.5)
            Handle.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Corner(Handle, 7)

            local SliderBtn = Instance.new("TextButton", Track)
            SliderBtn.Size = UDim2.new(1, 0, 1, 0)
            SliderBtn.BackgroundTransparency = 1
            SliderBtn.Text = ""
            SliderBtn.ZIndex = 2

            local draggingSlider = false
            local function updateSlider(inputPos)
                local rel = math.clamp((inputPos.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local raw = min + (max - min) * rel
                value = opts.Integer and math.floor(raw + 0.5) or (math.floor(raw * 10 + 0.5) / 10)
                value = math.clamp(value, min, max)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                Handle.Position = UDim2.new(rel, 0, 0.5, 0)
                ValLbl.Text = tostring(value) .. suffix
                Scarfaze.Flags[flag] = value
                callback(value)
            end

            SliderBtn.MouseButton1Down:Connect(function()
                draggingSlider = true
                Scarfaze._sliderActive = true
                local mousePos = UserInputService:GetMouseLocation()
                updateSlider(mousePos)
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                    Scarfaze._sliderActive = false
                end
            end)

            local obj = {}
            function obj:Set(v)
                value = math.clamp(v, min, max)
                local rel = (value - min) / (max - min)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                Handle.Position = UDim2.new(rel, 0, 0.5, 0)
                ValLbl.Text = tostring(value) .. suffix
                Scarfaze.Flags[flag] = value
                callback(value)
            end
            function obj:Get() return value end
            return obj
        end

        function Elements:AddDropdown(opts)
            opts = opts or {}
            local text     = opts.Text or "Dropdown"
            local flag     = opts.Flag or text
            local options  = opts.Options or {}
            local default  = opts.Default or options[1] or ""
            local callback = opts.Callback or function() end
            local multi    = opts.Multi or false

            local selected = Scarfaze.Flags[flag] or (multi and {} or default)
            local opened = false

            local Wrapper = Instance.new("Frame", Page)
            Wrapper.Size = UDim2.new(1, 0, 0, 50)
            Wrapper.BackgroundColor3 = Scarfaze.Theme.Surface2
            Wrapper.ClipsDescendants = false
            Corner(Wrapper, 10)
            Stroke(Wrapper, Color3.fromRGB(45, 45, 45), 1)

            local Header = Instance.new("TextButton", Wrapper)
            Header.Size = UDim2.new(1, 0, 0, 50)
            Header.BackgroundTransparency = 1
            Header.Text = ""

            local Lbl = Instance.new("TextLabel", Header)
            Lbl.Size = UDim2.new(0.65, 0, 1, 0)
            Lbl.Position = UDim2.new(0, 12, 0, 0)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local SelLbl = Instance.new("TextLabel", Header)
            SelLbl.Size = UDim2.new(0.3, 0, 1, 0)
            SelLbl.Position = UDim2.new(0.67, 0, 0, 0)
            SelLbl.Text = multi and "Select..." or tostring(selected)
            SelLbl.TextColor3 = Scarfaze.Theme.Accent
            SelLbl.Font = Enum.Font.Gotham
            SelLbl.TextSize = 13
            SelLbl.TextXAlignment = Enum.TextXAlignment.Right
            SelLbl.BackgroundTransparency = 1

            local Arrow = Instance.new("TextLabel", Header)
            Arrow.Size = UDim2.new(0, 20, 1, 0)
            Arrow.Position = UDim2.new(1, -24, 0, 0)
            Arrow.Text = "▾"
            Arrow.TextColor3 = Scarfaze.Theme.SubText
            Arrow.Font = Enum.Font.GothamBold
            Arrow.TextSize = 16
            Arrow.BackgroundTransparency = 1

            local DropList = Instance.new("Frame", Wrapper)
            DropList.Size = UDim2.new(1, 0, 0, 0)
            DropList.Position = UDim2.new(0, 0, 1, 6)
            DropList.BackgroundColor3 = Scarfaze.Theme.Surface
            DropList.ClipsDescendants = true
            DropList.ZIndex = 10
            DropList.Visible = false
            Corner(DropList, 10)
            Stroke(DropList, Color3.fromRGB(50, 50, 50), 1)

            local DropScroll = Instance.new("ScrollingFrame", DropList)
            DropScroll.Size = UDim2.new(1, 0, 1, 0)
            DropScroll.BackgroundTransparency = 1
            DropScroll.ScrollBarThickness = 3
            DropScroll.BorderSizePixel = 0
            DropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            DropScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            DropScroll.ZIndex = 10
            local DropLayout = Instance.new("UIListLayout", DropScroll)
            DropLayout.Padding = UDim.new(0, 4)
            DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            Padding(DropScroll, 6)

            local function buildOptions()
                for _, child in pairs(DropScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local OBtn = Instance.new("TextButton", DropScroll)
                    OBtn.Size = UDim2.new(1, 0, 0, 34)
                    OBtn.Text = "  " .. tostring(opt)
                    OBtn.TextSize = 14
                    OBtn.Font = Enum.Font.Gotham
                    OBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OBtn.ZIndex = 11
                    Corner(OBtn, 6)

                    local function refreshColor()
                        local isSel = multi and table.find(selected, opt) or (selected == opt)
                        OBtn.BackgroundColor3 = isSel and AccentTint(Scarfaze.Theme.Accent, 0.2) or Scarfaze.Theme.Surface3
                        OBtn.TextColor3 = isSel and Scarfaze.Theme.Accent or Scarfaze.Theme.Text
                    end
                    refreshColor()

                    OBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(selected, opt)
                            if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                            SelLbl.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
                        else
                            selected = opt
                            SelLbl.Text = opt
                            opened = false
                            Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 50) }, 0.2)
                            DropList.Visible = false
                            Tween(Arrow, { Rotation = 0 }, 0.2)
                        end
                        Scarfaze.Flags[flag] = selected
                        callback(selected)
                        refreshColor()
                    end)
                end
            end
            buildOptions()

            local dropH = math.min(#options * 42 + 12, 180)
            Header.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    DropList.Visible = true
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 50 + dropH + 6) }, 0.2)
                    Tween(DropList, { Size = UDim2.new(1, 0, 0, dropH) }, 0.2)
                    Tween(Arrow, { Rotation = 180 }, 0.2)
                else
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 50) }, 0.2)
                    Tween(DropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    Tween(Arrow, { Rotation = 0 }, 0.2)
                    task.delay(0.25, function() DropList.Visible = false end)
                end
            end)

            local obj = {}
            function obj:Set(val)
                selected = val
                SelLbl.Text = multi and table.concat(val, ", ") or val
                Scarfaze.Flags[flag] = selected
                callback(selected)
                buildOptions()
            end
            function obj:SetOptions(newOpts) options = newOpts; buildOptions() end
            function obj:Get() return selected end
            return obj
        end

        function Elements:AddTextInput(opts)
            opts = opts or {}
            local text        = opts.Text or "Input"
            local flag        = opts.Flag or text
            local placeholder = opts.Placeholder or "Type here..."
            local default     = opts.Default or ""
            local callback    = opts.Callback or function() end
            local numeric     = opts.Numeric or false

            local value = Scarfaze.Flags[flag] or default

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 70)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size = UDim2.new(1, -20, 0, 20)
            Lbl.Position = UDim2.new(0, 12, 0, 8)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local InputBox = Instance.new("Frame", Row)
            InputBox.Size = UDim2.new(1, -24, 0, 32)
            InputBox.Position = UDim2.new(0, 12, 0, 32)
            InputBox.BackgroundColor3 = Scarfaze.Theme.Surface3
            Corner(InputBox, 8)
            Stroke(InputBox, Color3.fromRGB(60, 60, 60), 1)

            local TB = Instance.new("TextBox", InputBox)
            TB.Size = UDim2.new(1, -16, 1, 0)
            TB.Position = UDim2.new(0, 8, 0, 0)
            TB.PlaceholderText = placeholder
            TB.Text = value
            TB.TextColor3 = Scarfaze.Theme.Text
            TB.PlaceholderColor3 = Scarfaze.Theme.SubText
            TB.Font = Enum.Font.Gotham
            TB.TextSize = 14
            TB.TextXAlignment = Enum.TextXAlignment.Left
            TB.BackgroundTransparency = 1
            TB.ClearTextOnFocus = false

            TB.Focused:Connect(function()
                Tween(InputBox, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) }, 0.15)
                Stroke(InputBox, Scarfaze.Theme.Accent, 1)
            end)
            TB.FocusLost:Connect(function(enterPressed)
                Tween(InputBox, { BackgroundColor3 = Scarfaze.Theme.Surface3 }, 0.15)
                Stroke(InputBox, Color3.fromRGB(60, 60, 60), 1)
                local val = TB.Text
                if numeric then val = tonumber(val) or 0 end
                value = val
                Scarfaze.Flags[flag] = value
                callback(value, enterPressed)
            end)

            local obj = {}
            function obj:Set(v) TB.Text = tostring(v); value = v; Scarfaze.Flags[flag] = v; callback(v, false) end
            function obj:Get() return value end
            return obj
        end

        function Elements:AddKeybind(opts)
            opts = opts or {}
            local text     = opts.Text or "Keybind"
            local flag     = opts.Flag or text
            local default  = opts.Default or Enum.KeyCode.Unknown
            local callback = opts.Callback or function() end

            local key = Scarfaze.Flags[flag] or default
            local listening = false

            local Row = Instance.new("Frame", Page)
            Row.Size = UDim2.new(1, 0, 0, 50)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size = UDim2.new(0.65, 0, 1, 0)
            Lbl.Position = UDim2.new(0, 12, 0, 0)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local KeyBtn = Instance.new("TextButton", Row)
            KeyBtn.Size = UDim2.new(0, 90, 0, 30)
            KeyBtn.Position = UDim2.new(1, -100, 0.5, -15)
            KeyBtn.Text = tostring(key.Name)
            KeyBtn.TextSize = 13
            KeyBtn.BackgroundColor3 = Scarfaze.Theme.Surface3
            KeyBtn.TextColor3 = Scarfaze.Theme.Accent
            KeyBtn.Font = Enum.Font.GothamBold
            Corner(KeyBtn, 6)
            Stroke(KeyBtn, Scarfaze.Theme.Accent, 1, 0.5)

            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "..."
                KeyBtn.TextColor3 = Scarfaze.Theme.Warning
            end)
            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and not gpe and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    key = input.KeyCode
                    KeyBtn.Text = key.Name
                    KeyBtn.TextColor3 = Scarfaze.Theme.Accent
                    Scarfaze.Flags[flag] = key
                end
                if not gpe and input.KeyCode == key then callback(key) end
            end)

            local obj = {}
            function obj:Set(k) key = k; KeyBtn.Text = k.Name; Scarfaze.Flags[flag] = k end
            function obj:Get() return key end
            return obj
        end

        function Elements:AddColorPicker(opts)
            opts = opts or {}
            local text     = opts.Text or "Color"
            local flag     = opts.Flag or text
            local default  = opts.Default or Color3.fromRGB(255, 0, 100)
            local callback = opts.Callback or function() end

            local color = Scarfaze.Flags[flag] or default
            local h, s, v = Color3.toHSV(color)
            local opened = false

            local Wrapper = Instance.new("Frame", Page)
            Wrapper.Size = UDim2.new(1, 0, 0, 50)
            Wrapper.BackgroundColor3 = Scarfaze.Theme.Surface2
            Wrapper.ClipsDescendants = false
            Corner(Wrapper, 10)
            Stroke(Wrapper, Color3.fromRGB(45, 45, 45), 1)

            local Header = Instance.new("TextButton", Wrapper)
            Header.Size = UDim2.new(1, 0, 0, 50)
            Header.BackgroundTransparency = 1
            Header.Text = ""

            local Lbl = Instance.new("TextLabel", Header)
            Lbl.Size = UDim2.new(0.7, 0, 1, 0)
            Lbl.Position = UDim2.new(0, 12, 0, 0)
            Lbl.Text = text
            Lbl.TextColor3 = Scarfaze.Theme.Text
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.TextSize = 15
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local Preview = Instance.new("Frame", Header)
            Preview.Size = UDim2.new(0, 32, 0, 22)
            Preview.Position = UDim2.new(1, -44, 0.5, -11)
            Preview.BackgroundColor3 = color
            Corner(Preview, 6)
            Stroke(Preview, Color3.fromRGB(80, 80, 80), 1)

            local Panel = Instance.new("Frame", Wrapper)
            Panel.Size = UDim2.new(1, 0, 0, 0)
            Panel.Position = UDim2.new(0, 0, 1, 6)
            Panel.BackgroundColor3 = Scarfaze.Theme.Surface
            Panel.ClipsDescendants = true
            Panel.ZIndex = 10
            Panel.Visible = false
            Corner(Panel, 10)
            Stroke(Panel, Color3.fromRGB(50, 50, 50), 1)

            local HueLbl = Instance.new("TextLabel", Panel)
            HueLbl.Size = UDim2.new(1, -24, 0, 16)
            HueLbl.Position = UDim2.new(0, 12, 0, 10)
            HueLbl.Text = "Hue"
            HueLbl.TextColor3 = Scarfaze.Theme.SubText
            HueLbl.Font = Enum.Font.Gotham
            HueLbl.TextSize = 12
            HueLbl.TextXAlignment = Enum.TextXAlignment.Left
            HueLbl.BackgroundTransparency = 1
            HueLbl.ZIndex = 11

            local HueTrack = Instance.new("Frame", Panel)
            HueTrack.Size = UDim2.new(1, -24, 0, 16)
            HueTrack.Position = UDim2.new(0, 12, 0, 28)
            HueTrack.ZIndex = 11
            Corner(HueTrack, 8)
            local HueGrad = Instance.new("UIGradient", HueTrack)
            HueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0, 0)),
            })

            local HueHandle = Instance.new("Frame", HueTrack)
            HueHandle.Size = UDim2.new(0, 12, 1, 4)
            HueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
            HueHandle.Position = UDim2.new(h, 0, 0.5, 0)
            HueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueHandle.ZIndex = 12
            Corner(HueHandle, 6)
            Stroke(HueHandle, Color3.fromRGB(0, 0, 0), 1, 0.5)

            local SVLbl = Instance.new("TextLabel", Panel)
            SVLbl.Size = UDim2.new(1, -24, 0, 16)
            SVLbl.Position = UDim2.new(0, 12, 0, 52)
            SVLbl.Text = "Saturation / Value"
            SVLbl.TextColor3 = Scarfaze.Theme.SubText
            SVLbl.Font = Enum.Font.Gotham
            SVLbl.TextSize = 12
            SVLbl.TextXAlignment = Enum.TextXAlignment.Left
            SVLbl.BackgroundTransparency = 1
            SVLbl.ZIndex = 11

            local SVBox = Instance.new("Frame", Panel)
            SVBox.Size = UDim2.new(1, -24, 0, 100)
            SVBox.Position = UDim2.new(0, 12, 0, 70)
            SVBox.ZIndex = 11
            Corner(SVBox, 8)

            local SVHueFrame = Instance.new("Frame", SVBox)
            SVHueFrame.Size = UDim2.new(1, 0, 1, 0)
            SVHueFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            SVHueFrame.ZIndex = 10
            Corner(SVHueFrame, 8)
            local SVGradS = Instance.new("UIGradient", SVHueFrame)
            SVGradS.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) })
            SVGradS.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })

            local SVGradV = Instance.new("Frame", SVHueFrame)
            SVGradV.Size = UDim2.new(1, 0, 1, 0)
            SVGradV.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            SVGradV.ZIndex = 11
            Corner(SVGradV, 8)
            local SVGradVG = Instance.new("UIGradient", SVGradV)
            SVGradVG.Rotation = 90
            SVGradVG.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })

            local SVHandle = Instance.new("Frame", SVBox)
            SVHandle.Size = UDim2.new(0, 12, 0, 12)
            SVHandle.AnchorPoint = Vector2.new(0.5, 0.5)
            SVHandle.Position = UDim2.new(s, 0, 1 - v, 0)
            SVHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SVHandle.ZIndex = 14
            Corner(SVHandle, 6)
            Stroke(SVHandle, Color3.fromRGB(0, 0, 0), 1.5)

            local HexLbl = Instance.new("TextLabel", Panel)
            HexLbl.Size = UDim2.new(1, -24, 0, 28)
            HexLbl.Position = UDim2.new(0, 12, 0, 178)
            HexLbl.Text = string.format("HEX: #%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
            HexLbl.TextColor3 = Scarfaze.Theme.SubText
            HexLbl.Font = Enum.Font.RobotoMono
            HexLbl.TextSize = 13
            HexLbl.TextXAlignment = Enum.TextXAlignment.Center
            HexLbl.BackgroundColor3 = Scarfaze.Theme.Surface3
            HexLbl.ZIndex = 11
            Corner(HexLbl, 6)

            local function applyColor()
                color = Color3.fromHSV(h, s, v)
                Preview.BackgroundColor3 = color
                SVHueFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                HueHandle.Position = UDim2.new(h, 0, 0.5, 0)
                SVHandle.Position = UDim2.new(s, 0, 1 - v, 0)
                HexLbl.Text = string.format("HEX: #%02X%02X%02X",
                    math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
                Scarfaze.Flags[flag] = color
                callback(color)
            end

            local draggingHue, draggingSV = false, false
            HueTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingHue = true
                    h = math.clamp((input.Position.X - HueTrack.AbsolutePosition.X) / HueTrack.AbsoluteSize.X, 0, 1)
                    applyColor()
                end
            end)
            SVBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = true
                    s = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    applyColor()
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if draggingHue then
                    h = math.clamp((input.Position.X - HueTrack.AbsolutePosition.X) / HueTrack.AbsoluteSize.X, 0, 1)
                    applyColor()
                end
                if draggingSV then
                    s = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    applyColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false; draggingSV = false end
            end)

            local PICKER_H = 215
            Header.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    Panel.Visible = true
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 50 + PICKER_H + 6) }, 0.2)
                    Tween(Panel, { Size = UDim2.new(1, 0, 0, PICKER_H) }, 0.2)
                else
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 50) }, 0.2)
                    Tween(Panel, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    task.delay(0.25, function() Panel.Visible = false end)
                end
            end)

            local obj = {}
            function obj:Set(c) color = c; h, s, v = Color3.toHSV(c); applyColor() end
            function obj:Get() return color end
            return obj
        end

        function Elements:AddAddon(opts)
            opts = opts or {}
            local name  = opts.Name or "Addon"
            local build = opts.Build

            local AddonFrame = Instance.new("Frame", Page)
            AddonFrame.Size = UDim2.new(1, 0, 0, opts.Height or 80)
            AddonFrame.BackgroundColor3 = Scarfaze.Theme.Surface2
            AddonFrame.ClipsDescendants = true
            Corner(AddonFrame, 10)
            Stroke(AddonFrame, Scarfaze.Theme.Accent, 1, 0.7)

            local AddonHeader = Instance.new("TextLabel", AddonFrame)
            AddonHeader.Size = UDim2.new(1, -20, 0, 22)
            AddonHeader.Position = UDim2.new(0, 12, 0, 8)
            AddonHeader.Text = "⚡ " .. name
            AddonHeader.TextColor3 = Scarfaze.Theme.Accent
            AddonHeader.Font = Enum.Font.GothamBold
            AddonHeader.TextSize = 13
            AddonHeader.TextXAlignment = Enum.TextXAlignment.Left
            AddonHeader.BackgroundTransparency = 1

            local Body = Instance.new("Frame", AddonFrame)
            Body.Size = UDim2.new(1, -24, 1, -36)
            Body.Position = UDim2.new(0, 12, 0, 32)
            Body.BackgroundTransparency = 1

            if build then pcall(build, Body, Scarfaze) end
            table.insert(Scarfaze.Addons, { name = name, frame = AddonFrame })
        end

        return Elements
    end

    return Window
end

function Scarfaze:EnableInfJump()
    if self._infJumpConn then self._infJumpConn:Disconnect() end
    self._infJumpConn = UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

function Scarfaze:DisableInfJump()
    if self._infJumpConn then
        self._infJumpConn:Disconnect()
        self._infJumpConn = nil
    end
end

return Scarfaze
