-- ==========================================
-- SERVIÇOS E DEPENDÊNCIAS
-- ==========================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ClientState = require(script.Parent:WaitForChild("ClientState"))

-- ==========================================
-- VARIÁVEIS LOCAIS E ESTADO
-- ==========================================
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local healthConnection = nil

-- ==========================================
-- CONSTRUÇÃO VISUAL (HUD GERAL)
-- ==========================================
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "EldenRingHUD"
hudGui.ResetOnSpawn = false
hudGui.Parent = playerGui

local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDContainer"
hudFrame.Size = UDim2.new(0, 400, 0, 100)
hudFrame.Position = UDim2.new(0, 20, 0, 20)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = hudGui

-- Ícone do Personagem (Círculo)
local charIcon = Instance.new("Frame")
charIcon.Name = "CharacterIcon"
charIcon.Size = UDim2.new(0, 50, 0, 50)
charIcon.Position = UDim2.new(0, 0, 0, 0)
charIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
charIcon.BorderSizePixel = 0
charIcon.Parent = hudFrame

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = charIcon

-- Vida (Fundo e Preenchimento)
local healthBg = Instance.new("Frame")
healthBg.Name = "HealthBackground"
healthBg.Size = UDim2.new(0, 300, 0, 14)
healthBg.Position = UDim2.new(0, 60, 0, 8)
healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
healthBg.BackgroundTransparency = 0.6
healthBg.BorderSizePixel = 0
healthBg.Parent = hudFrame

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(136, 0, 21)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBg

-- Mana (Fundo e Preenchimento)
local manaBg = Instance.new("Frame")
manaBg.Name = "ManaBackground"
manaBg.Size = UDim2.new(0, 270, 0, 10)
manaBg.Position = UDim2.new(0, 60, 0, 25)
manaBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
manaBg.BackgroundTransparency = 0.6
manaBg.BorderSizePixel = 0
manaBg.Parent = hudFrame

local manaFill = Instance.new("Frame")
manaFill.Name = "ManaFill"
manaFill.Size = UDim2.new(1, 0, 1, 0)
manaFill.BackgroundColor3 = Color3.fromRGB(0, 102, 204)
manaFill.BorderSizePixel = 0
manaFill.Parent = manaBg

-- Estamina (Fundo e Preenchimento)
local staminaBg = Instance.new("Frame")
staminaBg.Name = "StaminaBackground"
staminaBg.Size = UDim2.new(0, 240, 0, 10)
staminaBg.Position = UDim2.new(0, 60, 0, 38)
staminaBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
staminaBg.BackgroundTransparency = 0.6
staminaBg.BorderSizePixel = 0
staminaBg.Parent = hudFrame

local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.new(1, 0, 1, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBg

-- ==========================================
-- CONSTRUÇÃO VISUAL (HOTBAR)
-- ==========================================
local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "HotbarContainer"
hotbarFrame.AnchorPoint = Vector2.new(0, 1)
hotbarFrame.Position = UDim2.new(0, 40, 1, -40)
hotbarFrame.Size = UDim2.new(0, 150, 0, 150)
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.Parent = hudGui

-- Instancia as janelas visuais de cada equipamento
local function createSlot(name, position, color, slotKey)
    local slot = Instance.new("ImageLabel")
    slot.Name = name
    slot.Size = UDim2.new(0, 45, 0, 45)
    slot.Position = position
    slot.BackgroundColor3 = color
    slot.BackgroundTransparency = 0.4
    slot.BorderSizePixel = 0
    slot.Image = ""
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = slot
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = slot
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextScaled = true
    textLabel.Parent = slot
    
    slot.Parent = hotbarFrame
    return slot
end

local slotTop = createSlot("SlotMagic", UDim2.new(0, 52, 0, 5), Color3.fromRGB(20, 20, 60), "Top")
local slotBottom = createSlot("SlotItem", UDim2.new(0, 52, 0, 100), Color3.fromRGB(20, 60, 20), "Bottom")

-- Contador de Frascos
local flaskCountLabel = Instance.new("TextLabel")
flaskCountLabel.Name = "FlaskCount"
flaskCountLabel.Size = UDim2.new(0, 20, 0, 15)
flaskCountLabel.Position = UDim2.new(1, -22, 1, -15) -- Alinhado ao canto inferior direito
flaskCountLabel.BackgroundTransparency = 1
flaskCountLabel.Text = tostring(ClientState.CurrentFlasks)
flaskCountLabel.TextColor3 = Color3.new(1, 1, 1)
flaskCountLabel.TextStrokeTransparency = 0
flaskCountLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
flaskCountLabel.Font = Enum.Font.GothamBold
flaskCountLabel.TextSize = 14
flaskCountLabel.TextXAlignment = Enum.TextXAlignment.Right
flaskCountLabel.TextYAlignment = Enum.TextYAlignment.Bottom
flaskCountLabel.Parent = slotBottom

local slotLeft = createSlot("SlotShield", UDim2.new(0, 5, 0, 52), Color3.fromRGB(40, 40, 40), "Left")
local slotRight = createSlot("SlotWeapon", UDim2.new(0, 100, 0, 52), Color3.fromRGB(60, 20, 20), "Right")

-- ==========================================
-- FUNÇÕES DE ATUALIZAÇÃO E ANIMAÇÃO
-- ==========================================

-- Gerencia a barra de vida conectando ao Humanoid local
local function setupHealthConnection()
    if healthConnection then
        healthConnection:Disconnect()
    end
    
    local targetScale = humanoid.Health / humanoid.MaxHealth
    healthFill.Size = UDim2.new(targetScale, 0, 1, 0)
    
    healthConnection = humanoid.HealthChanged:Connect(function(health)
        local scale = health / humanoid.MaxHealth
        local targetSize = UDim2.new(scale, 0, 1, 0)
        local tween = TweenService:Create(healthFill, tweenInfo, {Size = targetSize})
        tween:Play()
    end)
end

-- Gerencia a barra de mana conectando ao ClientState
local function updateManaUI()
    local scale = ClientState.Mana / ClientState.MaxMana
    local targetSize = UDim2.new(scale, 0, 1, 0)
    local tween = TweenService:Create(manaFill, tweenInfo, {Size = targetSize})
    tween:Play()
end

-- ==========================================
-- INICIALIZAÇÃO E EVENTOS
-- ==========================================

setupHealthConnection()
updateManaUI()

-- Re-conecta a vida após o respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    setupHealthConnection()
end)

-- Escuta mudanças na estamina vindas do StaminaController
local staminaController = script.Parent:WaitForChild("StaminaController")
local staminaChangedEvent = staminaController:WaitForChild("StaminaChanged")

staminaChangedEvent.Event:Connect(function(currentStamina, maxStamina)
    local scale = currentStamina / maxStamina
    local targetSize = UDim2.new(scale, 0, 1, 0)
    local tween = TweenService:Create(staminaFill, tweenInfo, {Size = targetSize})
    tween:Play()
end)

-- Escuta mudanças no contador de Frascos
local flaskEvent = script.Parent:FindFirstChild("FlaskUsedEvent")
if not flaskEvent then
    flaskEvent = Instance.new("BindableEvent")
    flaskEvent.Name = "FlaskUsedEvent"
    flaskEvent.Parent = script.Parent
end

flaskEvent.Event:Connect(function(newCount)
    if flaskCountLabel then
        flaskCountLabel.Text = tostring(newCount)
    end
end)
