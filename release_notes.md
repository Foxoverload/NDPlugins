## Naruto Destiny v2.1.0

### Novidades
- **Exportacao HTML para IA Narradora**: Botao na aba Perfil gera arquivo HTML completo com todos os dados do personagem, ideal para alimentar IAs narradoras com contexto maximo
- **Segunda Coluna de Imagem**: Novo espaco de imagem no lado direito do perfil
- **Campos de Perfil Expandidos**: Tipo Sanguineo, Mao Dominante, Reconhecimento (0-6 estrelas com cores)
- **Formulas de Combate Visiveis**: Cada atributo de combate mostra a formula de calculo ao lado
- **Extracao Inteligente de RichEdit**: Sistema robusto de leitura de texto formatado para exportacao

### Downloads

| Arquivo | Descricao |
|---------|-----------|
| **Ficha.ND.rpk** | Plugin da ficha para instalar no Firecast |
| **ND_ScriptExtender_v2.1.0.zip** | Script Extender com instalador automatico |

### Como Instalar

**1. Ficha (obrigatorio)**
1. Baixe **Ficha.ND.rpk**
2. No Firecast: Plugins > Instalar Plugin > selecione o .rpk

**2. Script Extender (recomendado)**
1. Baixe **ND_ScriptExtender_v2.1.0.zip**
2. Extraia o conteudo em uma pasta
3. **Feche o Firecast**
4. Execute **instalar_script_extender.bat**
5. Reabra o Firecast

Para desinstalar: execute **desinstalar_script_extender.bat**

### Correcoes e Melhorias
- Export HTML salva na Desktop com auto-descoberta de caminho
- Verificacao real de gravacao do arquivo (fcext.fileExists)
- Toast de feedback visual apos exportacao
- Abertura automatica do HTML no navegador padrao
- Personalidade exportada como campos individuais (Gostos, Desgostos, etc.)
