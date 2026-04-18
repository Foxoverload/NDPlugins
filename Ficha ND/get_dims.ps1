Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("C:\Users\aaron\Desktop\Ficha ND\Ficha Img.png")
Write-Output $img.Width
Write-Output $img.Height
$img.Dispose()
