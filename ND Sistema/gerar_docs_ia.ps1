<#
.SYNOPSIS
    ND Sistema - Gerador All-in-One de documentos para IA
    
.DESCRIPTION
    1. Lê os textos extraídos dos .docx (pasta nd_system_txt)
    2. Gera os 4 documentos condensados para IA:
       - ND_SISTEMA_CONDENSADO_PARA_IA.txt (regras de combate)
       - ND_CLAS_CONDENSADO_PARA_IA.txt (clãs e kekkei genkai)
       - ND_JUTSUS_COMPACTO_PARA_IA.txt (catálogo de jutsus)
       - ND_EVOLUCAO_ITEMS_CONDENSADO_PARA_IA.txt (progressão e itens)
    3. Extrai fichas de jogadores do .bib (se disponível)
    
.NOTES
    Para atualizar os .docx -> .txt, rode o batch de extração primeiro.
    Os .txt devem estar em: proxy_dll\nd_system_txt\
#>

param(
    [string]$TxtDir = "C:\Users\aaron\Desktop\ND Fichas\proxy_dll\nd_system_txt",
    [string]$OutputDir = "C:\Users\aaron\Desktop\ND Fichas\ND Sistema",
    [string]$BibPath = "C:\Users\aaron\Desktop\ND Fichas\Biblioteca.bib"
)

$ErrorActionPreference = 'Continue'

Write-Host "`n======================================================" -ForegroundColor Cyan
Write-Host " ND Sistema - Gerador de Documentos para IA" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

if (-not (Test-Path $TxtDir)) {
    Write-Host "ERRO: Pasta $TxtDir nao encontrada!" -ForegroundColor Red
    Write-Host "Extraia os .docx primeiro." -ForegroundColor Red
    exit 1
}

$allTxt = Get-ChildItem $TxtDir -Filter "*.txt" | Sort-Object Name
Write-Host "`nFonte: $($allTxt.Count) arquivos .txt em nd_system_txt" -ForegroundColor Gray

# =====================================================================
# DOC 1: SISTEMA CONDENSADO (Regras de combate, atributos, formulas)
# =====================================================================
Write-Host "`n[1/5] Gerando SISTEMA CONDENSADO..." -ForegroundColor Yellow

$combateFile = $allTxt | Where-Object { $_.Name -match "^Sistema_1" }
$evolucaoFile = $allTxt | Where-Object { $_.Name -match "^Sistema_2" }
$fichaFile = $allTxt | Where-Object { $_.Name -match "^Ficha_1" }

$sistema = @"
# NARUTO DESTINY - MANUAL COMPLETO PARA IA NARRADORA
# Versão condensada algorítmica para uso como fonte em ChatGPT/Gemini/NotebookLM
# Atualizado: $(Get-Date -Format 'dd/MM/yyyy')

================================================================
SEÇÃO 1: REGRAS DE COMBATE (PROCEDIMENTOS)
================================================================

## 1.1 ROLAGEM BASE

FÓRMULA DE ATAQUE/DEFESA:
  resultado = 1d20 + AtributoCombate + bonus - redutores
  bonus = min(modo + estilo, 4) + bonus_ignoram_limite
  redutores = min(redutores_normais, 4) + redutores_ignoram_limite

FÓRMULA INTERPRETATIVA:
  resultado = 1d20 + AtributoInterpretativo + bonus - redutores

LIMITES:
  - Bônus máximo por atributo: +4 (exceto "ignora limite")
  - Redutor máximo por atributo: -4 (exceto "ignora limite")
  - Atributos interpretativos: máximo 10 pontos

## 1.2 INICIATIVA

PROCEDIMENTO:
1. Mestre declara "Ordem de Turnos"
2. Ordenar combatentes por Iniciativa (maior → menor)
3. SE empate no inteiro → comparar decimal (6.8 > 6.3)
4. SE empate decimal → comparar Agilidade
5. SE empate Agilidade → 1d20 sem bônus até desempatar
NOTA: Empatados mantêm posição acima de qualquer valor inferior

