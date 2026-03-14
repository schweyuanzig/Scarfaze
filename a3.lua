--[[
AugustusAllInOne.lua
Single-file version of:
- AugustusCloserUI.lua
- AugustusLinoriaCompat.lua

Usage:
    local Library = loadstring(readfile("AugustusAllInOne.lua"))()

This version has no external dependency on AugustusCloserUI.lua.
]]

local function __AugustusBuildCoreLibrary()
    local TweenService = game:GetService('TweenService')
    local UserInputService = game:GetService('UserInputService')
    local Lighting = game:GetService('Lighting')
    local HttpService = game:GetService('HttpService')
    local CoreGui = game:GetService('CoreGui')

    local Library = {}

    local State = {}
    State.__index = State

    local Window = {}
    Window.__index = Window

    local Tab = {}
    Tab.__index = Tab

    local Section = {}
    Section.__index = Section

    local SaveManager = {}
    SaveManager.__index = SaveManager

    local ThemeManager = {}
    ThemeManager.__index = ThemeManager

    local Themes = {
        Augustus = {
            Window = Color3.fromRGB(23, 24, 28),
            Window2 = Color3.fromRGB(26, 28, 33),
            Top = Color3.fromRGB(18, 19, 23),
            Panel = Color3.fromRGB(27, 29, 34),
            Panel2 = Color3.fromRGB(32, 34, 40),
            Border = Color3.fromRGB(60, 64, 73),
            BorderSoft = Color3.fromRGB(48, 52, 60),
            Text = Color3.fromRGB(225, 228, 235),
            DimText = Color3.fromRGB(141, 148, 160),
            Accent = Color3.fromRGB(86, 162, 255),
            Accent2 = Color3.fromRGB(47, 113, 194),
            Good = Color3.fromRGB(86, 178, 117),
            Bad = Color3.fromRGB(198, 83, 83),
            Blur = 12,
        },
        Mono = {
            Window = Color3.fromRGB(26, 26, 28),
            Window2 = Color3.fromRGB(30, 30, 33),
            Top = Color3.fromRGB(18, 18, 20),
            Panel = Color3.fromRGB(31, 31, 34),
            Panel2 = Color3.fromRGB(36, 36, 40),
            Border = Color3.fromRGB(67, 67, 74),
            BorderSoft = Color3.fromRGB(52, 52, 58),
            Text = Color3.fromRGB(232, 232, 235),
            DimText = Color3.fromRGB(150, 150, 156),
            Accent = Color3.fromRGB(188, 188, 188),
            Accent2 = Color3.fromRGB(122, 122, 122),
            Good = Color3.fromRGB(106, 180, 112),
            Bad = Color3.fromRGB(198, 91, 91),
            Blur = 10,
        },
        Crimson = {
            Window = Color3.fromRGB(24, 22, 27),
            Window2 = Color3.fromRGB(29, 25, 31),
            Top = Color3.fromRGB(17, 15, 19),
            Panel = Color3.fromRGB(33, 28, 35),
            Panel2 = Color3.fromRGB(41, 34, 43),
            Border = Color3.fromRGB(77, 60, 70),
            BorderSoft = Color3.fromRGB(58, 46, 54),
            Text = Color3.fromRGB(235, 227, 233),
            DimText = Color3.fromRGB(165, 148, 158),
            Accent = Color3.fromRGB(255, 110, 138),
            Accent2 = Color3.fromRGB(188, 69, 98),
            Good = Color3.fromRGB(98, 181, 120),
            Bad = Color3.fromRGB(204, 86, 86),
            Blur = 12,
        },
    }

    local function cloneTheme(theme)
        local out = {}
        for k, v in pairs(theme) do
            out[k] = v
        end
        return out
    end

    local function create(className, props)
        local obj = Instance.new(className)
        for k, v in pairs(props or {}) do
            obj[k] = v
        end
        return obj
    end

    local function addCorner(parent, radius)
        local c = create('UICorner', { CornerRadius = UDim.new(0, radius) })
        c.Parent = parent
        return c
    end

    local function addStroke(parent, color, thickness)
        local s = create('UIStroke', {
            Color = color,
            Thickness = thickness or 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        s.Parent = parent
        return s
    end

    local function addPadding(parent, left, right, top, bottom)
        local p = create('UIPadding', {
            PaddingLeft = UDim.new(0, left or 0),
            PaddingRight = UDim.new(0, right or 0),
            PaddingTop = UDim.new(0, top or 0),
            PaddingBottom = UDim.new(0, bottom or 0),
        })
        p.Parent = parent
        return p
    end

    local function tween(instance, data, props)
        local t = TweenService:Create(instance, data, props)
        t:Play()
        return t
    end

    local function safeParent(gui)
        local ok = pcall(function()
            gui.Parent = gethui and gethui() or CoreGui
        end)
        if not ok or not gui.Parent then
            gui.Parent = CoreGui
        end
    end

    local function clearChildren(parent)
        for _, child in ipairs(parent:GetChildren()) do
            child:Destroy()
        end
    end

    local function formatValue(value)
        if typeof(value) == 'number' then
            local rounded = math.floor(value * 100 + 0.5) / 100
            if rounded == math.floor(rounded) then
                return tostring(math.floor(rounded))
            end
            return tostring(rounded)
        end
        return tostring(value)
    end

    local function makeDraggable(handle, target)
        local dragging = false
        local dragStart
        local startPos

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = target.Position
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
                target.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    function SaveManager.new(state)
        return setmetatable({
            State = state,
            Folder = state.Options.ConfigFolder or 'AugustusUI',
            Ignore = {},
            Selected = nil,
        }, SaveManager)
    end

    function SaveManager:SetFolder(folder)
        self.Folder = folder
        self:RefreshUI()
    end

    function SaveManager:IgnoreKey(flag)
        self.Ignore[flag] = true
    end

    function SaveManager:_ensureFolder()
        if makefolder and isfolder and not isfolder(self.Folder) then
            makefolder(self.Folder)
        end
    end

    function SaveManager:GetConfigs()
        self:_ensureFolder()
        local out = {}
        if listfiles and isfolder and isfolder(self.Folder) then
            for _, path in ipairs(listfiles(self.Folder)) do
                local name = path:match('([^/\\]+)%.json$')
                if name then
                    table.insert(out, name)
                end
            end
        end
        table.sort(out)
        return out
    end

    function SaveManager:Save(name)
        if not writefile or not isfolder then
            return false, 'file api unavailable'
        end
        self:_ensureFolder()
        local data = {
            theme = self.State.ThemeName,
            flags = {},
        }
        for key, value in pairs(self.State.Flags) do
            if self.State.FlagSetters[key] and not self.Ignore[key] then
                data.flags[key] = value
            end
        end
        writefile(self.Folder .. '/' .. name .. '.json', HttpService:JSONEncode(data))
        self.Selected = name
        self:RefreshUI()
        return true
    end

    function SaveManager:Load(name)
        if not readfile or not isfile then
            return false, 'file api unavailable'
        end
        local path = self.Folder .. '/' .. name .. '.json'
        if not isfile(path) then
            return false, 'config not found'
        end
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if not ok or type(decoded) ~= 'table' then
            return false, 'invalid json'
        end
        if decoded.theme and Themes[decoded.theme] then
            self.State:SetTheme(decoded.theme)
        end
        if decoded.flags then
            for flag, value in pairs(decoded.flags) do
                self.State:SetFlag(flag, value)
            end
        end
        self.Selected = name
        self:RefreshUI()
        return true
    end

    function SaveManager:Delete(name)
        if not delfile or not isfile then
            return false, 'file api unavailable'
        end
        local path = self.Folder .. '/' .. name .. '.json'
        if not isfile(path) then
            return false, 'config not found'
        end
        delfile(path)
        if self.Selected == name then
            self.Selected = nil
        end
        self:RefreshUI()
        return true
    end

    function SaveManager:RefreshUI()
        local ui = self.UI
        if not ui then
            return
        end

        clearChildren(ui.List)
        local layout = create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })
        layout.Parent = ui.List

        local configs = self:GetConfigs()
        if #configs == 0 then
            local empty = create('TextLabel', {
                Parent = ui.List,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Code,
                Text = 'no configs',
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = self.State.Theme.DimText,
            })
            empty.TextColor3 = self.State.Theme.DimText
        else
            for _, name in ipairs(configs) do
                local row = create('TextButton', {
                    Parent = ui.List,
                    AutoButtonColor = false,
                    BackgroundColor3 = self.State.Theme.Panel2,
                    BackgroundTransparency = 0.25,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 22),
                    Text = '',
                })
                addCorner(row, 3)
                local rowStroke = addStroke(row, self.State.Theme.BorderSoft, 1)
                local text = create('TextLabel', {
                    Parent = row,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    Font = Enum.Font.Code,
                    Text = name,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = self.State.Theme.Text,
                })

                local function renderSelected()
                    local chosen = self.Selected == name
                    rowStroke.Color = chosen and self.State.Theme.Accent or self.State.Theme.BorderSoft
                    text.TextColor3 = chosen and self.State.Theme.Text or self.State.Theme.DimText
                end

                row.MouseButton1Click:Connect(function()
                    self.Selected = name
                    ui.NameBox.Text = name
                    self:RefreshUI()
                end)

                row.MouseEnter:Connect(function()
                    row.BackgroundTransparency = 0.12
                end)
                row.MouseLeave:Connect(function()
                    row.BackgroundTransparency = 0.25
                end)

                row.BackgroundColor3 = self.State.Theme.Panel2
                rowStroke.Color = self.State.Theme.BorderSoft
                text.TextColor3 = self.State.Theme.Text
                renderSelected()
            end
        end

        ui.CountLabel.Text = string.format('%d config', #configs)
    end

    function ThemeManager.new(state)
        return setmetatable({ State = state, Selected = state.ThemeName }, ThemeManager)
    end

    function ThemeManager:GetThemes()
        local out = {}
        for name in pairs(Themes) do
            table.insert(out, name)
        end
        table.sort(out)
        return out
    end

    function ThemeManager:SetTheme(name)
        if Themes[name] then
            self.Selected = name
            self.State:SetTheme(name)
            self:RefreshUI()
        end
    end

    function ThemeManager:RefreshUI()
        local ui = self.UI
        if not ui then
            return
        end

        clearChildren(ui.List)
        local layout = create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })
        layout.Parent = ui.List

        for _, name in ipairs(self:GetThemes()) do
            local row = create('TextButton', {
                Parent = ui.List,
                AutoButtonColor = false,
                BackgroundColor3 = self.State.Theme.Panel2,
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 22),
                Text = '',
            })
            addCorner(row, 3)
            local rowStroke = addStroke(row, self.State.Theme.BorderSoft, 1)

            local text = create('TextLabel', {
                Parent = row,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -12, 1, 0),
                Font = Enum.Font.Code,
                Text = name,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = self.State.Theme.Text,
            })

            local function renderSelected()
                local chosen = self.State.ThemeName == name
                rowStroke.Color = chosen and self.State.Theme.Accent or self.State.Theme.BorderSoft
                text.TextColor3 = chosen and self.State.Theme.Text or self.State.Theme.DimText
            end

            row.MouseButton1Click:Connect(function()
                self:SetTheme(name)
            end)

            row.MouseEnter:Connect(function()
                row.BackgroundTransparency = 0.12
            end)
            row.MouseLeave:Connect(function()
                row.BackgroundTransparency = 0.25
            end)

            row.BackgroundColor3 = self.State.Theme.Panel2
            rowStroke.Color = self.State.Theme.BorderSoft
            text.TextColor3 = self.State.Theme.Text
            renderSelected()
        end
    end

    function State:BindTheme(callback)
        table.insert(self.ThemeCallbacks, callback)
        callback(self.Theme)
    end

    function State:RegisterFlag(flag, default, setter, callback)
        self.Flags[flag] = default
        self.FlagSetters[flag] = setter
        self.FlagCallbacks[flag] = callback
    end

    function State:SetFlag(flag, value)
        self.Flags[flag] = value
        local setter = self.FlagSetters[flag]
        if setter then
            setter(value)
        end
        local callback = self.FlagCallbacks[flag]
        if callback then
            task.spawn(callback, value)
        end
    end

    function State:SetOpen(state)
        self.Open = state
        self.Gui.Enabled = state
        if self.Blur then
            self.Blur.Size = state and self.Theme.Blur or 0
            self.Blur.Enabled = state
        end
    end

    function State:Notify(title, text, duration)
        duration = duration or 3
        local card = create('Frame', {
            Parent = self.Notifications,
            BackgroundColor3 = self.Theme.Panel,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(250, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        addCorner(card, 4)
        local cardStroke = addStroke(card, self.Theme.Border, 1)
        addPadding(card, 8, 8, 6, 6)

        local line = create('Frame', {
            Parent = card,
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 1, 0),
            Position = UDim2.fromOffset(0, 0),
        })

        local layout = create('UIListLayout', {
            Parent = card,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })

        local titleLabel = create('TextLabel', {
            Parent = card,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -6, 0, 16),
            Position = UDim2.fromOffset(6, 0),
            Font = Enum.Font.Code,
            Text = title,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
        })

        local bodyLabel = create('TextLabel', {
            Parent = card,
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, -6, 0, 0),
            Position = UDim2.fromOffset(6, 0),
            Font = Enum.Font.Code,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = text,
            TextSize = 13,
            TextColor3 = self.Theme.DimText,
        })

        self:BindTheme(function(theme)
            card.BackgroundColor3 = theme.Panel
            cardStroke.Color = theme.Border
            line.BackgroundColor3 = theme.Accent
            titleLabel.TextColor3 = theme.Text
            bodyLabel.TextColor3 = theme.DimText
        end)

        card.BackgroundTransparency = 1
        tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.12 })
        task.delay(duration, function()
            if card.Parent then
                tween(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
                task.wait(0.18)
                if card.Parent then
                    card:Destroy()
                end
            end
        end)
    end

    function State:SetTheme(name)
        if not Themes[name] then
            return
        end
        self.ThemeName = name
        self.Theme = cloneTheme(Themes[name])
        for _, callback in ipairs(self.ThemeCallbacks) do
            callback(self.Theme)
        end
        if self.Blur then
            self.Blur.Size = self.Open and self.Theme.Blur or 0
        end
        if self.ThemeManager then
            self.ThemeManager.Selected = name
            self.ThemeManager:RefreshUI()
        end
        if self.SaveManager then
            self.SaveManager:RefreshUI()
        end
    end

    function State:_buildManager()
        local manager = create('Frame', {
            Parent = self.Gui,
            Name = 'Manager',
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.78, 0.45),
            Size = UDim2.fromOffset(320, 290),
            BackgroundColor3 = self.Theme.Window,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
        })
        addCorner(manager, 4)
        local managerStroke = addStroke(manager, self.Theme.Border, 1)
        self.Manager = manager

        local top = create('Frame', {
            Parent = manager,
            BackgroundColor3 = self.Theme.Top,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22),
        })
        addCorner(top, 4)
        local fix = create('Frame', {
            Parent = top,
            BackgroundColor3 = self.Theme.Top,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -4),
            Size = UDim2.new(1, 0, 0, 4),
        })
        local topStroke = addStroke(top, self.Theme.BorderSoft, 1)

        local title = create('TextLabel', {
            Parent = top,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -30, 1, 0),
            Font = Enum.Font.Code,
            Text = 'Configs',
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
        })

        local close = create('TextButton', {
            Parent = top,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -5, 0, 0),
            Size = UDim2.fromOffset(18, 22),
            Font = Enum.Font.Code,
            Text = 'x',
            TextSize = 15,
            TextColor3 = self.Theme.DimText,
        })

        close.MouseButton1Click:Connect(function()
            manager.Visible = false
        end)

        close.MouseEnter:Connect(function()
            close.TextColor3 = self.Theme.Text
        end)
        close.MouseLeave:Connect(function()
            close.TextColor3 = self.Theme.DimText
        end)

        local modeBar = create('Frame', {
            Parent = manager,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 28),
            Size = UDim2.new(1, -16, 0, 20),
        })

        local modes = create('UIListLayout', {
            Parent = modeBar,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        })

        local pages = create('Frame', {
            Parent = manager,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 54),
            Size = UDim2.new(1, -16, 1, -62),
        })

        local configPage = create('Frame', {
            Parent = pages,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
        })

        local themePage = create('Frame', {
            Parent = pages,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
        })

        local function createModeButton(textValue)
            local button = create('TextButton', {
                Parent = modeBar,
                AutoButtonColor = false,
                BackgroundColor3 = self.Theme.Panel,
                BackgroundTransparency = 0.18,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(76, 20),
                Font = Enum.Font.Code,
                Text = textValue,
                TextSize = 12,
                TextColor3 = self.Theme.DimText,
            })
            addCorner(button, 3)
            local strokeObj = addStroke(button, self.Theme.BorderSoft, 1)
            return button, strokeObj
        end

        local configMode, configModeStroke = createModeButton('Configs')
        local themeMode, themeModeStroke = createModeButton('Themes')

        local function setMode(mode)
            configPage.Visible = mode == 'configs'
            themePage.Visible = mode == 'themes'
            configModeStroke.Color = mode == 'configs' and self.Theme.Accent or self.Theme.BorderSoft
            themeModeStroke.Color = mode == 'themes' and self.Theme.Accent or self.Theme.BorderSoft
            configMode.TextColor3 = mode == 'configs' and self.Theme.Text or self.Theme.DimText
            themeMode.TextColor3 = mode == 'themes' and self.Theme.Text or self.Theme.DimText
        end

        configMode.MouseButton1Click:Connect(function()
            setMode('configs')
        end)
        themeMode.MouseButton1Click:Connect(function()
            setMode('themes')
        end)

        local nameBox = create('TextBox', {
            Parent = configPage,
            BackgroundColor3 = self.Theme.Panel,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -86, 0, 22),
            Font = Enum.Font.Code,
            PlaceholderText = 'config name',
            Text = '',
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
            PlaceholderColor3 = self.Theme.DimText,
            ClearTextOnFocus = false,
        })
        addCorner(nameBox, 3)
        local nameStroke = addStroke(nameBox, self.Theme.BorderSoft, 1)
        addPadding(nameBox, 6, 6, 0, 0)

        local listHolder = create('Frame', {
            Parent = configPage,
            BackgroundColor3 = self.Theme.Panel,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 28),
            Size = UDim2.new(1, -86, 1, -28),
        })
        addCorner(listHolder, 3)
        local listHolderStroke = addStroke(listHolder, self.Theme.BorderSoft, 1)

        local list = create('ScrollingFrame', {
            Parent = listHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.new(1, -12, 1, -28),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Theme.Accent,
        })

        local countLabel = create('TextLabel', {
            Parent = listHolder,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 6, 1, -4),
            Size = UDim2.new(1, -12, 0, 14),
            Font = Enum.Font.Code,
            Text = '0 config',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.DimText,
        })

        local actions = create('Frame', {
            Parent = configPage,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(78, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        local actionsLayout = create('UIListLayout', {
            Parent = actions,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        })

        local function actionButton(textValue)
            local b = create('TextButton', {
                Parent = actions,
                AutoButtonColor = false,
                BackgroundColor3 = self.Theme.Panel,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(78, 22),
                Font = Enum.Font.Code,
                Text = textValue,
                TextSize = 12,
                TextColor3 = self.Theme.Text,
            })
            addCorner(b, 3)
            local bStroke = addStroke(b, self.Theme.BorderSoft, 1)
            self:BindTheme(function(theme)
                b.BackgroundColor3 = theme.Panel
                b.TextColor3 = theme.Text
                bStroke.Color = theme.BorderSoft
            end)
            return b
        end

        local saveButton = actionButton('Save')
        local loadButton = actionButton('Load')
        local deleteButton = actionButton('Delete')
        local refreshButton = actionButton('Refresh')

        local themesHolder = create('Frame', {
            Parent = themePage,
            BackgroundColor3 = self.Theme.Panel,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
        })
        addCorner(themesHolder, 3)
        local themesHolderStroke = addStroke(themesHolder, self.Theme.BorderSoft, 1)

        local themeList = create('ScrollingFrame', {
            Parent = themesHolder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.new(1, -12, 1, -12),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Theme.Accent,
        })

        self.SaveManager.UI = {
            List = list,
            NameBox = nameBox,
            CountLabel = countLabel,
        }
        self.ThemeManager.UI = {
            List = themeList,
        }

        saveButton.MouseButton1Click:Connect(function()
            local name = nameBox.Text ~= '' and nameBox.Text or 'default'
            local ok, err = self.SaveManager:Save(name)
            self:Notify('Config', ok and ('saved ' .. name) or ('save failed: ' .. tostring(err)), 2.2)
        end)

        loadButton.MouseButton1Click:Connect(function()
            local name = nameBox.Text ~= '' and nameBox.Text or self.SaveManager.Selected
            if not name then
                self:Notify('Config', 'select a config first', 2)
                return
            end
            local ok, err = self.SaveManager:Load(name)
            self:Notify('Config', ok and ('loaded ' .. name) or ('load failed: ' .. tostring(err)), 2.2)
        end)

        deleteButton.MouseButton1Click:Connect(function()
            local name = nameBox.Text ~= '' and nameBox.Text or self.SaveManager.Selected
            if not name then
                self:Notify('Config', 'select a config first', 2)
                return
            end
            local ok, err = self.SaveManager:Delete(name)
            self:Notify('Config', ok and ('deleted ' .. name) or ('delete failed: ' .. tostring(err)), 2.2)
        end)

        refreshButton.MouseButton1Click:Connect(function()
            self.SaveManager:RefreshUI()
            self.ThemeManager:RefreshUI()
        end)

        self:BindTheme(function(theme)
            manager.BackgroundColor3 = theme.Window
            managerStroke.Color = theme.Border
            top.BackgroundColor3 = theme.Top
            fix.BackgroundColor3 = theme.Top
            topStroke.Color = theme.BorderSoft
            title.TextColor3 = theme.Text
            close.TextColor3 = theme.DimText
            configMode.BackgroundColor3 = theme.Panel
            themeMode.BackgroundColor3 = theme.Panel
            configModeStroke.Color = theme.BorderSoft
            themeModeStroke.Color = theme.BorderSoft
            nameBox.BackgroundColor3 = theme.Panel
            nameBox.TextColor3 = theme.Text
            nameBox.PlaceholderColor3 = theme.DimText
            nameStroke.Color = theme.BorderSoft
            listHolder.BackgroundColor3 = theme.Panel
            listHolderStroke.Color = theme.BorderSoft
            list.ScrollBarImageColor3 = theme.Accent
            countLabel.TextColor3 = theme.DimText
            themesHolder.BackgroundColor3 = theme.Panel
            themesHolderStroke.Color = theme.BorderSoft
            themeList.ScrollBarImageColor3 = theme.Accent
        end)

        self.SaveManager:RefreshUI()
        self.ThemeManager:RefreshUI()
        setMode('configs')

        makeDraggable(top, manager)
    end

    function State:_init(options)
        self.Options = options or {}
        self.ThemeName = self.Options.Theme or 'Augustus'
        self.Theme = cloneTheme(Themes[self.ThemeName] or Themes.Augustus)
        self.ThemeCallbacks = {}
        self.Flags = {}
        self.FlagSetters = {}
        self.FlagCallbacks = {}
        self.Tabs = {}
        self.CurrentTab = nil
        self.Open = true

        self.Gui = create('ScreenGui', {
            Name = self.Options.Name or 'AugustusUI',
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        safeParent(self.Gui)

        self.Notifications = create('Frame', {
            Parent = self.Gui,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.fromOffset(260, 220),
            BackgroundTransparency = 1,
        })
        create('UIListLayout', {
            Parent = self.Notifications,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
        })

        if self.Options.Blur ~= false then
            local old = Lighting:FindFirstChild('AugustusUI_Blur')
            if old then
                old:Destroy()
            end
            self.Blur = create('BlurEffect', {
                Name = 'AugustusUI_Blur',
                Parent = Lighting,
                Size = self.Theme.Blur,
                Enabled = true,
            })
        end

        self.Main = create('Frame', {
            Parent = self.Gui,
            Name = 'Main',
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.43, 0.48),
            Size = UDim2.fromOffset(880, 430),
            BackgroundColor3 = self.Theme.Window,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
        })
        addCorner(self.Main, 4)
        local mainStroke = addStroke(self.Main, self.Theme.Border, 1)

        self.TopBar = create('Frame', {
            Parent = self.Main,
            BackgroundColor3 = self.Theme.Top,
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22),
        })
        addCorner(self.TopBar, 4)
        local topFix = create('Frame', {
            Parent = self.TopBar,
            BackgroundColor3 = self.Theme.Top,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -4),
            Size = UDim2.new(1, 0, 0, 4),
        })
        local topStroke = addStroke(self.TopBar, self.Theme.BorderSoft, 1)

        self.TitleLabel = create('TextLabel', {
            Parent = self.TopBar,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(0.45, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = self.Options.Title or 'Augustus',
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
        })

        self.SubtitleLabel = create('TextLabel', {
            Parent = self.TopBar,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -26, 0, 0),
            Size = UDim2.new(0.42, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = self.Options.Subtitle or 'clickgui-inspired roblox library',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = self.Theme.DimText,
        })

        local managerButton = create('TextButton', {
            Parent = self.TopBar,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 0),
            Size = UDim2.fromOffset(18, 22),
            Font = Enum.Font.Code,
            Text = '+',
            TextSize = 15,
            TextColor3 = self.Theme.DimText,
        })

        local body = create('Frame', {
            Parent = self.Main,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 1, -22),
        })

        self.CategoryBar = create('Frame', {
            Parent = body,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 4),
            Size = UDim2.new(1, -16, 0, 18),
        })
        create('UIListLayout', {
            Parent = self.CategoryBar,
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        })

        local categoryLine = create('Frame', {
            Parent = body,
            BackgroundColor3 = self.Theme.BorderSoft,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 24),
            Size = UDim2.new(1, -16, 0, 1),
        })

        self.PageArea = create('Frame', {
            Parent = body,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 25),
            Size = UDim2.new(1, 0, 1, -25),
        })

        self:BindTheme(function(theme)
            self.Main.BackgroundColor3 = theme.Window
            mainStroke.Color = theme.Border
            self.TopBar.BackgroundColor3 = theme.Top
            topFix.BackgroundColor3 = theme.Top
            topStroke.Color = theme.BorderSoft
            self.TitleLabel.TextColor3 = theme.Text
            self.SubtitleLabel.TextColor3 = theme.DimText
            managerButton.TextColor3 = theme.DimText
            categoryLine.BackgroundColor3 = theme.BorderSoft
        end)

        managerButton.MouseButton1Click:Connect(function()
            self.Manager.Visible = not self.Manager.Visible
        end)

        managerButton.MouseEnter:Connect(function()
            managerButton.TextColor3 = self.Theme.Text
        end)
        managerButton.MouseLeave:Connect(function()
            managerButton.TextColor3 = self.Theme.DimText
        end)

        makeDraggable(self.TopBar, self.Main)

        self.SaveManager = SaveManager.new(self)
        self.ThemeManager = ThemeManager.new(self)
        self:_buildManager()

        local toggleKey = self.Options.ToggleKey or Enum.KeyCode.RightShift
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then
                return
            end
            if input.KeyCode == toggleKey then
                self:SetOpen(not self.Open)
            end
        end)
    end

    function State:_selectTab(tab)
        if self.CurrentTab == tab then
            return
        end
        self.CurrentTab = tab
        for _, item in ipairs(self.Tabs) do
            item.Page.Visible = item == tab
            item.RenderSelected(item == tab)
        end
        if tab and tab.SelectedSection then
            tab:SelectSection(tab.SelectedSection)
        end
    end

    function State:_createTab(name)
        local tab = setmetatable({
            State = self,
            Name = name,
            Sections = {},
            SelectedSection = nil,
        }, Tab)

        local width = math.max(46, (#name * 7) + 10)
        local button = create('TextButton', {
            Parent = self.CategoryBar,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(width, 18),
            Font = Enum.Font.Code,
            Text = string.upper(name),
            TextSize = 12,
            TextColor3 = self.Theme.DimText,
        })

        local underline = create('Frame', {
            Parent = button,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
        })

        local page = create('Frame', {
            Parent = self.PageArea,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
        })

        local moduleListWrap = create('Frame', {
            Parent = page,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(145, 1),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        local moduleList = create('ScrollingFrame', {
            Parent = moduleListWrap,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(8, 6),
            Size = UDim2.new(1, -12, 1, -12),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
        })
        create('UIListLayout', {
            Parent = moduleList,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })

        local verticalLine = create('Frame', {
            Parent = page,
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(145, 0),
            Size = UDim2.new(0, 1, 1, 0),
        })

        local contentWrap = create('Frame', {
            Parent = page,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(146, 0),
            Size = UDim2.new(1, -146, 1, 0),
        })

        local contentHeader = create('TextLabel', {
            Parent = contentWrap,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(1, -24, 0, 16),
            Font = Enum.Font.Code,
            Text = '',
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.Text,
        })

        local contentSub = create('TextLabel', {
            Parent = contentWrap,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 25),
            Size = UDim2.new(1, -24, 0, 14),
            Font = Enum.Font.Code,
            Text = '',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.Theme.DimText,
        })

        local contentLine = create('Frame', {
            Parent = contentWrap,
            BackgroundColor3 = self.Theme.BorderSoft,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 44),
            Size = UDim2.new(1, -24, 0, 1),
        })

        local sectionPages = create('Frame', {
            Parent = contentWrap,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 46),
            Size = UDim2.new(1, 0, 1, -46),
        })

        tab.Button = button
        tab.Underline = underline
        tab.Page = page
        tab.ModuleList = moduleList
        tab.ModuleListWrap = moduleListWrap
        tab.ContentHeader = contentHeader
        tab.ContentSub = contentSub
        tab.ContentLine = contentLine
        tab.SectionPages = sectionPages

        tab.RenderSelected = function(selected)
            button.TextColor3 = selected and self.Theme.Text or self.Theme.DimText
            underline.Visible = selected
        end

        button.MouseButton1Click:Connect(function()
            self:_selectTab(tab)
        end)

        self:BindTheme(function(theme)
            button.TextColor3 = self.CurrentTab == tab and theme.Text or theme.DimText
            underline.BackgroundColor3 = theme.Accent
            verticalLine.BackgroundColor3 = theme.Accent
            contentHeader.TextColor3 = theme.Text
            contentSub.TextColor3 = theme.DimText
            contentLine.BackgroundColor3 = theme.BorderSoft
        end)

        table.insert(self.Tabs, tab)
        if not self.CurrentTab then
            self:_selectTab(tab)
        end

        return tab
    end

    function Tab:SelectSection(section)
        if self.SelectedSection == section then
            return
        end
        self.SelectedSection = section
        for _, item in ipairs(self.Sections) do
            item.Page.Visible = item == section
            item.RenderSelected(item == section)
        end
        self.ContentHeader.Text = section.Name
        self.ContentSub.Text = section.Description or ''
    end

    function Tab:AddSection(name, description)
        local section = setmetatable({
            State = self.State,
            Tab = self,
            Name = name,
            Description = description or '',
        }, Section)

        local button = create('TextButton', {
            Parent = self.ModuleList,
            AutoButtonColor = false,
            BackgroundColor3 = self.State.Theme.Panel,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.Code,
            Text = '',
        })

        local accent = create('Frame', {
            Parent = button,
            BackgroundColor3 = self.State.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(1, 14),
            Position = UDim2.fromOffset(0, 3),
            Visible = false,
        })

        local label = create('TextLabel', {
            Parent = button,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -8, 1, 0),
            Font = Enum.Font.Code,
            Text = name,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.State.Theme.DimText,
        })

        local page = create('ScrollingFrame', {
            Parent = self.SectionPages,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(1, -24, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.State.Theme.Accent,
            Visible = false,
        })
        create('UIListLayout', {
            Parent = page,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 2),
        })

        section.Button = button
        section.Accent = accent
        section.Label = label
        section.Page = page

        section.RenderSelected = function(selected)
            accent.Visible = selected
            label.TextColor3 = selected and self.State.Theme.Text or self.State.Theme.DimText
            button.BackgroundTransparency = selected and 0.78 or 1
        end

        button.MouseButton1Click:Connect(function()
            self:SelectSection(section)
        end)

        self.State:BindTheme(function(theme)
            button.BackgroundColor3 = theme.Panel
            label.TextColor3 = self.SelectedSection == section and theme.Text or theme.DimText
            accent.BackgroundColor3 = theme.Accent
            page.ScrollBarImageColor3 = theme.Accent
        end)

        table.insert(self.Sections, section)
        if not self.SelectedSection then
            self:SelectSection(section)
        end

        return section
    end

    function Section:_row(height)
        local row = create('Frame', {
            Parent = self.Page,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, height or 22),
        })
        return row
    end

    function Section:_separator(y)
        local line = create('Frame', {
            Parent = y,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.State.Theme.BorderSoft,
            BorderSizePixel = 0,
        })
        self.State:BindTheme(function(theme)
            line.BackgroundColor3 = theme.BorderSoft
        end)
        return line
    end

    function Section:AddLabel(text)
        local row = self:_row(18)
        local label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.State.Theme.DimText,
        })
        self.State:BindTheme(function(theme)
            label.TextColor3 = theme.DimText
        end)
        return {
            Set = function(_, newText)
                label.Text = newText
            end,
        }
    end

    function Section:AddButton(options)
        options = options or {}
        local row = self:_row(22)
        local button = create('TextButton', {
            Parent = row,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = '',
        })

        local label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Font = Enum.Font.Code,
            Text = options.Text or 'Button',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.State.Theme.Text,
        })

        local action = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(56, 22),
            Font = Enum.Font.Code,
            Text = options.RightText or 'run',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = self.State.Theme.Accent,
        })

        self:_separator(row)

        button.MouseEnter:Connect(function()
            label.TextColor3 = self.State.Theme.Accent
        end)
        button.MouseLeave:Connect(function()
            label.TextColor3 = self.State.Theme.Text
        end)
        button.MouseButton1Click:Connect(function()
            if options.Callback then
                options.Callback()
            end
        end)

        self.State:BindTheme(function(theme)
            label.TextColor3 = theme.Text
            action.TextColor3 = theme.Accent
        end)

        return button
    end

    function Section:AddToggle(options)
        options = options or {}
        local flag = options.Flag or options.Text or ('Toggle_' .. tostring(#self.Page:GetChildren()))
        local value = options.Default == true

        local row = self:_row(22)
        local button = create('TextButton', {
            Parent = row,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = '',
        })

        local label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -70, 1, 0),
            Font = Enum.Font.Code,
            Text = options.Text or 'Toggle',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.State.Theme.Text,
        })

        local stateLabel = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(66, 22),
            Font = Enum.Font.Code,
            Text = 'false',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = self.State.Theme.Bad,
        })

        local function render(newValue)
            value = newValue == true
            stateLabel.Text = value and 'true' or 'false'
            stateLabel.TextColor3 = value and self.State.Theme.Good or self.State.Theme.Bad
        end

        button.MouseEnter:Connect(function()
            label.TextColor3 = self.State.Theme.Accent
        end)
        button.MouseLeave:Connect(function()
            label.TextColor3 = self.State.Theme.Text
        end)
        button.MouseButton1Click:Connect(function()
            self.State:SetFlag(flag, not value)
        end)

        self.State:RegisterFlag(flag, value, render, options.Callback)
        render(value)
        self:_separator(row)

        self.State:BindTheme(function(theme)
            label.TextColor3 = theme.Text
            stateLabel.TextColor3 = value and theme.Good or theme.Bad
        end)

        return {
            Set = function(_, newValue)
                self.State:SetFlag(flag, newValue)
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
        local flag = options.Flag or options.Text or ('Slider_' .. tostring(#self.Page:GetChildren()))
        local value = options.Default or min
        local dragging = false

        local row = self:_row(32)
        local button = create('TextButton', {
            Parent = row,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = '',
        })

        local label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -70, 0, 12),
            Font = Enum.Font.Code,
            Text = options.Text or 'Slider',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self.State.Theme.Text,
        })

        local valueLabel = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(66, 12),
            Font = Enum.Font.Code,
            Text = '0',
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = self.State.Theme.DimText,
        })

        local bar = create('Frame', {
            Parent = row,
            BackgroundColor3 = self.State.Theme.Panel2,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 18),
            Size = UDim2.new(1, 0, 0, 6),
        })
        addCorner(bar, 2)
        local barStroke = addStroke(bar, self.State.Theme.BorderSoft, 1)

        local fill = create('Frame', {
            Parent = bar,
            BackgroundColor3 = self.State.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
        })
        addCorner(fill, 2)

        local knob = create('Frame', {
            Parent = bar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(6, 10),
            BackgroundColor3 = self.State.Theme.Text,
            BorderSizePixel = 0,
        })
        addCorner(knob, 2)

        local function round(n)
            local mult = 10 ^ decimals
            return math.floor(n * mult + 0.5) / mult
        end

        local function render(newValue)
            value = math.clamp(round(newValue), min, max)
            local alpha = (value - min) / (max - min)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            valueLabel.Text = formatValue(value)
        end

        local function setByMouse(x)
            local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
            local newValue = min + ((max - min) * alpha)
            self.State:SetFlag(flag, newValue)
        end

        button.MouseEnter:Connect(function()
            label.TextColor3 = self.State.Theme.Accent
        end)
        button.MouseLeave:Connect(function()
            label.TextColor3 = self.State.Theme.Text
        end)

        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setByMouse(input.Position.X)
            end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setByMouse(input.Position.X)
            end
        end)

        self.State:RegisterFlag(flag, value, render, options.Callback)
        render(value)
        self:_separator(row)

        self.State:BindTheme(function(theme)
            label.TextColor3 = theme.Text
            valueLabel.TextColor3 = theme.DimText
            bar.BackgroundColor3 = theme.Panel2
            barStroke.Color = theme.BorderSoft
            fill.BackgroundColor3 = theme.Accent
            knob.BackgroundColor3 = theme.Text
        end)

        return {
            Set = function(_, newValue)
                self.State:SetFlag(flag, newValue)
            end,
            Get = function()
                return value
            end,
        }
    end

    function Window:AddTab(name)
        return self.State:_createTab(name)
    end

    function Window:Notify(title, text, duration)
        self.State:Notify(title, text, duration)
    end

    function Window:SetTheme(name)
        self.State:SetTheme(name)
    end

    function Window:SetOpen(state)
        self.State:SetOpen(state)
    end

    function Window:Destroy()
        if self.State.Blur then
            self.State.Blur:Destroy()
        end
        self.State.Gui:Destroy()
    end

    function Library:CreateWindow(options)
        local state = setmetatable({}, State)
        state:_init(options)
        local window = setmetatable({ State = state }, Window)
        window.SaveManager = state.SaveManager
        window.ThemeManager = state.ThemeManager
        return window
    end

    return Library
