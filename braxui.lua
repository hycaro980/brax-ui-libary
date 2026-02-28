--[[
    BRAX UI LIBRARY - v1.0
    Developer: hycaroao123
    License: Open Source (MIT)
    Description: Uma biblioteca de UI modular, de alta performance e focada em painéis robustos.
    Suporte: PC e Mobile (Touch)
]]

-- =============================================================================
-- 1. SERVIÇOS E VARIÁVEIS GLOBAIS
-- =============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Tabela principal da Biblioteca
local BraxUI = {}
BraxUI.__index = BraxUI

-- Configurações de Identidade
local CONFIG = {
    Title = "Brax UI Library",
    Version = "v1.0",
    Developer = "hycaroao123", -- Criador Fixo
    Watermark = "Brax Lib | v1.0 | Developer: hycaroao123"
}

-- =============================================================================
-- 2. ENGINE DE TEMAS (THEME ENGINE)
-- =============================================================================

local Themes = {
    Black = {
        Background = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(255, 50, 50),
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(150, 150, 150),
        ShadowColor = Color3.fromRGB(0, 0, 0),
        MainFrame = Color3.fromRGB(30, 30, 30)
    },
    White = {
        Background = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(0, 0, 0),
        SecondaryText = Color3.fromRGB(100, 100, 100),
        ShadowColor = Color3.fromRGB(100, 100, 100),
        MainFrame = Color3.fromRGB(255, 255, 255)
    },
    Green = {
        Background = Color3.fromRGB(10, 20, 10),
        Accent = Color3.fromRGB(50, 255, 50),
        Text = Color3.fromRGB(200, 255, 200),
        SecondaryText = Color3.fromRGB(100, 150, 100),
        ShadowColor = Color3.fromRGB(0, 50, 0),
        MainFrame = Color3.fromRGB(20, 30, 20)
    },
    Purple = {
        Background = Color3.fromRGB(20, 10, 30),
        Accent = Color3.fromRGB(150, 50, 255),
        Text = Color3.fromRGB(230, 200, 255),
        SecondaryText = Color3.fromRGB(150, 100, 200),
        ShadowColor = Color3.fromRGB(50, 0, 100),
        MainFrame = Color3.fromRGB(40, 20, 60)
    },
    Blue = {
        Background = Color3.fromRGB(10, 15, 30),
        Accent = Color3.fromRGB(50, 150, 255),
        Text = Color3.fromRGB(200, 220, 255),
        SecondaryText = Color3.fromRGB(100, 130, 180),
        ShadowColor = Color3.fromRGB(0, 20, 50),
        MainFrame = Color3.fromRGB(20, 30, 50)
    }
}

-- Tema Atual
local CurrentTheme = Themes.Black

-- =============================================================================
-- 3. FUNÇÕES AUXILIARES (UTILS)
-- =============================================================================

-- Criação de Instâncias Otimizada
local function CreateInstance(class, properties)
    local inst = Instance.new(class)
    if properties then
        for prop, val in pairs(properties) do
            inst[prop] = val
        end
    end
    return inst
end

-- Sistema de Tween Personalizado
local function TweenObject(obj, properties, duration, style)
    local tweenInfo = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Efeito Ripple (Ondulação) nos Botões
local function CreateRipple(button, color)
    local circle = CreateInstance("Frame", {
        Name = "Ripple",
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.5,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ZIndex = 10,
        ClipsDescendants = true,
        Parent = button
    })
    
    -- Arredondar o ripple
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = circle})

    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    local pos = Vector2.new(size, size)
    
    local tween = TweenService:Create(circle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1
    })
    
    tween.Completed:Connect(function()
        circle:Destroy()
    end)
    tween:Play()
end

-- =============================================================================
-- 4. CLASSE PRINCIPAL (WINDOW & CORE)
-- =============================================================================