## 1.3 TURNO OFENSIVO

AÇÕES DISPONÍVEIS POR TURNO:
  1x Ação de Ataque
  2x Ação de Suporte
  1x Ação de Movimentação (distância = Movimentação do personagem)

AÇÃO DE ATAQUE:
  Declarar técnica → Rolar 1d20 + Atributo + Bônus - Redutores
  SE resultado >= defesa do alvo → ACERTO (aplicar dano)
  SE resultado < defesa do alvo → ERRO (sem dano)

AÇÃO DE SUPORTE:
  Exemplos: ativar modo/estilo, usar item, preparar, trocar arma
  NÃO causa dano diretamente

## 1.4 TURNO DEFENSIVO

DEFESAS DISPONÍVEIS (escolher 1 por ataque recebido):
  Esquiva: 1d20 + Esquiva + Bônus - Redutores
  Bloqueio Físico: 1d20 + BloqFis + Bônus - Redutores (reduz 25% dano)
  Bloqueio Chakra: 1d20 + BloqChk + Bônus - Redutores (reduz 25% dano)
  Contra-Ataque: 1d20 + AtribAtaque + Bônus - Redutores

CONTRA-ATAQUE:
  SE contra-ataque >= ataque → defende E causa dano ao atacante
  SE contra-ataque < ataque → recebe dano +25% (penalidade por falhar)

REFLEXO (automático):
  Ativado quando o defensor NÃO é o alvo declarado
  1d20 + Reflexo → SE >= ataque, pode usar defesa normalmente

## 1.5 CÁLCULO DE DANO

FÓRMULA BASE:
  dano = resultado_ataque + dano_tecnica + bonus_dano
  
REDUÇÃO POR BLOQUEIO:
  SE defensor usou Bloqueio → dano final = dano * 0.75

TABELA DE REDUÇÃO POR DIFERENÇA DE RANK:
  Defensor rank MAIOR que atacante:
    1 rank acima: -10% dano
    2 ranks: -20% | 3 ranks: -30% | 4+ ranks: -40%
  Atacante rank MAIOR que defensor:
    1 rank acima: +5% dano
    2 ranks: +10% | 3 ranks: +15%

## 1.6 CRÍTICO E ERRO CRÍTICO

NAT 20 (Crítico):
  Em ataque: Dano x2
  Em defesa: Contra-ataque GRÁTIS (sem penalidade se falhar)
  NÃO é acerto automático, ainda compara com defesa

NAT 1 (Erro Crítico):
  Em ataque: Dano /2
  Em defesa: Dano recebido +50%

## 1.7 BARREIRAS

Técnicas de barreira bloqueiam dano até seu limite de absorção.
  Cooldown: 2 rodadas após uso
  Não conta como ação defensiva

## 1.8 ESTADOS E CONDIÇÕES

SE HP <= 0: Personagem INCONSCIENTE (não pode agir)
SE HP <= -100: Personagem MORTO
  
Efeitos ativos: Máximo 2 simultâneos por personagem
  Veneno: -X HP por turno
  Queimadura: -X HP por turno, -1 ataque
  Paralisia: Não pode agir por X turnos
  Sangramento: -X HP por turno quando se move
  Cegueira: -4 em ataques e esquiva
  Atordoamento: Perde próximo turno

## 1.9 ESTAMINA

REGRA FUNDAMENTAL:
  TODA ação física gasta Estamina = resultado da rolagem
  SE Estamina <= 0: Personagem EXAUSTO (-2 em todas ações)

## 1.10 MODO/ESTILO

REGRA DE INÍCIO:
  Combate SEMPRE inicia NEUTRO (sem Modo/Estilo/Avatar ativo)
  Ativar Modo/Estilo = 1 Ação de Suporte

================================================================
SEÇÃO 2: ATRIBUTOS
================================================================

