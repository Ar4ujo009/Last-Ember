local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ==========================================
-- CRIAÇÃO DA HUD (ESTÉTICA ELDEN RING)
-- ==========================================
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "EldenRingHUD"
hudGui.ResetOnSpawn = false
hudGui.Parent = playerGui

local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDContainer"
hudFrame.Size = UDim2.new(0, 400, 0, 100)
hudFrame.Position = UDim2.new(0, 20, 0, 20) -- Top Left
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
iconCorner.CornerRadius = UDim.new(1, 0) -- Transforma em círculo perfeito
iconCorner.Parent = charIcon

-- Barra de Vida (Fundo)
local healthBg = Instance.new("Frame")
healthBg.Name = "HealthBackground"
healthBg.Size = UDim2.new(0, 300, 0, 14)
healthBg.Position = UDim2.new(0, 60, 0, 8) -- À direita do ícone
healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
healthBg.BackgroundTransparency = 0.6
healthBg.BorderSizePixel = 0
healthBg.Parent = hudFrame

-- Barra de Vida (Preenchimento)
local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(136, 0, 21) -- Vermelho Carmesim
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBg

-- Barra de Estamina (Fundo)
local staminaBg = Instance.new("Frame")
staminaBg.Name = "StaminaBackground"
staminaBg.Size = UDim2.new(0, 240, 0, 10) -- Ligeiramente menor que a de vida
staminaBg.Position = UDim2.new(0, 60, 0, 28) -- Embaixo da barra de vida
staminaBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
staminaBg.BackgroundTransparency = 0.6
staminaBg.BorderSizePixel = 0
staminaBg.Parent = hudFrame

-- Barra de Estamina (Preenchimento)
local staminaFill = Instance.new("Frame")
staminaFill.Name = "StaminaFill"
staminaFill.Size = UDim2.new(1, 0, 1, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Verde Musgo
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBg

-- ==========================================
-- LÓGICA DE TWEEN (SUAVIZAÇÃO)
-- ==========================================
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local healthConnection

local function setupHealthConnection()
    if healthConnection then
        healthConnection:Disconnect()
    end
    
    -- Atualiza imediatamente ao carregar
    local targetScale = humanoid.Health / humanoid.MaxHealth
    healthFill.Size = UDim2.new(targetScale, 0, 1, 0)
    
    healthConnection = humanoid.HealthChanged:Connect(function(health)
        local scale = health / humanoid.MaxHealth
        local targetSize = UDim2.new(scale, 0, 1, 0)
        local tween = TweenService:Create(healthFill, tweenInfo, {Size = targetSize})
        tween:Play()
    end)
end

-- Se o personagem reaparecer, reconectar a barra de vida
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    setupHealthConnection()
end)

setupHealthConnection()

-- ==========================================
-- INTEGRAÇÃO COM STAMINA
-- ==========================================
local staminaController = script.Parent:WaitForChild("StaminaController")
local staminaChangedEvent = staminaController:WaitForChild("StaminaChanged")

staminaChangedEvent.Event:Connect(function(currentStamina, maxStamina)
    local scale = currentStamina / maxStamina
    local targetSize = UDim2.new(scale, 0, 1, 0)
    local tween = TweenService:Create(staminaFill, tweenInfo, {Size = targetSize})
    tween:Play()
end)
