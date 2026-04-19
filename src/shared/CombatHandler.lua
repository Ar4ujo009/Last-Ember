local RunService = game:GetService("RunService")

local CombatHandler = {}

-- [[ LÓGICA DE HITBOX POR RAYCAST (Raios) ]]
-- Como funciona: Em vez de usar uma .Touched (que é imprecisa), nós pegamos vários pontos virtuais
-- ao longo da lâmina da espada. A cada frame (quadro), traçamos uma linha invisível (Raio)
-- de onde o ponto estava no frame anterior, para onde ele está agora.
-- Se o raio esbarrar em um inimigo, registramos o acerto!
function CombatHandler.PerformHitbox(tool, duration, attackerCharacter)
    local hitHumanoids = {}
    local hitCache = {} -- Dicionário para evitar que a mesma pessoa tome dano 2 vezes no mesmo golpe (hitCache[humanoid] = true)
    
    local handle = tool:FindFirstChild("Handle")
    if not handle then
        warn("A ferramenta equipada não possui uma peça chamada 'Handle' para traçar o Raycast.")
        return hitHumanoids 
    end

    -- Quantidade de pontos ao longo da lâmina para checar. Mais pontos = hitbox mais densa,
    -- mas custa um pouco mais de processamento. 5 costuma ser perfeito para espadas médias.
    local numPoints = 5
    
    -- Função interna para pegar as posições atuais dos pontos na lâmina
    local function getBladePoints()
        local points = {}
        -- Supondo que a lâmina seja desenhada no eixo Y do Handle.
        local length = handle.Size.Y
        -- Base é o meio do Handle para baixo, Topo é o meio para cima (mude os eixos dependendo da modelagem da sua espada!)
        local basePos = handle.CFrame * Vector3.new(0, -length / 2, 0)
        local tipPos = handle.CFrame * Vector3.new(0, length / 2, 0)
        
        -- Cria pontos espaçados igualmente entre a base e o topo
        for i = 0, numPoints do
            local alpha = i / numPoints
            table.insert(points, basePos:Lerp(tipPos, alpha))
        end
        return points
    end
    
    -- Registramos as posições no momento em que o ataque iniciou
    local lastPositions = getBladePoints()
    
    -- Configuração do Raycast (Ignorar quem está batendo e a própria arma)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {attackerCharacter, tool}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local elapsedTime = 0
    
    -- Usamos um loop com Heartbeat para checar os raios frame a frame durante a duração do ataque
    while elapsedTime < duration do
        -- .Heartbeat:Wait() trava o código aqui até o próximo frame renderizar
        -- e retorna quanto tempo passou (deltaTime)
        local deltaTime = RunService.Heartbeat:Wait()
        elapsedTime = elapsedTime + deltaTime
        
        -- Pegamos a posição atualizada da espada neste novo frame
        local currentPositions = getBladePoints()
        
        -- Para cada pontinho na lâmina
        for i, currentPos in ipairs(currentPositions) do
            local lastPos = lastPositions[i]
            local direction = currentPos - lastPos -- Vetor que aponta de onde estava para onde foi
            local distance = direction.Magnitude
            
            -- Se a espada moveu o mínimo (evita criar raios de tamanho 0)
            if distance > 0.01 then
                -- Atira o raio! (De lastPos, na direção 'direction')
                local rayResult = workspace:Raycast(lastPos, direction, params)
                
                -- Se o raio bateu em algo...
                if rayResult then
                    local hitPart = rayResult.Instance
                    local hitModel = hitPart:FindFirstAncestorOfClass("Model")
                    
                    if hitModel then
                        local hitHumanoid = hitModel:FindFirstChildOfClass("Humanoid")
                        
                        -- Se bateu num Humanoid E ele ainda não foi acertado (not hitCache)
                        if hitHumanoid and not hitCache[hitHumanoid] then
                            -- Evitar que bata no próprio jogador de novo (redundância)
                            if hitModel ~= attackerCharacter then
                                
                                -- Checamos os i-frames daquele inimigo!
                                local isInvincible = hitModel:GetAttribute("IsInvincible")
                                
                                if not isInvincible then
                                    -- Registramos que ele apanhou, impedindo múltiplos acertos
                                    hitCache[hitHumanoid] = true
                                    table.insert(hitHumanoids, hitHumanoid)
                                end
                                
                            end
                        end
                    end
                end
            end
        end
        
        -- O que é atual vira passado para o próximo frame!
        lastPositions = currentPositions
    end
    
    -- Retornamos a lista de todos os que foram cortados
    return hitHumanoids
end

return CombatHandler
