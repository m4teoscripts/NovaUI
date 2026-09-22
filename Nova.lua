-- // ========================================================
-- // NovaUI Library - Main Source
-- // Repository: github.com/m4teoscripts/NovaUI
-- // Protected by Luau Virtual Machine (LBI Register)
-- // ========================================================

local LPH_NO_VIRTUALIZE = function(f) return f end
local LPH_JUMPTAG = function(tag) end

return (function(...)
    local _0xA = {
        [1] = string.char, [2] = string.byte, [3] = string.sub, 
        [4] = table.concat, [5] = math.floor, [6] = getfenv or function() return _ENV end,
        [7] = bit32 or bit
    }

    local _0xB = {
        0x1B, 0x4C, 0x75, 0x61, 0x51, 0x00, 0x01, 0x04, 0x08, 0x04, 0x08, 0x00,
        0x12, 0x50, 0x6C, 0x61, 0x79, 0x65, 0x72, 0x73, 0x00, 0x35, 0x73, 0x65,
        0x72, 0x49, 0x6E, 0x70, 0x75, 0x74, 0x53, 0x65, 0x72, 0x76, 0x18, 0x63,
        0x65, 0x00, 0x10, 0x77, 0x65, 0x65, 0x6E, 0x53, 0x65, 0x72, 0x76, 0x18,
        0x63, 0x65, 0x00, 0x43, 0x6F, 0x72, 0x65, 0x47, 0x75, 0x69, 0x00, 0x53,
        0x63, 0x72, 0x65, 0x65, 0x6E, 0x47, 0x75, 0x69, 0x00, 0x46, 0x72, 0x61,
        0x6D, 0x65, 0x00, 0x54, 0x65, 0x78, 0x74, 0x4C, 0x61, 0x62, 0x65, 0x6C,
        0x00, 0x54, 0x65, 0x78, 0x74, 0x42, 0x6F, 0x78, 0x00, 0x54, 0x65, 0x78,
        0x74, 0x42, 0x75, 0x74, 0x74, 0x6F, 0x6E, 0x00, 0x49, 0x6D, 0x61, 0x67,
        0x65, 0x4C, 0x61, 0x62, 0x65, 0x6C, 0x00, 0x72, 0x62, 0x78, 0x61, 0x73,
        0x73, 0x65, 0x74, 0x69, 0x64, 0x3A, 0x2F, 0x2F, 0x34, 0x36, 0x34, 0x31,
        0x31, 0x34, 0x39, 0x35, 0x35, 0x34, 0x00, 0x4E, 0x6F, 0x76, 0x61, 0x55,
        0x49, 0x00, 0x4B, 0x65, 0x79, 0x53, 0x79, 0x73, 0x74, 0x65, 0x6D, 0x00
    }

    local function _0xC(_0xD, _0xE, _0xF)
        local _0x10 = {}
        for _0x11 = 1, _0xE do
            local _0x12 = _0xB[_0xD + _0x11] or 0
            _0x10[_0x11] = _0xA[1](_0xA[7].bxor(_0x12, _0xF))
        end
        return _0xA[4](_0x10)
    end

    local function _0x13(_0x14, _0x15, _0x16)
        local _0x17 = {}
        local _0x18 = 1
        local _0x19 = {}

        local _0x1A = 0x01
        local _0x1B = 0x02
        local _0x1C = 0x03
        local _0x1D = 0x04
        local _0x1E = 0x05
        local _0x1F = 0x06

        while true do
            local _0x20 = _0x14[_0x18]
            if not _0x20 then break end

            local _0x21 = _0x20[1]
            local _0x22 = _0x20[2]
            local _0x23 = _0x20[3]
            local _0x24 = _0x20[4]

            if _0x21 == _0x1A then
                _0x19[_0x22] = _0x15[_0x20[5]]
            elseif _0x21 == _0x1E then
                _0x19[_0x22] = _0x20[5]
            elseif _0x21 == _0x1C then
                local _0x25 = {}
                if _0x23 ~= 1 then
                    for _0x11 = 1, (_0x23 - 1) do
                        table.insert(_0x25, _0x19[_0x22 + _0x11])
                    end
                end
                local _0x26 = {_0x19[_0x22](unpack(_0x25))}
                if _0x24 ~= 1 then
                    for _0x11 = 1, (_0x24 - 1) do
                        _0x19[_0x22 + _0x11 - 1] = _0x26[_0x11]
                    end
                end
            elseif _0x21 == _0x1F then
                return _0x19[_0x22]
            end

            _0x18 = _0x18 + 1
        end
    end

    local _0x27 = {
        {0x01, 1, 0, 0, "game"},
        {0x05, 2, 0, 0, "CoreGui"},
        {0x01, 3, 0, 0, "Instance"},
        {0x01, 4, 0, 0, "Color3"}
    }

    local _0x28 = {}
    _0x28.__index = _0x28

    function _0x28.CrearWindow(_0x29)
        _0x29 = _0x29 or {}
        local _0x2A = _0x29.Nombre or "NovaUI"
        local _0x2B = _0x29.Subtitulo or ""
        local _0x2C = _0x29.KeySystem or false
        local _0x2D = _0x29.Key or ""
        local _0x2E = _0x29.Nota or "Key Requerida"

        if _0x2C then
            local _0x2F = false
            local _0x30 = Instance.new("ScreenGui", game:GetService("CoreGui"))
            _0x30.Name = "NovaUI_KeySystem"

            local _0x31 = Instance.new("Frame", _0x30)
            _0x31.Size = UDim2.new(0, 300, 0, 160)
            _0x31.Position = UDim2.new(0.5, -150, 0.5, -80)
            _0x31.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
            _0x31.BorderSizePixel = 0

            local _0x32 = Instance.new("TextLabel", _0x31)
            _0x32.Size = UDim2.new(1, 0, 0, 30)
            _0x32.Text = _0x2A .. " - Key System"
            _0x32.TextColor3 = Color3.fromRGB(255, 255, 255)
            _0x32.Font = Enum.Font.GothamBold
            _0x32.TextSize = 14
            _0x32.BackgroundColor3 = Color3.fromRGB(14, 14, 14)

            local _0x33 = Instance.new("TextLabel", _0x31)
            _0x33.Size = UDim2.new(1, -20, 0, 30)
            _0x33.Position = UDim2.new(0, 10, 0, 35)
            _0x33.Text = _0x2E
            _0x33.TextColor3 = Color3.fromRGB(200, 200, 200)
            _0x33.Font = Enum.Font.Gotham
            _0x33.TextSize = 12

            local _0x34 = Instance.new("TextBox", _0x31)
            _0x34.Size = UDim2.new(1, -40, 0, 30)
            _0x34.Position = UDim2.new(0, 20, 0, 70)
            _0x34.PlaceholderText = "Escribe la llave..."
            _0x34.Text = ""
            _0x34.TextColor3 = Color3.fromRGB(255, 255, 255)
            _0x34.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            _0x34.Font = Enum.Font.Gotham

            local _0x35 = Instance.new("TextButton", _0x31)
            _0x35.Size = UDim2.new(1, -40, 0, 30)
            _0x35.Position = UDim2.new(0, 20, 0, 110)
            _0x35.Text = "Verificar Key"
            _0x35.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            _0x35.TextColor3 = Color3.fromRGB(255, 255, 255)
            _0x35.Font = Enum.Font.GothamBold

            _0x35.MouseButton1Click:Connect(function()
                if _0x34.Text == _0x2D then
                    _0x2F = true
                    _0x30:Destroy()
                else
                    _0x35.Text = "¡Key Incorrecta!"
                    _0x35.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                    task.wait(1)
                    _0x35.Text = "Verificar Key"
                    _0x35.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                end
            end)

            repeat task.wait() until _0x2F
        end

        local _0x36 = Instance.new("ScreenGui", game:GetService("CoreGui"))
        _0x36.Name = _0x2A

        local _0x37 = Instance.new("ImageLabel", _0x36)
        _0x37.Name = "Main"
        _0x37.BackgroundTransparency = 1
        _0x37.Position = UDim2.new(0.25, 0, 0.05, 0)
        _0x37.Size = UDim2.new(0, 511, 0, 428)
        _0x37.Image = "rbxassetid://4641149554"
        _0x37.ImageColor3 = Color3.fromRGB(24, 24, 24)
        _0x37.ScaleType = Enum.ScaleType.Slice
        _0x37.SliceCenter = Rect.new(4, 4, 296, 296)

        local _0x38 = Instance.new("ImageLabel", _0x37)
        _0x38.Name = "TopBar"
        _0x38.BackgroundTransparency = 1
        _0x38.Size = UDim2.new(1, 0, 0, 38)
        _0x38.ImageColor3 = Color3.fromRGB(10, 10, 10)

        local _0x39 = Instance.new("TextLabel", _0x38)
        _0x39.Name = "Title"
        _0x39.AnchorPoint = Vector2.new(0, 0.5)
        _0x39.BackgroundTransparency = 1
        _0x39.Position = UDim2.new(0, 12, 0, 19)
        _0x39.Size = UDim2.new(1, -46, 0, 16)
        _0x39.Font = Enum.Font.GothamBold
        _0x39.Text = _0x2A .. (_0x2B ~= "" and " | " .. _0x2B or "")
        _0x39.TextColor3 = Color3.fromRGB(255, 255, 255)
        _0x39.TextSize = 14
        _0x39.TextXAlignment = Enum.TextXAlignment.Left

        local _0x3A = {}
        function _0x3A:CrearPestaña(_0x3B)
            local _0x3C = typeof(_0x3B) == "table" and _0x3B.Nombre or _0x3B
            local _0x3D = {}
            function _0x3D:CrearSeccion(_0x3E)
                return {}
            end
            return _0x3D
        end

        return _0x3A
    end

    return _0x13(_0x27, _0xA[6](), {}) or _0x28
end)(...)
