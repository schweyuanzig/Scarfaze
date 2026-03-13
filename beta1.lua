local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local Scarfaze = {
    Flags = {},
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
}

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
end

local function Padding(parent, all)
    local p = Instance.new("UIPadding", parent)
    p.PaddingLeft   = UDim.new(0, all or 8)
    p.PaddingRight  = UDim.new(0, all or 8)
    p.PaddingTop    = UDim.new(0, all or 8)
    p.PaddingBottom = UDim.new(0, all or 8)
end

local function Stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.Color        = color        or Color3.fromRGB(60, 60, 60)
    s.Thickness    = thickness    or 1
    s.Transparency = transparency or 0
end

local function Tint(color, factor)
    return Color3.fromRGB(
        math.clamp(math.floor(color.R * 255 * factor), 0, 255),
        math.clamp(math.floor(color.G * 255 * factor), 0, 255),
        math.clamp(math.floor(color.B * 255 * factor), 0, 255)
    )
end

local NotifyContainer

function Scarfaze:Notify(title, text, kind, duration)
    if not NotifyContainer then return end
    kind     = kind     or "Info"
    duration = duration or 3

    local accent = ({
        Success = self.Theme.Success,
        Danger  = self.Theme.Danger,
        Warning = self.Theme.Warning,
        Info    = self.Theme.Accent,
    })[kind] or self.Theme.Accent

    local N = Instance.new("Frame", NotifyContainer)
    N.Size                = UDim2.new(1, 0, 0, 70)
    N.BackgroundColor3    = self.Theme.Surface
    N.BackgroundTransparency = 1
    N.AutomaticSize       = Enum.AutomaticSize.Y
    N.ClipsDescendants    = true
    Corner(N, 10)
    Stroke(N, accent, 1.5)

    local Bar = Instance.new("Frame", N)
    Bar.Size             = UDim2.new(0, 4, 1, 0)
    Bar.BackgroundColor3 = accent
    Corner(Bar, 4)

    local Inner = Instance.new("Frame", N)
    Inner.Size               = UDim2.new(1, -16, 1, 0)
    Inner.Position           = UDim2.new(0, 14, 0, 0)
    Inner.BackgroundTransparency = 1
    Inner.AutomaticSize      = Enum.AutomaticSize.Y

    local TitleLbl = Instance.new("TextLabel", Inner)
    TitleLbl.Size               = UDim2.new(1, 0, 0, 22)
    TitleLbl.Position           = UDim2.new(0, 0, 0, 8)
    TitleLbl.Text               = title
    TitleLbl.TextColor3         = accent
    TitleLbl.Font               = Enum.Font.GothamBold
    TitleLbl.TextSize           = 15
    TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLbl.BackgroundTransparency = 1

    local BodyLbl = Instance.new("TextLabel", Inner)
    BodyLbl.Size               = UDim2.new(1, 0, 0, 0)
    BodyLbl.Position           = UDim2.new(0, 0, 0, 32)
    BodyLbl.Text               = text
    BodyLbl.TextColor3         = self.Theme.SubText
    BodyLbl.Font               = Enum.Font.Gotham
    BodyLbl.TextSize           = 13
    BodyLbl.TextXAlignment     = Enum.TextXAlignment.Left
    BodyLbl.TextWrapped        = true
    BodyLbl.AutomaticSize      = Enum.AutomaticSize.Y
    BodyLbl.BackgroundTransparency = 1

    local Prog = Instance.new("Frame", N)
    Prog.Size             = UDim2.new(1, 0, 0, 2)
    Prog.Position         = UDim2.new(0, 0, 1, -2)
    Prog.BackgroundColor3 = accent
    Prog.BorderSizePixel  = 0

    Tween(N, { BackgroundTransparency = 0 }, 0.25)
    Tween(Prog, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        Tween(N, { BackgroundTransparency = 1 }, 0.25)
        task.wait(0.3)
        N:Destroy()
    end)
end

function Scarfaze:SetTheme(accent)
    self.Theme.Accent = accent
end

function Scarfaze:SaveConfig(name)
    local path = (name or "default") .. "_Scarfaze.json"
    local ok, err = pcall(function()
        writefile(path, HttpService:JSONEncode(self.Flags))
    end)
    self:Notify(
        ok and "Saved" or "Error",
        ok and path or tostring(err),
        ok and "Success" or "Danger", 3
    )
end

function Scarfaze:LoadConfig(name)
    local path = (name or "default") .. "_Scarfaze.json"
    if not isfile(path) then
        self:Notify("Not Found", path .. " does not exist.", "Warning", 3)
        return
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and data then
        for k, v in pairs(data) do self.Flags[k] = v end
        self:Notify("Loaded", path, "Success", 3)
        return data
    end
end

