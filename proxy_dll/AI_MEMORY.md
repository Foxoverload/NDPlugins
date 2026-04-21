# 🧠 AI Memory — Naruto Destiny Projects

> **Arquivo de contexto para assistentes AI.** Leia este arquivo antes de trabalhar em qualquer
> projeto neste repositorio. Ele contem a arquitetura, decisoes tecnicas, e estado atual de
> cada sub-projeto.

---

## 📂 Estrutura do Workspace

```
ND Fichas/                          # Workspace raiz (monorepo)
├── Ficha ND/                       # [PROJETO 1] Plugin de ficha de personagem
│   ├── FichaND.lfm                 # Layout principal (~2272 linhas, XML + Lua)
│   ├── exportar.lua                # Exportacao HTML da ficha
│   ├── module.xml                  # Manifesto do plugin Firecast
│   ├── Imagens/                    # Assets de imagem (elementos, etc.)
│   └── images/                     # Banners e backgrounds
│
├── Plugin ND/                      # [PROJETO 2] Combat Tracker / Automatizador
│   ├── NDCombatPlugin.lfm          # Plugin principal (~1744 linhas, XML + Lua)
│   ├── module.xml                  # Manifesto do plugin
│   └── README.md                   # Documentacao
│
├── proxy_dll/                      # [PROJETO 3] Firecast Script Extender (FCEXT)
│   ├── lua54x64_proxy.c            # Proxy DLL em C (~742 linhas)
│   ├── lua54x64.def                # Export definitions
│   ├── fcext_ui.lua                # Biblioteca UI de alto nivel (~500 linhas)
│   ├── build.bat                   # Compilacao (usa Zig CC)
│   ├── install.bat                 # Instala proxy no Firecast
│   ├── uninstall.bat               # Remove proxy
│   └── README.md                   # Documentacao
│
├── ND Sistema/                     # Regras e documentacao do sistema RPG
├── docs/                           # Screenshots e banner do README
├── README.md                       # README principal (Ficha ND)
├── lua_fix.py                      # Script de correcao de encoding
└── .gitignore                      # Git ignore
```

---

## 🎯 Projeto 1: Ficha ND (Plugin de Ficha de Personagem)

### Tecnologia
- **LFM** (Layout Form Markup) — XML do Firecast para interfaces
- **Lua** embutido em `<script>` tags dentro do XML
- **NodeDatabase (NDB)** — Persistencia via `sheet.campo`
- **Firecast SDK 3** — `rdk.exe` para compilar

### Arquivo Principal: `FichaND.lfm`
- ~2272 linhas
- Form type: `sheetTemplate`
- Data type: `br.com.rrpg.Ficha_Naruto_Destiny`
- 4 abas: Ficha Principal, Tecnicas, Inventario, Historia

### Calculos Automaticos
- **Nivel** = (soma core attributes / 2) - 7
- **Rank Shinobi** = baseado no nivel (Estudante → Fushi)
- **Pontos de Jutsu** = nivel x 100 (parser de richEdit)
- **Traits** = 450 + (nivel x 10), parser `(XXX pontos de Trait)`
- **Combinacao Elemental** = detecta 2-3 elementos selecionados
- **Atributos de Combate** = core + bonus + bonus_trait

### Compilacao
```batch
cd "Ficha ND"
"C:\Users\aaron\AppData\Local\FirecastSDK3\rdk.exe" -i    # Compila e instala
"C:\Users\aaron\AppData\Local\FirecastSDK3\rdk.exe" -c    # Apenas compila (.rpk)
```

### Campos NDB Importantes
```
nome, idade, sexo, nivel, rank_shinobi
forca, agilidade, constituicao, destreza, controle_chakra, concentracao, inteligencia, forcaesp
taijutsu, bukijutsu, ninjutsu, genjutsu, esquiva, bloqueio_fisico, reflexo, iniciativa
pv, pchakra, pestamina, pv_atual, pchakra_atual, pestamina_atual
elem_fogo, elem_agua, elem_terra, elem_vento, elem_raio
traits (richEdit), trait_resumo
```

