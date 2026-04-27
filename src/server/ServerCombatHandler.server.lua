local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local HIT_SOUND_ID = "rbxassetid://0"

-- O servidor garante que os RemoteEvents existam, criando-os caso o Rojo ou o Studio não o tenham feito.
local HealEvent = ReplicatedStorage:FindFirstChild("HealEvent")
if not HealEvent then
    HealEvent = Instance.new("RemoteEvent")
    HealEvent.Name = "HealEvent"
    HealEvent.Parent = ReplicatedStorage
    print("Servidor: HealEvent criado no ReplicatedStorage com sucesso!")
end

local AttackEvent = ReplicatedStorage:FindFirstChild("AttackEvent")
if not AttackEvent then
    AttackEvent = Instance.new("RemoteEvent")
    AttackEvent.Name = "AttackEvent"
    AttackEvent.Parent = ReplicatedStorage
    print("Servidor: AttackEvent criado no ReplicatedStorage com sucesso!")
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

AttackEvent.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart or humanoid.Health <= 0 then return end

    -- Criar Hitbox na frente do jogador (4x5x4, 3 studs à frente)
    local hitboxSize = Vector3.new(4, 5, 4)
    local hitboxCFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
    
    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = {character}
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    local partsInBox = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)
    
    local hitEnemies = {}

    for _, part in ipairs(partsInBox) do
        local enemyModel = part:FindFirstAncestorOfClass("Model")
        
        if enemyModel and enemyModel ~= character and not hitEnemies[enemyModel] then
            if CollectionService:HasTag(enemyModel, "Enemy") then
                local enemyHumanoid = enemyModel:FindFirstChildOfClass("Humanoid")
                
                -- Se o inimigo for invencível (esquiva, etc), ignorar o dano
                if enemyHumanoid and enemyHumanoid.Health > 0 and not enemyModel:GetAttribute("IsInvincible") then
                    hitEnemies[enemyModel] = true
                    enemyHumanoid:TakeDamage(20)
                    print("Servidor: " .. player.Name .. " causou 20 de dano em " .. enemyModel.Name)
                    
                    -- Feedback de Impacto (Som)
                    local enemyRoot = enemyModel:FindFirstChild("HumanoidRootPart")
                    if enemyRoot then
                        local hitSound = Instance.new("Sound")
                        hitSound.SoundId = HIT_SOUND_ID
                        hitSound.Parent = enemyRoot
                        hitSound:Play()
                        Debris:AddItem(hitSound, 2)
                    end
                    
                    -- Feedback Visual (Highlight vermelho)
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.4
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineTransparency = 0.2
                    highlight.Parent = enemyModel
                    Debris:AddItem(highlight, 0.2)
                end
            end
        end
    end
end)
