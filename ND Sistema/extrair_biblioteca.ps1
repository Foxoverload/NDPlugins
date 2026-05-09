param(
    [string]$BibPath = "C:\Users\aaron\Desktop\ND Fichas\Biblioteca.bib",
    [string]$OutputDir = "C:\Users\aaron\Desktop\ND Fichas\ND Sistema"
)

$ErrorActionPreference = 'Continue'
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host " ND - Extrator e Condensador de Biblioteca (.bib)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# ================================================================
# STEP 1: Decompress .bib (zlib at offset 23)
# ================================================================
Write-Host "`n[1/4] Descomprimindo .bib..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression
$bibBytes = [System.IO.File]::ReadAllBytes($BibPath)
$ms = New-Object System.IO.MemoryStream($bibBytes, [int]23, [int]($bibBytes.Length-23))
$ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
$outMs = New-Object System.IO.MemoryStream; $ds.CopyTo($outMs)
$rawBytes = $outMs.ToArray()
$raw = [System.Text.Encoding]::UTF8.GetString($rawBytes)
$ds.Close(); $ms.Close(); $outMs.Close()
$rawBytes = $null
Write-Host "  OK ($([math]::Round($raw.Length/1MB,1))MB)"

# ================================================================
# STEP 2: Extract all NDB documents (name + text blocks)
# ================================================================
Write-Host "`n[2/4] Extraindo documentos..." -ForegroundColor Yellow

# Find all <?xml block positions
$xmlPositions = [System.Collections.Generic.List[int]]::new()
$idx = 0
while (($idx = $raw.IndexOf('<?xml', $idx)) -ge 0) { $xmlPositions.Add($idx); $idx += 5 }

$documents = [System.Collections.Generic.List[PSObject]]::new()
for ($i = 0; $i -lt $xmlPositions.Count; $i++) {
    $xmlStart = $xmlPositions[$i]
    $xmlEnd = if ($i+1 -lt $xmlPositions.Count) { $xmlPositions[$i+1] } else { $raw.Length }

    # Find entry name (readable string before XML)
    $scanStart = [Math]::Max(0, $xmlStart - 300)
    $region = $raw.Substring($scanStart, $xmlStart - $scanStart)
    $nameMatches = [regex]::Matches($region, '[\x20-\x7E]{3,100}')
    $entryName = "Doc_$i"
    if ($nameMatches.Count -gt 0) {
        $c = $nameMatches[$nameMatches.Count - 1].Value.Trim()
        if ($c -notmatch '^\<|^xml|database|encoding|t_\w+=|/\u003e|^\d+$' -and $c.Length -ge 2) {
            $entryName = $c
        }
    }

    # Extract text="..." values, skipping NDB type artifacts
    $block = $raw.Substring($xmlStart, [Math]::Min($xmlEnd - $xmlStart, $raw.Length - $xmlStart))
    $texts = [System.Collections.Generic.List[string]]::new()
    $tIdx = 0
    while (($tIdx = $block.IndexOf('text="', $tIdx)) -ge 0) {
        $tStart = $tIdx + 6
        $tEnd = $block.IndexOf('"', $tStart)
        if ($tEnd -gt $tStart -and ($tEnd - $tStart) -lt 50000) {
            $content = $block.Substring($tStart, $tEnd - $tStart)
            $content = $content -replace '&#xD;&#xA;',"`n" -replace '&#xD;',"`n" -replace '&#xA;',"`n"
            $content = $content -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"'
            $ct = $content.Trim()
            if ($ct.Length -gt 0 -and $ct -ne 'S' -and $ct -ne 'B' -and $ct -ne 'I' -and $ct -ne 'D' -and $ct -ne 'SS') {
                $texts.Add($content)
            }
        }
        $tIdx = $tEnd + 1
        if ($tIdx -le 0) { break }
    }

    # Extract <database> attributes (for character sheets)
    $dbAttrs = ""
    if ($block -match '<database\s+([^>]+)') { $dbAttrs = $Matches[1] }

    $fullText = ($texts -join "`n").Trim()
    if ($fullText.Length -gt 5 -or $dbAttrs) {
        $documents.Add([PSCustomObject]@{
            Name = $entryName; FullText = $fullText; DbAttrs = $dbAttrs; Len = $fullText.Length
        })
    }
}
$raw = $null  # free memory
Write-Host "  $($documents.Count) documentos extraidos"