## 2.1 ATRIBUTOS CORE (8 atributos)

Força (FOR) | Agilidade (AGI) | Constituição (CST)
Destreza (DES) | Controle de Chakra (CCH) | Concentração (CON)
Inteligência (INT) | Força Espiritual (FEP)

## 2.2 FÓRMULAS DE ATRIBUTOS DE COMBATE

Taijutsu = FOR + AGI*0.5
Bukijutsu = DES + FOR*0.5
Ninjutsu = FEP + CCH*0.5
Genjutsu = CCH + INT*0.5
Fuinjutsu = INT + FEP*0.5
Arremesso = CON + DES*0.5
Esquiva = (AGI+CON+INT+CST)/2.5
Bloqueio Físico = (FOR+DES+CST+AGI)/2.5
Bloqueio Chakra = (CCH+FEP+CST+CON)/2.5
Reflexo = (CON+AGI+CST+INT)/2.5
Iniciativa = (FOR+DES+CON+AGI)/2.5
Movimentação = (AGI+DES+FOR+CST)/5
Genjutsu Kai = (INT+CCH+CON)/2
Tai-Bukijutsu = (TAI+BUKI)/2
Nin-Taijutsu = (NIN+TAI)/2
Hiraishin = (AGI+CON+CCH+INT)/2.5

## 2.3 FÓRMULAS DE STATUS

PV (Pontos de Vida) = (Força + Constituição) * 45
Chakra = (Controle de Chakra + Força Espiritual + Inteligência) * 34
Estamina = (Agilidade + Destreza + Concentração) * 34

## 2.4 ATRIBUTOS INTERPRETATIVOS (máx 10 cada)

Sobrevivência | Armadilhas | Empatia | Intimidação
Ladinagem | Enganação | Percepção | Persuasão
Sedução | Medicina | História | Ofício | Conhecimento

================================================================
SEÇÃO 3: PROGRESSÃO
================================================================

TABELA DE RANKS:
  Rank           | Nível | Pts Core | Max Core | Max Combate
  Aluno Academy  |  1    | 16       | 5        | 7
  Genin          |  5    | 24       | 6        | 9
  Chuunin        | 10    | 34       | 7        | 10
  Tokubetsu Jounin| 20   | 54       | 9        | 13
  Jounin         | 30    | 74       | 12       | 18
  Jounin Elite   | 40    | 94       | 15       | 22
  ANBU/Sannin Inf| 50    | 134      | 20       | 30
  Kage           | 120   | 254      | 35       | 52
  Kage Superior  | 140   | 294      | 40       | 60
  Kage Supremo   | 160   | 334      | 45       | 67

GANHO POR NÍVEL: +2 Core, +1 Interpretativo, +100 Jutsus, +10 Traits

PREÇO DOS JUTSUS:
  E:100 | D:200 | C:400 | B:700 | A:1100 | S:1600 | SS:2200 | SS+:2900 | SSS:3700

"@

$sistemaFile = Join-Path $OutputDir "ND_SISTEMA_CONDENSADO_PARA_IA.txt"
$sistema | Out-File $sistemaFile -Encoding UTF8
$w = ($sistema -split '\s+').Count
Write-Host "  OK: $([math]::Round($sistema.Length/1KB))KB, ~$([math]::Round($w*1.3)) tokens"

# =====================================================================
# DOC 2: CLÃS CONDENSADO
# =====================================================================
Write-Host "`n[2/5] Gerando CLÃS CONDENSADO..." -ForegroundColor Yellow

$clasOutput = "# NARUTO DESTINY - CLÃS E KEKKEI GENKAI (CONDENSADO)`n"
$clasOutput += "# Atualizado: $(Get-Date -Format 'dd/MM/yyyy')`n`n"

