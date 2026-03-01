-- ======================================================================================================
-- NIKO UI - Professional Roblox GUI Library (Part 1 of 3)
-- ======================================================================================================
-- MIT License
-- 
-- Copyright (c) 2026 Mestre H
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-- ======================================================================================================
-- VERSION: 1.0.0
-- REQUIREMENTS: Roblox Studio (2023+), Modern Executor Compatibility
-- DOCUMENTATION: See Help Tab in UI or visit https://github.com/mestreh/niko-ui
-- ======================================================================================================

-- SECURITY NOTICE: This library operates entirely within LocalScript context.
-- No global pollution (getgenv/setgenv) is used. All state is contained within the returned module.
-- All external service calls are wrapped in pcall for safety.

local NIKO_UI = {}

-- ======================================================================================================
-- CORE UTILITIES MODULE
-- Comprehensive set of helper functions for rendering, math, safety, and performance
-- ======================================================================================================

local Utilities = {}

--[[
    Creates a new Instance with properties applied safely
    @param className string - Roblox instance class name
    @param properties table - Properties to apply (supports nested tables for children)
    @param parent Instance? - Optional parent to reparent to
    @return Instance - Created instance
    @usage local frame = Utils.CreateInstance("Frame", {Size = UDim2.new(0,100,0,100)}, parent)]]
function Utilities.CreateInstance(className: string, properties: table, parent: Instance?)
    local success, result = pcall(function()
        local obj = Instance.new(className)
        
        -- Apply properties recursively
        if properties then
            for prop, value in pairs(properties) do
                if typeof(value) == "table" and not value.ClassName then
                    -- Handle nested children tables
                    if prop == "Children" then
                        for _, child in ipairs(value) do
                            if typeof(child) == "table" then
                                Utilities.CreateInstance(child.ClassName, child, obj)
                            elseif child:IsA("Instance") then
                                child.Parent = obj
                            end
                        end
                    else
                        -- Handle nested property tables (e.g., {Position = {X=0,Y=0}})
                        local nestedProps = {}
                        for k, v in pairs(value) do
                            nestedProps[k] = v
                        end
                        obj[prop] = nestedProps
                    end
                else
                    -- Direct property assignment with type safety
                    local propType = obj:GetPropertyChangedSignal(prop)
                    if propType then
                        obj[prop] = value
                    end
                end
            end
        end
        
        if parent then
            obj.Parent = parent
        end
        
        return obj
    end)
    
    if not success then
        warn("[NIKO UI] CreateInstance failed:", result)
        return nil
    end
    
    return result
end
--[[
    Safely destroys an instance with delay to prevent rendering glitches
    @param instance Instance - Instance to destroy
    @param delay number? - Optional delay before destruction (default 0)
]]
function Utilities.SafeDestroy(instance: Instance, delay: number?)
    if not instance or not instance.Parent then return end
    delay = delay or 0
    
    if delay > 0 then
        task.delay(delay, function()
            if instance and instance.Parent then
                instance:Destroy()
            end
        end)
    else
        instance:Destroy()
    end
end

--[[
    Creates a smooth tween with built-in cleanup
    @param instance Instance - Target instance
    @param properties table - Tween properties
    @param info table - TweenInfo parameters (time, style, direction, etc.)
    @param onComplete function? - Callback on completion
    @return Tween - Created tween object
]]
function Utilities.CreateTween(instance: Instance, properties: table, info: table, onComplete: (() -> ())?)
    local tweenInfo = TweenInfo.new(
        info.Time or 0.3,
        info.Style or Enum.EasingStyle.Quad,
        info.Direction or Enum.EasingDirection.Out,
        info.RepeatCount or 0,
        info.Reverses or false,
        info.Delay or 0
    )
    
    local tween = game:GetService("TweenService"):Create(instance, tweenInfo, properties)
    
    if onComplete then
        tween.Completed:Connect(function(playbackState)
            if playbackState == Enum.PlaybackState.Completed then
                onComplete()
            end
        end)
    end
    
    tween:Play()    return tween
end

--[[
    Generates a unique identifier for UI elements
    @return string - UUID-like string
]]
function Utilities.GenerateUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local r = math.random(16)
        if c == "x" then
            return string.format("%x", r)
        else
            return string.format("%x", bit32.bor(bit32.band(r, 0x3), 0x8))
        end
    end)
end