end

local BaseLibrary = __AugustusBuildCoreLibrary()

local UserInputService = game:GetService('UserInputService')
local HttpService = game:GetService('HttpService')

local Library = {
    Options = {},
    Toggles = {},
    _CurrentWindow = nil,
}

local function create(className, props)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    return obj
end

local function addCorner(parent, radius)
    local c = create('UICorner', { CornerRadius = UDim.new(0, radius) })
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = create('UIStroke', {
        Color = color,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    s.Parent = parent
    return s
end

local function addPadding(parent, left, right, top, bottom)
    local p = create('UIPadding', {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
    p.Parent = parent
    return p
end

local function shallowCopy(tbl)
    local out = {}
    for key, value in pairs(tbl or {}) do
        out[key] = value
    end
    return out
end

local function keyNameToCode(name)
    if typeof(name) == 'EnumItem' then
        return name
    end
    if type(name) ~= 'string' then
        return Enum.KeyCode.Unknown
    end
    return Enum.KeyCode[name] or Enum.KeyCode.Unknown
end

local function serializeValue(value)
    local valueType = typeof(value)

    if valueType == 'Color3' then
        return {
            __augustus_type = 'Color3',
            r = value.R,
            g = value.G,
            b = value.B,
        }
    end

    if valueType == 'EnumItem' and value.EnumType == Enum.KeyCode then
        return {
            __augustus_type = 'KeyCode',
            name = value.Name,
        }
    end

    if type(value) == 'table' then
        local out = {}
        for key, inner in pairs(value) do
            out[key] = serializeValue(inner)
        end
        return out
    end

    return value
end

local function deserializeValue(value)
    if type(value) == 'table' and value.__augustus_type == 'Color3' then
        return Color3.new(value.r or 0, value.g or 0, value.b or 0)
    end

    if type(value) == 'table' and value.__augustus_type == 'KeyCode' then
        return value.name or 'Unknown'
    end

    if type(value) == 'table' then
        local out = {}
        for key, inner in pairs(value) do
            out[key] = deserializeValue(inner)
        end
        return out
    end

    return value
end

local function normalizeNamedArguments(first, second, kind)
    if type(first) == 'table' then
        local options = shallowCopy(first)
        options.Flag = options.Flag or options.Text or (kind .. tostring(math.random(1000, 9999)))
        options.Text = options.Text or tostring(options.Flag)
        return tostring(options.Flag), options
    end

    local options = shallowCopy(second or {})
    options.Flag = tostring(first)
    options.Text = options.Text or tostring(first)
    return tostring(first), options
end

local function normalizeButtonArguments(first, second)
    if type(first) == 'table' then
        local options = shallowCopy(first)
        options.Callback = options.Callback or options.Func
        options.Text = options.Text or 'Button'
        return options
    end

    return {
        Text = tostring(first or 'Button'),
        Callback = second,
    }
end

local function registerOptionsGlobal()
    local env = getgenv and getgenv() or _G
    env.Options = Library.Options
    env.Toggles = Library.Toggles
end

local function patchSaveManager(saveManager, state)
    function saveManager:Save(name)
        if not writefile or not isfolder then
            return false, 'file api unavailable'
        end

        if makefolder and isfolder and not isfolder(self.Folder) then
            makefolder(self.Folder)
        end

        local data = {
            theme = state.ThemeName,
            flags = {},
        }

        for key, value in pairs(state.Flags) do
            if state.FlagSetters[key] and not self.Ignore[key] then
                data.flags[key] = serializeValue(value)
            end
        end

        writefile(self.Folder .. '/' .. name .. '.json', HttpService:JSONEncode(data))
        self.Selected = name
        if self.RefreshUI then
            self:RefreshUI()
        end
        return true
    end

    function saveManager:Load(name)
        if not readfile or not isfile then
            return false, 'file api unavailable'
        end

        local path = self.Folder .. '/' .. name .. '.json'
        if not isfile(path) then
            return false, 'config not found'
        end

        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)

        if not ok or type(decoded) ~= 'table' then
            return false, 'invalid json'
        end

        if decoded.theme then
            state:SetTheme(decoded.theme)
        end

        for flag, value in pairs(decoded.flags or {}) do
            state:SetFlag(flag, deserializeValue(value))
        end

        self.Selected = name
        if self.RefreshUI then
            self:RefreshUI()
        end
        return true
    end

    function saveManager:SetLibrary(library)
        self.Library = library
        return self
    end
end

local function patchThemeManager(themeManager)
    function themeManager:SetLibrary(library)
        self.Library = library
        return self
    end

    function themeManager:SetFolder(folder)
        self.Folder = folder
        return self
    end
end

local function bindTheme(state, callback)
    state:BindTheme(callback)
end

local function wrapControl(kind, flag, state, rawHandle, initialValue, initialCallback)
    local callbacks = {}
    local control = {
        Type = kind,
        Flag = flag,
        Value = initialValue,
        _state = state,
        _raw = rawHandle,
    }

    if initialCallback then
        table.insert(callbacks, initialCallback)
    end

    function control:OnChanged(callback)
        table.insert(callbacks, callback)
        return self
    end

    function control:_emit(value)
        self.Value = value
        for _, callback in ipairs(callbacks) do
            task.spawn(callback, value)
        end
    end

    function control:SetValue(value)
        state:SetFlag(flag, value)
    end

    function control:Set(value)
        state:SetFlag(flag, value)
    end

    function control:GetValue()
        return self.Value
    end

    function control:Get()
        return self.Value
    end

    return control
end

local function makeKeyPicker(sectionWrapper, flag, options, linkedToggle, anchorRow)
    options = shallowCopy(options or {})
    options.Text = options.Text or flag
    local state = sectionWrapper._base.State
    local window = sectionWrapper._window
    local defaultName = typeof(options.Default) == 'EnumItem' and options.Default.Name or tostring(options.Default or 'RightShift')

    local row = anchorRow or sectionWrapper._base:_row(22)
    local label = row:FindFirstChildWhichIsA('TextLabel')
    if label then
        label.Size = UDim2.new(1, -86, 1, 0)
        if options.Text then
            label.Text = options.Text
        end
    else
        label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -86, 1, 0),
            Font = Enum.Font.Code,
            Text = options.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = state.Theme.Text,
        })
    end

    local valueButton = create('TextButton', {
        Parent = row,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(82, 22),
        Font = Enum.Font.Code,
        Text = '',
    })

    local valueLabel = create('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(82, 22),
        Font = Enum.Font.Code,
        Text = defaultName,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = state.Theme.Accent,
    })

    if not anchorRow then
        sectionWrapper._base:_separator(row)
    end

    local control = wrapControl('KeyPicker', flag, state, nil, defaultName, options.Callback)
    Library.Options[flag] = control
    registerOptionsGlobal()

    local waiting = false
    local holdActive = false
    local mode = tostring(options.Mode or 'Toggle')

    local function render(newValue)
        local name = typeof(newValue) == 'EnumItem' and newValue.Name or tostring(newValue or 'Unknown')
        control.Value = name
        valueLabel.Text = waiting and '...' or name
    end

    state:RegisterFlag(flag, defaultName, render, function(newValue)
        control:_emit(typeof(newValue) == 'EnumItem' and newValue.Name or tostring(newValue))
        if string.lower(flag) == 'menukeybind' or string.lower(flag) == 'menubind' then
            window._menuKeyName = typeof(newValue) == 'EnumItem' and newValue.Name or tostring(newValue)
        end
    end)
    state:SetFlag(flag, defaultName)

    valueButton.MouseButton1Click:Connect(function()
        waiting = true
        render(control.Value)
    end)

    bindTheme(state, function(theme)
        label.TextColor3 = theme.Text
        valueLabel.TextColor3 = waiting and theme.Text or theme.Accent
    end)

    table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if waiting then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                waiting = false
                state:SetFlag(flag, input.KeyCode.Name)
            end
            return
        end

        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        local current = keyNameToCode(control.Value)
        if input.KeyCode ~= current then
            return
        end

        if linkedToggle and options.SyncToggleState then
            if mode == 'Hold' then
                holdActive = true
                linkedToggle:Set(true)
            else
                linkedToggle:Set(not linkedToggle.Value)
            end
        end

        if options.Callback then
            task.spawn(options.Callback, control.Value)
        end
    end))

    table.insert(window._connections, UserInputService.InputEnded:Connect(function(input)
        if not linkedToggle or not options.SyncToggleState or mode ~= 'Hold' or not holdActive then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyNameToCode(control.Value) then
            holdActive = false
            linkedToggle:Set(false)
        end
    end))

    return control
