local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local ClientState = require(script.Parent:WaitForChild("ClientState"))

-- Configurações da Câmera
local CAMERA_OFFSET = CFrame.new(2, 1.5, 10) -- X positivo: ombro direito (direita). Y: altura (cima). Z: distância (trás)
local CAMERA_SMOOTHNESS = 0.15 -- Valor para o Lerp (quanto menor, mais suave/pesado)
local CHARACTER_ROTATION_SMOOTHNESS = 0.1 -- Suavidade ao rotacionar o personagem

-- Variáveis de controle de rotação da câmera (mouse)
local cameraAngleX = 0
local cameraAngleY = 0
local MOUSE_SENSITIVITY = 0.003

-- Travar o mouse no centro da tela e ocultá-lo para controle de terceira pessoa
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false

-- Aguardar o personagem carregar
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Atualizar referências se o personagem respawnar
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
end)

-- Mudar a câmera para Scriptable para termos controle total através de código
camera.CameraType = Enum.CameraType.Scriptable

-- Capturar movimento do mouse para rotacionar os ângulos da câmera
UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- Acumulamos o movimento do mouse nas nossas variáveis de ângulo
        cameraAngleX = cameraAngleX - input.Delta.X * MOUSE_SENSITIVITY
        
        -- Limitar o ângulo Y (cima/baixo) para não permitir que a câmera dê "cambalhotas" (-75 a 75 graus)
        cameraAngleY = math.clamp(cameraAngleY - input.Delta.Y * MOUSE_SENSITIVITY, -math.rad(75), math.rad(75))
    end
end)

-- Função principal de atualização da câmera que rodará a cada frame
local function updateCamera(deltaTime)
    if not humanoidRootPart then return end

    local targetCameraCFrame
    
    -- Verifica se temos um alvo travado definido no ClientState
    local lockedTargetPart = ClientState.LockedTarget

    if lockedTargetPart and typeof(lockedTargetPart) == "Instance" and lockedTargetPart:IsA("BasePart") then
        -- [[ MODO LOCK-ON ]]
        -- Para evitar a sensação da câmera "entrar na terra", nivelamos a base do jogador.
        -- Nós ignoramos a altura (Y) do inimigo para posicionar a câmera, mantendo-a sempre alta e atrás do ombro.
        local myPos = humanoidRootPart.Position
        local targetPos = lockedTargetPart.Position
        
        -- Vetor de direção completamente nivelado
        local flatLookDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z)
        if flatLookDir.Magnitude > 0 then
            flatLookDir = flatLookDir.Unit
        else
            flatLookDir = humanoidRootPart.CFrame.LookVector
        end
        
        -- Cria uma base no jogador apontando para o alvo (apenas no eixo horizontal)
        local baseCFrame = CFrame.lookAt(myPos, myPos + flatLookDir)
        
        -- Aplica o CAMERA_OFFSET relativo a essa base nivelada.
        -- A câmera ficará recuada e para a direita do personagem, e subirá um pouco no eixo Y durante o lock-on.
        local camPos = (baseCFrame * CAMERA_OFFSET).Position + Vector3.new(0, 2, 0)
        
        -- Ponto focal: miramos um pouco acima do centro do inimigo (ex: peito/cabeça) para a câmera não apontar pro chão
        local focusPos = targetPos + Vector3.new(0, 1.5, 0)
        
        -- Faz a câmera final olhar para o ponto focal a partir da nova posição calculada com o offset
        targetCameraCFrame = CFrame.lookAt(camPos, focusPos)
        
        -- Atualizamos os ângulos internos do mouse para não dar "tranco" ao destravar
        -- Pegamos a rotação da câmera final para manter a mesma inclinação que ela já estava
        local rx, ry, rz = targetCameraCFrame:ToEulerAnglesYXZ()
        cameraAngleX = ry
        cameraAngleY = rx
    else
        -- [[ MODO OVER-THE-SHOULDER NORMAL ]]
        -- 1. Matriz na posição atual do centro do personagem.
        -- 2. Aplicamos a rotação horizontal e vertical armazenadas.
        -- 3. Multiplicamos diretamente pelo CAMERA_OFFSET (que já é um CFrame) para o recuo OTS.
        targetCameraCFrame = CFrame.new(humanoidRootPart.Position) 
            * CFrame.Angles(0, cameraAngleX, 0) 
            * CFrame.Angles(cameraAngleY, 0, 0) 
            * CAMERA_OFFSET
    end

    -- [[ MATEMÁTICA DA SUAVIZAÇÃO (LERP) ]]
    -- Lerp significa "Linear Interpolation" (Interpolação Linear). É uma função que encontra um valor intermediário entre A e B.
    -- A fórmula base é: Atual + (Destino - Atual) * Alpha (onde Alpha é o nosso CAMERA_SMOOTHNESS, 0.15).
    -- Isso significa que, a cada frame, a câmera percorre 15% da distância que falta até o alvo.
    -- O resultado matemático é uma curva assintótica: o movimento é rápido no começo (quando a distância é grande)
    -- e desacelera suavemente conforme se aproxima do destino. Isso elimina o "pulo" instantâneo e gera um ótimo Game Feel!
    camera.CFrame = camera.CFrame:Lerp(targetCameraCFrame, CAMERA_SMOOTHNESS)

    -- [[ ROTAÇÃO DO PERSONAGEM (MECÂNICA SOULS) ]]
    -- Em jogos souls-like, ao se mover, o personagem rotaciona para a direção que a câmera está apontando.
    if humanoid.MoveDirection.Magnitude > 0 then
        -- Pegamos o vetor de direção para onde a câmera está olhando
        local lookDirection = camera.CFrame.LookVector
        
        -- Zeramos o eixo Y para evitar que o personagem incline para cima ou para baixo e pegamos o vetor unitário
        local targetCharacterLook = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
        
        -- Criamos um CFrame na posição do personagem, apontando para essa nova direção
        local targetCharacterCFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + targetCharacterLook)
        
        -- Usamos Lerp no HumanoidRootPart para que ele não "snappe" (vire instantaneamente) ao andar
        humanoidRootPart.CFrame = humanoidRootPart.CFrame:Lerp(targetCharacterCFrame, CHARACTER_ROTATION_SMOOTHNESS)
    end
end

-- [[ BIND TO RENDER STEP EXPLICADO ]]
-- O RunService:BindToRenderStep serve para ligar uma função à etapa de renderização ("Render Step") do Roblox.
-- Essa etapa ocorre dezenas de vezes por segundo, imediatamente antes do frame atual ser desenhado na tela.
--
-- Por que usar BindToRenderStep e não RenderStepped ou Heartbeat?
-- Ao manipular a câmera, nós precisamos garantir que o nosso código rode NA PRIORIDADE EXATA de atualização da câmera.
-- Passamos "Enum.RenderPriority.Camera.Value" para dizer ao motor: "Rode esta função no mesmo momento em que as
-- outras câmeras internas da engine seriam calculadas." Se não fizermos isso, a movimentação do personagem
-- e a câmera ficarão fora de sincronia em alguns frames, causando um efeito visual de tremulação (jittering).
RunService:BindToRenderStep("ThirdPersonCamera", Enum.RenderPriority.Camera.Value, updateCamera)
