local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configurações da Câmera
local CAMERA_OFFSET = Vector3.new(1.5, 3, 11) -- X positivo: ombro direito. Y: altura. Z: distância para trás
local CAMERA_SMOOTHNESS = 0.15 -- Valor para o Lerp (quanto menor, mais suave/pesado)
local CHARACTER_ROTATION_SMOOTHNESS = 0.1 -- Suavidade ao rotacionar o personagem

-- Variáveis de controle de rotação da câmera (mouse)
local cameraAngleX = 0
local cameraAngleY = 0
local MOUSE_SENSITIVITY = 0.003

-- Travar o mouse no centro da tela e ocultá-lo para controle de terceira pessoa
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

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

    -- [[ CÁLCULO DO CFRAME DA CÂMERA ]]
    -- 1. Começamos criando uma matriz (CFrame) na posição atual do centro do personagem (HumanoidRootPart).
    -- 2. Aplicamos a rotação horizontal (cameraAngleX no eixo Y).
    -- 3. Aplicamos a rotação vertical (cameraAngleY no eixo X).
    -- 4. Finalmente, multiplicamos pelo CAMERA_OFFSET. Isso projeta a câmera para a direita, cima e para trás,
    --    respeitando a rotação que acabamos de definir, criando o efeito de ficar por cima do ombro.
    local targetCameraCFrame = CFrame.new(humanoidRootPart.Position) 
        * CFrame.Angles(0, cameraAngleX, 0) 
        * CFrame.Angles(cameraAngleY, 0, 0) 
        * CFrame.new(CAMERA_OFFSET)

    -- [[ SUAVIZAÇÃO COM LERP ]]
    -- Em vez de atribuir o `targetCameraCFrame` diretamente à câmera (o que faria o movimento ser instantâneo),
    -- usamos a função :Lerp() (Linear Interpolation). Ela move a câmera gradualmente de onde ela está agora
    -- em direção ao alvo usando um fator (CAMERA_SMOOTHNESS). Isso gera um atraso agradável, passando a sensação de peso.
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