function BraxUI.new(title)
    local self = setmetatable({}, BraxUI)
    
    -- Estado Interno
    self.Connections = {}
    self.Pages = {}
    self.CurrentPage = nil
    self.IsLoaded = true
    self.Notifications = {}
    
    -- Interface Gráfica Principal
    self.ScreenGui = CreateInstance("ScreenGui", {
        Name = "BraxUI_Main",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = LocalPlayer:WaitForChild("PlayerGui")
    })

    -- Frame Principal (Janela)
    self.MainFrame = CreateInstance("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 700, 0, 500),
        Position = UDim2.new(0.5, -350, 0.5, -250),
        BackgroundColor3 = CurrentTheme.MainFrame,
        BorderColor3 = CurrentTheme.Accent,
        BorderSizePixel = 1,
        Parent = self.ScreenGui
    })
    
    -- Sombra (Visual)
    local shadow = CreateInstance("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0.5, -20, 0.5, -20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014102112", -- Sombra suave
        ImageColor3 = CurrentTheme.ShadowColor,
        ZIndex = 0,
        Parent = self.MainFrame
    })
    self.MainFrame.ZIndex = 1

    -- Barra de Título
    local titleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })

    -- Texto do Título
    local titleText = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or CONFIG.Title,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })

    -- Nick do Usuário (Dinâmico)
    local userText = CreateInstance("TextLabel", {
        Name = "UserNick",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(1, -190, 0, 0),
        BackgroundTransparency = 1,
        Text = "User: " .. LocalPlayer.Name,
        TextColor3 = CurrentTheme.Accent,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = titleBar
    })

    -- Marca D'água (Watermark)
    local watermark = CreateInstance("TextLabel", {
        Name = "Watermark",
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 10, 1, -30),
        BackgroundTransparency = 1,
        Text = CONFIG.Watermark,
        TextColor3 = CurrentTheme.SecondaryText,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.MainFrame
    })

    -- Botão de Fechar
    local closeBtn = CreateInstance("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = CurrentTheme.Accent,
        Text = "X",
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBold,
        Parent = titleBar
    })

    closeBtn.MouseButton1Click:Connect(function()
        self:Unload()
    end)

    -- Container de Páginas (Abas)
    local pageContainer = CreateInstance("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.MainFrame
    })

    -- Barra Lateral de Navegação
    local navBar = CreateInstance("Frame", {
        Name = "NavBar",
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = pageContainer
    })

    local navLayout = CreateInstance("UIListLayout", {
        Parent = navBar,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local navPadding = CreateInstance("UIPadding", {
        Parent = navBar,
        PaddingTop = UDim.new(0, 10)
    })

    -- Área de Conteúdo
    local contentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 150, 0, 0),
        BackgroundColor3 = CurrentTheme.MainFrame,
        BorderSizePixel = 0,
        Parent = pageContainer
    })

    -- Scrolling Frame para Conteúdo
    local scrollFrame = CreateInstance("ScrollingFrame", {
        Name = "ContentScroll",
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = CurrentTheme.Accent,
        Parent = contentArea
    })
    
    local contentLayout = CreateInstance("UIListLayout", {
        Parent = scrollFrame,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    local contentPadding = CreateInstance("UIPadding", {
        Parent = scrollFrame,
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })

    -- Atualização dinâmica do CanvasSize
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)

    -- Armazenar referências para métodos
    self.NavBar = navBar
    self.ContentScroll = scrollFrame
    self.NavLayout = navLayout
    
    -- Sistema de Arrasto (Draggable) Otimizado
    self:InitDraggable(titleBar)
    
    -- Inicializar Página de Output Nativa
    self:AddPage("Console/Output", "rbxassetid://12345") -- Icone placeholder
    self:InitOutputPage()

    return self
end

-- =============================================================================
-- 5. SISTEMA DE ARRASTO (DRAGGABLE)
-- =============================================================================

function BraxUI:InitDraggable(inputObject)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function update(input)
        local delta = input.Position - dragStart
        self.MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    -- Suporte Mouse e Touch
    inputObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    inputObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    InputService.InputEnded:Connect(onInputEnded)
    InputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- =============================================================================
-- 6. GERENCIAMENTO DE PÁGINAS (TABS)
-- =============================================================================

function BraxUI:AddPage(name, icon)
    local pageIndex = #self.Pages + 1
    
    -- Botão da Aba
    local tabBtn = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = CurrentTheme.Background,
        Text = name,
        TextColor3 = CurrentTheme.SecondaryText,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = self.NavBar
    })
    
    local tabCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = tabBtn})
    
    -- Indicador de Seleção
    local indicator = CreateInstance("Frame", {
        Name = "Indicator",
        Size = UDim2.new(0, 4, 1, -10),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = CurrentTheme.Accent,
        Visible = false,
        Parent = tabBtn
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 2), Parent = indicator})

    -- Frame de Conteúdo da Página
    local pageFrame = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0), -- Altura dinâmica
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentScroll
    })
    
    local pageLayout = CreateInstance("UIListLayout", {
        Parent = pageFrame,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local function updatePageCanvas()
        pageFrame.Size = UDim2.new(1, 0, 0, pageLayout.AbsoluteContentSize.Y)
    end
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePageCanvas)
    updatePageCanvas()

    -- Lógica de Troca de Aba
    local function SelectPage()
        for _, btn in pairs(self.NavBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.TextColor3 = CurrentTheme.SecondaryText
                btn.BackgroundColor3 = CurrentTheme.Background
                if btn:FindFirstChild("Indicator") then
                    btn.Indicator.Visible = false
                end
            end
        end
        for _, pg in pairs(self.ContentScroll:GetChildren()) do
            if pg:IsA("Frame") then
                pg.Visible = false
            end
        end

        tabBtn.TextColor3 = CurrentTheme.Text
        tabBtn.BackgroundColor3 = CurrentTheme.MainFrame
        indicator.Visible = true
        pageFrame.Visible = true
        
        -- Animação suave
        TweenObject(pageFrame, {Position = UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Quint)
        
        self.CurrentPage = pageFrame
    end

    tabBtn.MouseButton1Click:Connect(SelectPage)
    
    -- Selecionar primeira página automaticamente
    if pageIndex == 1 then
        task.wait() -- Pequeno delay para garantir renderização
        SelectPage()
    end

    local pageObj = {
        Frame = pageFrame,
        Layout = pageLayout,
        Button = tabBtn
    }
    
    table.insert(self.Pages, pageObj)
    return pageObj
end

-- =============================================================================
-- 7. SISTEMA DE OUTPUT (CONSOLE NATIVO)
-- =============================================================================

function BraxUI:InitOutputPage()
    -- A primeira página criada foi o Console no constructor
    local consolePage = self.Pages[1]
    if not consolePage then return end

    local outputBox = CreateInstance("Frame", {
        Name = "OutputBox",
        Size = UDim2.new(1, 0, 0, 400),
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        BorderColor3 = CurrentTheme.Accent,
        Parent = consolePage.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = outputBox})

    local scrollOutput = CreateInstance("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Parent = outputBox
    })
    
    local outputLayout = CreateInstance("UIListLayout", {
        Parent = scrollOutput,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    outputLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollOutput.CanvasSize = UDim2.new(0, 0, 0, outputLayout.AbsoluteContentSize.Y)
        scrollOutput.CanvasPosition = Vector2.new(0, outputLayout.AbsoluteContentSize.Y)
    end)

    -- Função para adicionar log
    local function AddLog(text, color)
        local logEntry = CreateInstance("TextLabel", {
            Name = "Log",
            Size = UDim2.new(1, -10, 0, 20),
            BackgroundTransparency = 1,
            Text = "[BRAX] " .. text,
            TextColor3 = color or CurrentTheme.Text,
            Font = Enum.Font.GothamMono,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = scrollOutput
        })
    end

    -- Hooking de Print (Simulado para compatibilidade)
    -- Em exploits reais, hookfunction(print, ...) seria usado.
    -- Aqui usamos LogService para capturar mensagens do jogo.
    local function onMessageAdded(message, messageType)
        if messageType == Enum.MessageType.MessageOutput then
            AddLog(message, Color3.new(1, 1, 1))
        elseif messageType == Enum.MessageType.MessageWarning then
            AddLog(message, Color3.new(1, 1, 0))
        elseif messageType == Enum.MessageType.MessageError then
            AddLog(message, Color3.new(1, 0, 0))
        end
    end

    local logConn = LogService.MessageOut:Connect(onMessageAdded)
    table.insert(self.Connections, logConn)
    
    -- Adicionar método público para logar
    self.Log = function(msg, type)
        local c = CurrentTheme.Text
        if type == "warn" then c = Color3.new(1,1,0) end
        if type == "error" then c = Color3.new(1,0,0) end
        AddLog(msg, c)
    end
    
    AddLog("Brax UI Library Initialized.", Color3.fromRGB(0, 255, 0))
    AddLog("Developer: hycaroao123", CurrentTheme.Accent)
end

-- =============================================================================
-- 8. ELEMENTOS DE UI (COMPONENTS)
-- =============================================================================

-- Botão com Ripple
function BraxUI:AddButton(page, text, callback)
    local btn = CreateInstance("TextButton", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CurrentTheme.Background,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        Parent = page.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = btn})

    btn.MouseButton1Click:Connect(function()
        CreateRipple(btn, CurrentTheme.Accent)
        if callback then callback() end
    end)
    
    btn.MouseEnter:Connect(function()
        TweenObject(btn, {BackgroundColor3 = CurrentTheme.MainFrame}, 0.2)
    end)
    btn.MouseLeave:Connect(function()
        TweenObject(btn, {BackgroundColor3 = CurrentTheme.Background}, 0.2)
    end)
end

-- Toggle (Switch)
function BraxUI:AddToggle(page, text, default, callback)
    local state = default or false
    
    local container = CreateInstance("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = page.Frame
    })
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local switchBg = CreateInstance("Frame", {
        Name = "Switch",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = CurrentTheme.SecondaryText,
        Parent = container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchBg})
    
    local switchCircle = CreateInstance("Frame", {
        Name = "Circle",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = switchBg
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = switchCircle})

    local function UpdateState()
        state = not state
        if callback then callback(state) end
        
        if state then
            TweenObject(switchBg, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
            TweenObject(switchCircle, {Position = UDim2.new(0, 22, 0.5, 0)}, 0.2)
        else
            TweenObject(switchBg, {BackgroundColor3 = CurrentTheme.SecondaryText}, 0.2)
            TweenObject(switchCircle, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.2)
        end
    end

    local clickConn = container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UpdateState()
        end
    end)
    table.insert(self.Connections, clickConn)
end

-- Slider
function BraxUI:AddSlider(page, text, min, max, default, callback)
    local val = default or min
    local sliderBg = CreateInstance("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = CurrentTheme.Background,
        Parent = page.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = sliderBg})
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = text .. ": " .. val,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderBg
    })
    
    local track = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -20, 0, 10),
        Position = UDim2.new(0, 10, 1, -25),
        BackgroundColor3 = CurrentTheme.SecondaryText,
        Parent = sliderBg
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = track})
    
    local fill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = CurrentTheme.Accent,
        Parent = track
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = fill})
    
    local knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        Parent = track
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

    local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local function update(input)
        if dragging then
            local pos = UDim2.new(math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1), 0, 0.5, 0)
            fill.Size = UDim2.new(pos.X.Scale, 0, 1, 0)
            knob.Position = pos
            
            local newValue = math.floor(min + (max - min) * pos.X.Scale)
            val = newValue
            label.Text = text .. ": " .. val
            if callback then callback(val) end
        end
    end
    
    local inputConn = InputService.InputChanged:Connect(update)
    table.insert(self.Connections, inputConn)