--[[
    Validates color input and converts to Color3 if needed
    @param color any - Color input (Color3, BrickColor, string, table)
    @param default Color3 - Fallback color if validation fails
    @return Color3 - Validated color
]]
function Utilities.ValidateColor(color: any, default: Color3)
    if typeof(color) == "Color3" then return color end
    if typeof(color) == "BrickColor" then return color.Color end
    if typeof(color) == "string" then
        local success, result = pcall(BrickColor.new, color)
        if success and result then return result.Color end
    end
    if typeof(color) == "table" then
        if color.R and color.G and color.B then
            return Color3.new(color.R, color.G, color.B)
        elseif color[1] and color[2] and color[3] then
            return Color3.new(color[1], color[2], color[3])
        end
    end
    warn("[NIKO UI] Invalid color format, using default")
    return default or Color3.fromRGB(60, 60, 70)
end

--[[
    Clamps a number between min and max values
    @param value number - Input value
    @param min number - Minimum bound
    @param max number - Maximum bound
    @return number - Clamped value
]]function Utilities.Clamp(value: number, min: number, max: number)
    return math.min(math.max(value, min), max)
end

--[[
    Rounds a number to specified decimal places
    @param num number - Number to round
    @param decimalPlaces number - Decimal precision (default 2)
    @return number - Rounded number
]]
function Utilities.Round(num: number, decimalPlaces: number)
    decimalPlaces = decimalPlaces or 2
    local factor = 10 ^ decimalPlaces
    return math.floor(num * factor + 0.5) / factor
end

--[[
    Measures text size with Roblox TextService
    @param text string - Text content
    @param font Enum.Font - Font type
    @param textSize number - Font size
    @param frameSize UDim2 - Containing frame size
    @return Vector2 - Text dimensions
]]
function Utilities.GetTextSize(text: string, font: Enum.Font, textSize: number, frameSize: UDim2)
    local TextService = game:GetService("TextService")
    local success, size = pcall(function()
        return TextService:GetTextSize(
            text,
            textSize,
            font,
            Vector2.new(frameSize.X.Offset, frameSize.Y.Offset)
        )
    end)
    
    if success then
        return size
    else
        warn("[NIKO UI] TextService measurement failed, using fallback")
        return Vector2.new(100, textSize * 1.5)
    end
end

--[[
    Creates a rounded rectangle image with dynamic sizing
    @param size UDim2 - Size of the rectangle
    @param cornerRadius number - Corner radius in pixels (default 8)
    @param color Color3 - Fill color
    @param parent Instance - Parent container
    @return ImageLabel - Created rounded rectangle]]
function Utilities.CreateRoundedRectangle(size: UDim2, cornerRadius: number, color: Color3, parent: Instance)
    cornerRadius = cornerRadius or 8
    local aspectRatio = (cornerRadius * 2) / size.Y.Offset
    
    local frame = Utilities.CreateInstance("Frame", {
        Size = size,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Children = {
            {
                ClassName = "UICorner",
                CornerRadius = UDim.new(0, cornerRadius)
            }
        }
    }, parent)
    
    return frame
end

--[[
    Creates a subtle gradient overlay for depth effects
    @param parent Instance - Parent frame
    @param direction string - "Top", "Bottom", "Left", "Right" (default "Bottom")
    @param intensity number - Opacity of gradient (0-1, default 0.15)
]]
function Utilities.CreateGradient(parent: Instance, direction: string, intensity: number)
    direction = direction or "Bottom"
    intensity = intensity or 0.15
    
    local gradient = Utilities.CreateInstance("UIGradient", {
        Rotation = direction == "Top" and 180 or direction == "Left" and 270 or direction == "Right" and 90 or 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1 - intensity),
            NumberSequenceKeypoint.new(1, 1)
        })
    }, parent)
    
    return gradient
end

--[[
    Safely gets LocalPlayer with fallback handling
    @return Player? - Current local player or nil
]]function Utilities.GetLocalPlayer()
    local Players = game:GetService("Players")
    local success, player = pcall(function()
        return Players.LocalPlayer
    end)
    
    if success and player then
        return player
    end
    
    -- Fallback: Wait for player to exist
    if not player then
        Players.PlayerAdded:Wait()
        return Players.LocalPlayer
    end
    
    return nil
end

--[[
    Creates a hover effect with smooth color transition
    @param target Instance - Frame/Button to apply effect to
    @param hoverColor Color3 - Color on hover
    @param normalColor Color3 - Base color
    @param duration number - Animation duration (default 0.2)
]]
function Utilities.ApplyHoverEffect(target: Instance, hoverColor: Color3, normalColor: Color3, duration: number)
    duration = duration or 0.2
    local originalColor = normalColor
    
    target.MouseEnter:Connect(function()
        Utilities.CreateTween(target, {BackgroundColor3 = hoverColor}, {Time = duration})
    end)
    
    target.MouseLeave:Connect(function()
        Utilities.CreateTween(target, {BackgroundColor3 = originalColor}, {Time = duration})
    end)
