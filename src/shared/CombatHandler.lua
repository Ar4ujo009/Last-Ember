local RunService = game:GetService("RunService")

local CombatHandler = {}

-- [[ LÓGICA DE HITBOX POR SPATIAL QUERY (GetPartsInPart) ]]
-- Como funciona: Raycast falha se a espada nascer já "dentro" do inimigo (pois o raio começa e termina dentro dele).
-- O GetPartsInPart resolve isso verificando fisicamente a caixa de colisão da espada contra o mundo a cada frame.
function CombatHandler.PerformHitbox(tool, duration, attackerCharacter)
    local hitHumanoids = {}
    local hitCache = {} -- Dicionário para evitar que a mesma pessoa tome dano 2 vezes no mesmo golpe
    
    local handle = tool:FindFirstChild("Handle")
    if not handle then
        warn("A ferramenta equipada não possui uma peça chamada 'Handle' para o Spatial Query.")
        return hitHumanoids 
    end

    -- Configuração do OverlapParams (Spatial Query)
    -- Semelhante ao Raycast, mas focado em volume (caixa de colisão)
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {attackerCharacter, tool} -- Ignora quem bateu e a própria arma
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local elapsedTime = 0
    
    -- Usamos um loop com Heartbeat para checar interseções frame a frame durante o ataque
    while elapsedTime < duration do
        local deltaTime = RunService.Heartbeat:Wait()
        elapsedTime = elapsedTime + deltaTime
        
        -- Atira a Query! O motor verifica todas as peças tocando fisicamente no "Handle" neste exato frame
        local partsInHandle = workspace:GetPartsInPart(handle, params)
        
        -- Para cada peça encontrada que está tocando a espada
        for _, hitPart in ipairs(partsInHandle) do
            local hitModel = hitPart:FindFirstAncestorOfClass("Model")
            
            if hitModel then
                local hitHumanoid = hitModel:FindFirstChildOfClass("Humanoid")
                
                -- Se achou um Humanoid e ele ainda não foi acertado
                if hitHumanoid and not hitCache[hitHumanoid] then
                    -- Evitar que bata no próprio jogador
                    if hitModel ~= attackerCharacter then
                        
                        -- Checamos os i-frames daquele inimigo!
                        local isInvincible = hitModel:GetAttribute("IsInvincible")
                        
                        if not isInvincible then
                            -- Registramos que ele apanhou, impedindo múltiplos acertos no mesmo golpe
                            hitCache[hitHumanoid] = true
                            table.insert(hitHumanoids, hitHumanoid)
                        end
                        
                    end
                end
            end
        end
    end
    
    -- Retornamos a lista de todos os que foram cortados
    return hitHumanoids
end

return CombatHandler