$claFiles = $allTxt | Where-Object { $_.Name -match "^Ficha_Cl" -or $_.Name -match "^Ficha_Kekkei" }
foreach ($cf in $claFiles) {
    $content = Get-Content $cf.FullName -Raw -Encoding UTF8
    $claName = $cf.BaseName -replace '^Ficha_Cls e Kekkei Genkais_\d+ - [^_]+_','' -replace '_',' '
    $claName = $claName -replace '^Ficha_Cls e Kekkei Genkais_Kekkei Genkai Neutro_',''
    $claName = $claName -replace '^Ficha_Cls e Kekkei Genkais_',''
    
    $clasOutput += "--- $claName ---`n"
    
    # Extract key fields
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        $lt = $line.Trim()
        if ($lt -match 'Passiva|Membro|Bônus|Bonus|Vantagem|Desvantagem|Kekkei|Habilidade|Efeito|Dano|Gasto|Rank|Requisito' -and $lt.Length -gt 10 -and $lt.Length -lt 500) {
            $clasOutput += "  $lt`n"
        }
    }
    $clasOutput += "`n"
}

$clasFile = Join-Path $OutputDir "ND_CLAS_CONDENSADO_PARA_IA.txt"
$clasOutput | Out-File $clasFile -Encoding UTF8
$w = ($clasOutput -split '\s+').Count
Write-Host "  OK: $([math]::Round($clasOutput.Length/1KB))KB, ~$([math]::Round($w*1.3)) tokens, $($claFiles.Count) clas"

# =====================================================================
# DOC 3: JUTSUS COMPACTO
# =====================================================================
Write-Host "`n[3/5] Gerando JUTSUS COMPACTO..." -ForegroundColor Yellow

$jutOutput = "# ND JUTSUS - REFERÊNCIA COMPACTA`n"
$jutOutput += "# Atualizado: $(Get-Date -Format 'dd/MM/yyyy')`n"
$jutOutput += "# Formato: FUNC|RANK|ATRIB|DIST|DANO|GASTO|EFEITO`n`n"

$jutsuFiles = $allTxt | Where-Object { $_.Name -match "^Jutsus_" }
$totalTech = 0

foreach ($jf in $jutsuFiles) {
    $content = Get-Content $jf.FullName -Raw -Encoding UTF8
    $cat = $jf.BaseName -replace '^Jutsus_\d+ - ','' -replace '_',' > '
    $jutOutput += "`n--- $cat ---`n"
    
    $techBlocks = $content -split '(?=Quem usa:)'
    foreach ($block in $techBlocks) {
        if ($block -notmatch 'Fun..o:') { continue }
        
        $funcao = ""; $rank = ""; $atrib = ""; $dist = ""; $dano = ""; $gasto = ""; $efeito = ""
        if ($block -match 'Fun..o:\s*([\w,\s\-]+?)(?:\s+Rank:)') { $funcao = $Matches[1].Trim() -replace '\s+',' ' }
        if ($block -match 'Rank:\s*([\w\s\+\-á]+?)(?:\s+(?:Atributo|Dist))') { $rank = $Matches[1].Trim() }
        if ($block -match 'Atributo:\s*([\w\s]+?)(?:\s+Dist)') { $atrib = $Matches[1].Trim() }
        if ($block -match 'Dist.ncia:\s*([\w\sá]+?)(?:\s+Selos)') { $dist = $Matches[1].Trim() }
        if ($block -match 'Dano:\s*([^\r\n]+)') { $dano = $Matches[1].Trim(); if($dano.Length -gt 60){$dano=$dano.Substring(0,60)} }
        if ($block -match 'Gasto:\s*([^\r\n]+)') { $gasto = $Matches[1].Trim(); if($gasto.Length -gt 60){$gasto=$gasto.Substring(0,60)} }
        if ($block -match 'Efeito:\s*([^\r\n]+)') { $efeito = $Matches[1].Trim(); if($efeito.Length -gt 80){$efeito=$efeito.Substring(0,80)} }
        
        if ($rank -and $funcao) {
            $jutOutput += "$funcao|$rank|$atrib|$dist|$dano|$gasto|$efeito`n"
            $totalTech++
        }
    }
}

