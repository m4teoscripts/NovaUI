--[[
    NovaUI.lua
    Standalone Rayfield-style UI library
    by M4teo

    No external asset/HTTP dependency.
    Public API:
      NovaUI:CreateWindow
      NovaUI:Notify
      NovaUI:LoadConfiguration
      NovaUI:SetVisibility
      NovaUI:IsVisible
      NovaUI:Destroy

      Window:CreateTab
      Window:ModifyTheme

      Tab:CreateButton
      Tab:CreateToggle
      Tab:CreateSlider
      Tab:CreateDropdown
      Tab:CreateInput
      Tab:CreateColorPicker
      Tab:CreateKeybind
      Tab:CreateLabel
      Tab:CreateParagraph
      Tab:CreateSection
      Tab:CreateDivider
]]

local NovaUI = {}
NovaUI.Flags = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local GUI_PARENT = CoreGui

pcall(function()
    if gethui then
        GUI_PARENT = gethui()
    end
end)

local Themes = {
    Default = {
        TextColor = Color3.fromRGB(240,240,240),
        Background = Color3.fromRGB(24,24,27),
        Topbar = Color3.fromRGB(31,31,35),
        Shadow = Color3.fromRGB(0,0,0),
        NotificationBackground = Color3.fromRGB(28,28,32),
        TabBackground = Color3.fromRGB(38,38,43),
        TabSelected = Color3.fromRGB(70,110,180),
        ElementBackground = Color3.fromRGB(34,34,39),
        ElementHover = Color3.fromRGB(43,43,49),
        ElementStroke = Color3.fromRGB(55,55,62),
        Accent = Color3.fromRGB(65,135,230),
        InputBackground = Color3.fromRGB(29,29,34),
        PlaceholderColor = Color3.fromRGB(160,160,165),
    },
    Ocean = {
        TextColor = Color3.fromRGB(230,245,250),
        Background = Color3.fromRGB(18,28,32),
        Topbar = Color3.fromRGB(23,39,44),
        Shadow = Color3.fromRGB(0,0,0),
        NotificationBackground = Color3.fromRGB(22,37,40),
        TabBackground = Color3.fromRGB(31,55,59),
        TabSelected = Color3.fromRGB(45,150,160),
        ElementBackground = Color3.fromRGB(26,45,48),
        ElementHover = Color3.fromRGB(35,60,63),
        ElementStroke = Color3.fromRGB(45,75,78),
        Accent = Color3.fromRGB(0,170,180),
        InputBackground = Color3.fromRGB(23,40,43),
        PlaceholderColor = Color3.fromRGB(140,165,168),
    },
    AmberGlow = {
        TextColor = Color3.fromRGB(255,245,230),
        Background = Color3.fromRGB(38,27,20),
        Topbar = Color3.fromRGB(51,36,24),
        Shadow = Color3.fromRGB(0,0,0),
        NotificationBackground = Color3.fromRGB(48,33,23),
        TabBackground = Color3.fromRGB(68,47,31),
        TabSelected = Color3.fromRGB(225,150,55),
        ElementBackground = Color3.fromRGB(55,39,29),
        ElementHover = Color3.fromRGB(68,47,34),
        ElementStroke = Color3.fromRGB(90,61,42),
        Accent = Color3.fromRGB(245,145,45),
        InputBackground = Color3.fromRGB(48,34,26),
        PlaceholderColor = Color3.fromRGB(190,155,125),
    },
    Light = {
        TextColor = Color3.fromRGB(35,35,38),
        Background = Color3.fromRGB(244,244,247),
        Topbar = Color3.fromRGB(228,228,233),
        Shadow = Color3.fromRGB(160,160,165),
        NotificationBackground = Color3.fromRGB(250,250,252),
        TabBackground = Color3.fromRGB(232,232,237),
        TabSelected = Color3.fromRGB(190,210,240),
        ElementBackground = Color3.fromRGB(238,238,242),
        ElementHover = Color3.fromRGB(224,224,230),
        ElementStroke = Color3.fromRGB(205,205,212),
        Accent = Color3.fromRGB(50,120,210),
        InputBackground = Color3.fromRGB(248,248,250),
        PlaceholderColor = Color3.fromRGB(125,125,135),
    },
    Amethyst = {
        TextColor = Color3.fromRGB(242,238,250),
        Background = Color3.fromRGB(30,21,39),
        Topbar = Color3.fromRGB(43,29,54),
        Shadow = Color3.fromRGB(0,0,0),
        NotificationBackground = Color3.fromRGB(38,26,48),
        TabBackground = Color3.fromRGB(57,39,72),
        TabSelected = Color3.fromRGB(150,100,195),
        ElementBackground = Color3.fromRGB(45,31,58),
        ElementHover = Color3.fromRGB(56,39,70),
        ElementStroke = Color3.fromRGB(75,52,92),
        Accent = Color3.fromRGB(155,95,205),
        InputBackground = Color3.fromRGB(39,27,50),
        PlaceholderColor = Color3.fromRGB(170,150,185),
    },
    Green = {
        TextColor = Color3.fromRGB(235,250,235),
        Background = Color3.fromRGB(20,32,23),
        Topbar = Color3.fromRGB(28,47,32),
        Shadow = Color3.fromRGB(0,0,0),
        NotificationBackground = Color3.fromRGB(24,40,27),
        TabBackground = Color3.fromRGB(35,59,40),
        TabSelected = Color3.fromRGB(75,160,85),
        ElementBackground = Color3.fromRGB(28,49,33),
        ElementHover = Color3.fromRGB(38,65,43),
        ElementStroke = Color3.fromRGB(52,82,57),
        Accent = Color3.fromRGB(75,170,85),
        InputBackground = Color3.fromRGB(24,43,29),
        PlaceholderColor = Color3.fromRGB(145,170,150),
    },
}

