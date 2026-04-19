-- ==========================================
-- SERVIÇOS E DEPENDÊNCIAS
-- ==========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatHandler = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatHandler"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

-- ==========================================
-- VARIÁVEIS LOCAIS E ESTADO
-- ==========================================
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local staminaController = script.Parent:WaitForChild("StaminaController")
local requestStaminaDrain = staminaController:WaitForChild("RequestStaminaDrain")
local damageEvent = ReplicatedStorage:WaitForChild("DamageEvent")

-- Configurações de Combate
local ATTACK_COOLDOWN = 0.5
local ATTACK_STAMINA_COST = 15
local HITBOX_DURATION = 0.3

local lastAttackTime = 0
local isAttacking = false

-- ==========================================
-- CICLO DE VIDA DO PERSONAGEM
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

-- ==========================================
-- FUNÇÕES DE COMBATE
-- ==========================================

-- Gerencia a rotina completa de um ataque (cooldown, stamina, hitbox)
local function PerformAttack()
    if isAttacking or (tick() - lastAttackTime < ATTACK_COOLDOWN) then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    local hasStamina = requestStaminaDrain:Invoke(ATTACK_STAMINA_COST)
    if not hasStamina then return end
    
    isAttacking = true
    lastAttackTime = tick()
    
    local hitTargets = CombatHandler.PerformHitbox(equippedTool, HITBOX_DURATION, character)
    
    for _, hitHumanoid in ipairs(hitTargets) do
        print("Acerto crítico (Raycast) em: " .. hitHumanoid.Parent.Name)
        damageEvent:FireServer(hitHumanoid, 20)
    end
    
    isAttacking = false
end

-- ==========================================
-- CAPTURA DE INPUTS
-- ==========================================

-- Lida com o clique do mouse para Ataque (LMB) e Defesa (RMB)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        PerformAttack()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        local leftItem = ClientState.EquippedItems.Left
        if leftItem and string.match(leftItem, "Escudo") then
            ClientState.IsGuarding = true
            print("Bloqueando...")
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        ClientState.IsGuarding = false
    end
end)