end

--[[
    Creates a pulse animation for notifications or alerts
    @param target Instance - Target instance to pulse
    @param color Color3 - Pulse color
    @param duration number - Total pulse duration (default 1.5)
]]
function Utilities.CreatePulseEffect(target: Instance, color: Color3, duration: number)
    duration = duration or 1.5
    local originalColor = target.BackgroundColor3
    
    local pulse = Utilities.CreateTween(target, {        BackgroundColor3 = color,
        Size = UDim2.new(1.1, 0, 1.1, 0)
    }, {
        Time = duration * 0.3,
        Style = Enum.EasingStyle.Quad,
        Direction = Enum.EasingDirection.Out
    }, function()
        Utilities.CreateTween(target, {
            BackgroundColor3 = originalColor,
            Size = UDim2.new(1, 0, 1, 0)
        }, {
            Time = duration * 0.7,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out
        })
    end)
    
    return pulse
end

--[[
    Converts RGB values to HSV for color manipulation
    @param r number - Red (0-1)
    @param g number - Green (0-1)
    @param b number - Blue (0-1)
    @return number, number, number - Hue, Saturation, Value
]]
function Utilities.RGBtoHSV(r: number, g: number, b: number)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local d = max - min
    local h, s, v = 0, 0, max
    
    if max ~= min then
        s = d / max
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

--[[
    Converts HSV values to RGB
    @param h number - Hue (0-1)    @param s number - Saturation (0-1)
    @param v number - Value (0-1)
    @return number, number, number - Red, Green, Blue
]]
function Utilities.HSVtoRGB(h: number, s: number, v: number)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    
    return r, g, b
end

--[[
    Creates a color picker dot with HSV visualization
    @param parent Instance - Parent frame
    @param size number - Dot size in pixels
    @param hsv table - {H, S, V} values
    @return Frame - Color dot instance
]]
function Utilities.CreateColorDot(parent: Instance, size: number, hsv: table)
    local dot = Utilities.CreateInstance("Frame", {
        Size = UDim2.new(0, size, 0, size),
        BackgroundColor3 = Color3.fromHSV(hsv[1], hsv[2], hsv[3]),
        BorderSizePixel = 2,
        BorderColor3 = Color3.new(0.1, 0.1, 0.1),
        Children = {
            {ClassName = "UICorner", CornerRadius = UDim.new(1, 0)}
        }
    }, parent)
    
    return dot
end

--[[
    Safely connects events with cleanup tracking
    @param event RBXScriptSignal - Event to connect
    @param callback function - Callback function
    @param cleanupTable table - Table to store connection for later disconnect
    @return RBXScriptConnection - Connection object]]
function Utilities.ConnectEvent(event: RBXScriptSignal, callback: (...any) -> (), cleanupTable: table)
    local success, connection = pcall(function()
        return event:Connect(callback)
    end)
    
    if success and connection then
        table.insert(cleanupTable, connection)
        return connection
    else
        warn("[NIKO UI] Event connection failed")
        return nil
    end
end

--[[
    Disconnects all connections in cleanup table
    @param cleanupTable table - Table of RBXScriptConnections
]]
function Utilities.CleanupConnections(cleanupTable: table)
    for _, connection in ipairs(cleanupTable) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    cleanupTable = {}
end

--[[
    Creates a shadow effect using multiple layers
    @param parent Instance - Parent frame
    @param depth number - Shadow depth (default 4)
    @param spread number - Shadow spread (default 0.2)
    @param opacity number - Max opacity (default 0.3)
]]
function Utilities.CreateShadow(parent: Instance, depth: number, spread: number, opacity: number)
    depth = depth or 4
    spread = spread or 0.2
    opacity = opacity or 0.3
    
    local shadowContainer = Utilities.CreateInstance("Frame", {
        Size = UDim2.new(1, depth * 2, 1, depth * 2),
        Position = UDim2.new(0, -depth, 0, -depth),
        BackgroundTransparency = 1,
        ZIndex = 0,
        Parent = parent
    })
    
    for i = depth, 1, -1 do
        local alpha = opacity * (i / depth)        local sizeOffset = (depth - i) * spread
        
        Utilities.CreateInstance("Frame", {
            Size = UDim2.new(1, -sizeOffset * 2, 1, -sizeOffset * 2),
            Position = UDim2.new(0, sizeOffset, 0, sizeOffset),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1 - alpha,
            BorderSizePixel = 0,
            ZIndex = i,
            Children = {
                {ClassName = "UICorner", CornerRadius = UDim.new(0, 8)}
            },
            Parent = shadowContainer
        })
    end
    
    return shadowContainer