# ================================================================
# STEP 3: Classify documents into 4 categories + fichas
# ================================================================
Write-Host "`n[3/4] Classificando e condensando..." -ForegroundColor Yellow

$catSistema = [System.Collections.Generic.List[PSObject]]::new()   # Combat, rules, mechanics
$catClas    = [System.Collections.Generic.List[PSObject]]::new()   # Clans, KG
$catJutsus  = [System.Collections.Generic.List[PSObject]]::new()   # Jutsu techniques
$catEvo     = [System.Collections.Generic.List[PSObject]]::new()   # Evolution, items, traits, shop
$catFichas  = [System.Collections.Generic.List[PSObject]]::new()   # Player character sheets
$catSkip    = 0

# Known clan names for matching
$clanNames = 'Uchiha|Hyuga|Uzumaki|Senju|Nara|Akimichi|Aburame|Inuzuka|Yamanaka|Kaguya|Hoshigaki|zuki|Yuki|Yota|Otsutsuki|Ootsutsuki|Kurama|Hatake|Sarutobi|Fuuma|Shimura|Izuno|Kamizuru|Chinoike|Yome|Kazekage|Chikamatsu|Jashin|Jiongu|Ju Giga|Shikigami|Yotsuki|Tei$|Kazan|Wasabi|Hane$|Hon$|Jugo'

# Known jutsu doc names
$jutsuNames = 'Taijutsu|Bukijutsu|Ninjutsu|Genjutsu|Fuinjutsu|Kugutsu|Senjutsu|Hiden|Kinjutsu|Katon|Suiton|Doton|Raiton|Futon|Shabondama|Chidori|Rasengan|Hiraishin|Iryo|Kanchi|Kekkai|Tensei|Hachimon|Jinch|Juinka|Bushinjutsu|Goken|Rakanken|Suiken|Muon|Kakuran|Happa|Nin-Taijutsu|Chakra Enhanced|Arm Growth|Kenjutsu|Shurikenjutsu|Tessenjutsu|Iaid|Ansatsu|Akurobatto|Hagama|Hien|Saganken|Sairento|Claw Creation|Fluxo de Chakra|Kasa$|Shakuj|Kuroi Kaminari|Shichi Tenk|MSS\+|Enton|Ranton|Futton|Jinton|Taiton|Shakuton|Meiton|Yoton|Hyouton|Mokuton|Jiton|Bakuton|Kibaku|Shouton|Kouton|Doujutsu|Akagan|Tenseigan|Kuchiyose|Kuchyose|Invoca|Modo$|Kimera|Kujaku|Quimera|Shisha Kugutsu|Senzoku|Hari Jiz|Suna no Jutsu|Kemuri|Carbon Control|Tubos de|Veneno|Elemental|Umibozu|Komori|Itachi|Nue$|Doru Goremu|Kame$|Tori$|Namekuji|Moru$|Sansh|Sharingan Spying|Kaigara|Baku$|Doki|Aranha|Gumo|Garaga|Aoda$|Hebi$|Gama$|Akino|Bisuke|Guruko|Uhei|Shiba$|Cachorros|Urushi|Bull$|Pakkun|Novas$'

