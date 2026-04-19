-- ==========================================
-- SERVIÇOS E DEPENDÊNCIAS
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ClientState = require(script.Parent:WaitForChild("ClientState"))

-- ==========================================
-- VARIÁVEIS LOCAIS E ESTADO
-- ==========================================
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configurações de Stamina
local MAX_STAMINA = 100
local currentStamina = MAX_STAMINA
local REGEN_DELAY = 1.5
local REGEN_RATE = 25
local SPRINT_DRAIN_RATE = 15

local WALK_SPEED = 16
local SPRINT_SPEED = 24

-- Controle de Estado
local lastStaminaUseTime = 0
local isHoldingSprint = false

-- Eventos de Comunicação
local staminaChanged = Instance.new("BindableEvent")
staminaChanged.Name = "StaminaChanged"
staminaChanged.Parent = script

local requestStaminaDrain = Instance.new("BindableFunction")
requestStaminaDrain.Name = "RequestStaminaDrain"
requestStaminaDrain.Parent = script

-- ==========================================
-- CICLO DE VIDA DO PERSONAGEM
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
end)

-- ==========================================
-- FUNÇÕES DE GERENCIAMENTO
-- ==========================================

-- Drena stamina e reinicia o delay de regeneração
local function DrainStamina(amount)
    currentStamina = math.clamp(currentStamina - amount, 0, MAX_STAMINA)
    lastStaminaUseTime = tick() 
    staminaChanged:Fire(currentStamina, MAX_STAMINA)
end

-- Regenera stamina gradualmente se o delay já passou
local function RegenStamina(deltaTime)
    if tick() - lastStaminaUseTime >= REGEN_DELAY then
        if currentStamina < MAX_STAMINA then
            local regenAmount = REGEN_RATE * deltaTime
            currentStamina = math.clamp(currentStamina + regenAmount, 0, MAX_STAMINA)
            staminaChanged:Fire(currentStamina, MAX_STAMINA)
        end
    end
end

-- ==========================================
-- INTEGRAÇÃO PÚBLICA (BINDABLES)
-- ==========================================

-- Processa pedidos externos de consumo de stamina
requestStaminaDrain.OnInvoke = function(amount)
    if currentStamina >= amount then
        DrainStamina(amount)
        return true
    end
    return false
end

-- ==========================================
-- CAPTURA DE INPUT (CORRIDA)
-- ==========================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isHoldingSprint = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isHoldingSprint = false
    end
end)

-- ==========================================
-- LOOP PRINCIPAL (FÍSICA E ATUALIZAÇÃO)
-- ==========================================

RunService.Heartbeat:Connect(function(deltaTime)
    if not humanoid then return end

    local isMoving = humanoid.MoveDirection.Magnitude > 0

    if isHoldingSprint and isMoving and currentStamina > 0 then
        -- Estado de Corrida
        DrainStamina(SPRINT_DRAIN_RATE * deltaTime)
        humanoid.WalkSpeed = SPRINT_SPEED
        
        if currentStamina == 0 then
            humanoid.WalkSpeed = WALK_SPEED
        end
    else
        -- Estado Padrão ou Guarda
        if ClientState.IsGuarding then
            humanoid.WalkSpeed = WALK_SPEED * 0.4 -- Lentidão de 60%
        else
            humanoid.WalkSpeed = WALK_SPEED
        end
        
        RegenStamina(deltaTime)
    end
end)
