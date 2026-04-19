local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Atualizar referências se o personagem respawnar
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
end)

-- ==========================================
-- CONFIGURAÇÕES DE STAMINA
-- ==========================================
local MAX_STAMINA = 100
local currentStamina = MAX_STAMINA

local REGEN_DELAY = 1.5 -- Tempo em segundos sem gastar para começar a recuperar
local REGEN_RATE = 25   -- Quantidade de stamina recuperada por segundo
local SPRINT_DRAIN_RATE = 15 -- Quantidade de stamina gasta por segundo ao correr

local WALK_SPEED = 16
local SPRINT_SPEED = 24

-- Variáveis de controle de estado
local lastStaminaUseTime = 0
local isHoldingSprint = false

-- ==========================================
-- COMUNICAÇÃO DE INTERFACE
-- ==========================================
local staminaChanged = Instance.new("BindableEvent")
staminaChanged.Name = "StaminaChanged"
staminaChanged.Parent = script


-- ==========================================
-- LÓGICA BASE E FUNÇÕES
-- ==========================================

-- Função utilitária para drenar stamina (pode ser usada por outras ações como Esquiva/Ataque)
local function DrainStamina(amount)
    -- Garante que a stamina não desça abaixo de 0
    currentStamina = math.clamp(currentStamina - amount, 0, MAX_STAMINA)
    -- Atualiza o tempo do último gasto, resetando o delay para regeneração
    lastStaminaUseTime = tick() 
    staminaChanged:Fire(currentStamina, MAX_STAMINA)
end

-- Função utilitária para regenerar stamina gradualmente
local function RegenStamina(deltaTime)
    -- tick() é o tempo atual em segundos.
    -- Se a diferença entre o tempo atual e o último uso for maior que o delay estipulado...
    if tick() - lastStaminaUseTime >= REGEN_DELAY then
        if currentStamina < MAX_STAMINA then
            -- Calculamos o quanto regenerar com base no tempo que passou no frame (deltaTime)
            local regenAmount = REGEN_RATE * deltaTime
            currentStamina = math.clamp(currentStamina + regenAmount, 0, MAX_STAMINA)
            staminaChanged:Fire(currentStamina, MAX_STAMINA)
        end
    end
end

-- ==========================================
-- INTERFACE PÚBLICA (COMUNICAÇÃO COM OUTROS SCRIPTS)
-- ==========================================
-- Criamos um BindableFunction anexado a este script para que o DodgeController possa pedir para gastar stamina.
local requestStaminaDrain = Instance.new("BindableFunction")
requestStaminaDrain.Name = "RequestStaminaDrain"
requestStaminaDrain.Parent = script

requestStaminaDrain.OnInvoke = function(amount)
    if currentStamina >= amount then
        DrainStamina(amount)
        return true -- Sucesso! Tem stamina suficiente.
    end
    return false -- Falhou! Não tem stamina.
end




-- ==========================================
-- CONTROLE DE INPUT (CORRIDA)
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
-- LOOP PRINCIPAL (ATUALIZAÇÃO POR FRAME)
-- ==========================================
-- Usamos Heartbeat pois é o ideal para lógicas de status e física ligadas ao personagem
RunService.Heartbeat:Connect(function(deltaTime)
    if not humanoid then return end

    -- Verifica se o personagem está realmente em movimento
    local isMoving = humanoid.MoveDirection.Magnitude > 0

    -- Se o jogador está segurando Shift, se movendo, e tem stamina sobrando...
    if isHoldingSprint and isMoving and currentStamina > 0 then
        
        -- Drena a stamina baseada na taxa por segundo e no tempo do frame (deltaTime)
        DrainStamina(SPRINT_DRAIN_RATE * deltaTime)
        humanoid.WalkSpeed = SPRINT_SPEED
        
        -- Se esgotou a stamina durante a corrida, voltamos à velocidade de caminhada
        if currentStamina == 0 then
            humanoid.WalkSpeed = WALK_SPEED
        end
        
    else
        -- Caso não esteja correndo, a velocidade é a padrão
        humanoid.WalkSpeed = WALK_SPEED
        
        -- E tentamos regenerar a stamina
        RegenStamina(deltaTime)
    end

end)