foreach ($doc in $documents) {
    $name = $doc.Name
    $text = $doc.FullText

    # Character sheet?
    if ($doc.DbAttrs -match '\bnome="([^"]+)"' -and $doc.DbAttrs -match '\bforca=') {
        $catFichas.Add($doc)
        continue
    }

    # Classify by document name (order matters: more specific first)

    # 1. ITEMS / LOJA (check FIRST to avoid jutsu fallback capturing these)
    if ($name -match 'Armadilha|Armadur|Consumiv|veis$|rios$|Armas (Unicas|sicas|B)|Loja|Items|Equipamento|Avatar|Estilo de Luta|Novo Sistema') {
        $catEvo.Add($doc)
    }
    # 2. TRAITS / EVOLUÇÃO
    elseif ($name -match 'Trait|Evolu|sen$|cnicas$') {
        $catEvo.Add($doc)
    }
    # 3. CLÃS (require at least 3 chars after "Cl" to avoid matching "Claw Creation")
    elseif ($name -match "^($clanNames)$" -or $name -match '^(\d+ - )?Cl[^a]' -or $name -match 'Kekkei Genkai') {
        $catClas.Add($doc)
    }
    # 4. SISTEMA / MECÂNICAS
    elseif ($name -match 'Combate|Sistema|Tabelinha|Narrar|Bem Vindo|Inimigo|Guerra|Leis Inter|Bingo Book|Campo de Trein|Rank das Miss|Organiza|Ficha|Timeline|Reconhecimento|Natureza e Comp|Qualidades|Icones|Interpreta|Debates|Creation|Mapa|Mural|Titereiro') {
        $catSistema.Add($doc)
    }
    # 5. JUTSUS (by name)
    elseif ($name -match "($jutsuNames)") {
        $catJutsus.Add($doc)
    }
    # 6. Fallback: classify by content
    elseif ($text -match 'Quem usa:' -and $text -match 'Fun..o:' -and $text.Length -gt 200) {
        $catJutsus.Add($doc)
    }
    elseif ($text -match 'Quem usa:' -and $text -match 'Rank:') {
        $catJutsus.Add($doc)
    }
    elseif ($text -match 'Passiva|Ichizoku|Membros:' -and $text.Length -gt 300) {
        $catClas.Add($doc)
    }
    elseif ($text -match 'Pre.o:|Ryous|Trait|Custo:' -and $text.Length -gt 200) {
        $catEvo.Add($doc)
    }
    elseif ($text.Length -gt 100) {
        $catSistema.Add($doc)  # default: system
    }
    else {
        $catSkip++
    }
}

Write-Host "  Sistema/Mecanicas: $($catSistema.Count) docs"
Write-Host "  Clas/KG:           $($catClas.Count) docs"
Write-Host "  Jutsus/Tecnicas:   $($catJutsus.Count) docs"
Write-Host "  Evolucao/Items:    $($catEvo.Count) docs"
Write-Host "  Fichas:            $($catFichas.Count)"
Write-Host "  Ignorados:         $catSkip"

# ================================================================
# STEP 4: Write condensed output files
# ================================================================
Write-Host "`n[4/4] Gerando arquivos condensados..." -ForegroundColor Yellow

$date = Get-Date -Format 'dd/MM/yyyy HH:mm'
$totalTokens = 0

# --- Helper: write a category file ---
function Write-CategoryFile {
    param($docs, $fileName, $title)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# NARUTO DESTINY - $title")
    [void]$sb.AppendLine("# Extraido de: $([System.IO.Path]::GetFileName($BibPath))")
    [void]$sb.AppendLine("# Atualizado: $date")
    [void]$sb.AppendLine("# Documentos: $($docs.Count)")
    [void]$sb.AppendLine("")

    foreach ($doc in $docs) {
        [void]$sb.AppendLine("=== $($doc.Name) ===")
        $lines = $doc.FullText -split "`n"
        foreach ($line in $lines) {
            $lt = $line.Trim()
            if ($lt.Length -gt 0) { [void]$sb.AppendLine($lt) }
        }
        [void]$sb.AppendLine("")
    }

    $path = Join-Path $OutputDir $fileName
    $content = $sb.ToString()
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    $size = (Get-Item $path).Length
    $words = ($content -split '\s+').Count
    $tokens = [math]::Round($words * 1.3)
    Write-Host ("  {0,-50} {1,5}KB  ~{2,6} tokens  ({3} docs)" -f $fileName, [math]::Round($size/1KB), $tokens, $docs.Count)
    return $tokens
}