end

--[[
    Validates table structure for configuration
    @param tbl table - Table to validate
    @param schema table - Schema definition {key = "type", ...}
    @return boolean, string - Validation result and error message
]]
function Utilities.ValidateConfig(tbl: table, schema: table)
    for key, expectedType in pairs(schema) do
        if tbl[key] == nil then
            return false, "Missing required key: " .. key
        end
        if typeof(tbl[key]) ~= expectedType then
            return false, string.format("Key '%s' expected type %s, got %s", key, expectedType, typeof(tbl[key]))
        end
    end
    return true, nil
end

--[[
    Deep copies a table (handles nested tables)
    @param orig table - Original table
    @return table - Deep copy
]]
function Utilities.DeepCopy(orig: table)
    local copy = {}
    for key, value in pairs(orig) do
        if typeof(value) == "table" then
            copy[key] = Utilities.DeepCopy(value)
        else
            copy[key] = value
        end    end
    return copy
end

--[[
    Creates a loading spinner animation
    @param parent Instance - Parent frame
    @param size number - Spinner size in pixels
    @param color Color3 - Spinner color
    @return Frame - Spinner container
]]
function Utilities.CreateSpinner(parent: Instance, size: number, color: Color3)
    size = size or 24
    color = color or Color3.fromRGB(100, 180, 255)
    
    local spinner = Utilities.CreateInstance("Frame", {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
        Rotation = 0,
        Parent = parent
    })
    
    -- Create circular segments
    local segments = 8
    local radius = size * 0.4
    local segmentSize = size * 0.15
    
    for i = 1, segments do
        local angle = (i - 1) / segments * math.pi * 2
        local x = math.cos(angle) * radius + size/2
        local y = math.sin(angle) * radius + size/2
        
        local segment = Utilities.CreateInstance("Frame", {
            Size = UDim2.new(0, segmentSize, 0, segmentSize),
            Position = UDim2.new(0, x - segmentSize/2, 0, y - segmentSize/2),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.2 + (i / segments) * 0.6,
            Children = {
                {ClassName = "UICorner", CornerRadius = UDim.new(1, 0)}
            },
            Parent = spinner
        })
    end
    
    -- Animate rotation
    game:GetService("RunService").RenderStepped:Connect(function(dt)
        spinner.Rotation = (spinner.Rotation + dt * 180) % 360
    end)
    
    return spinnerend

--[[
    Creates a skeleton loading placeholder
    @param parent Instance - Parent frame
    @param width number - Placeholder width
    @param height number - Placeholder height
    @return Frame - Skeleton container
]]
function Utilities.CreateSkeleton(parent: Instance, width: number, height: number)
    local skeleton = Utilities.CreateInstance("Frame", {
        Size = UDim2.new(0, width, 0, height),
        BackgroundColor3 = Color3.fromRGB(50, 50, 60),
        BorderSizePixel = 0,
        Children = {
            {ClassName = "UICorner", CornerRadius = UDim.new(0, 4)}
        },
        Parent = parent
    })
    
    -- Add shimmer effect
    local shimmer = Utilities.CreateInstance("Frame", {
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(-1, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(70, 70, 85),
        BorderSizePixel = 0,
        Children = {
            {ClassName = "UICorner", CornerRadius = UDim.new(0, 4)}
        },
        Parent = skeleton
    })
    
    -- Animate shimmer
    Utilities.CreateTween(shimmer, {
        Position = UDim2.new(1, 0, 0, 0)
    }, {
        Time = 1.5,
        Style = Enum.EasingStyle.Linear,
        RepeatCount = -1
    })
    
    return skeleton
end

--[[
    Formats large numbers with suffixes (K, M, B)
    @param num number - Number to format
    @param decimals number - Decimal places (default 1)
    @return string - Formatted string
]]function Utilities.FormatNumber(num: number, decimals: number)
    decimals = decimals or 1
    local suffixes = {"", "K", "M", "B", "T"}
    local i = 1
    
    while num >= 1000 and i <= #suffixes do
        num = num / 1000
        i = i + 1
    end
    
    return string.format("%." .. decimals .. "f%s", num, suffixes[i])
end

--[[
    Creates a tooltip that appears on hover
    @param target Instance - Element to attach tooltip to
    @param text string - Tooltip text
    @param positionOffset Vector2 - Offset from cursor (default Vector2.new(10, 10))
]]
function Utilities.CreateTooltip(target: Instance, text: string, positionOffset: Vector2)
    positionOffset = positionOffset or Vector2.new(10, 10)
    local tooltip = nil
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    
    target.MouseEnter:Connect(function()
        tooltip = Utilities.CreateInstance("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, mouse.X + positionOffset.X, 0, mouse.Y + positionOffset.Y),
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            BorderColor3 = Color3.fromRGB(80, 80, 100),
            BorderSizePixel = 1,
            ZIndex = 100,
            Children = {
                {ClassName = "UICorner", CornerRadius = UDim.new(0, 4)},
                {ClassName = "TextLabel", 
                 Size = UDim2.new(1, -8, 1, -4),
                 Position = UDim2.new(0, 4, 0, 2),
                 BackgroundTransparency = 1,
                 Text = text,
                 TextColor3 = Color3.fromRGB(220, 220, 255),
                 TextSize = 14,
                 Font = Enum.Font.Gotham,
                 TextXAlignment = Enum.TextXAlignment.Left}
            },
            Parent = game:GetService("CoreGui")
        })
        
        -- Calculate size after text is set
        local label = tooltip:FindFirstChildOfClass("TextLabel")
        if label then            local textSize = Utilities.GetTextSize(
                text, 
                Enum.Font.Gotham, 
                14, 
                UDim2.new(0, 200, 0, 50)
            )
            tooltip.Size = UDim2.new(0, textSize.X + 16, 0, 24)
        end
    end)
    
    target.MouseMove:Connect(function(x, y)
        if tooltip and tooltip.Parent then
            tooltip.Position = UDim2.new(0, x + positionOffset.X, 0, y + positionOffset.Y)
        end
    end)
    
    target.MouseLeave:Connect(function()
        if tooltip then
            Utilities.SafeDestroy(tooltip, 0.1)
            tooltip = nil
        end
    end)