function Scarfaze:CreateWindow(config)
    config = config or {}
    local title     = config.Name      or "Scarfaze"
    local toggleKey = config.Key       or Enum.KeyCode.RightShift
    local watermark = config.Watermark ~= false

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name          = "ScarfazeV3"
    ScreenGui.ResetOnSpawn  = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

    local Main = Instance.new("Frame", ScreenGui)
    Main.Size             = UDim2.new(0, 700, 0, 500)
    Main.Position         = UDim2.new(0.5, -350, 0.5, -250)
    Main.BackgroundColor3 = self.Theme.Background
    Main.BorderSizePixel  = 0
    Main.ClipsDescendants = true
    Corner(Main, 14)
    Stroke(Main, Color3.fromRGB(40, 40, 40), 1.5)

    local Shadow = Instance.new("ImageLabel", Main)
    Shadow.Size               = UDim2.new(1, 40, 1, 40)
    Shadow.Position           = UDim2.new(0, -20, 0, -20)
    Shadow.Image              = "rbxassetid://5028857084"
    Shadow.ImageColor3        = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency  = 0.5
    Shadow.BackgroundTransparency = 1
    Shadow.ZIndex             = -1
    Shadow.ScaleType          = Enum.ScaleType.Slice
    Shadow.SliceCenter        = Rect.new(24, 24, 276, 276)

    -- Drag (only top bar)
    local DragBar = Instance.new("TextButton", Main)
    DragBar.Size               = UDim2.new(1, 0, 0, 46)
    DragBar.BackgroundTransparency = 1
    DragBar.Text               = ""
    DragBar.ZIndex             = 10

    local _sliderActive = false
    local dragging, dragStart, startPos
    DragBar.MouseButton1Down:Connect(function()
        if _sliderActive then return end
        dragging  = true
        dragStart = UserInputService:GetMouseLocation()
        startPos  = Main.Position
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and not _sliderActive and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = UserInputService:GetMouseLocation() - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Sidebar
    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size             = UDim2.new(0, 200, 1, 0)
    Sidebar.BackgroundColor3 = self.Theme.Surface
    Sidebar.BorderSizePixel  = 0
    Corner(Sidebar, 14)

    local TitleLbl = Instance.new("TextLabel", Sidebar)
    TitleLbl.Size           = UDim2.new(1, 0, 0, 46)
    TitleLbl.Position       = UDim2.new(0, 0, 0, 0)
    TitleLbl.Text           = title
    TitleLbl.TextColor3     = Color3.fromRGB(255, 255, 255)
    TitleLbl.Font           = Enum.Font.GothamBlack
    TitleLbl.TextSize       = 22
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Center
    TitleLbl.BackgroundTransparency = 1

    local SideDiv = Instance.new("Frame", Sidebar)
    SideDiv.Size             = UDim2.new(1, -24, 0, 1)
    SideDiv.Position         = UDim2.new(0, 12, 0, 46)
    SideDiv.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SideDiv.BorderSizePixel  = 0

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Size             = UDim2.new(1, 0, 1, -100)
    TabList.Position         = UDim2.new(0, 0, 0, 54)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 3
    TabList.ScrollBarImageColor3 = self.Theme.Accent
    TabList.BorderSizePixel  = 0
    TabList.CanvasSize        = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Padding(TabList, 10)
    local TabLayout = Instance.new("UIListLayout", TabList)
    TabLayout.Padding    = UDim.new(0, 6)
    TabLayout.SortOrder  = Enum.SortOrder.LayoutOrder

    local SideDiv2 = Instance.new("Frame", Sidebar)
    SideDiv2.Size             = UDim2.new(1, -24, 0, 1)
    SideDiv2.Position         = UDim2.new(0, 12, 1, -48)
    SideDiv2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SideDiv2.BorderSizePixel  = 0

    local UnloadBtn = Instance.new("TextButton", Sidebar)
    UnloadBtn.Size             = UDim2.new(1, -20, 0, 32)
    UnloadBtn.Position         = UDim2.new(0, 10, 1, -42)
    UnloadBtn.Text             = "⏻  Unload"
    UnloadBtn.TextSize         = 13
    UnloadBtn.BackgroundColor3 = Color3.fromRGB(50, 18, 18)
    UnloadBtn.TextColor3       = self.Theme.Danger
    UnloadBtn.Font             = Enum.Font.GothamBold
    Corner(UnloadBtn, 8)
    Stroke(UnloadBtn, self.Theme.Danger, 1, 0.6)
    UnloadBtn.MouseEnter:Connect(function()
        Tween(UnloadBtn, { BackgroundColor3 = self.Theme.Danger, TextColor3 = Color3.fromRGB(255,255,255) }, 0.15)
    end)
    UnloadBtn.MouseLeave:Connect(function()
        Tween(UnloadBtn, { BackgroundColor3 = Color3.fromRGB(50,18,18), TextColor3 = self.Theme.Danger }, 0.15)
    end)
    UnloadBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Content
    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size             = UDim2.new(1, -215, 1, -15)
    ContentArea.Position         = UDim2.new(0, 210, 0, 8)
    ContentArea.BackgroundTransparency = 1

    -- Notifications
    NotifyContainer = Instance.new("Frame", ScreenGui)
    NotifyContainer.Size     = UDim2.new(0, 280, 1, 0)
    NotifyContainer.Position = UDim2.new(1, -292, 0, 0)
    NotifyContainer.BackgroundTransparency = 1
    Padding(NotifyContainer, 10)
    local NLayout = Instance.new("UIListLayout", NotifyContainer)
    NLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NLayout.Padding           = UDim.new(0, 8)

    -- Watermark
    if watermark then
        local WM = Instance.new("TextLabel", ScreenGui)
        WM.Size             = UDim2.new(0, 0, 0, 26)
        WM.Position         = UDim2.new(0, 10, 0, 10)
        WM.AutomaticSize    = Enum.AutomaticSize.X
        WM.Text             = "  " .. title .. "  ·  " .. LocalPlayer.Name .. "  "
        WM.TextColor3       = Color3.fromRGB(255, 255, 255)
        WM.Font             = Enum.Font.GothamBold
        WM.TextSize         = 13
        WM.BackgroundColor3 = self.Theme.Surface
        Corner(WM, 6)
        Stroke(WM, Color3.fromRGB(50,50,50), 1)
    end

    -- Toggle key
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            Main.Visible = not Main.Visible
        end
    end)

    local Window   = { _tabBtns = {}, _pages = {} }

    local function activateTab(page, btn)
        for _, p in pairs(Window._pages)   do p.Visible = false end
        for _, b in pairs(Window._tabBtns) do
            Tween(b, { BackgroundColor3 = Scarfaze.Theme.Surface2, TextColor3 = Scarfaze.Theme.SubText }, 0.15)
        end
        page.Visible = true
        Tween(btn, {
            BackgroundColor3 = Tint(Scarfaze.Theme.Accent, 0.15),
            TextColor3       = Scarfaze.Theme.Accent,
        }, 0.15)
    end

    function Window:AddTab(name, icon)
        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.Size             = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible          = false
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Scarfaze.Theme.Accent
        Page.BorderSizePixel  = 0
        Page.CanvasSize        = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local PLayout = Instance.new("UIListLayout", Page)
        PLayout.Padding   = UDim.new(0, 8)
        PLayout.SortOrder = Enum.SortOrder.LayoutOrder
        Padding(Page, 8)

        local TBtn = Instance.new("TextButton", TabList)
        TBtn.Size             = UDim2.new(1, 0, 0, 38)
        TBtn.Text             = (icon and icon .. "  " or "   ") .. name
        TBtn.TextSize         = 14
        TBtn.BackgroundColor3 = Scarfaze.Theme.Surface2
        TBtn.TextColor3       = Scarfaze.Theme.SubText
        TBtn.Font             = Enum.Font.GothamMedium
        TBtn.TextXAlignment   = Enum.TextXAlignment.Left
        Corner(TBtn, 8)
        Padding(TBtn, 10)

        TBtn.MouseEnter:Connect(function()
            if Page.Visible then return end
            Tween(TBtn, { BackgroundColor3 = Scarfaze.Theme.Surface3 }, 0.12)
        end)
        TBtn.MouseLeave:Connect(function()
            if Page.Visible then return end
            Tween(TBtn, { BackgroundColor3 = Scarfaze.Theme.Surface2 }, 0.12)
        end)
        TBtn.MouseButton1Click:Connect(function() activateTab(Page, TBtn) end)

        table.insert(Window._tabBtns, TBtn)
        table.insert(Window._pages, Page)
        if #Window._pages == 1 then activateTab(Page, TBtn) end

        local E = {}

        -- Divider / Section
        function E:AddDivider(label)
            if label then
                local S = Instance.new("TextLabel", Page)
                S.Size             = UDim2.new(1, 0, 0, 28)
                S.Text             = "  " .. string.upper(label)
                S.TextColor3       = Scarfaze.Theme.Accent
                S.Font             = Enum.Font.GothamBlack
                S.TextSize         = 10
                S.TextXAlignment   = Enum.TextXAlignment.Left
                S.BackgroundColor3 = Tint(Scarfaze.Theme.Accent, 0.08)
                S.BorderSizePixel  = 0
                Corner(S, 6)
                Stroke(S, Scarfaze.Theme.Accent, 1, 0.7)
            else
                local D = Instance.new("Frame", Page)
                D.Size             = UDim2.new(1, 0, 0, 1)
                D.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                D.BorderSizePixel  = 0
            end
        end

        -- Label
        function E:AddLabel(text)
            local L = Instance.new("TextLabel", Page)
            L.Size             = UDim2.new(1, 0, 0, 34)
            L.Text             = "  " .. text
            L.TextColor3       = Scarfaze.Theme.SubText
            L.Font             = Enum.Font.Gotham
            L.TextSize         = 13
            L.TextXAlignment   = Enum.TextXAlignment.Left
            L.BackgroundColor3 = Scarfaze.Theme.Surface2
            L.TextWrapped      = true
            L.BorderSizePixel  = 0
            Corner(L, 8)
            local obj = {}
            function obj:Set(v) L.Text = "  " .. v end
            function obj:Get() return L.Text:sub(3) end
            return obj
        end

        -- Toggle
        function E:AddToggle(opts)
            opts = opts or {}
            local text     = opts.Text     or "Toggle"
            local flag     = opts.Flag     or text
            local default  = opts.Default  or false
            local desc     = opts.Description
            local callback = opts.Callback or function() end

            local state = Scarfaze.Flags[flag]
            if state == nil then state = default end

            local Row = Instance.new("Frame", Page)
            Row.Size             = UDim2.new(1, 0, 0, desc and 60 or 46)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Row.BorderSizePixel  = 0
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size           = UDim2.new(1, -58, 0, 20)
            Lbl.Position       = UDim2.new(0, 12, 0, desc and 8 or 13)
            Lbl.Text           = text
            Lbl.TextColor3     = Scarfaze.Theme.Text
            Lbl.Font           = Enum.Font.GothamMedium
            Lbl.TextSize       = 14
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            if desc then
                local Desc = Instance.new("TextLabel", Row)
                Desc.Size           = UDim2.new(1, -58, 0, 14)
                Desc.Position       = UDim2.new(0, 12, 0, 30)
                Desc.Text           = desc
                Desc.TextColor3     = Scarfaze.Theme.SubText
                Desc.Font           = Enum.Font.Gotham
                Desc.TextSize       = 11
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
            end

            local Track = Instance.new("Frame", Row)
            Track.Size             = UDim2.new(0, 42, 0, 22)
            Track.Position         = UDim2.new(1, -52, 0.5, -11)
            Track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            Corner(Track, 11)

            local Knob = Instance.new("Frame", Track)
            Knob.Size             = UDim2.new(0, 16, 0, 16)
            Knob.Position         = UDim2.new(0, 3, 0.5, -8)
            Knob.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
            Corner(Knob, 8)

            local function refresh()
                if state then
                    Tween(Track, { BackgroundColor3 = Scarfaze.Theme.Accent }, 0.18)
                    Tween(Knob, { Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255,255,255) }, 0.18)
                else
                    Tween(Track, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) }, 0.18)
                    Tween(Knob, { Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(140,140,140) }, 0.18)
                end
                Scarfaze.Flags[flag] = state
                callback(state)
            end

            Row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    state = not state
                    refresh()
                end
            end)
            refresh()

            local obj = {}
            function obj:Set(v) state = v; refresh() end
            function obj:Get() return state end
            return obj
        end

        -- Button
        function E:AddButton(opts)
            opts = opts or {}
            local text     = opts.Text     or "Button"
            local desc     = opts.Description
            local callback = opts.Callback or function() end

            local Btn = Instance.new("TextButton", Page)
            Btn.Size             = UDim2.new(1, 0, 0, desc and 60 or 44)
            Btn.BackgroundColor3 = Scarfaze.Theme.Surface3
            Btn.Text             = ""
            Btn.BorderSizePixel  = 0
            Corner(Btn, 10)
            Stroke(Btn, Color3.fromRGB(55, 55, 55), 1)

            local Lbl = Instance.new("TextLabel", Btn)
            Lbl.Size           = UDim2.new(1, -32, 0, 20)
            Lbl.Position       = UDim2.new(0, 12, 0, desc and 8 or 12)
            Lbl.Text           = text
            Lbl.TextColor3     = Scarfaze.Theme.Text
            Lbl.Font           = Enum.Font.GothamBold
            Lbl.TextSize       = 14
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            if desc then
                local Desc = Instance.new("TextLabel", Btn)
                Desc.Size           = UDim2.new(1, -32, 0, 14)
                Desc.Position       = UDim2.new(0, 12, 0, 30)
                Desc.Text           = desc
                Desc.TextColor3     = Scarfaze.Theme.SubText
                Desc.Font           = Enum.Font.Gotham
                Desc.TextSize       = 11
                Desc.TextXAlignment = Enum.TextXAlignment.Left
                Desc.BackgroundTransparency = 1
            end

            local Arrow = Instance.new("TextLabel", Btn)
            Arrow.Size           = UDim2.new(0, 20, 1, 0)
            Arrow.Position       = UDim2.new(1, -26, 0, 0)
            Arrow.Text           = "›"
            Arrow.TextColor3     = Scarfaze.Theme.SubText
            Arrow.Font           = Enum.Font.GothamBold
            Arrow.TextSize       = 20
            Arrow.BackgroundTransparency = 1

            local orig = Scarfaze.Theme.Surface3
            Btn.MouseEnter:Connect(function()
                Tween(Btn, { BackgroundColor3 = Color3.fromRGB(48,48,48) }, 0.12)
            end)
            Btn.MouseLeave:Connect(function()
                Tween(Btn, { BackgroundColor3 = orig }, 0.12)
            end)
            Btn.MouseButton1Down:Connect(function()
                Tween(Btn, { BackgroundColor3 = Tint(Scarfaze.Theme.Accent, 0.3) }, 0.08)
            end)
            Btn.MouseButton1Up:Connect(function()
                Tween(Btn, { BackgroundColor3 = orig }, 0.12)
            end)
            Btn.MouseButton1Click:Connect(callback)
        end

        -- Slider
        function E:AddSlider(opts)
            opts = opts or {}
            local text     = opts.Text     or "Slider"
            local flag     = opts.Flag     or text
            local min      = opts.Min      or 0
            local max      = opts.Max      or 100
            local default  = opts.Default  or min
            local suffix   = opts.Suffix   or ""
            local integer  = opts.Integer  or false
            local callback = opts.Callback or function() end

            local value = Scarfaze.Flags[flag] or default

            local Row = Instance.new("Frame", Page)
            Row.Size             = UDim2.new(1, 0, 0, 64)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Row.BorderSizePixel  = 0
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size           = UDim2.new(0.6, 0, 0, 20)
            Lbl.Position       = UDim2.new(0, 12, 0, 8)
            Lbl.Text           = text
            Lbl.TextColor3     = Scarfaze.Theme.Text
            Lbl.Font           = Enum.Font.GothamMedium
            Lbl.TextSize       = 14
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local ValLbl = Instance.new("TextLabel", Row)
            ValLbl.Size           = UDim2.new(0.35, 0, 0, 20)
            ValLbl.Position       = UDim2.new(0.63, 0, 0, 8)
            ValLbl.Text           = tostring(value) .. suffix
            ValLbl.TextColor3     = Scarfaze.Theme.Accent
            ValLbl.Font           = Enum.Font.GothamBold
            ValLbl.TextSize       = 14
            ValLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValLbl.BackgroundTransparency = 1

            local Track = Instance.new("Frame", Row)
            Track.Size             = UDim2.new(1, -24, 0, 6)
            Track.Position         = UDim2.new(0, 12, 0, 42)
            Track.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            Track.BorderSizePixel  = 0
            Corner(Track, 3)

            local Fill = Instance.new("Frame", Track)
            Fill.Size             = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Scarfaze.Theme.Accent
            Fill.BorderSizePixel  = 0
            Corner(Fill, 3)

            local Handle = Instance.new("Frame", Track)
            Handle.Size             = UDim2.new(0, 14, 0, 14)
            Handle.AnchorPoint      = Vector2.new(0.5, 0.5)
            Handle.Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Handle.BorderSizePixel  = 0
            Corner(Handle, 7)

            -- Invisible clickable overlay on top of track
            local SliderBtn = Instance.new("TextButton", Row)
            SliderBtn.Size               = UDim2.new(1, -24, 0, 24)
            SliderBtn.Position           = UDim2.new(0, 12, 0, 34)
            SliderBtn.BackgroundTransparency = 1
            SliderBtn.Text               = ""
            SliderBtn.ZIndex             = 5

            local draggingSlider = false

            local function applyValue(mouseX)
                local rel = math.clamp((mouseX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local raw = min + (max - min) * rel
                value = integer and math.floor(raw + 0.5) or (math.floor(raw * 10 + 0.5) / 10)
                value = math.clamp(value, min, max)
                local clamped = (value - min) / (max - min)
                Fill.Size      = UDim2.new(clamped, 0, 1, 0)
                Handle.Position = UDim2.new(clamped, 0, 0.5, 0)
                ValLbl.Text    = tostring(value) .. suffix
                Scarfaze.Flags[flag] = value
                callback(value)
            end

            SliderBtn.MouseButton1Down:Connect(function()
                draggingSlider  = true
                _sliderActive   = true
                applyValue(UserInputService:GetMouseLocation().X)
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    applyValue(UserInputService:GetMouseLocation().X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                    _sliderActive  = false
                end
            end)

            local obj = {}
            function obj:Set(v)
                value = math.clamp(v, min, max)
                local rel = (value - min) / (max - min)
                Fill.Size       = UDim2.new(rel, 0, 1, 0)
                Handle.Position = UDim2.new(rel, 0, 0.5, 0)
                ValLbl.Text     = tostring(value) .. suffix
                Scarfaze.Flags[flag] = value
                callback(value)
            end
            function obj:Get() return value end
            return obj
        end

        -- Dropdown
        function E:AddDropdown(opts)
            opts = opts or {}
            local text     = opts.Text     or "Dropdown"
            local flag     = opts.Flag     or text
            local options  = opts.Options  or {}
            local default  = opts.Default  or options[1] or ""
            local multi    = opts.Multi    or false
            local callback = opts.Callback or function() end

            local selected = Scarfaze.Flags[flag] or (multi and {} or default)
            local opened   = false

            local Wrapper = Instance.new("Frame", Page)
            Wrapper.Size             = UDim2.new(1, 0, 0, 46)
            Wrapper.BackgroundColor3 = Scarfaze.Theme.Surface2
            Wrapper.ClipsDescendants = false
            Wrapper.BorderSizePixel  = 0
            Corner(Wrapper, 10)
            Stroke(Wrapper, Color3.fromRGB(45, 45, 45), 1)

            local Header = Instance.new("TextButton", Wrapper)
            Header.Size               = UDim2.new(1, 0, 0, 46)
            Header.BackgroundTransparency = 1
            Header.Text               = ""

            local HLbl = Instance.new("TextLabel", Header)
            HLbl.Size           = UDim2.new(0.6, 0, 1, 0)
            HLbl.Position       = UDim2.new(0, 12, 0, 0)
            HLbl.Text           = text
            HLbl.TextColor3     = Scarfaze.Theme.Text
            HLbl.Font           = Enum.Font.GothamMedium
            HLbl.TextSize       = 14
            HLbl.TextXAlignment = Enum.TextXAlignment.Left
            HLbl.BackgroundTransparency = 1

            local SelLbl = Instance.new("TextLabel", Header)
            SelLbl.Size           = UDim2.new(0.33, 0, 1, 0)
            SelLbl.Position       = UDim2.new(0.62, 0, 0, 0)
            SelLbl.Text           = multi and "Select..." or tostring(selected)
            SelLbl.TextColor3     = Scarfaze.Theme.Accent
            SelLbl.Font           = Enum.Font.Gotham
            SelLbl.TextSize       = 13
            SelLbl.TextXAlignment = Enum.TextXAlignment.Right
            SelLbl.BackgroundTransparency = 1

            local Arrow = Instance.new("TextLabel", Header)
            Arrow.Size           = UDim2.new(0, 20, 1, 0)
            Arrow.Position       = UDim2.new(1, -22, 0, 0)
            Arrow.Text           = "▾"
            Arrow.TextColor3     = Scarfaze.Theme.SubText
            Arrow.Font           = Enum.Font.GothamBold
            Arrow.TextSize       = 15
            Arrow.BackgroundTransparency = 1

            -- DropList ScreenGui'ye parent edilir — Main'in ClipsDescendants'ından kaçmak için
            local dropH    = math.min(#options * 38 + 12, 180)
            local DropList = Instance.new("Frame", ScreenGui)
            DropList.Size             = UDim2.new(0, 0, 0, 0)
            DropList.BackgroundColor3 = Scarfaze.Theme.Surface
            DropList.ClipsDescendants = true
            DropList.ZIndex           = 50
            DropList.Visible          = false
            DropList.BorderSizePixel  = 0
            Corner(DropList, 10)
            Stroke(DropList, Color3.fromRGB(50, 50, 50), 1)

            -- DropList konumunu Wrapper'a göre güncelle (scroll ve drag'e karşı)
            game:GetService("RunService").RenderStepped:Connect(function()
                if DropList.Visible then
                    local abs = Wrapper.AbsolutePosition
                    local sz  = Wrapper.AbsoluteSize
                    DropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                    DropList.Size     = UDim2.new(0, sz.X, 0, dropH)
                end
            end)

            local DScroll = Instance.new("ScrollingFrame", DropList)
            DScroll.Size             = UDim2.new(1, 0, 1, 0)
            DScroll.BackgroundTransparency = 1
            DScroll.ScrollBarThickness = 3
            DScroll.BorderSizePixel  = 0
            DScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
            DScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            DScroll.ZIndex            = 51
            Padding(DScroll, 6)
            local DLayout = Instance.new("UIListLayout", DScroll)
            DLayout.Padding   = UDim.new(0, 4)
            DLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local function closeDropdown()
                opened = false
                Tween(Arrow, { Rotation = 0 }, 0.18)
                task.delay(0.18, function() DropList.Visible = false end)
            end

            local function buildOpts()
                for _, c in pairs(DScroll:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local OBtn = Instance.new("TextButton", DScroll)
                    OBtn.Size           = UDim2.new(1, 0, 0, 32)
                    OBtn.Text           = "  " .. tostring(opt)
                    OBtn.TextSize       = 13
                    OBtn.Font           = Enum.Font.Gotham
                    OBtn.TextXAlignment = Enum.TextXAlignment.Left
                    OBtn.ZIndex         = 52
                    OBtn.BorderSizePixel = 0
                    Corner(OBtn, 6)

                    local function rc()
                        local sel = multi and table.find(selected, opt) or (selected == opt)
                        OBtn.BackgroundColor3 = sel and Tint(Scarfaze.Theme.Accent, 0.18) or Scarfaze.Theme.Surface3
                        OBtn.TextColor3       = sel and Scarfaze.Theme.Accent or Scarfaze.Theme.Text
                    end
                    rc()

                    OBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local i = table.find(selected, opt)
                            if i then table.remove(selected, i) else table.insert(selected, opt) end
                            SelLbl.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
                        else
                            selected    = opt
                            SelLbl.Text = opt
                            closeDropdown()
                        end
                        Scarfaze.Flags[flag] = selected
                        callback(selected)
                        rc()
                    end)
                end
            end
            buildOpts()

            Header.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    local abs = Wrapper.AbsolutePosition
                    local sz  = Wrapper.AbsoluteSize
                    DropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                    DropList.Size     = UDim2.new(0, sz.X, 0, dropH)
                    DropList.Visible  = true
                    Tween(Arrow, { Rotation = 180 }, 0.18)
                else
                    closeDropdown()
                end
            end)

            local obj = {}
            function obj:Set(v)
                selected = v
                SelLbl.Text = multi and table.concat(v, ", ") or v
                Scarfaze.Flags[flag] = v
                callback(v)
                buildOpts()
            end
            function obj:SetOptions(v)
                options = v
                dropH   = math.min(#v * 38 + 12, 180)
                buildOpts()
            end
            function obj:Get() return selected end
            return obj
        end

        -- TextInput
        function E:AddTextInput(opts)
            opts = opts or {}
            local text     = opts.Text        or "Input"
            local flag     = opts.Flag        or text
            local ph       = opts.Placeholder or "Type here..."
            local default  = opts.Default     or ""
            local numeric  = opts.Numeric     or false
            local callback = opts.Callback    or function() end

            local value = Scarfaze.Flags[flag] or default

            local Row = Instance.new("Frame", Page)
            Row.Size             = UDim2.new(1, 0, 0, 66)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Row.BorderSizePixel  = 0
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size           = UDim2.new(1, -16, 0, 18)
            Lbl.Position       = UDim2.new(0, 12, 0, 7)
            Lbl.Text           = text
            Lbl.TextColor3     = Scarfaze.Theme.Text
            Lbl.Font           = Enum.Font.GothamMedium
            Lbl.TextSize       = 13
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local Box = Instance.new("Frame", Row)
            Box.Size             = UDim2.new(1, -24, 0, 30)
            Box.Position         = UDim2.new(0, 12, 0, 30)
            Box.BackgroundColor3 = Scarfaze.Theme.Surface3
            Box.BorderSizePixel  = 0
            Corner(Box, 7)
            local BoxStroke = Instance.new("UIStroke", Box)
            BoxStroke.Color       = Color3.fromRGB(55, 55, 55)
            BoxStroke.Thickness   = 1

            local TB = Instance.new("TextBox", Box)
            TB.Size              = UDim2.new(1, -16, 1, 0)
            TB.Position          = UDim2.new(0, 8, 0, 0)
            TB.PlaceholderText   = ph
            TB.Text              = value
            TB.TextColor3        = Scarfaze.Theme.Text
            TB.PlaceholderColor3 = Scarfaze.Theme.SubText
            TB.Font              = Enum.Font.Gotham
            TB.TextSize          = 13
            TB.TextXAlignment    = Enum.TextXAlignment.Left
            TB.BackgroundTransparency = 1
            TB.ClearTextOnFocus  = false

            TB.Focused:Connect(function()
                Tween(Box, { BackgroundColor3 = Color3.fromRGB(42,42,42) }, 0.12)
                BoxStroke.Color = Scarfaze.Theme.Accent
            end)
            TB.FocusLost:Connect(function(enter)
                Tween(Box, { BackgroundColor3 = Scarfaze.Theme.Surface3 }, 0.12)
                BoxStroke.Color = Color3.fromRGB(55, 55, 55)
                value = numeric and (tonumber(TB.Text) or 0) or TB.Text
                Scarfaze.Flags[flag] = value
                callback(value, enter)
            end)

            local obj = {}
            function obj:Set(v) TB.Text = tostring(v); value = v; Scarfaze.Flags[flag] = v; callback(v, false) end
            function obj:Get() return value end
            return obj
        end

        -- Keybind
        function E:AddKeybind(opts)
            opts = opts or {}
            local text     = opts.Text     or "Keybind"
            local flag     = opts.Flag     or text
            local default  = opts.Default  or Enum.KeyCode.Unknown
            local callback = opts.Callback or function() end

            local key       = Scarfaze.Flags[flag] or default
            local listening = false

            local Row = Instance.new("Frame", Page)
            Row.Size             = UDim2.new(1, 0, 0, 46)
            Row.BackgroundColor3 = Scarfaze.Theme.Surface2
            Row.BorderSizePixel  = 0
            Corner(Row, 10)
            Stroke(Row, Color3.fromRGB(45, 45, 45), 1)

            local Lbl = Instance.new("TextLabel", Row)
            Lbl.Size           = UDim2.new(0.6, 0, 1, 0)
            Lbl.Position       = UDim2.new(0, 12, 0, 0)
            Lbl.Text           = text
            Lbl.TextColor3     = Scarfaze.Theme.Text
            Lbl.Font           = Enum.Font.GothamMedium
            Lbl.TextSize       = 14
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.BackgroundTransparency = 1

            local KeyBtn = Instance.new("TextButton", Row)
            KeyBtn.Size             = UDim2.new(0, 88, 0, 28)
            KeyBtn.Position         = UDim2.new(1, -96, 0.5, -14)
            KeyBtn.Text             = key.Name
            KeyBtn.TextSize         = 12
            KeyBtn.BackgroundColor3 = Scarfaze.Theme.Surface3
            KeyBtn.TextColor3       = Scarfaze.Theme.Accent
            KeyBtn.Font             = Enum.Font.GothamBold
            KeyBtn.BorderSizePixel  = 0
            Corner(KeyBtn, 6)
            Stroke(KeyBtn, Scarfaze.Theme.Accent, 1, 0.5)

            KeyBtn.MouseButton1Click:Connect(function()
                listening    = true
                KeyBtn.Text  = "..."
                KeyBtn.TextColor3 = Scarfaze.Theme.Warning
            end)
            UserInputService.InputBegan:Connect(function(input, gpe)
                -- Listening modunda gpe'ye bakma — UI içinden de key yakalanabilsin
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    -- Escape ile iptal et
                    if input.KeyCode == Enum.KeyCode.Escape then
                        listening        = false
                        KeyBtn.Text      = key.Name
                        KeyBtn.TextColor3 = Scarfaze.Theme.Accent
                        return
                    end
                    listening            = false
                    key                  = input.KeyCode
                    KeyBtn.Text          = key.Name
                    KeyBtn.TextColor3    = Scarfaze.Theme.Accent
                    Scarfaze.Flags[flag] = key
                    return
                end
                if not listening and not gpe and input.KeyCode == key and key ~= Enum.KeyCode.Unknown then
                    callback(key)
                end
            end)

            local obj = {}
            function obj:Set(k) key = k; KeyBtn.Text = k.Name; Scarfaze.Flags[flag] = k end
            function obj:Get() return key end
            return obj
        end

        -- ColorPicker
        function E:AddColorPicker(opts)
            opts = opts or {}
            local text     = opts.Text     or "Color"
            local flag     = opts.Flag     or text
            local default  = opts.Default  or Color3.fromRGB(255, 0, 100)
            local callback = opts.Callback or function() end

            local color  = Scarfaze.Flags[flag] or default
            local h, s, v = Color3.toHSV(color)
            local opened  = false

            local Wrapper = Instance.new("Frame", Page)
            Wrapper.Size             = UDim2.new(1, 0, 0, 46)
            Wrapper.BackgroundColor3 = Scarfaze.Theme.Surface2
            Wrapper.ClipsDescendants = false
            Wrapper.BorderSizePixel  = 0
            Corner(Wrapper, 10)
            Stroke(Wrapper, Color3.fromRGB(45, 45, 45), 1)

            local Header = Instance.new("TextButton", Wrapper)
            Header.Size               = UDim2.new(1, 0, 0, 46)
            Header.BackgroundTransparency = 1
            Header.Text               = ""

            local HLbl = Instance.new("TextLabel", Header)
            HLbl.Size           = UDim2.new(0.7, 0, 1, 0)
            HLbl.Position       = UDim2.new(0, 12, 0, 0)
            HLbl.Text           = text
            HLbl.TextColor3     = Scarfaze.Theme.Text
            HLbl.Font           = Enum.Font.GothamMedium
            HLbl.TextSize       = 14
            HLbl.TextXAlignment = Enum.TextXAlignment.Left
            HLbl.BackgroundTransparency = 1

            local Preview = Instance.new("Frame", Header)
            Preview.Size             = UDim2.new(0, 30, 0, 20)
            Preview.Position         = UDim2.new(1, -40, 0.5, -10)
            Preview.BackgroundColor3 = color
            Preview.BorderSizePixel  = 0
            Corner(Preview, 5)
            Stroke(Preview, Color3.fromRGB(70, 70, 70), 1)

            local Panel = Instance.new("Frame", Wrapper)
            Panel.Size             = UDim2.new(1, 0, 0, 0)
            Panel.Position         = UDim2.new(0, 0, 1, 4)
            Panel.BackgroundColor3 = Scarfaze.Theme.Surface
            Panel.ClipsDescendants = true
            Panel.ZIndex           = 10
            Panel.Visible          = false
            Panel.BorderSizePixel  = 0
            Corner(Panel, 10)
            Stroke(Panel, Color3.fromRGB(50, 50, 50), 1)

            -- Hue bar
            local HueTrack = Instance.new("Frame", Panel)
            HueTrack.Size             = UDim2.new(1, -24, 0, 14)
            HueTrack.Position         = UDim2.new(0, 12, 0, 12)
            HueTrack.ZIndex           = 11
            HueTrack.BorderSizePixel  = 0
            Corner(HueTrack, 7)
            local HueGrad = Instance.new("UIGradient", HueTrack)
            HueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
            })
            local HueHandle = Instance.new("Frame", HueTrack)
            HueHandle.Size             = UDim2.new(0, 10, 1, 4)
            HueHandle.AnchorPoint      = Vector2.new(0.5, 0.5)
            HueHandle.Position         = UDim2.new(h, 0, 0.5, 0)
            HueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HueHandle.ZIndex           = 12
            HueHandle.BorderSizePixel  = 0
            Corner(HueHandle, 5)
            Stroke(HueHandle, Color3.fromRGB(0,0,0), 1, 0.4)

            -- SV box
            local SVBox = Instance.new("Frame", Panel)
            SVBox.Size            = UDim2.new(1, -24, 0, 90)
            SVBox.Position        = UDim2.new(0, 12, 0, 34)
            SVBox.ZIndex          = 11
            SVBox.BorderSizePixel = 0
            Corner(SVBox, 7)

            local SVHue = Instance.new("Frame", SVBox)
            SVHue.Size             = UDim2.new(1, 0, 1, 0)
            SVHue.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            SVHue.ZIndex           = 10
            SVHue.BorderSizePixel  = 0
            Corner(SVHue, 7)
            local GS = Instance.new("UIGradient", SVHue)
            GS.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))})
            GS.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})

            local GV = Instance.new("Frame", SVHue)
            GV.Size             = UDim2.new(1, 0, 1, 0)
            GV.BackgroundColor3 = Color3.fromRGB(0,0,0)
            GV.ZIndex           = 11
            GV.BorderSizePixel  = 0
            Corner(GV, 7)
            local GVG = Instance.new("UIGradient", GV)
            GVG.Rotation    = 90
            GVG.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})

            local SVHandle = Instance.new("Frame", SVBox)
            SVHandle.Size             = UDim2.new(0, 10, 0, 10)
            SVHandle.AnchorPoint      = Vector2.new(0.5, 0.5)
            SVHandle.Position         = UDim2.new(s, 0, 1 - v, 0)
            SVHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
            SVHandle.ZIndex           = 14
            SVHandle.BorderSizePixel  = 0
            Corner(SVHandle, 5)
            Stroke(SVHandle, Color3.fromRGB(0,0,0), 1.5)

            -- Hex label
            local HexLbl = Instance.new("TextLabel", Panel)
            HexLbl.Size             = UDim2.new(1, -24, 0, 24)
            HexLbl.Position         = UDim2.new(0, 12, 0, 132)
            HexLbl.Text             = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
            HexLbl.TextColor3       = Scarfaze.Theme.SubText
            HexLbl.Font             = Enum.Font.RobotoMono
            HexLbl.TextSize         = 12
            HexLbl.TextXAlignment   = Enum.TextXAlignment.Center
            HexLbl.BackgroundColor3 = Scarfaze.Theme.Surface3
            HexLbl.ZIndex           = 11
            HexLbl.BorderSizePixel  = 0
            Corner(HexLbl, 5)

            local PANEL_H = 165

            local function apply()
                color = Color3.fromHSV(h, s, v)
                Preview.BackgroundColor3 = color
                SVHue.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                HueHandle.Position       = UDim2.new(h, 0, 0.5, 0)
                SVHandle.Position        = UDim2.new(s, 0, 1 - v, 0)
                HexLbl.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
                Scarfaze.Flags[flag] = color
                callback(color)
            end

            local dHue, dSV = false, false
            local HueBtn = Instance.new("TextButton", Panel)
            HueBtn.Size               = UDim2.new(1, -24, 0, 14)
            HueBtn.Position           = UDim2.new(0, 12, 0, 12)
            HueBtn.BackgroundTransparency = 1
            HueBtn.Text               = ""
            HueBtn.ZIndex             = 13

            local SVBtn = Instance.new("TextButton", Panel)
            SVBtn.Size               = UDim2.new(1, -24, 0, 90)
            SVBtn.Position           = UDim2.new(0, 12, 0, 34)
            SVBtn.BackgroundTransparency = 1
            SVBtn.Text               = ""
            SVBtn.ZIndex             = 15

            HueBtn.MouseButton1Down:Connect(function()
                dHue = true
                h = math.clamp((UserInputService:GetMouseLocation().X - HueTrack.AbsolutePosition.X) / HueTrack.AbsoluteSize.X, 0, 1)
                apply()
            end)
            SVBtn.MouseButton1Down:Connect(function()
                dSV = true
                local mx = UserInputService:GetMouseLocation()
                s = math.clamp((mx.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((mx.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                apply()
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local mx = UserInputService:GetMouseLocation()
                if dHue then
                    h = math.clamp((mx.X - HueTrack.AbsolutePosition.X) / HueTrack.AbsoluteSize.X, 0, 1)
                    apply()
                end
                if dSV then
                    s = math.clamp((mx.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((mx.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    apply()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dHue = false; dSV = false end
            end)

            Header.MouseButton1Click:Connect(function()
                opened = not opened
                if opened then
                    Panel.Visible = true
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 46 + PANEL_H + 4) }, 0.18)
                    Tween(Panel,   { Size = UDim2.new(1, 0, 0, PANEL_H) }, 0.18)
                else
                    Tween(Wrapper, { Size = UDim2.new(1, 0, 0, 46) }, 0.18)
                    Tween(Panel,   { Size = UDim2.new(1, 0, 0, 0)  }, 0.18)
                    task.delay(0.2, function() Panel.Visible = false end)
                end
            end)

            local obj = {}
            function obj:Set(c) color = c; h, s, v = Color3.toHSV(c); apply() end
            function obj:Get() return color end
            return obj
        end

        return E
    end

    return Window
end

return Scarfaze
