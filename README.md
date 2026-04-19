# 🔥 Last Ember - Protótipo RPG Soulslike

![Roblox](https://img.shields.io/badge/Roblox-Studio-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![Luau](https://img.shields.io/badge/Luau-Scripting-000075?style=for-the-badge)
![Rojo](https://img.shields.io/badge/Rojo-Workflow-FF4B4B?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-success?style=for-the-badge)

> *"No fim dos tempos, apenas a última brasa restará para iluminar a escuridão."*

**Last Ember** é um protótipo de RPG de Ação e Fantasia Sombria (Soulslike) desenvolvido na engine do Roblox. O projeto tem foco em combate tático, gerenciamento rigoroso de estamina e uma atmosfera imersiva. 

---

## 🎮 Visão Geral e Pitch

O jogador controla o **Errante**, um guerreiro que deve explorar um mundo devastado e enfrentar inimigos implacáveis. Diferente da maioria dos jogos na plataforma, *Last Ember* não perdoa erros: cada ataque, esquiva e bloqueio deve ser calculado. O jogo utiliza arquitetura moderna orientada a eventos e gerenciamento de estado (`ClientState`) para garantir um código limpo e escalável.


---

## ✨ Principais Mecânicas (Features)

Abaixo estão as mecânicas já implementadas neste protótipo:

* **🗡️ Combate Preciso:** Hitboxes baseadas em `Spatial Query` (`GetPartsInPart`) com validação e aplicação de dano seguras via Servidor (Client-Server boundary).
* **💨 Sistema de Esquiva (Dash):** Rolamentos com frames de invencibilidade (i-frames) calculados, exigindo timing perfeito.
* **🫀 Gerenciamento de Stamina:** Interface dinâmica com barra que consome fôlego para ações (ataque/esquiva) e possui regeneração inteligente.
* **🎯 Lock-on System (Trava de Mira):** Câmera *Over-the-shoulder* com interpolação suave (`Lerp`) focada no inimigo mais próximo, ocultando o ponteiro do mouse para máxima imersão.
* **🧠 Client State Manager:** Arquitetura limpa para evitar conflitos de scripts, garantindo que a câmera e os controles conversem perfeitamente.

---

## 🛠️ Tecnologias e Ferramentas

| Tecnologia | Uso |
| :--- | :--- |
| **Roblox Studio** | Engine principal de física e renderização |
| **Luau** | Linguagem de programação para scripts (Client/Server) |
| **Rojo** | Sincronização de código com sistema de arquivos local |
| **Git / GitHub** | Controle de versão e versionamento semântico |
| **Google Antigravity** | Assistente de IA para pair programming e geração de lógicas |

---

## 🚀 Como Rodar o Projeto (Setup)

Este projeto foi construído utilizando o fluxo de trabalho do **Rojo**. Para testar o jogo na sua máquina:

1. Clone este repositório:
   ```bash
   git clone [https://github.com/](https://github.com/)Ar4ujo009/Last-Ember.git

   ------
   Desenvolvido por Rafael Farias de Araujo / Ar4ujo009 | Portfólio de Game Development