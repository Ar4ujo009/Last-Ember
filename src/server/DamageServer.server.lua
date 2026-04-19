local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================
-- INICIALIZAÇÃO DE REDE
-- ==========================================
-- O servidor garante que o RemoteEvent exista, criando-o caso o Rojo ou o Studio não o tenham feito.
local DamageEvent = ReplicatedStorage:FindFirstChild("DamageEvent")
if not DamageEvent then
    DamageEvent = Instance.new("RemoteEvent")
    DamageEvent.Name = "DamageEvent"
    DamageEvent.Parent = ReplicatedStorage
    print("Servidor: DamageEvent criado no ReplicatedStorage com sucesso!")
end

-- ==========================================
-- O JUIZ: SERVIDOR (Server-Sided Logic)
-- ==========================================
DamageEvent.OnServerEvent:Connect(function(player, targetHumanoid, damageAmount)
    -- 1. O alvo existe e o dano enviado é realmente um número?
    if not targetHumanoid or type(damageAmount) ~= "number" then
        return warn("Tentativa de dano corrompida enviada por: " .. player.Name)
    end
    
    -- 2. Anti-Suicídio: O jogador está tentando bater nele mesmo?
    local attackerCharacter = player.Character
    if targetHumanoid.Parent == attackerCharacter then
        return warn(player.Name .. " tentou atacar a si mesmo!")
    end

    -- Aplica o dano no alvo!
    targetHumanoid:TakeDamage(damageAmount)
    print("SERVIDOR: " .. player.Name .. " causou " .. damageAmount .. " de dano em " .. targetHumanoid.Parent.Name)
end)