end

local function makeDropdown(sectionWrapper, flag, options)
    options = shallowCopy(options or {})
    local state = sectionWrapper._base.State
    local row = sectionWrapper._base:_row(22)
    local listValues = shallowCopy(options.Values or {})
    local isMulti = options.Multi == true

    local button = create('TextButton', {
        Parent = row,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Text = '',
    })

    local label = create('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -90, 0, 22),
        Font = Enum.Font.Code,
        Text = options.Text or flag,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = state.Theme.Text,
    })

    local valueLabel = create('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(86, 22),
        Font = Enum.Font.Code,
        Text = 'none',
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = state.Theme.DimText,
    })

    local dropdown = create('Frame', {
        Parent = row,
        BackgroundColor3 = state.Theme.Panel2,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
    })
    addCorner(dropdown, 3)
    local dropdownStroke = addStroke(dropdown, state.Theme.BorderSoft, 1)

    local scroller = create('ScrollingFrame', {
        Parent = dropdown,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = state.Theme.Accent,
    })
    addPadding(scroller, 4, 4, 4, 4)
    local listLayout = create('UIListLayout', {
        Parent = scroller,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })

    sectionWrapper._base:_separator(row)

    local open = false
    local control

    local function normalizeDefault()
        if isMulti then
            if type(options.Default) == 'table' then
                return shallowCopy(options.Default)
            end
            return {}
        end

        if type(options.Default) == 'number' then
            return listValues[options.Default]
        end
        if options.Default ~= nil then
            return options.Default
        end
        return listValues[1]
    end

    local function summary(value)
        if isMulti then
            local picked = {}
            for _, choice in ipairs(listValues) do
                if value[choice] then
                    table.insert(picked, choice)
                end
            end
            if #picked == 0 then
                return 'none'
            end
            if #picked == 1 then
                return picked[1]
            end
            return tostring(#picked) .. ' selected'
        end
        return tostring(value or 'none')
    end

    local function setOpen(stateOpen)
        open = stateOpen
        dropdown.Visible = stateOpen
        local targetHeight = 0
        if stateOpen then
            targetHeight = math.min(#listValues, 6) * 20 + 10
        end
        dropdown.Size = UDim2.new(1, 0, 0, targetHeight)
        row.Size = UDim2.new(1, 0, 0, 22 + (stateOpen and (targetHeight + 4) or 0))
        valueLabel.TextColor3 = stateOpen and state.Theme.Accent or state.Theme.DimText
    end

    local function render(newValue)
        control.Value = newValue
        valueLabel.Text = summary(newValue)
    end

    control = wrapControl('Dropdown', flag, state, nil, normalizeDefault(), options.Callback)
    Library.Options[flag] = control
    registerOptionsGlobal()

    state:RegisterFlag(flag, control.Value, render, function(newValue)
        control:_emit(newValue)
    end)
    state:SetFlag(flag, control.Value)

    local function rebuildButtons()
        for _, child in ipairs(scroller:GetChildren()) do
            if not child:IsA('UIListLayout') and not child:IsA('UIPadding') then
                child:Destroy()
            end
        end

        for _, choice in ipairs(listValues) do
            local rowButton = create('TextButton', {
                Parent = scroller,
                AutoButtonColor = false,
                BackgroundColor3 = state.Theme.Panel,
                BackgroundTransparency = 0.18,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 18),
                Text = '',
            })
            addCorner(rowButton, 2)
            local rowStroke = addStroke(rowButton, state.Theme.BorderSoft, 1)

            local rowText = create('TextLabel', {
                Parent = rowButton,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -12, 1, 0),
                Font = Enum.Font.Code,
                Text = tostring(choice),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = state.Theme.Text,
            })

            local function refreshChoice(theme)
                theme = theme or state.Theme
                local selected = isMulti and control.Value[choice] or control.Value == choice
                rowStroke.Color = selected and theme.Accent or theme.BorderSoft
                rowText.TextColor3 = selected and theme.Text or theme.DimText
                rowButton.BackgroundColor3 = theme.Panel
            end

            rowButton.MouseButton1Click:Connect(function()
                if isMulti then
                    local newValue = shallowCopy(control.Value)
                    newValue[choice] = not newValue[choice]
                    state:SetFlag(flag, newValue)
                else
                    state:SetFlag(flag, choice)
                    setOpen(false)
                end
                refreshChoice()
            end)

            bindTheme(state, function(theme)
                refreshChoice(theme)
            end)

            refreshChoice()
        end
    end

    function control:SetValues(values)
        listValues = shallowCopy(values or {})
        if isMulti then
            local fresh = {}
            for _, choice in ipairs(listValues) do
                if control.Value[choice] then
                    fresh[choice] = true
                end
            end
            state:SetFlag(flag, fresh)
        else
            if control.Value == nil or table.find(listValues, control.Value) == nil then
                state:SetFlag(flag, listValues[1])
            else
                render(control.Value)
            end
        end
        rebuildButtons()
        setOpen(open)
    end

    button.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    bindTheme(state, function(theme)
        label.TextColor3 = theme.Text
        valueLabel.TextColor3 = open and theme.Accent or theme.DimText
        dropdown.BackgroundColor3 = theme.Panel2
        dropdownStroke.Color = theme.BorderSoft
        scroller.ScrollBarImageColor3 = theme.Accent
    end)

    rebuildButtons()
    setOpen(false)

    return control