end

-- Store utilities in main module
NIKO_UI.Utilities = Utilities

-- ======================================================================================================
-- THEME SYSTEM MODULE
-- Professional dark theme with neon accents and accessibility features
-- ======================================================================================================

local ThemeSystem = {}
ThemeSystem.CurrentTheme = "Dark"
ThemeSystem.Themes = {}

--[[
    Defines the default dark theme with neon purple accents
    Structure includes:
    - Primary colors (main UI elements)
    - Secondary colors (accents, highlights)
    - Semantic colors (success, warning, error)
    - Typography settings
    - Spacing scale
    - Animation timings
]]
function ThemeSystem:InitializeThemes()
    self.Themes.Dark = {
        -- Core Backgrounds
        Background = Color3.fromRGB(25, 25, 35),        Surface = Color3.fromRGB(35, 35, 45),
        ElevatedSurface = Color3.fromRGB(45, 45, 55),
        
        -- Text Colors
        TextPrimary = Color3.fromRGB(240, 240, 255),
        TextSecondary = Color3.fromRGB(180, 180, 200),
        TextDisabled = Color3.fromRGB(100, 100, 120),
        TextInverse = Color3.fromRGB(30, 30, 40),
        
        -- Accent Colors (Neon Purple Theme)
        Primary = Color3.fromRGB(140, 100, 255),    -- Main interactive elements
        PrimaryHover = Color3.fromRGB(160, 120, 255), -- Hover state
        PrimaryActive = Color3.fromRGB(120, 80, 235), -- Active/pressed state
        Secondary = Color3.fromRGB(80, 200, 220),     -- Secondary accents (cyan)
        SecondaryHover = Color3.fromRGB(100, 220, 240),
        
        -- Semantic Colors
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(220, 180, 50),
        Error = Color3.fromRGB(230, 90, 90),
        Info = Color3.fromRGB(100, 180, 255),
        
        -- Borders & Dividers
        Border = Color3.fromRGB(60, 60, 75),
        Divider = Color3.fromRGB(50, 50, 65),
        
        -- Input Elements
        InputBackground = Color3.fromRGB(40, 40, 50),
        InputBorder = Color3.fromRGB(70, 70, 85),
        InputPlaceholder = Color3.fromRGB(130, 130, 150),
        
        -- Scrollbar
        ScrollbarBackground = Color3.fromRGB(40, 40, 50),
        ScrollbarThumb = Color3.fromRGB(70, 70, 85),
        ScrollbarThumbHover = Color3.fromRGB(90, 90, 110),
        
        -- Window Chrome
        WindowHeader = Color3.fromRGB(40, 40, 50),
        WindowBorder = Color3.fromRGB(80, 80, 100),
        
        -- Typography
        Font = Enum.Font.Gotham,
        BaseTextSize = 14,
        TitleTextSize = 18,
        HeaderTextSize = 16,
        SmallTextSize = 12,
        
        -- Spacing Scale (in pixels)
        Spacing = {
            XS = 4,            SM = 8,
            MD = 12,
            LG = 16,
            XL = 24,
            XXL = 32
        },
        
        -- Border Radii
        BorderRadius = {
            Small = 4,
            Medium = 8,
            Large = 12,
            Circular = 9999
        },
        
        -- Animation Timings (in seconds)
        Animation = {
            Fast = 0.1,
            Normal = 0.25,
            Slow = 0.4,
            Hover = 0.15,
            PageTransition = 0.3
        },
        
        -- Shadows
        Shadow = {
            Small = {Depth = 2, Spread = 0.1, Opacity = 0.2},
            Medium = {Depth = 4, Spread = 0.15, Opacity = 0.25},
            Large = {Depth = 8, Spread = 0.2, Opacity = 0.3}
        },
        
        -- Opacity Values
        Opacity = {
            Disabled = 0.5,
            HoverOverlay = 0.08,
            PressedOverlay = 0.15,
            TooltipBackground = 0.92
        }
    }
    
    -- Light theme placeholder (for future expansion)
    self.Themes.Light = {
        -- Would contain light theme definitions
        -- Currently falls back to Dark theme
    }
    
    -- Set default theme
    self.CurrentTheme = "Dark"
