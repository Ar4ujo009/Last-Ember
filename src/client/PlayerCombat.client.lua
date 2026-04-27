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
local healEvent = ReplicatedStorage:WaitForChild("HealEvent")
local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")

local flaskEvent = script.Parent:FindFirstChild("FlaskUsedEvent")
if not flaskEvent then
    flaskEvent = Instance.new("BindableEvent")
    flaskEvent.Name = "FlaskUsedEvent"
    flaskEvent.Parent = script.Parent
end

-- Configurações de Combate
local ATTACK_COOLDOWN = 0.6
local ATTACK_STAMINA_COST = 15
local ATTACK_ANIM_ID = "rbxassetid://0" -- Substitua pelo ID da sua animação
local SWING_SOUND_ID = "rbxassetid://0"

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
    if isAttacking or ClientState.IsDrinking or ClientState.IsGuarding then return end
    if tick() - lastAttackTime < ATTACK_COOLDOWN then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    local hasStamina = requestStaminaDrain:Invoke(ATTACK_STAMINA_COST)
    if not hasStamina then return end
    
    isAttacking = true
    lastAttackTime = tick()
    
    -- Inicia a Animação
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = ATTACK_ANIM_ID
    local attackTrack = animator:LoadAnimation(anim)
    attackTrack:Play()
    
    -- Efeito de Som de 'Swing'
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local swingSound = Instance.new("Sound")
        swingSound.SoundId = SWING_SOUND_ID
        swingSound.Parent = rootPart
        swingSound:Play()
        game:GetService("Debris"):AddItem(swingSound, 2)
    end
    
    -- Dispara para o servidor processar a Hitbox
    attackEvent:FireServer()
    
    -- Duração da animação/ataque
    task.wait(0.6)
    
    if attackTrack.IsPlaying then
        attackTrack:Stop()
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
                healEvent:FireServer(maxHealth * 0.4)
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
