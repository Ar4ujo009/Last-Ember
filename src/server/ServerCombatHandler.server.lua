local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- O servidor garante que o RemoteEvent exista, criando-o caso o Rojo ou o Studio não o tenham feito.
local HealEvent = ReplicatedStorage:FindFirstChild("HealEvent")
if not HealEvent then
    HealEvent = Instance.new("RemoteEvent")
    HealEvent.Name = "HealEvent"
    HealEvent.Parent = ReplicatedStorage
    print("Servidor: HealEvent criado no ReplicatedStorage com sucesso!")
end

HealEvent.OnServerEvent:Connect(function(player, healAmount)
    -- Verifica se o valor de cura é um número
    if type(healAmount) ~= "number" then
        return warn("Tentativa de cura inválida enviada por: " .. player.Name)
    end

    -- Prevenção básica contra valores negativos que reduziriam a vida
    if healAmount <= 0 then
        return warn("Valor de cura não pode ser negativo ou zero. Jogador: " .. player.Name)
    end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Aplica a cura com segurança limitando a vida máxima
    humanoid.Health = math.clamp(humanoid.Health + healAmount, 0, humanoid.MaxHealth)
    print("SERVIDOR: " .. player.Name .. " curou " .. healAmount .. " de HP!")
end)