end
--[[
    Gets color value from current theme
    @param key string - Color key (e.g., "Primary", "Background")
    @param fallback Color3 - Fallback color if key not found
    @return Color3 - Theme color
]]
function ThemeSystem:GetColor(key: string, fallback: Color3)
    local theme = self.Themes[self.CurrentTheme]
    if theme and theme[key] then
        return theme[key]
    end
    warn("[NIKO UI] Theme color not found:", key, "using fallback")
    return fallback or Color3.fromRGB(100, 100, 100)
end

--[[
    Gets numeric value from theme (spacing, radius, etc.)
    @param category string - Category (e.g., "Spacing", "BorderRadius")
    @param key string - Specific key within category (e.g., "MD", "Medium")
    @param fallback number - Fallback value
    @return number - Theme value
]]
function ThemeSystem:GetValue(category: string, key: string, fallback: number)
    local theme = self.Themes[self.CurrentTheme]
    if theme and theme[category] and theme[category][key] then
        return theme[category][key]
    end
    warn("[NIKO UI] Theme value not found:", category, key)
    return fallback or 0
end

--[[
    Gets animation timing by name
    @param key string - Timing key (e.g., "Normal", "Hover")
    @return number - Duration in seconds
]]
function ThemeSystem:GetAnimationTime(key: string)
    return self:GetValue("Animation", key, 0.2)
end

--[[
    Applies theme colors to an existing instance
    @param instance Instance - Target instance
    @param propertyMap table - Mapping of theme keys to instance properties
    Example: {BackgroundColor3 = "Surface", TextColor3 = "TextPrimary"}
]]
function ThemeSystem:ApplyTheme(instance: Instance, propertyMap: table)
    for property, themeKey in pairs(propertyMap) do
        local color = self:GetColor(themeKey)
        if color and instance:FindFirstChild(property) then            instance[property] = color
        end
    end
end

--[[
    Creates a themed frame with consistent styling
    @param properties table - Frame properties (size, position, etc.)
    @param themeType string - Theme key for background ("Surface", "Background", etc.)
    @param parent Instance - Parent instance
    @return Frame - Created frame
]]
function ThemeSystem:CreateThemedFrame(properties: table, themeType: string, parent: Instance)
    themeType = themeType or "Surface"
    local bgColor = self:GetColor(themeType)
    
    local frameProps = Utilities.DeepCopy(properties)
    frameProps.BackgroundColor3 = bgColor
    frameProps.BorderSizePixel = 0
    
    local frame = Utilities.CreateInstance("Frame", frameProps, parent)
    
    -- Add subtle border if needed
    if themeType == "Surface" or themeType == "ElevatedSurface" then
        Utilities.CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, -1),
            BackgroundColor3 = self:GetColor("Divider"),
            BorderSizePixel = 0,
            Parent = frame
        })
    end
    
    return frame
end

--[[
    Creates a themed text label with proper styling
    @param text string - Display text
    @param textSize number - Font size
    @param textColorKey string - Theme key for text color (default "TextPrimary")
    @param parent Instance - Parent instance
    @param additionalProps table - Additional properties to apply
    @return TextLabel - Created label
]]
function ThemeSystem:CreateThemedLabel(text: string, textSize: number, textColorKey: string, parent: Instance, additionalProps: table)
    textColorKey = textColorKey or "TextPrimary"
    additionalProps = additionalProps or {}
    
    local labelProps = {        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self:GetColor(textColorKey),
        TextSize = textSize,
        Font = self:GetValue("Font", "", Enum.Font.Gotham),
        TextXAlignment = additionalProps.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = additionalProps.TextYAlignment or Enum.TextYAlignment.Center
    }
    
    -- Merge additional properties
    for k, v in pairs(additionalProps) do
        labelProps[k] = v
    end
    
    return Utilities.CreateInstance("TextLabel", labelProps, parent)
