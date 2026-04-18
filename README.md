<p align="center">
  <img src="docs/banner.png" alt="Naruto Destiny Banner" width="100%"/>
</p>

<h1 align="center">🍥 Naruto Destiny — Ficha de Personagem</h1>

<p align="center">
  <strong>Plugin de ficha de personagem para o RPG Naruto Destiny no <a href="https://firecast.app">Firecast</a></strong>
</p>

<p align="center">
  <a href="https://github.com/Foxoverload/NDPlugins/releases/latest">
    <img src="https://img.shields.io/github/v/release/Foxoverload/NDPlugins?style=for-the-badge&color=FF6B35&label=Download&logo=github" alt="Download"/>
  </a>
  <a href="https://github.com/Foxoverload/NDPlugins/releases/latest">
    <img src="https://img.shields.io/github/downloads/Foxoverload/NDPlugins/total?style=for-the-badge&color=1A1A2E&label=Downloads" alt="Downloads"/>
  </a>
  <a href="https://github.com/Foxoverload/NDPlugins/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Foxoverload/NDPlugins?style=for-the-badge&color=2A2A4E" alt="License"/>
  </a>
</p>

---

## 📖 Sobre

**Naruto Destiny — Ficha de Personagem** é um plugin para o [Firecast](https://firecast.app) que fornece uma ficha completa e automatizada para o sistema de RPG **Naruto Destiny**. A ficha foi projetada com foco em usabilidade, automação de cálculos e uma interface visual rica em tema dark.

---

## ✨ Funcionalidades

### 📋 Ficha Completa
- **Dados Pessoais** — Nome, idade, vila, clã, rank shinobi, kekkei genkai e mais
- **Personalidade** — Comportamento, objetivo, sonho, gostos e desgostos
- **6 Slots de Imagem** — Para aparência do personagem, alinhados horizontalmente
- **Família e Relações** — Pais, irmãos, amigos, inimigos e neutros

### ⚔️ Sistema de Combate
- **Atributos Core** — Força, Agilidade, Constituição, Destreza, Controle de Chakra, Concentração, Inteligência e Força Espiritual
- **Atributos de Combate** — Taijutsu, Bukijutsu, Ninjutsu, Genjutsu, Fuinjutsu, Esquiva, Bloqueio e mais
- **Barras de Status** — PV, Chakra e Estamina com valores atuais e máximos
- **Perícias** — 14 perícias incluindo Sobrevivência, Medicina, Percepção, etc.
- **Elementos** — Fogo, Água, Vento, Terra, Raio e Combo

### 🧮 Cálculos Automáticos

#### Pontos de Jutsu
O sistema calcula automaticamente os pontos de jutsu gastos baseado no rank de cada técnica:

| Rank | Custo |
|------|-------|
| D | 50 pts |
| C | 100 pts |
| B | 150 pts |
| A | 200 pts |
| S | 250 pts |
| SS | 300 pts |
| SS+ | 350 pts |
| SSS / MSS+ | 400 pts |

- Máximo de pontos = **Nível × 100**
- Técnicas marcadas como **(Gratuito)** não são contabilizadas
- Atualização em tempo real via timer de 2 segundos

#### Traits
- Parser automático de traits no formato `(XXX pontos de Trait)`
- Detecção de bônus no formato `[bônus: CAMPO +/-N%]`
- Cálculo de pontos usados vs. disponíveis (Nível × 40 + 120)

### 📑 Abas Organizadas
- **Ficha Principal** — Dados pessoais, atributos, combate, perícias, traits e aparência
- **Técnicas** — 8 categorias (Taijutsu, Bukijutsu, Ninjutsu, Elemental, Fuinjutsu, Kuchiyose, Kekkei Genkai, Hab. Gerais)
- **Inventário** — Editor rich text para itens e equipamentos
- **História** — Editor rich text para background do personagem

### 🔒 Recursos Extras
- **Travar Ficha** — Impede edições acidentais
- **Exportar como HTML** — Gera um arquivo HTML estilizado com todos os dados da ficha
- **Ficha de Kuchiyose** — Aba completa para invocações com atributos e traits próprios

---

## 📸 Screenshots

<details>
<summary><strong>🎯 Aba de Técnicas com Pontos de Jutsu</strong></summary>
<br/>
<img src="docs/screenshot_tecnicas.png" alt="Técnicas" width="100%"/>
</details>

<details>
<summary><strong>🌟 Sistema de Traits</strong></summary>
<br/>
<img src="docs/screenshot_traits.png" alt="Traits" width="100%"/>
</details>

---

## 📥 Instalação

1. **Baixe** o arquivo `Ficha_ND.rpk` na [página de releases](https://github.com/Foxoverload/NDPlugins/releases/latest)
2. **Abra** o Firecast
3. **Importe** o plugin: vá em `Plugins` → `Instalar Plugin` e selecione o arquivo `.rpk`
4. **Crie** uma nova ficha selecionando o modelo **Naruto Destiny**

---

## 🛠️ Desenvolvimento

### Pré-requisitos
- [Firecast SDK 3](https://firecast.app/sdk3/) (rdk.exe)
- Editor de texto com suporte a XML/Lua

### Estrutura do Projeto

```
Ficha ND/
├── FichaND.lfm          # Layout principal da ficha (XML + Lua)
├── exportar.lua          # Módulo de exportação HTML
├── cabecalho.xml         # Componente visual de cabeçalho de seção
├── module.xml            # Manifesto do plugin
└── output/               # Diretório de build (gerado)
```

### Compilando

```bash
cd "Ficha ND"
rdk.exe -c
```

O arquivo `.rpk` será gerado no diretório `output/`.

### Tecnologias
- **LFM** (Layout Form Markup) — XML estendido do Firecast para definir interfaces
- **Lua** — Lógica de automação, cálculos e exportação
- **Firecast SDK 3** — Framework de plugins para o Firecast
- **NodeDatabase (NDB)** — Sistema de persistência de dados do Firecast

---

## 📝 Changelog

### v1.0.0
- Ficha completa com todas as seções
- Cálculo automático de Pontos de Jutsu via `richEdit:getText()`
- Cálculo automático de Traits com bônus
- 6 slots de imagem de aparência
- Exportação da ficha em HTML
- Sistema de travar ficha
- Ficha de Kuchiyose integrada

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests.

1. Faça um fork do projeto
2. Crie uma branch (`git checkout -b feature/minha-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona minha feature'`)
4. Push para a branch (`git push origin feature/minha-feature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto é de uso livre para a comunidade de RPG Naruto Destiny.

---

<p align="center">
  Feito com 🍥 para a comunidade <strong>Naruto Destiny</strong>
</p>
