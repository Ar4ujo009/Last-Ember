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
-- CRIAÇÃO DA INTERFACE VIA CÓDIGO
-- ==========================================
-- Pegamos o PlayerGui, onde ficam as interfaces do jogador
local playerGui = player:WaitForChild("PlayerGui")

-- Criamos o contêiner principal da interface (ScreenGui)
local staminaScreenGui = Instance.new("ScreenGui")
staminaScreenGui.Name = "StaminaUI"
staminaScreenGui.ResetOnSpawn = false -- Evita que a UI suma ou pisque quando o jogador morrer
staminaScreenGui.Parent = playerGui

-- Criamos a barra de fundo (Cinza Escuro)
local backgroundBar = Instance.new("Frame")
backgroundBar.Name = "Background"
backgroundBar.Size = UDim2.new(0, 250, 0, 15) -- Largura: 250 pixels, Altura: 15 pixels
backgroundBar.Position = UDim2.new(0, 40, 0, 40) -- Canto superior esquerdo com margem de 40px
backgroundBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Cor cinza escuro
backgroundBar.BorderSizePixel = 0
backgroundBar.Parent = staminaScreenGui

-- Adicionamos cantos arredondados ao fundo
local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 8)
bgCorner.Parent = backgroundBar

-- Criamos a barra de preenchimento (Verde/Amarela)
local fillBar = Instance.new("Frame")
fillBar.Name = "Fill"
-- Tamanho inicial de 100% em relação à largura e altura da barra de fundo (1, 0, 1, 0)
fillBar.Size = UDim2.new(1, 0, 1, 0)
fillBar.BackgroundColor3 = Color3.fromRGB(150, 200, 50) -- Tom esverdeado/amarelado
fillBar.BorderSizePixel = 0
fillBar.Parent = backgroundBar

-- Adicionamos cantos arredondados também ao preenchimento
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = fillBar


-- ==========================================
-- LÓGICA BASE E FUNÇÕES
-- ==========================================

-- Função utilitária para drenar stamina (pode ser usada por outras ações como Esquiva/Ataque)
local function DrainStamina(amount)
    -- Garante que a stamina não desça abaixo de 0
    currentStamina = math.clamp(currentStamina - amount, 0, MAX_STAMINA)
    -- Atualiza o tempo do último gasto, resetando o delay para regeneração
    lastStaminaUseTime = tick() 
end

-- Função utilitária para regenerar stamina gradualmente
local function RegenStamina(deltaTime)
    -- tick() é o tempo atual em segundos.
    -- Se a diferença entre o tempo atual e o último uso for maior que o delay estipulado...
    if tick() - lastStaminaUseTime >= REGEN_DELAY then
        -- Calculamos o quanto regenerar com base no tempo que passou no frame (deltaTime)
        local regenAmount = REGEN_RATE * deltaTime
        currentStamina = math.clamp(currentStamina + regenAmount, 0, MAX_STAMINA)
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

    -- ==========================================
    -- ATUALIZAÇÃO VISUAL SUAVE (UI)
    -- ==========================================
    -- Calculamos a porcentagem atual da stamina (vai de 0.0 a 1.0)
    local targetScale = currentStamina / MAX_STAMINA
    
    -- [[ EXPLICAÇÃO DO LERP ]]
    -- Em vez de simplesmente definir fillBar.Size = UDim2.new(targetScale, ...),
    -- usamos o :Lerp() para que o tamanho atual "persiga" o tamanho alvo.
    -- Multiplicamos por deltaTime para manter a suavidade independente do framerate.
    -- Isso evita o efeito "engasgado" na UI.
    local targetSize = UDim2.new(targetScale, 0, 1, 0)
    fillBar.Size = fillBar.Size:Lerp(targetSize, 15 * deltaTime)
    
    -- Bônus: Mudança suave de cor se a stamina estiver muito baixa (< 20%)
    if targetScale < 0.2 then
        fillBar.BackgroundColor3 = fillBar.BackgroundColor3:Lerp(Color3.fromRGB(200, 50, 50), 10 * deltaTime) -- Fica avermelhado
    else
        fillBar.BackgroundColor3 = fillBar.BackgroundColor3:Lerp(Color3.fromRGB(150, 200, 50), 10 * deltaTime) -- Volta pro Verde/Amarelo
    end
end)
