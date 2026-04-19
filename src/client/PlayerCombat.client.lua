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
local humanoid = character:WaitForChild("Humanoid")

local staminaController = script.Parent:WaitForChild("StaminaController")
local requestStaminaDrain = staminaController:WaitForChild("RequestStaminaDrain")
local damageEvent = ReplicatedStorage:WaitForChild("DamageEvent")

local flaskEvent = script.Parent:FindFirstChild("FlaskUsedEvent")
if not flaskEvent then
    flaskEvent = Instance.new("BindableEvent")
    flaskEvent.Name = "FlaskUsedEvent"
    flaskEvent.Parent = script.Parent
end

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
    humanoid = character:WaitForChild("Humanoid")
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

-- Gerencia o uso do Frasco de Cura
local function UseFlask()
    if ClientState.CurrentFlasks > 0 and not ClientState.IsDrinking and not isAttacking then
        local currentHealth = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        
        if currentHealth < maxHealth then
            ClientState.IsDrinking = true
            
            task.wait(0.6) -- Tempo que leva o frasco até a boca
            
            if ClientState.IsDrinking then -- Verifica se não foi cancelado
                humanoid.Health = math.clamp(humanoid.Health + (maxHealth * 0.4), 0, maxHealth)
                ClientState.CurrentFlasks = ClientState.CurrentFlasks - 1
                print("Frasco usado! Restam: " .. ClientState.CurrentFlasks)
                
                ClientState.IsDrinking = false
                flaskEvent:Fire(ClientState.CurrentFlasks)
            end
        end
    end
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
    elseif input.KeyCode == Enum.KeyCode.R then
        UseFlask()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        ClientState.IsGuarding = false
    end
end)