end

local function makeColorPicker(sectionWrapper, flag, options, anchorRow)
    options = shallowCopy(options or {})
    local state = sectionWrapper._base.State
    local row = anchorRow or sectionWrapper._base:_row(22)
    local existingLabel = row:FindFirstChildWhichIsA('TextLabel')
    if existingLabel then
        existingLabel.Size = UDim2.new(1, -26, 1, 0)
    end
    local workingHeight = 78

    local pickerButton = create('TextButton', {
        Parent = row,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(22, 22),
        Text = '',
    })

    local swatch = create('Frame', {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = options.Default or Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    addCorner(swatch, 2)
    local swatchStroke = addStroke(swatch, state.Theme.BorderSoft, 1)

    local popup = create('Frame', {
        Parent = row,
        BackgroundColor3 = state.Theme.Panel2,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false,
        ClipsDescendants = true,
    })
    addCorner(popup, 3)
    local popupStroke = addStroke(popup, state.Theme.BorderSoft, 1)
    addPadding(popup, 6, 6, 6, 6)

    create('UIListLayout', {
        Parent = popup,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })

    local control = wrapControl('ColorPicker', flag, state, nil, options.Default or Color3.fromRGB(255, 255, 255), options.Callback)
    Library.Options[flag] = control
    registerOptionsGlobal()

    local open = false
    local currentH, currentS, currentV = Color3.toHSV(control.Value)

    local function setOpen(stateOpen)
        open = stateOpen
        popup.Visible = stateOpen
        popup.Size = UDim2.new(1, 0, 0, stateOpen and workingHeight or 0)
        row.Size = UDim2.new(1, 0, 0, 22 + (stateOpen and workingHeight + 4 or 0))
    end

    local function makeHSVBar(titleText)
        local holder = create('Frame', {
            Parent = popup,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
        })

        local title = create('TextLabel', {
            Parent = holder,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(16, 16),
            Font = Enum.Font.Code,
            Text = titleText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = state.Theme.Text,
        })

        local bar = create('Frame', {
            Parent = holder,
            BackgroundColor3 = state.Theme.Panel,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(18, 4),
            Size = UDim2.new(1, -18, 0, 8),
        })
        addCorner(bar, 2)
        local barStroke = addStroke(bar, state.Theme.BorderSoft, 1)

        local fill = create('Frame', {
            Parent = bar,
            BackgroundColor3 = state.Theme.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0),
        })
        addCorner(fill, 2)

        local knob = create('Frame', {
            Parent = bar,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(6, 10),
            BackgroundColor3 = state.Theme.Text,
            BorderSizePixel = 0,
        })
        addCorner(knob, 2)

        local dragging = false
        local api = {}

        function api:SetAlpha(alpha)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        end

        function api:Bind(onChanged)
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    onChanged(alpha)
                end
            end)
            bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
                    onChanged(alpha)
                end
            end)
        end

        bindTheme(state, function(theme)
            title.TextColor3 = theme.Text
            bar.BackgroundColor3 = theme.Panel
            barStroke.Color = theme.BorderSoft
            knob.BackgroundColor3 = theme.Text
        end)

        return api
    end

    local hueBar = makeHSVBar('H')
    local satBar = makeHSVBar('S')
    local valBar = makeHSVBar('V')

    local function syncFromColor(color)
        control.Value = color
        swatch.BackgroundColor3 = color
        currentH, currentS, currentV = Color3.toHSV(color)
        hueBar:SetAlpha(currentH)
        satBar:SetAlpha(currentS)
        valBar:SetAlpha(currentV)
    end

    local function emitColor()
        local color = Color3.fromHSV(currentH, currentS, currentV)
        state:SetFlag(flag, color)
    end

    hueBar:Bind(function(alpha)
        currentH = alpha
        emitColor()
    end)
    satBar:Bind(function(alpha)
        currentS = alpha
        emitColor()
    end)
    valBar:Bind(function(alpha)
        currentV = alpha
        emitColor()
    end)

    state:RegisterFlag(flag, control.Value, syncFromColor, function(newValue)
        control:_emit(newValue)
    end)
    state:SetFlag(flag, control.Value)

    pickerButton.MouseButton1Click:Connect(function()
        setOpen(not open)
    end)

    bindTheme(state, function(theme)
        swatchStroke.Color = theme.BorderSoft
        popup.BackgroundColor3 = theme.Panel2
        popupStroke.Color = theme.BorderSoft
    end)

    setOpen(false)
    return control