end

-- Dropdown (Simplificado)
function BraxUI:AddDropdown(page, text, options, callback)
    local selected = options[1]
    local container = CreateInstance("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CurrentTheme.Background,
        Parent = page.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = container})
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = text .. ": " .. selected,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        Parent = container
    })
    
    local arrow = CreateInstance("TextLabel", {
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = CurrentTheme.Accent,
        Parent = container
    })

    -- Lista de opções (Overlay)
    local optionList = CreateInstance("Frame", {
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CurrentTheme.MainFrame,
        Visible = false,
        Parent = container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = optionList})
    local listLayout = CreateInstance("UIListLayout", {Parent = optionList})
    
    for _, opt in ipairs(options) do
        local btn = CreateInstance("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Text = opt,
            TextColor3 = CurrentTheme.Text,
            Parent = optionList
        })
        btn.MouseButton1Click:Connect(function()
            selected = opt
            label.Text = text .. ": " .. selected
            optionList.Visible = false
            TweenObject(optionList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            if callback then callback(selected) end
        end)
    end

    container.MouseButton1Click:Connect(function()
        optionList.Visible = not optionList.Visible
        if optionList.Visible then
            TweenObject(optionList, {Size = UDim2.new(1, 0, 0, #options * 30)}, 0.2)
        else
            TweenObject(optionList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
        end
    end)
end

-- ColorPicker (Básico)
function BraxUI:AddColorPicker(page, text, default, callback)
    local color = default or Color3.new(1,1,1)
    local container = CreateInstance("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = page.Frame
    })
    
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local preview = CreateInstance("Frame", {
        Name = "Preview",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = color,
        Parent = container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = preview})
    
    -- Nota: Implementação completa de ColorPicker exigiria muito espaço.
    -- Este é um placeholder visual que chama o callback ao clicar.
    preview.MouseButton1Click:Connect(function()
        -- Em uma lib completa, abriria um modal.
        -- Aqui simulamos uma mudança para cor aleatória para demonstração
        color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        preview.BackgroundColor3 = color
        if callback then callback(color) end
        self:Log("Color changed to " .. tostring(color), "warn")
    end)
end

-- TextBox
function BraxUI:AddTextBox(page, text, placeholder, callback)
    local container = CreateInstance("Frame", {
        Name = text,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CurrentTheme.Background,
        Parent = page.Frame
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = container})
    
    local input = CreateInstance("TextBox", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = placeholder or text,
        Text = "",
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        Parent = container
    })
    
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            if callback then callback(input.Text) end
            input.Text = ""
        end
    end)
end

-- =============================================================================
-- 9. SISTEMA DE NOTIFICAÇÕES
-- =============================================================================

function BraxUI:Notify(title, content, type)
    local notifGui = self.ScreenGui:FindFirstChild("Notifications")
    if not notifGui then
        notifGui = CreateInstance("ScreenGui", {
            Name = "Notifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = self.ScreenGui
        })
    end

    local color = CurrentTheme.Accent
    if type == "success" then color = Color3.fromRGB(0, 255, 0) end
    if type == "error" then color = Color3.fromRGB(255, 0, 0) end

    local notif = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, 20, 1, -100), -- Começa fora da tela
        BackgroundColor3 = CurrentTheme.MainFrame,
        BorderColor3 = color,
        Parent = notifGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = notif})
    
    local titleLbl = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif
    })
    
    local contentLbl = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -10, 1, -25),
        Position = UDim2.new(0, 5, 0, 25),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notif
    })

    -- Animação Slide In
    TweenObject(notif, {Position = UDim2.new(1, -320, 1, -100)}, 0.5, Enum.EasingStyle.Quint)

    -- Remover após 5 segundos
    task.delay(5, function()
        TweenObject(notif, {Position = UDim2.new(1, 20, 1, -100)}, 0.5, Enum.EasingStyle.Quint)
        task.wait(0.6)
        notif:Destroy()
    end)