$totalTokens += Write-CategoryFile $catSistema "ND_SISTEMA_CONDENSADO_PARA_IA.txt" "MECANICAS, REGRAS E COMBATE"
$totalTokens += Write-CategoryFile $catClas    "ND_CLAS_CONDENSADO_PARA_IA.txt" "CLAS E KEKKEI GENKAI"
$totalTokens += Write-CategoryFile $catJutsus  "ND_JUTSUS_COMPACTO_PARA_IA.txt" "CATALOGO DE JUTSUS E TECNICAS"
$totalTokens += Write-CategoryFile $catEvo     "ND_EVOLUCAO_ITEMS_CONDENSADO_PARA_IA.txt" "EVOLUCAO, TRAITS, ITEMS E LOJA"

# --- Write character sheets ---
if ($catFichas.Count -gt 0) {
    $sheetSb = [System.Text.StringBuilder]::new()
    [void]$sheetSb.AppendLine("# FICHAS DOS JOGADORES - NARUTO DESTINY")
    [void]$sheetSb.AppendLine("# Atualizado: $date")
    [void]$sheetSb.AppendLine("")
    $sc = 0
    $skip = @('TESTE','asdas','asdasd','asdasdasd','Nome do seu Personagem')
    foreach ($doc in $catFichas) {
        if ($doc.DbAttrs -match '\bnome="([^"]+)"') {
            $n = $Matches[1]
            if ($skip -contains $n -or $n.Length -lt 2) { continue }
            $sc++
            [void]$sheetSb.AppendLine("=== $n ===")
            $attrs = [regex]::Matches($doc.DbAttrs, '(\w+)="([^"]*)"')
            $d = @{}; foreach ($a in $attrs) { $d[$a.Groups[1].Value] = $a.Groups[2].Value }
            foreach ($cat in @(
                @('PERFIL',@('nome','idade','sexo','vila_nascimento','cla_ninja','kekkei_genkai','rank_shinobi','nivel','sensei','kuchiyose','natureza','comportamento','qualidade','defeito','mao_dominante','ryous_fmt','objetivo','sonho')),
                @('STATUS',@('pv','pv_atual','pchakra','pchakra_atual','pestamina','pestamina_atual','xp_max')),
                @('CORE',@('forca','agilidade','constituicao','destreza','ctrl_chakra','concentracao','inteligencia','forca_espiritual')),
                @('COMBATE',@('taijutsu','bukijutsu','ninjutsu','genjutsu','fuinjutsu','arremesso','esquiva','bloqueio_fisico','bloqueio_chakra','reflexo','iniciativa','movimentacao','genjutsu_kai','tai_bukijutsu','nin_taijutsu','hiraishin')),
                @('INTERP',@('sobrevivencia','armadilha','empatia','intimidacao','ladinagem','enganacao','percepcao','persuasao','seducao','medicina','conhecimento','aprendizado','ensinamento'))
            )) {
                $p = @(); foreach ($f in $cat[1]) { if ($d[$f] -and $d[$f] -ne '0' -and $d[$f] -ne 'False') { $p += "$f=$($d[$f])" } }
                if ($p.Count) { [void]$sheetSb.AppendLine("$($cat[0]): $($p -join ' | ')") }
            }
            [void]$sheetSb.AppendLine("")
        }
    }
    $sheetPath = Join-Path $OutputDir "ND_BIB_FICHAS_JOGADORES.txt"
    [System.IO.File]::WriteAllText($sheetPath, $sheetSb.ToString(), [System.Text.Encoding]::UTF8)
    Write-Host "  ND_BIB_FICHAS_JOGADORES.txt: $sc fichas"
}

# ================================================================
# SUMMARY
# ================================================================
Write-Host "`n====================================================" -ForegroundColor Green
Write-Host " RESULTADO" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  TOTAL: ~$totalTokens tokens nos 4 arquivos" -ForegroundColor Cyan
Write-Host ""
if ($totalTokens -lt 128000) {
    Write-Host "  ChatGPT (128k): CABE!" -ForegroundColor Green
} elseif ($totalTokens -lt 200000) {
    Write-Host "  ChatGPT (128k): Apertado - suba os 4 como Knowledge" -ForegroundColor Yellow
} else {
    Write-Host "  ChatGPT (128k): EXCEDE - priorize Sistema + Jutsus" -ForegroundColor Yellow
}
Write-Host "  Gemini  (1M):   CABE!" -ForegroundColor Green
Write-Host "  NotebookLM:     CABE (4 fontes)" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