---

## ⚔️ Projeto 2: Combat Tracker (Plugin ND)

### Arquivo Principal: `NDCombatPlugin.lfm`
- ~1744 linhas
- Form type: `tablesDock`
- Registrado como `frmNDCombatPlugin`
- Aparece na aba lateral do Firecast

### Estado do Combate (variaveis Lua locais)
```lua
combatentes = {}  -- Array de {nome, ini, fof, efeitos={}}
turnoAtual = 0
rodadaAtual = 0
```

### Funcoes Principais
| Funcao | Descricao |
|---|---|
| `adicionarJogadores()` | Importa jogadores da mesa |
| `adicionarNPC()` | Adiciona NPC manualmente |
| `rolarIniciativas()` | Rola 1d20+ini para todos |
| `proximoTurno()` | Avanca turno, processa efeitos |
| `limparTracker()` | Reseta combate |
| `abrirPopupTracker()` | Abre popup nativo (FCEXT) |
| `explorarGUI()` | Dev: dump da API GUI |
| `fichaDemo()` | Dev: demonstra fcext_ui.lua |

### FCEXT Integration
- Botao "F" → `testarFcext()` → `abrirPopupTracker()`
- Botao "G" → `explorarGUI()` (dump API)
- Botao "D" → `fichaDemo()` (demo UI library)
- Funcoes de combate sao forward-declared e convertidas de `local function` para assignment form

### Importante: Forward Declarations
```lua
-- No topo do script (antes do popup code)
local toggleNpcPanel, adicionarJogadores, rolarIniciativas;
local proximoTurno, limparTracker, removerCombatente;

-- Depois, as funcoes sao definidas como assignments:
toggleNpcPanel = function() ... end
```
Isso e necessario porque `abrirPopupTracker()` referencia essas funcoes, mas e definida antes delas no fonte.

---

## 🔧 Projeto 3: Firecast Script Extender (FCEXT) v2.1

### Arquivo Principal: `lua54x64_proxy.c`
- 742 linhas de C
- Proxy DLL que intercepta Lua 5.4

### Mecanismo de Injecao
1. `DllMain` carrega `lua54x64_original.dll`
2. Resolve 154 funcoes Lua via `GetProcAddress`
3. Hook `luaL_openlibs()` — registra modulo `fcext`
4. Hook `lua_pcallk()` — registra em novos Lua states
5. Registro triplo: `_G.fcext`, `_LOADED.fcext`, `package.loaded.fcext`
6. `.def` file forwards 153 funcoes diretamente

### Funcoes fcext
```
readFile, writeFile, fileExists, listDir      # Filesystem
clipboardGet, clipboardSet                     # Clipboard
log, getTime, sleep, exec, version             # Utilidades
sharedGet, sharedSet                           # Cross-state KV
globals                                        # Discovery
overlayCreate, overlaySetLine, overlayShow,    # Win32 Overlay
overlayClose, overlaySetTitle
```

### GUI API Descoberta (93 funcoes)
A API GUI interna do Firecast tem 93 funcoes e 19+ tipos de controle. Todas sao acessiveis via a global `GUI` no ambiente Lua interno. O FCEXT expoe essa global para plugins sandboxed.

Controles testados e funcionais:
```
PopupForm, Popup, ScrollBox, Label, Button, Edit, Rectangle,
Layout, CheckBox, ComboBox, ProgressBar, HorzLine, Image,
TextEditor, RichEdit, TabControl, Timer, ColorComboBox,
Path, Frame, DataLink
```

Extras existentes (nao testados):
```
ActivityIndicator, RadioButton, FlowLayout, FlowLineBreak,
FlowPart, DataScopeBox, Container, Col, Row, Form,
Drag, Drop, GridRecordList, ImageCheckBox, InertialMovement
```

### fcext_ui.lua — Biblioteca de Componentes
Carregada via: `local ui = load(fcext.readFile("caminho/fcext_ui.lua"))()`