NovaUI.Theme = Themes

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        pcall(function()
            fn(table.unpack(args, 1, args.n))
        end)
    end)
end

local function tween(obj, info, props)
    local ok, result = pcall(function()
        local t = TweenService:Create(obj, info, props)
        t:Play()
        return t
    end)
    return ok and result or nil
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1,1,1)
    s.Transparency = transparency or 0
    s.Thickness = 1
    s.Parent = parent
    return s
end

local function padding(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0,l or 0)
    p.PaddingRight = UDim.new(0,r or 0)
    p.PaddingTop = UDim.new(0,t or 0)
    p.PaddingBottom = UDim.new(0,b or 0)
    p.Parent = parent
    return p
end

local function makeText(parent, text, size, color, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = tostring(text or "")
    label.TextColor3 = color
    label.TextSize = size or 14
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, text)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = tostring(text or "")
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundTransparency = 1
    b.Parent = parent
    return b
end

local function playClick()
    -- Intentionally local and optional; avoids external sound dependencies.
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://6026984224"
    sound.Volume = 0.18
    sound.Parent = GUI_PARENT
    sound:Play()
    task.delay(2, function()
        pcall(function() sound:Destroy() end)
    end)
end

local WindowMethods = {}
WindowMethods.__index = WindowMethods
local TabMethods = {}
TabMethods.__index = TabMethods

function NovaUI:_applyTheme()
    local theme = self._theme
    if not self._gui or not self._gui.Parent then return end

    self._main.BackgroundColor3 = theme.Background
    self._topbar.BackgroundColor3 = theme.Topbar
    self._title.TextColor3 = theme.TextColor
    self._subtitle.TextColor3 = theme.PlaceholderColor
    self._windowStroke.Color = theme.ElementStroke

    for _, tab in pairs(self._tabs) do
        tab._button.BackgroundColor3 = tab._selected and theme.TabSelected or theme.TabBackground
        tab._button.TextColor3 = theme.TextColor
        tab._page.BackgroundColor3 = theme.Background
    end

    for _, obj in ipairs(self._themeObjects) do
        if obj.kind == "element" and obj.object.Parent then
            obj.object.BackgroundColor3 = theme.ElementBackground
            if obj.stroke then obj.stroke.Color = theme.ElementStroke end
        elseif obj.kind == "label" and obj.object.Parent then
            obj.object.TextColor3 = theme.TextColor
        elseif obj.kind == "input" and obj.object.Parent then
            obj.object.BackgroundColor3 = theme.InputBackground
            obj.object.TextColor3 = theme.TextColor
            obj.object.PlaceholderColor3 = theme.PlaceholderColor
        end
    end