$jutOutput += "`nTotal: $totalTech tecnicas`n"
$jutFile = Join-Path $OutputDir "ND_JUTSUS_COMPACTO_PARA_IA.txt"
$jutOutput | Out-File $jutFile -Encoding UTF8
$w = ($jutOutput -split '\s+').Count
Write-Host "  OK: $([math]::Round($jutOutput.Length/1KB))KB, ~$([math]::Round($w*1.3)) tokens, $totalTech tecnicas"

# =====================================================================
# DOC 4: EVOLUÇÃO E ITEMS
# =====================================================================
Write-Host "`n[4/5] Gerando EVOLUÇÃO E ITEMS..." -ForegroundColor Yellow

$evoOutput = "# ND - EVOLUÇÃO, TRAITS E ITEMS`n"
$evoOutput += "# Atualizado: $(Get-Date -Format 'dd/MM/yyyy')`n`n"

# Traits
$traitFile = $allTxt | Where-Object { $_.Name -match "Traits" } | Select-Object -First 1
if ($traitFile) {
    $content = Get-Content $traitFile.FullName -Raw -Encoding UTF8
    $evoOutput += "## TRAITS`n"
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        $lt = $line.Trim()
        if ($lt.Length -gt 15 -and $lt.Length -lt 500 -and ($lt -match 'Trait|Custo|Efeito|Requisito|Pontos|Passiva|Bônus|Bonus|Vantagem|Restrição')) {
            $evoOutput += "  $lt`n"
        }
    }
    $evoOutput += "`n"
}

# Items/Shop
$lojaFiles = $allTxt | Where-Object { $_.Name -match "^Loja" }
foreach ($lf in $lojaFiles) {
    $content = Get-Content $lf.FullName -Raw -Encoding UTF8
    $itemCat = $lf.BaseName -replace '^Loja de Items_',''
    $evoOutput += "## LOJA: $itemCat`n"
    $lines = $content -split "`n"
    foreach ($line in $lines) {
        $lt = $line.Trim()
        if ($lt.Length -gt 10 -and $lt.Length -lt 400 -and ($lt -match 'Pre.o|Ryous|Efeito|Dano|Bônus|Bonus|Rank|Requisito|Armadura|Arma|Consumível|Acessório')) {
            $evoOutput += "  $lt`n"
        }
    }
    $evoOutput += "`n"
}

$evoFile = Join-Path $OutputDir "ND_EVOLUCAO_ITEMS_CONDENSADO_PARA_IA.txt"
$evoOutput | Out-File $evoFile -Encoding UTF8
$w = ($evoOutput -split '\s+').Count
Write-Host "  OK: $([math]::Round($evoOutput.Length/1KB))KB, ~$([math]::Round($w*1.3)) tokens"

