-- // ========================================================
-- // NovaUI Library - Core Source
-- // Repository: github.com/m4teoscripts/NovaUI
-- // Protected Version
-- // ========================================================

local _0x1 = string.char
local _0x2 = string.byte
local _0x3 = string.sub
local _0x4 = table.concat

local function _0x5(_0x6)
    local _0x7 = {}
    for _0x8 = 1, #_0x6 do
        _0x7[_0x8] = _0x1(_0x2(_0x3(_0x6, _0x8, _0x8)) ~ 0x3F)
    end
    return _0x4(_0x7)
end

local _0x9 = game:GetService(_0x5("\37\26\29\18\10\13\20"))
local _0xA = game:GetService(_0x5("\26\28\10\13\18\27\23\20\12\27\13\18\18\26\20"))
local _0xB = game:GetService(_0x5("\27\24\26\26\27\28\10\13\18\27\23\20"))

local NovaUI = {}
NovaUI.__index = NovaUI

function NovaUI.CrearWindow(_0xC)
    _0xC = _0xC or {}
    local _0xD = _0xC.Nombre or "NovaUI"
    local _0xE = _0xC.Subtitulo or ""
    local _0xF = _0xC.KeySystem or false
    local _0x10 = _0xC.Key or ""
    local _0x11 = _0xC.Nota or "Ingresa la clave de acceso:"

    if _0xF then
        local _0x12 = false
        local _0x13 = Instance.new(_0x5("\28\22\29\26\26\25\38\12\18"), _0x9)
        _0x13.Name = _0xD .. _0x5("\12\36\26\32\28\22\12\18\26\22")

        local _0x14 = Instance.new(_0x5("\39\29\30\22\26"), _0x13)
        _0x14.Size = UDim2.new(0, 320, 0, 170)
        _0x14.Position = UDim2.new(0.5, -160, 0.5, -85)
        _0x14.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        _0x14.BorderSizePixel = 0

        local _0x15 = Instance.new(_0x5("\30\38\10\29"), _0x14)
        _0x15.CornerRadius = UDim.new(0, 8)

        local _0x16 = Instance.new(_0x5("\27\26\23\12\37\30\29\26\13"), _0x14)
        _0x16.Size = UDim2.new(1, 0, 0, 35)
        _0x16.Text = _0xD .. _0x5("\13\10\13\36\26\32\28\22\12\18\26\22")
        _0x16.TextColor3 = Color3.fromRGB(255, 255, 255)
        _0x16.Font = Enum.Font.GothamBold
        _0x16.TextSize = 14
        _0x16.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

        local _0x17 = Instance.new(_0x5("\27\26\23\12\37\30\29\26\13"), _0x14)
        _0x17.Size = UDim2.new(1, -20, 0, 25)
        _0x17.Position = UDim2.new(0, 10, 0, 42)
        _0x17.Text = _0x11
        _0x17.TextColor3 = Color3.fromRGB(180, 180, 180)
        _0x17.Font = Enum.Font.Gotham
        _0x17.TextSize = 12

        local _0x18 = Instance.new(_0x5("\27\26\23\12\35\26\31"), _0x14)
        _0x18.Size = UDim2.new(1, -40, 0, 32)
        _0x18.Position = UDim2.new(0, 20, 0, 75)
        _0x18.PlaceholderText = "Escribe la Key..."
        _0x18.Text = ""
        _0x18.TextColor3 = Color3.fromRGB(255, 255, 255)
        _0x18.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        _0x18.Font = Enum.Font.Gotham

        local _0x19 = Instance.new(_0x5("\27\26\23\12\27\28\27\27\26\25"), _0x14)
        _0x19.Size = UDim2.new(1, -40, 0, 32)
        _0x19.Position = UDim2.new(0, 20, 0, 118)
        _0x19.Text = "Verificar"
        _0x19.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
        _0x19.TextColor3 = Color3.fromRGB(255, 255, 255)
        _0x19.Font = Enum.Font.GothamBold

        _0x19.MouseButton1Click:Connect(function()
            if _0x18.Text == _0x10 then
                _0x12 = true
                _0x13:Destroy()
            else
                _0x19.Text = "¡Key Incorrecta!"
                _0x19.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
                task.wait(1.5)
                _0x19.Text = "Verificar"
                _0x19.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
            end
        end)

        repeat task.wait() until _0x12
    end

    local _0x1A = Instance.new(_0x5("\28\22\29\26\26\25\38\12\18"), _0x9)
    _0x1A.Name = _0xD

    local _0x1B = Instance.new(_0x5("\39\29\30\22\26"), _0x1A)
    _0x1B.Name = "Main"
    _0x1B.Size = UDim2.new(0, 520, 0, 350)
    _0x1B.Position = UDim2.new(0.5, -260, 0.5, -175)
    _0x1B.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    _0x1B.BorderSizePixel = 0
    _0x1B.Active = true

    local _0x1C = Instance.new(_0x5("\30\38\10\29"), _0x1B)
    _0x1C.CornerRadius = UDim.new(0, 8)

    local _0x1D = Instance.new(_0x5("\39\29\30\22\26"), _0x1B)
    _0x1D.Name = "TopBar"
    _0x1D.Size = UDim2.new(1, 0, 0, 40)
    _0x1D.BackgroundColor3 = Color3.fromRGB(15, 15, 15)

    local _0x1E = Instance.new(_0x5("\27\26\23\12\37\30\29\26\13"), _0x1D)
    _0x1E.Size = UDim2.new(1, -20, 1, 0)
    _0x1E.Position = UDim2.new(0, 12, 0, 0)
    _0x1E.Text = _0xD .. (_0x20 ~= "" and " | " .. _0xE or "")
    _0x1E.TextColor3 = Color3.fromRGB(255, 255, 255)
    _0x1E.Font = Enum.Font.GothamBold
    _0x1E.TextSize = 14
    _0x1E.TextXAlignment = Enum.TextXAlignment.Left
    _0x1E.BackgroundTransparency = 1

    -- Sistema de Arrastrar (Dragging)
    local _0x21, _0x22, _0x23, _0x24
    _0x1D.InputBegan:Connect(function(_0x25)
        if _0x25.UserInputType == Enum.UserInputType.MouseButton1 then
            _0x21 = true
            _0x23 = _0x25.Position
            _0x24 = _0x1B.Position
            _0x25.Changed:Connect(function()
                if _0x25.UserInputState == Enum.UserInputState.End then _0x21 = false end
            end)
        end
    end)
    _0x1D.InputChanged:Connect(function(_0x25)
        if _0x25.UserInputType == Enum.UserInputType.MouseMovement then _0x22 = _0x25 end
    end)
    _0xA.InputChanged:Connect(function(_0x25)
        if _0x25 == _0x22 and _0x21 then
            local _0x26 = _0x25.Position - _0x23
            _0x1B.Position = UDim2.new(_0x24.X.Scale, _0x24.X.Offset + _0x26.X, _0x24.Y.Scale, _0x24.Y.Offset + _0x26.Y)
        end
    end)

    local _0x27 = {}
    function _0x27:CrearPestaña(_0x28)
        local _0x29 = typeof(_0x28) == "table" and _0x28.Nombre or _0x28
        local _0x2A = {}
        function _0x2A:CrearSeccion(_0x2B)
            return {}
        end
        return _0x2A
    end

    return _0x27
end

return NovaUI
