param(
    [string]$Output = "$env:USERPROFILE\Desktop\ND_FICHAS_JOGADORES_PARA_IA.txt"
)

Write-Host "`nBuscando fichas HTML exportadas..." -ForegroundColor Cyan

$searchDirs = @(
    "$env:USERPROFILE\Desktop\Fichas e BG",
    "$env:USERPROFILE\Desktop"
)
$fichas = @()
foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        $fichas += Get-ChildItem $dir -Filter "Ficha_*.html" -ErrorAction SilentlyContinue
    }
}
$fichas = $fichas | Sort-Object Name -Unique

if ($fichas.Count -eq 0) {
    Write-Host "Nenhuma ficha encontrada!" -ForegroundColor Red
    exit 1
}

Write-Host "Encontradas $($fichas.Count) fichas" -ForegroundColor Green

$result = "# FICHAS DOS JOGADORES - NARUTO DESTINY`n"
$result += "# Atualizado: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n`n"

foreach ($f in $fichas) {
    Write-Host "  Processando: $($f.Name)..." -ForegroundColor Gray
    $html = Get-Content $f.FullName -Raw -Encoding UTF8
    
    $name = "?"
    if ($html -match 'Ficha de Personagem:\s*([^<]+)') { $name = $Matches[1].Trim() }
    
    $result += "================================================================`n"
    $result += "PERSONAGEM: $name`n"
    $result += "================================================================`n"
    
    # Extract th/td pairs grouped by h2 sections
    $lines = $html -split "`n"
    $currentSection = "DADOS"
    
    foreach ($line in $lines) {
        if ($line -match '<h2>([^<]+)</h2>') {
            $currentSection = $Matches[1].Trim().ToUpper() -replace '\s+','_' -replace '[^A-Z_]',''
        }
        if ($line -match '<th>([^<]+)</th>.*<td[^>]*>(.+?)</td>') {
            $key = $Matches[1].Trim()
            $val = $Matches[2] -replace '<[^>]+>',''
            $val = $val.Trim()
            if ($val -and $val -ne '0' -and $val -ne 'table: ' -and $val -notmatch '^table:') {
                $result += "  $key = $val`n"
            }
        }
    }
    
    # Extract elements (tag-on)
    $elemList = @()
    foreach ($line in $lines) {
        if ($line -match "tag-on'>([^<]+)<") {
            $elemList += $Matches[1]
        }
    }
    if ($elemList.Count -gt 0) {
        $result += "ELEMENTOS: $($elemList -join ', ')`n"
    }
    
    # Extract jutsus from <pre> blocks inside Jutsus section
    $inJutsuSection = $false
    $jutsuList = @()
    foreach ($line in $lines) {
        if ($line -match '<h2>Jutsus') { $inJutsuSection = $true; continue }
        if ($inJutsuSection -and $line -match '<h2>' -and $line -notmatch 'Jutsus') { $inJutsuSection = $false; continue }
        
        if ($inJutsuSection) {
            if ($line -match '<h3>([^<]+)</h3>') {
                $jutsuList += "  --- $($Matches[1].Trim()) ---"
            }
            # Extract jutsu name pattern (typically after "?" or at line start with specific format)
            if ($line -match 'Fun..o:\s*(.+)') {
                $funcao = $Matches[1].Trim()
                $jutsuList += "    Função: $funcao"
            }
            if ($line -match 'Rank:\s*(.+)') {
                $rank = $Matches[1].Trim()
                $jutsuList += "    Rank: $rank"
            }
            if ($line -match 'Dano:\s*(.+)') {
                $dano = $Matches[1].Trim()
                if ($dano.Length -gt 80) { $dano = $dano.Substring(0,80) }
                $jutsuList += "    Dano: $dano"
            }
            if ($line -match 'Gasto:\s*(.+)') {
                $gasto = $Matches[1].Trim()
                if ($gasto.Length -gt 80) { $gasto = $gasto.Substring(0,80) }
                $jutsuList += "    Gasto: $gasto"
            }
        }
    }
    if ($jutsuList.Count -gt 0) {
        $result += "JUTSUS:`n"
        $result += ($jutsuList -join "`n") + "`n"
    }
    
    # Extract history from <pre> blocks in Historia section
    $inHistSection = $false
    $histText = ""
    foreach ($line in $lines) {
        if ($line -match '<h2>Hist') { $inHistSection = $true; continue }
        if ($inHistSection -and $line -match '<h2>' -and $line -notmatch 'Hist') { $inHistSection = $false; continue }
        if ($inHistSection -and $line -match '<pre[^>]*>(.*)') {
            $histText = $Matches[1] -replace '</pre>','' -replace '<[^>]+>',''
        }
        if ($inHistSection -and $histText -eq "" -and $line -notmatch '<' -and $line.Trim()) {
            $histText += $line.Trim() + " "
        }
    }
    if ($histText.Trim()) {
        $hist = $histText.Trim() -replace '\s+',' '
        if ($hist.Length -gt 500) { $hist = $hist.Substring(0,500) + "..." }
        $result += "HISTORIA: $hist`n"
    }
    
    $result += "`n"
}

$result | Out-File $Output -Encoding UTF8
$fileSize = (Get-Item $Output).Length
$words = ($result -split '\s+').Count

Write-Host "`n=== RESULTADO ===" -ForegroundColor Green
Write-Host "Arquivo: $Output" -ForegroundColor Cyan
Write-Host "Fichas: $($fichas.Count) personagens" -ForegroundColor Cyan
Write-Host "Tamanho: $([math]::Round($fileSize/1KB))KB, ~$words palavras, ~$([math]::Round($words*1.3)) tokens" -ForegroundColor Cyan