end

-- =============================================================================
-- 10. FUNÇÃO DE TEMA E UNLOAD
-- =============================================================================

function BraxUI:SetTheme(themeName)
    if Themes[themeName] then
        CurrentTheme = Themes[themeName]
        -- Aplicar tema a todos os elementos existentes seria complexo em uma demo,
        -- mas aqui atualizamos as cores base para novos elementos.
        self:Log("Theme changed to " .. themeName, "success")
    end
end

function BraxUI:Unload()
    if not self.IsLoaded then return end
    self.IsLoaded = false
    
    -- Desconectar tudo
    for _, conn in pairs(self.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    
    -- Destruir GUI
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    self:Log("Brax UI Unloaded.", "warn")
end

-- =============================================================================
-- 11. EXEMPLO DE USO (LOCALSCRIPT TEST)
-- =============================================================================
-- Copie tudo acima e cole em um LocalScript ou no seu executor.
-- A parte abaixo é a implementação prática.

print("Iniciando Brax UI Library...")

-- Instanciar a Biblioteca
local UI = BraxUI.new("Brax Exploit Panel")

-- Criar Páginas
local homePage = UI:AddPage("Home", "rbxassetid://0")
local scriptsPage = UI:AddPage("Scripts", "rbxassetid://0")
local settingsPage = UI:AddPage("Settings", "rbxassetid://0")

-- Adicionar Elementos na Home
UI:AddButton(homePage, "Notificar Teste", function()
    UI:Notify("Olá Mestre H", "Esta é uma notificação de teste da Brax Lib.", "success")
end)

UI:AddToggle(homePage, "Auto Farm", false, function(state)
    UI:Log("Auto Farm toggled: " .. tostring(state))
end)

UI:AddSlider(homePage, "WalkSpeed", 16, 500, 16, function(val)
    LocalPlayer.Character.Humanoid.WalkSpeed = val
    UI:Log("WalkSpeed set to " .. val)
end)

-- Adicionar Elementos na Página de Scripts
UI:AddTextBox(scriptsPage, "Script Executor", "Cole seu script aqui...", function(text)
    UI:Log("Attempting to execute script...", "warn")
    -- Em um exploit real, aqui iria a lógica de execução
    loadstring(text)() 
end)

UI:AddDropdown(scriptsPage, "Script Preset", {"Fly", "Noclip", "ESP"}, function(selected)
    UI:Log("Selected preset: " .. selected)
end)

-- Adicionar Elementos na Página de Configurações
UI:AddColorPicker(settingsPage, "Accent Color", Color3.new(1,0,0), function(color)
    -- Em uma lib completa, isso atualizaria o tema dinamicamente
    UI:Log("Color picked: " .. tostring(color))
end)

UI:AddButton(settingsPage, "Change Theme: Green", function()
    UI:SetTheme("Green")
    UI:Notify("Theme Changed", "Now using Green Theme", "success")
end)

UI:AddButton(settingsPage, "Change Theme: Purple", function()
    UI:SetTheme("Purple")
    UI:Notify("Theme Changed", "Now using Purple Theme", "success")
end)

UI:AddButton(settingsPage, "Unload UI", function()
    UI:Unload()
end)

-- Log Inicial
UI:Log("Brax UI Library Ready.", "success")
UI:Log("Developer: hycaroao123", "success")
UI:Notify("Bem-vindo", "Brax UI Library carregada com sucesso.", "success")
