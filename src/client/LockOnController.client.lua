local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local lockedTarget = nil
local lockOnGui = nil
local lockOnConnection = nil
local LOCK_ON_RADIUS = 100
local UNLOCK_RADIUS = 150

-- Cria o indicador visual (BillboardGui)
local function createLockOnIndicator(targetRoot)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LockOnIndicator"
	
	-- O BillboardGui é anexado ao alvo travado no HumanoidRootPart dele
	billboard.Adornee = targetRoot
	billboard.Size = UDim2.new(0, 15, 0, 15)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Um ponto quadrado vermelho
	frame.BackgroundTransparency = 0.2
	frame.Rotation = 45 -- Deixamos em formato de losango para parecer uma mira
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	billboard.Parent = player:WaitForChild("PlayerGui")
	
	return billboard
end

-- Destrava do alvo atual
local function unlockTarget()
	if lockedTarget then
		-- Parar de checar distância e vida
		if lockOnConnection then
			lockOnConnection:Disconnect()
			lockOnConnection = nil
		end
		
		lockedTarget = nil
		-- Remove do ClientState, comunicando aos outros scripts que não há mais alvo
		ClientState.LockedTarget = nil
		
		if lockOnGui then
			lockOnGui:Destroy()
			lockOnGui = nil
		end
	end
end

-- Busca o melhor alvo considerando distância e proximidade ao centro da tela
local function findBestTarget()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
	
	local playerRoot = character.HumanoidRootPart
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	
	local bestTarget = nil
	local bestScore = math.huge -- Menor pontuação é melhor
	
	-- Procura em todo o Workspace por modelos que não sejam o jogador
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= character then
			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			local rootPart = obj:FindFirstChild("HumanoidRootPart")
			
			if humanoid and rootPart and humanoid.Health > 0 then
				local distance = (playerRoot.Position - rootPart.Position).Magnitude
				
				if distance <= LOCK_ON_RADIUS then
					-- Direção da câmera até o inimigo
					local directionToTarget = (rootPart.Position - camera.CFrame.Position).Unit
					local cameraLookVector = camera.CFrame.LookVector
					
					--[[ 
						ESTUDO DO DOT PRODUCT (Produto Escalar):
						O Dot Product entre dois vetores unitários (tamanho 1) retorna um valor de -1 a 1.
						-  1: Os dois vetores apontam exatamente para a mesma direção (0 graus de diferença).
						-  0: Os vetores são perpendiculares (90 graus).
						- -1: Os vetores apontam para direções opostas (180 graus).
						
						Ao exigir que dotProduct > 0.5, o inimigo precisa estar
						dentro de um cone de aproximadamente 60 graus a partir do centro da tela.
					]]
					local dotProduct = cameraLookVector:Dot(directionToTarget)
					
					if dotProduct > 0.5 then
						-- Score baseia-se na distância + penalidade por estar fora do centro
						-- dotProduct perfeito é 1. Se for menor, a penalidade aumenta.
						-- Multiplicamos por 100 para que o peso do ângulo tenha impacto frente à distância em studs.
						local anglePenalty = (1 - dotProduct) * 100
						local score = distance + anglePenalty
						
						if score < bestScore then
							bestScore = score
							bestTarget = obj
						end
					end
				end
			end
		end
	end
	
	return bestTarget
end

-- Verifica as condições de destravamento automático
local function checkAutoUnlock()
	if not lockedTarget then return end
	
	local targetHumanoid = lockedTarget:FindFirstChildOfClass("Humanoid")
	local targetRoot = lockedTarget:FindFirstChild("HumanoidRootPart")
	
	local character = player.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	
	-- Destravar Automático: Se o inimigo morrer ou desaparecer
	if not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or not playerRoot then
		unlockTarget()
		return
	end
	
	-- Destravar Automático: Se ficar muito longe (mais de 60 studs)
	local distance = (playerRoot.Position - targetRoot.Position).Magnitude
	if distance > UNLOCK_RADIUS then
		unlockTarget()
		return
	end
end

-- Ativação via teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Usando LeftControl conforme solicitado
	if input.KeyCode == Enum.KeyCode.LeftControl then
		if lockedTarget then
			-- Se já está com alvo, destrava
			unlockTarget()
		else
			-- Se não está travado, busca o melhor alvo no campo de visão
			local target = findBestTarget()
			if target then
				lockedTarget = target
				local targetRoot = target:FindFirstChild("HumanoidRootPart")
				
				if targetRoot then
					lockOnGui = createLockOnIndicator(targetRoot)
					
					-- Define no ClientState para o CameraHandler poder ler
					ClientState.LockedTarget = targetRoot
					
					-- Liga o loop apenas para o destravamento automático
					lockOnConnection = RunService.Heartbeat:Connect(checkAutoUnlock)
				end
			end
		end
	end
end)
