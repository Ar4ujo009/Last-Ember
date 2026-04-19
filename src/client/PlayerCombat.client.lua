local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Atualiza referências ao respawnar
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

-- ==========================================
-- IMPORTAÇÕES E REFERÊNCIAS
-- ==========================================
-- Pegamos o módulo compartilhado (Shared mapeia para ReplicatedStorage.Shared pelo Rojo)
local CombatHandler = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatHandler"))

-- Pegamos a porta da Stamina que deixamos aberta no arquivo anterior
local staminaController = script.Parent:WaitForChild("StaminaController")
local requestStaminaDrain = staminaController:WaitForChild("RequestStaminaDrain")

-- ==========================================
-- CONFIGURAÇÕES DE COMBATE
-- ==========================================
local ATTACK_COOLDOWN = 0.5
local ATTACK_STAMINA_COST = 15
local HITBOX_DURATION = 0.3 -- Quanto tempo (em segundos) a lâmina corta o ar após clicar

local lastAttackTime = 0
local isAttacking = false

-- ==========================================
-- LÓGICA DE CLIQUE E ATAQUE
-- ==========================================
local function PerformAttack()
    -- 1. Verifica Cooldown e Estado (se já não está no meio de um ataque)
    if isAttacking or (tick() - lastAttackTime < ATTACK_COOLDOWN) then return end
    
    -- 2. Verifica se tem alguma ferramenta (Tool) equipada
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end -- Sem arma, sem ataque
    
    -- 3. Integração com Stamina
    -- Invoca e pede permissão para gastar
    local hasStamina = requestStaminaDrain:Invoke(ATTACK_STAMINA_COST)
    if not hasStamina then return end -- Sem fôlego suficiente
    
    -- Tudo passou! Começamos o ataque.
    isAttacking = true
    lastAttackTime = tick()
    
    -- (Opcional Futuro: animTrack:Play() Aqui!)
    
    -- 4. Chamar a Hitbox (Isto trava o script localmente pela duração do HITBOX_DURATION)
    -- Nós chamamos o ModuleScript para resolver a matemática dos raios.
    local hitTargets = CombatHandler.PerformHitbox(equippedTool, HITBOX_DURATION, character)
    
    -- 5. Processar quem apanhou
    for _, hitHumanoid in ipairs(hitTargets) do
        -- Printe exigido no log de quem foi cortado
        print("Acerto crítico (Raycast) em: " .. hitHumanoid.Parent.Name)
        
        -- NOTA IMPORTANTE PARA MULTIPLAYER:
        -- Aqui no LocalScript você validou o acerto na tela do jogador (Client-Sided).
        -- Para o monstro tomar dano de verdade (Server-Sided), você criaria um RemoteEvent:
        -- game.ReplicatedStorage.HitEvent:FireServer(hitHumanoid)
    end
    
    isAttacking = false
end

-- Captura do Clique Esquerdo
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        PerformAttack()
    end
end)
