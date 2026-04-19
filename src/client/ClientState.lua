-- ==========================================
-- CLIENT STATE MANAGER
-- ==========================================
-- Armazena e compartilha dados locais essenciais do jogador.
-- Acessível por qualquer LocalScript que precise ler ou alterar estado.

local ClientState = {
    LockedTarget = nil,      -- Inimigo atualmente travado pela câmera
    Mana = 100,              -- Pontos de Foco (FP) atuais
    MaxMana = 100,           -- Pontos de Foco (FP) máximos
    IsGuarding = false,      -- Indica se o jogador está levantando o escudo
    IsDrinking = false,      -- Indica se o jogador está bebendo um frasco
    
    CurrentFlasks = 3,       -- Frascos de cura atuais
    MaxFlasks = 3,           -- Frascos de cura máximos
    
    -- Itens equipados nos slots da Hotbar (Estilo D-Pad)
    EquippedItems = {
        Top = "Magia",
        Bottom = "Frasco_de_Vida",
        Left = "Escudo_Madeira",
        Right = "Espada_Iniciante"
    }
}

return ClientState