18 componentes:
```
ui.window()      ui.section()     ui.card()        ui.statBar()
ui.field()       ui.attribute()   ui.banner()      ui.badge()
ui.grid()        ui.label()       ui.button()      ui.image()
ui.separator()   ui.spacer()      ui.checkRow()    ui.timer()
ui.dataLink()    ui.toast()
```

Sistema de temas: `ui.setTheme("naruto")` ou `ui.setTheme("dark")`

### Compilacao da DLL
```batch
cd proxy_dll
build.bat        # Requer Zig CC no PATH
install.bat      # Copia para pasta do Firecast (fecha Firecast primeiro!)
```

### Arquivos Gerados pelo FCEXT (na pasta do Firecast)
```
fcext_log.txt              # Log de debug
fcext_globals.txt          # Dump de todas as globals Lua
fcext_firecast_api.txt     # Dump profundo da API Firecast
fcext_gui_dump.txt         # Dump de todos os controles GUI
```

---

## 🔗 Dependencias entre Projetos

```
Ficha ND ←── usa dados de ──→ Combat Tracker
    │                              │
    └──── ambos dependem de ──────→ FCEXT v2.1
                                    │
                                    └── fcext_ui.lua
```

- **Ficha ND** funciona SEM FCEXT (puro LFM)
- **Combat Tracker** funciona parcialmente SEM FCEXT (tabela LFM basica)
- **Popup nativo e UI avancada** requerem FCEXT instalado
- **fcext_ui.lua** deve estar em `C:\Users\aaron\AppData\Local\Firecast\`

---

## 🛠️ Ambiente de Desenvolvimento

| Item | Valor |
|---|---|
| OS | Windows 10/11 x64 |
| Firecast | Versao com Lua 5.4 |
| SDK | `C:\Users\aaron\AppData\Local\FirecastSDK3\rdk.exe` |
| Compilador DLL | Zig CC (x86_64-windows-gnu) |
| Firecast Dir | `C:\Users\aaron\AppData\Local\Firecast\` |
| Build Ficha | `rdk.exe -i` na pasta `Ficha ND\` |
| Build Tracker | `rdk.exe -i` na pasta `Plugin ND\` |
| Build DLL | `build.bat` na pasta `proxy_dll\` |

### Regras de Encoding para LFM
- Arquivos `.lfm` sao XML — caracteres especiais dentro de `<script>` devem ser ASCII
- `&` → usar `e` ou escape XML `&amp;`
- Acentos (ã, é, ê, õ, etc.) podem causar falha no RDK — usar ASCII no Lua
- Acentos no XML (atributos como `text="..."`) funcionam normalmente

### Workflow de Teste
1. Editar `.lfm` ou `.c`
2. Compilar com `rdk.exe -i` (plugins) ou `build.bat` (DLL)
3. No Firecast: recarregar mesa (Ctrl+F5 ou reabrir)
4. Testar funcionalidade
5. Verificar `fcext_log.txt` para debug

---

## 📋 Estado Atual e Proximos Passos

### Concluido
- [x] FCEXT v2.1 com 93 funcoes GUI desbloqueadas
- [x] Popup nativo do Combat Tracker funcionando
- [x] Botoes do popup conectados as funcoes de combate
- [x] fcext_ui.lua com 18 componentes
- [x] Ficha Demo funcional via fichaDemo()
- [x] Deep dump de toda a API GUI

### Em Andamento
- [ ] Data binding popup ↔ NDB (sheet) para ficha real
- [ ] Path/SVG para graficos vetoriais (pentagono de atributos)
- [ ] Frame com URL para HTML embutido
- [ ] Animacoes via Timer
- [ ] Migrar FichaND.lfm para usar fcext_ui

### Futuro
- [ ] WebView2 embedding para HTML/CSS/JS completo
- [ ] GDI+ canvas para graficos avancados
- [ ] Auto-updater para plugins