# =====================================================================
# DOC 5: FICHAS DO BIB (se disponível)
# =====================================================================
if (Test-Path $BibPath) {
    Write-Host "`n[5/5] Extraindo fichas do .bib..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.IO.Compression
    $bibBytes = [System.IO.File]::ReadAllBytes($BibPath)
    $ms = New-Object System.IO.MemoryStream($bibBytes, [int]23, [int]($bibBytes.Length-23))
    $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $outMs = New-Object System.IO.MemoryStream; $ds.CopyTo($outMs)
    $raw = [System.Text.Encoding]::UTF8.GetString($outMs.ToArray())
    $ds.Close(); $ms.Close(); $outMs.Close()
    
    $sheetOut = "# FICHAS DOS JOGADORES - NARUTO DESTINY`n# Atualizado: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n`n"
    $skip = @('TESTE','asdas','asdasd','asdasdasd','Nome do seu Personagem')
    $sc = 0; $dbIdx = 0
    while (($dbIdx = $raw.IndexOf('<database ', $dbIdx)) -ge 0) {
        $endIdx = $raw.IndexOf('/>', $dbIdx)
        if ($endIdx -gt 0 -and ($endIdx-$dbIdx) -lt 50000) {
            $block = $raw.Substring($dbIdx, $endIdx-$dbIdx+2)
            if ($block -match '\bnome="([^"]+)"' -and $block -match '\bforca=') {
                $n = $Matches[1]
                if ($skip -notcontains $n -and $n.Length -ge 2) {
                    $sc++
                    $sheetOut += "=== $n ===`n"
                    $attrs = [regex]::Matches($block, '(\w+)="([^"]*)"')
                    $d = @{}; foreach ($a in $attrs) { $d[$a.Groups[1].Value] = $a.Groups[2].Value }
                    foreach ($cat in @(
                        @('PERFIL',@('nome','idade','sexo','vila_nascimento','cla_ninja','kekkei_genkai','rank_shinobi','nivel','sensei','kuchiyose','natureza','comportamento','qualidade','defeito','mao_dominante','ryous_fmt','objetivo','sonho')),
                        @('STATUS',@('pv','pv_atual','pchakra','pchakra_atual','pestamina','pestamina_atual','xp_max')),
                        @('CORE',@('forca','agilidade','constituicao','destreza','ctrl_chakra','concentracao','inteligencia','forca_espiritual')),
                        @('COMBATE',@('taijutsu','bukijutsu','ninjutsu','genjutsu','fuinjutsu','arremesso','esquiva','bloqueio_fisico','bloqueio_chakra','reflexo','iniciativa','movimentacao','genjutsu_kai','tai_bukijutsu','nin_taijutsu','hiraishin')),
                        @('INTERP',@('sobrevivencia','armadilha','empatia','intimidacao','ladinagem','enganacao','percepcao','persuasao','seducao','medicina','conhecimento','aprendizado','ensinamento'))
                    )) {
                        $p = @(); foreach ($f in $cat[1]) { if ($d[$f] -and $d[$f] -ne '0' -and $d[$f] -ne 'False') { $p += "$f=$($d[$f])" } }
                        if ($p.Count) { $sheetOut += "$($cat[0]): $($p -join ' | ')`n" }
                    }
                    $sheetOut += "`n"
                }
            }
        }
        $dbIdx++
    }
    $sheetFile = Join-Path $OutputDir "ND_BIB_FICHAS_JOGADORES.txt"
    $sheetOut | Out-File $sheetFile -Encoding UTF8
    Write-Host "  OK: $sc fichas extraidas"
} else {
    Write-Host "`n[5/5] Biblioteca.bib nao encontrada, pulando fichas." -ForegroundColor Gray
}

# =====================================================================
# RESUMO FINAL
# =====================================================================
Write-Host "`n======================================================" -ForegroundColor Green
Write-Host " RESUMO FINAL" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
$totalTokens = 0
foreach ($f in (Get-ChildItem $OutputDir -Filter "ND_*CONDENSADO*") + (Get-ChildItem $OutputDir -Filter "ND_JUTSUS_COMPACTO*") + (Get-ChildItem $OutputDir -Filter "ND_BIB_FICHAS*")) {
    if (Test-Path $f.FullName) {
        $w = ((Get-Content $f.FullName -Raw) -split '\s+').Count
        $t = [math]::Round($w * 1.3)
        $totalTokens += $t
        Write-Host ("  {0,-45} {1,6}KB  ~{2,6} tokens" -f $f.Name, [math]::Round($f.Length/1KB), $t)
    }
}
Write-Host ""
Write-Host "  TOTAL: ~$totalTokens tokens" -ForegroundColor Cyan
Write-Host "  ChatGPT (128k): $(if($totalTokens -lt 128000){'CABE!'}else{'EXCEDE - divida'})" -ForegroundColor $(if($totalTokens -lt 128000){'Green'}else{'Yellow'})
Write-Host "  Gemini  (1M):   CABE!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