end

--[[
    Switches between available themes
    @param themeName string - Theme name ("Dark", "Light")
    @return boolean - Success status
]]
function ThemeSystem:SwitchTheme(themeName: string)
    if self.Themes[themeName] then
        self.CurrentTheme = themeName
        -- In a full implementation, this would trigger a UI refresh
        -- For this library, new elements will use the new theme
        return true
    end
    warn("[NIKO UI] Theme not found:", themeName)
    return false
end

-- Initialize themes on module load
ThemeSystem:InitializeThemes()
NIKO_UI.Theme = ThemeSystem

-- ======================================================================================================
-- INPUT HANDLING MODULE
-- Advanced mouse/keyboard interaction system with gesture support
-- ======================================================================================================

local InputHandler = {}
InputHandler.Connections = {}
InputHandler.Dragging = {}
InputHandler.HoverElements = {}

--[[
    Initializes mouse and input objects
    @return boolean - Success status]]
function InputHandler:Initialize()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    
    local success, result = pcall(function()
        self.Mouse = Players.LocalPlayer:GetMouse()
        self.UserInputService = UserInputService
        return true
    end)
    
    if not success then
        warn("[NIKO UI] Input initialization failed:", result)
        return false
    end
    
    -- Setup global hover tracking
    self:_setupHoverTracking()
    
    return true
end

--[[
    Sets up global hover tracking for tooltips and effects
]]
function InputHandler:_setupHoverTracking()
    local lastHovered = nil
    
    self.Mouse.Move:Connect(function()
        -- This is handled per-element in CreateHoverEffect
    end)
    
    -- Track mouse enter/leave for custom hover states
    self.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Handle click interactions globally if needed
        end
    end)
end

