# ⚔️ Naruto Destiny Combat Tracker

<p align="center">
  <strong>Plugin de combate automatizado para o sistema Naruto Destiny no <a href="https://firecast.app">Firecast</a></strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0-22C55E?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/Firecast-SDK3-4FC3F7?style=for-the-badge" alt="Firecast"/>
  <img src="https://img.shields.io/badge/FCEXT-v2.1-AB47BC?style=for-the-badge" alt="FCEXT"/>
</p>

---

## 📖 Sobre

O **Combat Tracker** e um plugin para o Firecast que automatiza o gerenciamento de combate no sistema **Naruto Destiny**. Ele gerencia turnos, iniciativa, efeitos ativos e envia mensagens automaticas no chat da mesa.

Utiliza o **Firecast Script Extender (FCEXT)** para renderizar uma interface nativa avanccada via popup, superando as limitacoes do sistema LFM padrao.

---

## ✨ Funcionalidades

### 🎯 Gerenciamento de Combate
- **Controle de Turnos** — Avanco e retrocesso de turnos com mensagens no chat
- **Controle de Rodadas** — Contagem automatica de rodadas
- **Iniciativa** — Rolagem automatica com formula `1d20 + ini_combate`
- **Ordenacao** — Combatentes ordenados por iniciativa (maior primeiro)

### 👥 Combatentes
- **Adicionar Jogadores** — Importa automaticamente todos os jogadores da mesa
- **Adicionar NPCs** — Painel para inserir NPCs manualmente (nome + iniciativa)
- **Remover** — Botao X por combatente
- **Friend or Foe (FoF)** — Indicador verde/amarelo/vermelho

### 🎭 Efeitos Ativos
- **Sistema de Efeitos** — Adicionar efeitos com duracao, bonus e dano por rodada
- **Processamento Automatico** — Efeitos processados a cada nova rodada
- **Expiracao** — Efeitos expiram automaticamente e notificam no chat
- **Sharingan** — Comando especial `/sharingan C|B|A` com mecanica completa

### 🖥️ Interface Nativa (via FCEXT)
- **Popup Flutuante** — Dashboard de combate em janela nativa do Firecast
- **Botoes Interativos** — +, Roll, Add Players, Clear, Next Turn
- **Atualizacao Dinamica** — UI atualiza automaticamente ao mudar estado

---

## 🔧 Comandos de Chat

| Comando | Descricao |
|---|---|
| `/nd ajuda` | Lista todos os comandos disponiveis |
| `/nd ataque [nome]` | Rola ataque contra um alvo |
| `/nd defesa [tipo]` | Rola defesa (esquiva, bloqueio, etc.) |
| `/nd sharingan [C\|B\|A]` | Ativa Sharingan com rank especifico |
| `/nd desfazer sharingan` | Desativa Sharingan ativo |

---

## 📥 Instalacao

### Requisitos
- [Firecast](https://firecast.app) instalado
- [Firecast SDK 3](https://firecast.app/sdk3/) para desenvolvimento
- **FCEXT v2.1** instalado (para interface nativa)

### Compilar e Instalar
```batch
cd "Plugin ND"
"C:\Users\...\FirecastSDK3\rdk.exe" -i
```

O flag `-i` compila e instala automaticamente no Firecast.

### Arquivo Pre-compilado
Baixe `NarutoDestinyPlugin.rpk` e importe via Firecast > Plugins > Instalar.

---

## 📁 Estrutura

```
Plugin ND/
├── NDCombatPlugin.lfm   # Plugin principal (XML + Lua, ~1700 linhas)
├── module.xml           # Manifesto do plugin
├── output/              # Build output (.rpk)
└── sdk/                 # Firecast SDK local
```

### Arquitetura do Codigo (NDCombatPlugin.lfm)

```
┌─────────────────────────────────────────────────┐
│ Forward Declarations                             │
│ (toggleNpcPanel, rolarIniciativas, etc.)         │
├─────────────────────────────────────────────────┤
│ explorarGUI()     — API Explorer (dev tool)      │
│ fichaDemo()       — UI Library demo              │
├─────────────────────────────────────────────────┤
│ abrirPopupTracker() — Popup nativo via GUI API   │
│ atualizarPopup()    — Refresh do popup           │
├─────────────────────────────────────────────────┤
│ renderizarTracker() — Renderiza na tabela LFM    │
├─────────────────────────────────────────────────┤
│ Combat Logic                                     │
│ ├── adicionarJogadores()                         │
│ ├── rolarIniciativas()                           │
│ ├── proximoTurno() / turnoAnterior()             │
│ ├── limparTracker()                              │
│ ├── removerCombatente()                          │
│ ├── adicionarNPC()                               │
│ └── adicionarEfeito() / processarEfeitos()       │
├─────────────────────────────────────────────────┤
│ Chat Commands Parser (/nd ...)                   │
├─────────────────────────────────────────────────┤
│ XML Layout (header, NPC input, tracker table)    │
└─────────────────────────────────────────────────┘
```

---

## 🔗 Dependencias

- **Ficha ND** — Le dados dos personagens (nome, atributos de combate)
- **FCEXT v2.1** — Interface nativa popup (opcional, fallback para LFM)
- **fcext_ui.lua** — Biblioteca de componentes UI (para fichaDemo)

---

## 📄 Licenca

Uso livre para a comunidade Naruto Destiny.
