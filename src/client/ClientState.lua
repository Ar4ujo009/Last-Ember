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
    
    -- Itens equipados nos slots da Hotbar (Estilo D-Pad)
    EquippedItems = {
        Top = "Magia",
        Bottom = "Poção",
        Left = "Escudo_Madeira",
        Right = "Espada_Iniciante"
    }
}

return ClientState
