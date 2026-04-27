local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Atualiza referências se o jogador morrer e respawnar
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Pegando a referência do StaminaController (que compartilha a mesma pasta src/client)
-- Como ambos carregam juntos, precisamos esperar o script e o evento estarem prontos.
local staminaController = script.Parent:WaitForChild("StaminaController")
local requestStaminaDrain = staminaController:WaitForChild("RequestStaminaDrain")

-- ==========================================
-- CONFIGURAÇÕES DA ESQUIVA
-- ==========================================
local DODGE_STAMINA_COST = 25
local DODGE_COOLDOWN = 1.0     -- Tempo mínimo entre esquivas para evitar spam
local IFRAME_DURATION = 0.4    -- Quanto tempo o personagem fica invulnerável (em segundos)
local DODGE_FORCE = 75         -- Força do impulso da esquiva
local ROLL_ANIMATION_ID = ""   -- Ex: "rbxassetid://12345678" (Deixe aqui seu ID para usar depois)

local lastDodgeTime = 0
local isDodging = false

-- ==========================================
-- LÓGICA PRINCIPAL DA ESQUIVA
-- ==========================================
local function Dodge()
    -- 1. Verificar Cooldown e Estado
    -- Não permite esquivar se já estiver no meio de uma esquiva ou no cooldown
    if isDodging or (tick() - lastDodgeTime < DODGE_COOLDOWN) then return end
    
    -- 2. Comunicação com a Stamina
    -- Invocamos o BindableFunction no StaminaController. Ele retorna true se tinha 25 de stamina e já cobrou.
    local hasStamina = requestStaminaDrain:Invoke(DODGE_STAMINA_COST)
    if not hasStamina then return end -- Sem fôlego suficiente! Cancela a esquiva.

    -- Iniciamos o estado de esquiva
    isDodging = true
    lastDodgeTime = tick()

    -- 3. Calcular a Direção
    -- MoveDirection retorna um vetor unitário (0 a 1) para onde as teclas WASD estão mandando o personagem
    local moveDir = humanoid.MoveDirection
    
    -- Se o jogador não estiver apertando nada (parado), esquivamos para trás (padrão de soulslikes)
    if moveDir.Magnitude == 0 then
        moveDir = -humanoidRootPart.CFrame.LookVector
    end

    -- 4. Impulso Físico (Dash)
    -- [[ EXPLICAÇÃO DO IMPULSO (LinearVelocity) ]]
    -- LinearVelocity aplica uma velocidade constante num corpo físico usando um Attachment como âncora.
    -- Setamos a RelativeTo como World, assim o personagem é arremessado na direção do moveDir do mundo.
    local attachment = Instance.new("Attachment")
    attachment.Parent = humanoidRootPart
    
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = attachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.MaxForce = 100000 -- Força imensa para sobrepujar a fricção do chão rapidamente
    linearVelocity.VectorVelocity = moveDir * DODGE_FORCE
    linearVelocity.Parent = humanoidRootPart
    
    -- O Debris destrói o impulso rapidamente (0.15s), criando aquele efeito de um "pulo horizontal" explosivo e curto
    Debris:AddItem(attachment, 0.15)
    Debris:AddItem(linearVelocity, 0.15)

    -- 5. Animação de Rolamento
    if ROLL_ANIMATION_ID ~= "" then
        local anim = Instance.new("Animation")
        anim.AnimationId = ROLL_ANIMATION_ID
        local animTrack = humanoid:LoadAnimation(anim)
        animTrack:Play()
    end

    -- 6. I-Frames (Invencibilidade)
    -- [[ EXPLICAÇÃO DOS I-FRAMES ]]
    -- I-frames (Invincibility Frames) são cruciais num Soulslike. É a janela de tempo onde o ataque do inimigo atravessa você sem dar dano.
    -- Colocamos um atributo "IsInvincible" direto no Character.
    -- A regra de ouro agora é: QUALQUER script de ataque/hitbox do inimigo ou chefe DEVE verificar se esse atributo é true antes de aplicar dano!
    -- Exemplo lá no inimigo: if character:GetAttribute("IsInvincible") then return end
    character:SetAttribute("IsInvincible", true)
    
    -- Usamos task.delay para agendar o fim da esquiva e da invencibilidade sem congelar o script
    task.delay(IFRAME_DURATION, function()
        if character then
            character:SetAttribute("IsInvincible", false)
        end
        isDodging = false
    end)
end

-- ==========================================
-- CONTROLE DE INPUT
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    -- Se o jogador apertar Q ou LeftAlt, tenta esquivar
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        Dodge();
    end
end)