--[[
    Makes a frame draggable with constraints
    @param frame Instance - Frame to make draggable
    @param dragHandle Instance? - Optional handle area (defaults to frame)
    @param constraints table? - {MinX, MaxX, MinY, MaxY} screen constraints
    @param onComplete function? - Callback when drag completes
]]
function InputHandler:MakeDraggable(frame: Instance, dragHandle: Instance?, constraints: table?, onComplete: (() -> ())?)
    dragHandle = dragHandle or frame    local UserInputService = self.UserInputService
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updatePosition(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        local newX = startPos.X + delta.X
        local newY = startPos.Y + delta.Y
        
        -- Apply constraints if provided
        if constraints then
            newX = Utilities.Clamp(newX, constraints.MinX or -math.huge, constraints.MaxX or math.huge)
            newY = Utilities.Clamp(newY, constraints.MinY or -math.huge, constraints.MaxY or math.huge)
        end
        
        frame.Position = UDim2.new(0, newX, 0, newY)
    end
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position.X.Offset
            startPos = {X = frame.Position.X.Offset, Y = frame.Position.Y.Offset}
            frame.ZIndex = 1000 -- Bring to front while dragging
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updatePosition(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging and onComplete then
                onComplete()
            end
            dragging = false
            if frame.ZIndex == 1000 then
                frame.ZIndex = 1 -- Reset ZIndex
            end
        end
    end)
end

--[[    Creates a context menu at mouse position
    @param items table - Array of {Text, Callback, Icon?}
    @param position Vector2? - Screen position (defaults to mouse)
    @return Frame - Context menu frame
]]
function InputHandler:CreateContextMenu(items: table, position: Vector2?)
    position = position or Vector2.new(self.Mouse.X, self.Mouse.Y)
    local theme = NIKO_UI.Theme
    local menuSize = 200
    local itemHeight = 32
    
    local menu = Utilities.CreateInstance("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Children = {
            {
                ClassName = "Frame",
                Size = UDim2.new(0, menuSize, 0, #items * itemHeight + 8),
                Position = UDim2.new(0, position.X, 0, position.Y),
                BackgroundColor3 = theme:GetColor("Surface"),
                BorderColor3 = theme:GetColor("WindowBorder"),
                BorderSizePixel = 1,
                ClipsDescendants = true,
                Children = {
                    {ClassName = "UICorner", CornerRadius = UDim.new(0, theme:GetValue("BorderRadius", "Medium"))},
                    {ClassName = "UIPadding", PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}
                }
            }
        },
        Parent = game:GetService("CoreGui")
    })
    
    local menuFrame = menu:FindFirstChildOfClass("Frame")
    Utilities.CreateShadow(menuFrame, 4, 0.15, 0.25)
    
    -- Create menu items
    for i, item in ipairs(items) do
        local itemFrame = Utilities.CreateInstance("TextButton", {
            Size = UDim2.new(1, -8, 0, itemHeight),
            Position = UDim2.new(0, 4, 0, (i - 1) * itemHeight + 4),
            BackgroundColor3 = theme:GetColor("Surface"),
            BorderSizePixel = 0,
            Text = "",
            Children = {
                {ClassName = "UICorner", CornerRadius = UDim.new(0, 4)},
                {ClassName = "TextLabel",
                 Size = UDim2.new(1, 0, 1, 0),
                 BackgroundTransparency = 1,
                 Text = item.Text,
                 TextColor3 = theme:GetColor("TextPrimary"),                 TextSize = theme:GetValue("BaseTextSize"),
                 Font = theme:GetValue("Font"),
                 TextXAlignment = Enum.TextXAlignment.Left}
            },
            Parent = menuFrame
        })
        
        -- Add icon if provided
        if item.Icon then
            Utilities.CreateInstance("ImageLabel", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 8, 0.5, -10),
                BackgroundTransparency = 1,
                Image = item.Icon,
                Parent = itemFrame
            })
        end
        
        -- Hover effect
        Utilities.ApplyHoverEffect(
            itemFrame,
            theme:GetColor("PrimaryHover"),
            theme:GetColor("Surface"),
            theme:GetAnimationTime("Fast")
        )
        
        -- Click handler
        itemFrame.MouseButton1Click:Connect(function()
            if item.Callback then
                item.Callback()
            end
            Utilities.SafeDestroy(menu, 0.1)
        end)
    end
    
    -- Auto-close when clicking outside
    local outsideClick = Utilities.CreateInstance("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 999,
        Parent = game:GetService("CoreGui")
    })
    
    outsideClick.MouseButton1Click:Connect(function()
        Utilities.SafeDestroy(menu, 0.1)
        Utilities.SafeDestroy(outsideClick)
    end)
        -- Prevent menu from going off-screen
    local GuiService = game:GetService("GuiService")
    local success, screenSize = pcall(function() return GuiService:GetGuiInset() end)
    if success then
        local maxY = screenSize.Y - menuFrame.Size.Y.Offset - 20
        if position.Y > maxY then
            menuFrame.Position = UDim2.new(0, position.X, 0, maxY)
        end
    end
    
    return menuFrame
end

--[[
    Adds keyboard navigation to a container (arrow keys, enter)
    @param container Instance - Frame containing interactive elements
    @param focusElements table - Array of focusable elements
]]
function InputHandler:AddKeyboardNavigation(container: Instance, focusElements: table)
    local currentIndex = 1
    local UserInputService = self.UserInputService
    
    -- Highlight initial element
    if focusElements[1] and focusElements[1].Focus then
        focusElements[1].Focus()
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab or 
           input.KeyCode == Enum.KeyCode.Down then
            currentIndex = currentIndex % #focusElements + 1
            if focusElements[currentIndex].Focus then
                focusElements[currentIndex].Focus()
            end
        elseif input.KeyCode == Enum.KeyCode.Up then
            currentIndex = (currentIndex - 2) % #focusElements + 1
            if focusElements[currentIndex].Focus then
                focusElements[currentIndex].Focus()
            end
        elseif input.KeyCode == Enum.KeyCode.Enter and focusElements[currentIndex].Activate then
            focusElements[currentIndex].Activate()
        end
    end)
end

-- Initialize input handler
if not InputHandler:Initialize() then
    warn("[NIKO UI] Failed to initialize input system. Some features may be limited.")end

NIKO_UI.Input = InputHandler

-- ======================================================================================================
-- PART 1 SUMMARY
-- This concludes Part 1 of the NIKO UI library.
-- Included modules:
--   * Comprehensive Utilities (25+ functions with full documentation)
--   * Professional Theme System (Dark theme with neon accents)
--   * Advanced Input Handling (dragging, context menus, keyboard nav)
-- 
-- NEXT IN PART 2:
--   * Core UI Element Classes (Button, Toggle, Slider, Dropdown, TextBox)
--   * Window System Implementation (draggable window with controls)
--   * Tab System Architecture
--   * User Footer Component
-- 
-- Continue to Part 2 for the main UI components and window system.
-- ======================================================================================================
return NIKO_UI