end

function WindowMethods:ModifyTheme(theme)
    if type(theme) == "string" and Themes[theme] then
        self._theme = Themes[theme]
        self._owner._theme = self._theme
        self._owner:_applyTheme()
        return true
    elseif type(theme) == "table" then
        self._theme = theme
        self._owner._theme = theme
        self._owner:_applyTheme()
        return true
    end
    return false
end

function WindowMethods:CreateTab(name, icon)
    name = tostring(name or "Tab")

    local button = makeButton(self._tabList, name)
    button.Size = UDim2.new(0, 104, 1, 0)
    button.BackgroundColor3 = self._owner._theme.TabBackground
    button.TextColor3 = self._owner._theme.TextColor
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    corner(button, 7)

    local page = Instance.new("ScrollingFrame")
    page.Name = name:gsub("%W","") .. "Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = self._owner._theme.Accent
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.Parent = self._pages

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    padding(page, 8, 8, 8, 8)

    local tab = setmetatable({
        _owner = self._owner,
        _window = self,
        _button = button,
        _page = page,
        _selected = false,
        _order = #self._owner._tabs + 1,
    }, TabMethods)

    self._owner._tabs[name] = tab
    self._owner._tabArray[#self._owner._tabArray+1] = tab

    button.Activated:Connect(function()
        playClick()
        self._owner:_selectTab(tab)
    end)

    if #self._owner._tabArray == 1 then
        self._owner:_selectTab(tab)
    end

    return tab
end

function NovaUI:_selectTab(tab)
    for _, t in ipairs(self._tabArray) do
        t._selected = (t == tab)
        t._page.Visible = t._selected
        t._button.BackgroundColor3 = t._selected and self._theme.TabSelected or self._theme.TabBackground
    end
end

function NovaUI:_registerThemeObject(object, kind, st)
    self._themeObjects[#self._themeObjects+1] = {
        object = object,
        kind = kind,
        stroke = st
    }
end

function TabMethods:_elementBase(height)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,height or 48)
    f.BackgroundColor3 = self._owner._theme.ElementBackground
    f.BorderSizePixel = 0
    corner(f, 8)
    local st = stroke(f, self._owner._theme.ElementStroke, 0.15)
    f.Parent = self._page
    self._owner:_registerThemeObject(f, "element", st)
    return f
end

function TabMethods:CreateSection(text)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,30)
    holder.BackgroundTransparency = 1
    holder.Parent = self._page
    local label = makeText(holder, text, 13, self._owner._theme.TextColor, true)
    label.Size = UDim2.new(1,0,1,0)
    self._owner:_registerThemeObject(label, "label")
    return label
end

function TabMethods:CreateDivider()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,1)
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = self._owner._theme.ElementStroke
    frame.Parent = self._page
    return frame
end

function TabMethods:CreateLabel(text, icon, color, richText)
    local holder = self:_elementBase(38)
    local label = makeText(holder, text, 13, color or self._owner._theme.TextColor, false)
    label.Size = UDim2.new(1,-18,1,0)
    label.Position = UDim2.new(0,9,0,0)
    label.TextWrapped = true
    if richText then label.RichText = true end
    return label
end

function TabMethods:CreateParagraph(data)
    data = data or {}
    local title = tostring(data.Title or "Paragraph")
    local content = tostring(data.Content or "")
    local holder = self:_elementBase(70)
    local titleLabel = makeText(holder, title, 13, self._owner._theme.TextColor, true)
    titleLabel.Position = UDim2.new(0,10,0,5)
    titleLabel.Size = UDim2.new(1,-20,0,22)
    local contentLabel = makeText(holder, content, 12, self._owner._theme.PlaceholderColor, false)
    contentLabel.Position = UDim2.new(0,10,0,27)
    contentLabel.Size = UDim2.new(1,-20,0,38)
    contentLabel.TextWrapped = true
    return holder
end

