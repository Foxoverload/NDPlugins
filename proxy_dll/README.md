# 🔧 Firecast Script Extender (FCEXT) v2.1

<p align="center">
  <strong>Proxy DLL que remove as limitações do sandbox Lua do <a href="https://firecast.app">Firecast</a>, expondo APIs nativas para criação de plugins ilimitados.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.1-FF6B35?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/Lua-5.4-2C2D72?style=for-the-badge&logo=lua" alt="Lua"/>
  <img src="https://img.shields.io/badge/Windows-x64-0078D6?style=for-the-badge&logo=windows" alt="Windows"/>
</p>

---

## 📖 Sobre

O Firecast usa **Lua 5.4** para scripting de plugins, mas o ambiente é **sandboxed** — sem acesso a filesystem, GUI programática, clipboard, etc.

O FCEXT é uma **DLL proxy** que intercepta o carregamento do Lua para injetar:
- Módulo `fcext` com funções de sistema (filesystem, clipboard, etc.)
- Acesso à **API GUI interna** do Firecast (93 funções, 19+ controles)
- Biblioteca `fcext_ui.lua` com componentes de alto nível
- Estado compartilhado entre instâncias Lua (cross-state)

```
Firecast.exe → lua54x64.dll (PROXY) → lua54x64_original.dll
                     │
                     ├── Módulo "fcext" (filesystem, clipboard, overlay)
                     ├── Acesso GUI API (newPopupForm, newLabel, etc.)
                     └── fcext_ui.lua (18 componentes UI)
```

---

## 🎯 Capacidades

### API GUI Interna Desbloqueada (93 funções)

| Categoria | Controles |
|---|---|
| **Janelas** | `PopupForm`, `Popup`, `Form` |
| **Layout** | `Layout`, `ScrollBox`, `FlowLayout`, `FlowPart`, `Container` |
| **Texto** | `Label`, `Edit`, `TextEditor`, `RichEdit` |
| **Controles** | `Button`, `CheckBox`, `RadioButton`, `ComboBox`, `ColorComboBox`, `ImageCheckBox` |
| **Visuais** | `Rectangle`, `Path`, `Image`, `HorzLine`, `ProgressBar` |
| **Dados** | `DataLink`, `DataScopeBox`, `RecordList`, `GridRecordList` |
| **Navegacao** | `TabControl`, `Tab`, `Frame` |
| **Utilidades** | `Timer`, `Drag`, `Drop`, `ActivityIndicator`, `InertialMovement` |

### Biblioteca fcext_ui.lua (18 componentes)

```lua
local ui = load(fcext.readFile("caminho/fcext_ui.lua"))()

-- Janela com scroll
local popup = ui.window({title = "Minha Ficha", width = 800, height = 600})

-- Seções estilizadas
ui.section(content, {text = "Status"})

-- Barras de HP/Chakra/Stamina com ProgressBar
ui.statBar(content, {label = "HP", current = 500, max = 1000, color = "#EF4444"})

-- Campos com label + edit
ui.field(content, {label = "Nome", field = "nome", placeholder = "Digite..."})

-- Cards, badges, grids, imagens, timers, etc.
ui.card(content, {title = "Rank", height = 100})
ui.badge(row, {text = "Katon", bgColor = "#EA580C"})
ui.grid(content, {cols = 2, totalWidth = 800})
```

### Funções do Módulo fcext

| Categoria | Funções |
|---|---|
| **Filesystem** | `readFile`, `writeFile`, `fileExists`, `listDir` |
| **Clipboard** | `clipboardGet`, `clipboardSet` |
| **Sistema** | `log`, `getTime`, `sleep`, `exec`, `version` |
| **Overlay** | `overlayCreate`, `overlaySetLine`, `overlayShow`, `overlayClose` |
| **Shared State** | `sharedGet`, `sharedSet` (cross Lua-state KV store) |
| **Discovery** | `globals` (dump de todas as globals do Firecast) |

---

## 📥 Instalacao

### Requisitos
- Windows 10/11 (64-bit)
- Firecast instalado
- Visual Studio / Zig para compilar (ou use DLL pre-compilada)

### Compilar
```batch
cd proxy_dll
build.bat
```

### Instalar
1. **Feche o Firecast**
2. Execute `install.bat` (faz backup automatico da DLL original)
3. Abra o Firecast

### Desinstalar
1. **Feche o Firecast**
2. Execute `uninstall.bat` (restaura DLL original)

---

## 📁 Estrutura

```
proxy_dll/
├── lua54x64_proxy.c    # Codigo-fonte do proxy (742 linhas)
├── lua54x64.def        # Exports (153 forwarded + hooks)
├── fcext_ui.lua         # Biblioteca UI de alto nivel
├── build.bat           # Compilacao
├── install.bat         # Instalador
├── uninstall.bat       # Desinstalador
├── lua54x64.dll        # DLL compilada
└── README.md           # Este arquivo
```

## 🔬 Como Funciona

1. O proxy carrega via `DllMain` e resolve `lua54x64_original.dll`
2. 153 funcoes sao **forwarded** diretamente via `.def`
3. `luaL_openlibs()` e `lua_pcallk()` sao **hooked**
4. No hook, registra `fcext` em `_G`, `_LOADED`, e `package.loaded`
5. Plugins acessam via `require("fcext")` ou `fcext.funcao()`
6. GUI API acessivel via global `GUI` (injetada pelo Firecast internamente)

| Detalhe | Valor |
|---|---|
| Lua Version | 5.4 |
| Arquitetura | x86_64 |
| Exports | 154 (153 forwarded + hooks) |
| Hook Targets | `luaL_openlibs`, `lua_pcallk` |
| Tamanho DLL | ~210KB |
| Controles GUI | 19+ tipos testados |
| Funcoes GUI | 93 catalogadas |

---

## 📄 Licenca

Uso livre para a comunidade Naruto Destiny.