end

local function wrapSection(windowWrapper, tabWrapper, rawSection)
    local sectionWrapper = {
        _window = windowWrapper,
        _tab = tabWrapper,
        _base = rawSection,
    }

    function sectionWrapper:AddDivider(text)
        local row = self._base:_row(text and 14 or 8)
        local line = create('Frame', {
            Parent = row,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self._base.State.Theme.BorderSoft,
            BorderSizePixel = 0,
        })

        local label
        if text then
            label = create('TextLabel', {
                Parent = row,
                BackgroundColor3 = self._base.State.Theme.Window,
                BackgroundTransparency = 0,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.fromOffset(math.max(30, #text * 7), 14),
                Font = Enum.Font.Code,
                Text = text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = self._base.State.Theme.DimText,
            })
        end

        bindTheme(self._base.State, function(theme)
            line.BackgroundColor3 = theme.BorderSoft
            if label then
                label.BackgroundColor3 = theme.Window
                label.TextColor3 = theme.DimText
            end
        end)

        return row
    end

    function sectionWrapper:AddLabel(text)
        local row = self._base:_row(22)
        local label = create('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.Code,
            Text = text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = self._base.State.Theme.DimText,
        })

        bindTheme(self._base.State, function(theme)
            label.TextColor3 = theme.DimText
        end)

        local object = {}
        function object:Set(newText)
            label.Text = newText
        end
        function object:AddColorPicker(flag, options)
            return makeColorPicker(sectionWrapper, flag, options, row)
        end
        function object:AddKeyPicker(flag, options)
            return makeKeyPicker(sectionWrapper, flag, options, nil, row)
        end
        return object
    end

    function sectionWrapper:AddButton(first, second)
        local options = normalizeButtonArguments(first, second)
        return self._base:AddButton({
            Text = options.Text,
            RightText = options.RightText or 'run',
            Callback = options.Callback,
        })
    end

    function sectionWrapper:AddToggle(first, second)
        local flag, options = normalizeNamedArguments(first, second, 'Toggle')
        local control
        local raw = self._base:AddToggle({
            Flag = flag,
            Text = options.Text,
            Default = options.Default,
            Callback = function(value)
                if control then
                    control:_emit(value)
                end
            end,
        })

        control = wrapControl('Toggle', flag, self._base.State, raw, raw:Get(), options.Callback)
        Library.Toggles[flag] = control
        registerOptionsGlobal()

        function control:Set(value)
            raw:Set(value)
        end
        function control:SetValue(value)
            raw:Set(value)
        end
        function control:Get()
            return raw:Get()
        end
        function control:AddKeyPicker(keyFlag, keyOptions)
            return makeKeyPicker(sectionWrapper, keyFlag, keyOptions, self)
        end

        control:OnChanged(function(value)
            control.Value = value
        end)

        return control
    end

    function sectionWrapper:AddSlider(first, second)
        local flag, options = normalizeNamedArguments(first, second, 'Slider')
        local control
        local raw = self._base:AddSlider({
            Flag = flag,
            Text = options.Text,
            Min = options.Min,
            Max = options.Max,
            Default = options.Default,
            Decimals = options.Decimals or options.Rounding or 0,
            Callback = function(value)
                if control then
                    control:_emit(value)
                end
            end,
        })

        control = wrapControl('Slider', flag, self._base.State, raw, raw:Get(), options.Callback)
        Library.Options[flag] = control
        registerOptionsGlobal()

        function control:SetValue(value)
            raw:Set(value)
        end
        function control:Set(value)
            raw:Set(value)
        end
        function control:GetValue()
            return raw:Get()
        end
        function control:Get()
            return raw:Get()
        end

        control:OnChanged(function(value)
            control.Value = value
        end)

        return control
    end

    function sectionWrapper:AddDropdown(first, second)
        local flag, options = normalizeNamedArguments(first, second, 'Dropdown')
        return makeDropdown(self, flag, options)
    end

    function sectionWrapper:AddColorPicker(first, second)
        local flag, options = normalizeNamedArguments(first, second, 'Color')
        return makeColorPicker(self, flag, options)
    end

    function sectionWrapper:AddKeyPicker(first, second)
        local flag, options = normalizeNamedArguments(first, second, 'Key')
        return makeKeyPicker(self, flag, options)
    end

    return sectionWrapper
end

local function wrapTab(windowWrapper, rawTab)
    local tabWrapper = {
        _window = windowWrapper,
        _base = rawTab,
    }

    function tabWrapper:AddSection(name, description)
        return wrapSection(windowWrapper, self, self._base:AddSection(name, description))
    end

    function tabWrapper:AddLeftGroupbox(name)
        return self:AddSection(name, '')
    end

    function tabWrapper:AddRightGroupbox(name)
        return self:AddSection(name, '')
    end

    return tabWrapper
end

function Library:CreateWindow(options)
    options = shallowCopy(options or {})

    local baseWindow = BaseLibrary:CreateWindow({
        Name = options.Name,
        Title = options.Title,
        Subtitle = options.Subtitle or options.FooterText or 'augustus linoria-safe compatibility layer',
        Theme = options.Theme or 'Augustus',
        ToggleKey = Enum.KeyCode.Unknown,
        Blur = options.Blur ~= false,
        ConfigFolder = options.ConfigFolder or 'AugustusConfigs',
    })

    patchSaveManager(baseWindow.SaveManager, baseWindow.State)
    patchThemeManager(baseWindow.ThemeManager)

    local windowWrapper = {
        _base = baseWindow,
        _connections = {},
        _menuKeyName = typeof(options.ToggleKey) == 'EnumItem' and options.ToggleKey.Name or tostring(options.ToggleKey or 'RightShift'),
    }

    function windowWrapper:AddTab(name)
        return wrapTab(self, self._base:AddTab(name))
    end

    function windowWrapper:Notify(title, text, duration)
        self._base:Notify(title, text, duration)
    end

    function windowWrapper:SetTheme(name)
        self._base:SetTheme(name)
    end

    function windowWrapper:SetOpen(state)
        self._base:SetOpen(state)
    end

    function windowWrapper:Destroy()
        for _, connection in ipairs(self._connections) do
            connection:Disconnect()
        end
        self._base:Destroy()
        if Library._CurrentWindow == self then
            Library._CurrentWindow = nil
        end
    end

    function windowWrapper:Unload()
        self:Destroy()
    end

    table.insert(windowWrapper._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyNameToCode(windowWrapper._menuKeyName) then
            windowWrapper:SetOpen(not windowWrapper._base.State.Open)
        end
    end))

    function baseWindow.SaveManager:BuildConfigSection(tab)
        local section = tab:AddLeftGroupbox('Config Manager')
        local selectedName = self.Selected or 'default'

        local chooser = section:AddDropdown('__augustus_config_select', {
            Text = 'Config',
            Values = self:GetConfigs(),
            Default = 1,
        })

        chooser:OnChanged(function(value)
            selectedName = value or selectedName
        end)

        section:AddButton({
            Text = 'Refresh Configs',
            RightText = 'refresh',
            Callback = function()
                chooser:SetValues(self:GetConfigs())
                windowWrapper:Notify('Configs', 'config list refreshed', 2)
            end,
        })

        section:AddButton({
            Text = 'Save default',
            RightText = 'save',
            Callback = function()
                local ok = self:Save('default')
                chooser:SetValues(self:GetConfigs())
                if ok then
                    windowWrapper:Notify('Configs', 'saved default.json', 2)
                end
            end,
        })

        section:AddButton({
            Text = 'Load selected',
            RightText = 'load',
            Callback = function()
                local ok = self:Load(selectedName or 'default')
                if ok then
                    windowWrapper:Notify('Configs', 'loaded ' .. tostring(selectedName or 'default'), 2)
                end
            end,
        })

        section:AddButton({
            Text = 'Delete selected',
            RightText = 'delete',
            Callback = function()
                local ok = self:Delete(selectedName or 'default')
                chooser:SetValues(self:GetConfigs())
                if ok then
                    windowWrapper:Notify('Configs', 'deleted ' .. tostring(selectedName or 'default'), 2)
                end
            end,
        })

        return section
    end

    function baseWindow.ThemeManager:ApplyToTab(tab)
        local section = tab:AddRightGroupbox('Theme Manager')
        for _, name in ipairs(self:GetThemes()) do
            section:AddButton({
                Text = 'Load ' .. name,
                RightText = 'theme',
                Callback = function()
                    self:SetTheme(name)
                    windowWrapper:Notify('Theme', name .. ' loaded', 2)
                end,
            })
        end
        return section
    end

    windowWrapper.SaveManager = baseWindow.SaveManager
    windowWrapper.ThemeManager = baseWindow.ThemeManager

    Library._CurrentWindow = windowWrapper
    Library.SaveManager = baseWindow.SaveManager
    Library.ThemeManager = baseWindow.ThemeManager
    registerOptionsGlobal()

    return windowWrapper
end

function Library:Notify(title, text, duration)
    if self._CurrentWindow then
        self._CurrentWindow:Notify(title, text, duration)
    end
end

function Library:Unload()
    if self._CurrentWindow then
        self._CurrentWindow:Destroy()
    end
end

return Library