function TabMethods:CreateButton(data)
    data = data or {}
    local holder = self:_elementBase(46)
    local label = makeText(holder, data.Name or "Button", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(1,-75,1,0)

    local button = makeButton(holder, "CLICK")
    button.Position = UDim2.new(1,-66,0,7)
    button.Size = UDim2.new(0,55,0,32)
    button.BackgroundColor3 = self._owner._theme.Accent
    button.BackgroundTransparency = 0
    button.TextSize = 11
    button.TextColor3 = Color3.new(1,1,1)
    corner(button, 6)

    button.Activated:Connect(function()
        playClick()
        safeCall(data.Callback)
    end)

    return {
        Set = function(_, value)
            label.Text = tostring(value)
        end
    }
end

function TabMethods:CreateToggle(data)
    data = data or {}
    local current = data.CurrentValue == true
    local holder = self:_elementBase(46)

    local label = makeText(holder, data.Name or "Toggle", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(1,-75,1,0)

    local switch = makeButton(holder, "")
    switch.Position = UDim2.new(1,-58,0.5,-13)
    switch.Size = UDim2.new(0,46,0,26)
    switch.BackgroundColor3 = current and self._owner._theme.Accent or self._owner._theme.ElementStroke
    switch.BackgroundTransparency = 0
    corner(switch, 13)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,20,0,20)
    knob.Position = current and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    corner(knob, 10)
    knob.Parent = switch

    local function set(v, fire)
        current = v == true
        tween(switch, TweenInfo.new(0.16), {
            BackgroundColor3 = current and self._owner._theme.Accent or self._owner._theme.ElementStroke
        })
        tween(knob, TweenInfo.new(0.16), {
            Position = current and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        })
        if data.Flag then NovaUI.Flags[data.Flag] = current end
        if fire then safeCall(data.Callback, current) end
    end

    switch.Activated:Connect(function()
        playClick()
        set(not current, true)
    end)

    if data.Flag then NovaUI.Flags[data.Flag] = current end

    return {
        Set = function(_, v) set(v, true) end
    }
end

function TabMethods:CreateSlider(data)
    data = data or {}
    local range = data.Range or {0,100}
    local min, max = tonumber(range[1]) or 0, tonumber(range[2]) or 100
    local increment = tonumber(data.Increment) or 1
    local value = tonumber(data.CurrentValue) or min
    value = math.clamp(value, min, max)

    local holder = self:_elementBase(62)
    local label = makeText(holder, data.Name or "Slider", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,4)
    label.Size = UDim2.new(0.7,0,0,22)

    local valueLabel = makeText(holder, "", 12, self._owner._theme.PlaceholderColor, false)
    valueLabel.Position = UDim2.new(0.7,0,0,4)
    valueLabel.Size = UDim2.new(0.3,-12,0,22)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0,12,0,36)
    bar.Size = UDim2.new(1,-24,0,8)
    bar.BackgroundColor3 = self._owner._theme.ElementStroke
    bar.BorderSizePixel = 0
    bar.Parent = holder
    corner(bar, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = self._owner._theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    corner(fill, 4)

    local dragging = false

    local function quantize(v)
        v = math.clamp(v, min, max)
        local steps = math.floor(((v-min)/increment)+0.5)
        return math.clamp(min + steps*increment, min, max)
    end

    local function setValue(v, fire)
        value = quantize(tonumber(v) or min)
        local alpha = (max == min) and 0 or ((value-min)/(max-min))
        fill.Size = UDim2.new(alpha,0,1,0)
        valueLabel.Text = tostring(value) .. tostring(data.Suffix or "")
        if data.Flag then NovaUI.Flags[data.Flag] = value end
        if fire then safeCall(data.Callback, value) end
    end

    local function fromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(min + (max-min)*alpha, true)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    setValue(value, false)

    return {
        Set = function(_, v) setValue(v, true) end
    }
end

function TabMethods:CreateDropdown(data)
    data = data or {}
    local options = {}
    for _, v in ipairs(data.Options or {}) do table.insert(options, tostring(v)) end
    local selected = {}
    for _, v in ipairs(data.CurrentOption or {}) do table.insert(selected, tostring(v)) end
    if #selected == 0 and #options > 0 and data.AllowNone ~= true then
        selected[1] = options[1]
    end

    local holder = self:_elementBase(48)
    local title = makeText(holder, data.Name or "Dropdown", 13, self._owner._theme.TextColor, true)
    title.Position = UDim2.new(0,12,0,0)
    title.Size = UDim2.new(0.45,0,1,0)

    local select = makeButton(holder, (#selected > 0 and table.concat(selected,", ")) or "Select")
    select.Position = UDim2.new(0.46,0,0,6)
    select.Size = UDim2.new(0.52,-8,0,36)
    select.BackgroundColor3 = self._owner._theme.InputBackground
    select.BackgroundTransparency = 0
    select.TextColor3 = self._owner._theme.TextColor
    select.TextSize = 11
    corner(select, 6)
    stroke(select, self._owner._theme.ElementStroke, 0.25)

    local list = Instance.new("Frame")
    list.Visible = false
    list.Position = UDim2.new(0,0,1,4)
    list.Size = UDim2.new(1,0,0,math.min(180, math.max(34,#options*32+8)))
    list.BackgroundColor3 = self._owner._theme.Background
    list.BorderSizePixel = 0
    list.ZIndex = 50
    corner(list, 7)
    stroke(list, self._owner._theme.ElementStroke, 0)
    list.Parent = select

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ZIndex = 51
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = list
    padding(scroll,4,4,4,4)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,3)
    layout.Parent = scroll

    local function contains(v)
        for _, x in ipairs(selected) do if x == v then return true end end
        return false
    end

    local function refreshText()
        select.Text = (#selected > 0 and table.concat(selected,", ")) or "Select"
        if data.Flag then NovaUI.Flags[data.Flag] = table.clone(selected) end
    end

    for _, option in ipairs(options) do
        local b = makeButton(scroll, option)
        b.Size = UDim2.new(1,0,0,28)
        b.BackgroundColor3 = contains(option) and self._owner._theme.TabSelected or self._owner._theme.ElementBackground
        b.BackgroundTransparency = 0
        b.TextColor3 = self._owner._theme.TextColor
        b.TextSize = 11
        b.ZIndex = 52
        corner(b,5)

        b.Activated:Connect(function()
            playClick()
            if data.MultipleOptions then
                if contains(option) then
                    for i,x in ipairs(selected) do
                        if x == option then table.remove(selected,i) break end
                    end
                else
                    table.insert(selected, option)
                end
            else
                selected = {option}
                list.Visible = false
            end
            refreshText()
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = contains(child.Text) and self._owner._theme.TabSelected or self._owner._theme.ElementBackground
                end
            end
            safeCall(data.Callback, table.clone(selected))
        end)
    end

    select.Activated:Connect(function()
        playClick()
        list.Visible = not list.Visible
    end)

    if data.Flag then NovaUI.Flags[data.Flag] = table.clone(selected) end

    return {
        Set = function(_, values)
            selected = {}
            if type(values) == "table" then
                for _, v in ipairs(values) do table.insert(selected, tostring(v)) end
            elseif values ~= nil then
                table.insert(selected, tostring(values))
            end
            refreshText()
        end
    }
end

function TabMethods:CreateInput(data)
    data = data or {}
    local holder = self:_elementBase(50)
    local label = makeText(holder, data.Name or "Input", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(0.38,0,1,0)

    local box = Instance.new("TextBox")
    box.Position = UDim2.new(0.4,0,0,7)
    box.Size = UDim2.new(0.58,-10,0,36)
    box.BackgroundColor3 = self._owner._theme.InputBackground
    box.BorderSizePixel = 0
    box.TextColor3 = self._owner._theme.TextColor
    box.PlaceholderColor3 = self._owner._theme.PlaceholderColor
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Text = tostring(data.CurrentValue or "")
    box.PlaceholderText = tostring(data.PlaceholderText or "Enter text...")
    box.Parent = holder
    corner(box,6)
    stroke(box, self._owner._theme.ElementStroke, 0.25)
    self._owner:_registerThemeObject(box, "input")

    local function changed()
        local value = box.Text
        if data.Flag then NovaUI.Flags[data.Flag] = value end
        safeCall(data.Callback, value)
        if data.RemoveTextAfterFocusLost then
            box.Text = ""
        end
    end

    box.FocusLost:Connect(changed)

    if data.Flag then NovaUI.Flags[data.Flag] = box.Text end

    return {
        Set = function(_, value)
            box.Text = tostring(value or "")
            if data.Flag then NovaUI.Flags[data.Flag] = box.Text end
        end
    }
end

local function createColorPopup(owner, initial, callback)
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0,250,0,180)
    popup.BackgroundColor3 = owner._theme.Background
    popup.BorderSizePixel = 0
    popup.Visible = false
    popup.ZIndex = 100
    popup.Parent = owner._gui
    corner(popup, 9)
    stroke(popup, owner._theme.ElementStroke, 0)

    local title = makeText(popup, "Color Picker", 13, owner._theme.TextColor, true)
    title.Position = UDim2.new(0,12,0,8)
    title.Size = UDim2.new(1,-24,0,25)
    title.ZIndex = 101

    local preview = Instance.new("Frame")
    preview.Position = UDim2.new(0,12,0,42)
    preview.Size = UDim2.new(1,-24,0,42)
    preview.BackgroundColor3 = initial
    preview.BorderSizePixel = 0
    preview.ZIndex = 101
    preview.Parent = popup
    corner(preview,7)

    local hue = Instance.new("TextBox")
    hue.Position = UDim2.new(0,12,0,94)
    hue.Size = UDim2.new(1,-24,0,30)
    hue.BackgroundColor3 = owner._theme.InputBackground
    hue.TextColor3 = owner._theme.TextColor
    hue.PlaceholderColor3 = owner._theme.PlaceholderColor
    hue.Text = ""
    hue.PlaceholderText = "R,G,B  (example: 255,0,0)"
    hue.TextSize = 11
    hue.ClearTextOnFocus = false
    hue.Parent = popup
    hue.ZIndex = 101
    corner(hue,6)

    local ok = makeButton(popup, "Aceptar")
    ok.Position = UDim2.new(0,12,1,-43)
    ok.Size = UDim2.new(0.5,-18,0,32)
    ok.BackgroundColor3 = owner._theme.Accent
    ok.BackgroundTransparency = 0
    ok.ZIndex = 101
    corner(ok,6)

    local cancel = makeButton(popup, "Cancelar")
    cancel.Position = UDim2.new(0.5,6,1,-43)
    cancel.Size = UDim2.new(0.5,-18,0,32)
    cancel.BackgroundColor3 = owner._theme.ElementStroke
    cancel.BackgroundTransparency = 0
    cancel.ZIndex = 101
    corner(cancel,6)

    local chosen = initial

    hue.FocusLost:Connect(function()
        local r,g,b = hue.Text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
        if r then
            chosen = Color3.fromRGB(
                math.clamp(tonumber(r),0,255),
                math.clamp(tonumber(g),0,255),
                math.clamp(tonumber(b),0,255)
            )
            preview.BackgroundColor3 = chosen
        end
    end)

    ok.Activated:Connect(function()
        callback(chosen)
        popup.Visible = false
    end)

    cancel.Activated:Connect(function()
        popup.Visible = false
    end)

    return popup, preview
end

function TabMethods:CreateColorPicker(data)
    data = data or {}
    local current = data.Color or Color3.new(1,1,1)
    local holder = self:_elementBase(46)

    local label = makeText(holder, data.Name or "Color Picker", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(1,-75,1,0)

    local swatch = makeButton(holder, "")
    swatch.Position = UDim2.new(1,-55,0.5,-13)
    swatch.Size = UDim2.new(0,44,0,26)
    swatch.BackgroundColor3 = current
    swatch.BackgroundTransparency = 0
    corner(swatch,6)

    local popup, preview = createColorPopup(self._owner, current, function(c)
        current = c
        swatch.BackgroundColor3 = c
        if data.Flag then NovaUI.Flags[data.Flag] = c end
        safeCall(data.Callback, c)
    end)

    swatch.Activated:Connect(function()
        playClick()
        local pos = swatch.AbsolutePosition
        popup.Position = UDim2.new(0,pos.X,0,pos.Y + swatch.AbsoluteSize.Y + 5)
        popup.Visible = not popup.Visible
    end)

    if data.Flag then NovaUI.Flags[data.Flag] = current end

    return {
        Set = function(_, c)
            if typeof(c) == "Color3" then
                current = c
                swatch.BackgroundColor3 = c
                preview.BackgroundColor3 = c
            end
        end
    }
end

function TabMethods:CreateKeybind(data)
    data = data or {}
    local key = data.CurrentKeybind or data.Keybind or "K"
    local holder = self:_elementBase(46)

    local label = makeText(holder, data.Name or "Keybind", 13, self._owner._theme.TextColor, true)
    label.Position = UDim2.new(0,12,0,0)
    label.Size = UDim2.new(0.55,0,1,0)

    local keyButton = makeButton(holder, tostring(key))
    keyButton.Position = UDim2.new(1,-75,0.5,-15)
    keyButton.Size = UDim2.new(0,62,0,30)
    keyButton.BackgroundColor3 = self._owner._theme.InputBackground
    keyButton.BackgroundTransparency = 0
    keyButton.TextColor3 = self._owner._theme.TextColor
    corner(keyButton,6)

    local listening = false

    keyButton.Activated:Connect(function()
        playClick()
        listening = true
        keyButton.Text = "..."
    end)

    local connection
    connection = UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                key = input.KeyCode.Name
                keyButton.Text = key
                listening = false
            end
            return
        end

        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == tostring(key) then
            safeCall(data.Callback, data.HoldToInteract and true or key)
        end
    end)

    if data.Flag then NovaUI.Flags[data.Flag] = key end

    return {
        Set = function(_, newKey)
            key = tostring(newKey)
            keyButton.Text = key
            if data.Flag then NovaUI.Flags[data.Flag] = key end
        end,
        Destroy = function()
            pcall(function() connection:Disconnect() end)
        end
    }
end

function NovaUI:Notify(data)
    data = data or {}
    if not self._notifications then return end

    local title = tostring(data.Title or "NovaUI")
    local content = tostring(data.Content or "")
    local duration = tonumber(data.Duration) or 4

    local item = Instance.new("Frame")
    item.Size = UDim2.new(1,-16,0,72)
    item.BackgroundColor3 = self._theme.NotificationBackground
    item.BorderSizePixel = 0
    item.BackgroundTransparency = 0.04
    item.Parent = self._notifications
    corner(item,8)
    stroke(item, self._theme.ElementStroke, 0.1)

    local t = makeText(item, title, 13, self._theme.TextColor, true)
    t.Position = UDim2.new(0,10,0,6)
    t.Size = UDim2.new(1,-20,0,22)

    local c = makeText(item, content, 11, self._theme.PlaceholderColor, false)
    c.Position = UDim2.new(0,10,0,29)
    c.Size = UDim2.new(1,-20,0,35)
    c.TextWrapped = true

    item.Position = UDim2.new(1,20,0,0)
    tween(item, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0,0,0,0)
    })

    task.delay(duration, function()
        if item.Parent then
            tween(item, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1,20,0,0),
                BackgroundTransparency = 1
            })
            task.wait(0.3)
            pcall(function() item:Destroy() end)
        end
    end)
end

function NovaUI:SetVisibility(value)
    if not self._gui then return end
    self._visible = value == true
    self._gui.Enabled = self._visible
end

function NovaUI:IsVisible()
    return self._visible == true
end

function NovaUI:LoadConfiguration()
    -- Kept as a compatible API. Runtime flags are already initialized when controls are created.
    return true
end

function NovaUI:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self._visible = false
    for _, connection in ipairs(self._connections) do
        pcall(function() connection:Disconnect() end)
    end
    if self._gui then
        pcall(function() self._gui:Destroy() end)
    end
end

function NovaUI:CreateWindow(settings)
    settings = settings or {}

    if self._gui and self._gui.Parent then
        self:Destroy()
    end

    self._theme = Themes[settings.Theme or "Default"] or Themes.Default
    self._tabs = {}
    self._tabArray = {}
    self._themeObjects = {}
    self._connections = {}
    self._visible = true
    self._destroyed = false

    local gui = Instance.new("ScreenGui")
    gui.Name = "NovaUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = GUI_PARENT
    self._gui = gui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.Position = UDim2.new(0.5,0,0.5,0)
    main.Size = UDim2.new(0,470,0,330)
    main.BackgroundColor3 = self._theme.Background
    main.BorderSizePixel = 0
    main.Parent = gui
    self._main = main
    corner(main, 12)
    self._windowStroke = stroke(main, self._theme.ElementStroke, 0)

    local scale = Instance.new("UIScale")
    scale.Scale = 0.92
    scale.Parent = main

    local topbar = Instance.new("Frame")
    topbar.Size = UDim2.new(1,0,0,58)
    topbar.BackgroundColor3 = self._theme.Topbar
    topbar.BorderSizePixel = 0
    topbar.Parent = main
    corner(topbar, 12)
    self._topbar = topbar

    local cover = Instance.new("Frame")
    cover.Position = UDim2.new(0,0,1,-12)
    cover.Size = UDim2.new(1,0,0,12)
    cover.BackgroundColor3 = self._theme.Topbar
    cover.BorderSizePixel = 0
    cover.Parent = topbar

    local title = makeText(topbar, settings.Name or "NovaUI", 16, self._theme.TextColor, true)
    title.Position = UDim2.new(0,14,0,7)
    title.Size = UDim2.new(1,-105,0,25)
    self._title = title

    local subtitle = makeText(topbar, settings.LoadingSubtitle or "(Rayfield Modified)", 10, self._theme.PlaceholderColor, false)
    subtitle.Position = UDim2.new(0,15,0,31)
    subtitle.Size = UDim2.new(1,-105,0,18)
    self._subtitle = subtitle

    local minimize = makeButton(topbar, "—")
    minimize.Position = UDim2.new(1,-65,0,13)
    minimize.Size = UDim2.new(0,26,0,26)
    minimize.TextSize = 18
    minimize.TextColor3 = self._theme.TextColor

    local close = makeButton(topbar, "×")
    close.Position = UDim2.new(1,-36,0,13)
    close.Size = UDim2.new(0,26,0,26)
    close.TextSize = 20
    close.TextColor3 = self._theme.TextColor

    local tabs = Instance.new("ScrollingFrame")
    tabs.Position = UDim2.new(0,8,0,66)
    tabs.Size = UDim2.new(1,-16,0,36)
    tabs.BackgroundTransparency = 1
    tabs.BorderSizePixel = 0
    tabs.ScrollBarThickness = 0
    tabs.ScrollingDirection = Enum.ScrollingDirection.X
    tabs.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabs.CanvasSize = UDim2.new()
    tabs.Parent = main
    self._tabList = tabs

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,6)
    tabLayout.Parent = tabs

    local pages = Instance.new("Frame")
    pages.Position = UDim2.new(0,8,0,108)
    pages.Size = UDim2.new(1,-16,1,-116)
    pages.BackgroundTransparency = 1
    pages.Parent = main
    self._pages = pages

    local notifications = Instance.new("Frame")
    notifications.AnchorPoint = Vector2.new(1,0)
    notifications.Position = UDim2.new(1,-12,0,12)
    notifications.Size = UDim2.new(0,280,1,-24)
    notifications.BackgroundTransparency = 1
    notifications.Parent = gui
    self._notifications = notifications

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.Padding = UDim.new(0,7)
    notifLayout.Parent = notifications

    local dragging = false
    local dragStart
    local startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    minimize.Activated:Connect(function()
        playClick()
        if self._minimized then
            self._minimized = false
            tween(main, TweenInfo.new(0.22), {Size = UDim2.new(0,470,0,330)})
            tabs.Visible = true
            pages.Visible = true
        else
            self._minimized = true
            tabs.Visible = false
            pages.Visible = false
            tween(main, TweenInfo.new(0.22), {Size = UDim2.new(0,470,0,58)})
        end
    end)

    close.Activated:Connect(function()
        playClick()
        self:Destroy()
    end)

    self._connections[#self._connections+1] = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            -- kept as a connection owner for clean destruction
        end
    end)

    -- Opening animation.
    main.Size = UDim2.new(0,420,0,290)
    main.BackgroundTransparency = 1
    tween(main, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,470,0,330),
        BackgroundTransparency = 0
    })

    local window = setmetatable({
        _owner = self,
        _theme = self._theme,
        _tabList = tabs,
        _pages = pages,
    }, WindowMethods)

    if settings.KeySystem == true then
        self:Notify({
            Title = "NovaUI",
            Content = "KeySystem is not included in this standalone build. Window opened normally.",
            Duration = 4
        })
    end

    if settings.LoadingTitle or settings.LoadingSubtitle then
        -- Loading is represented by the opening animation; no external asset is required.
    end

    return window
end

return NovaUI
