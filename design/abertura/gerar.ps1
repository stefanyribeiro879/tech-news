# Gera as imagens JPEG da tela de abertura a partir de abertura.html.
#   powershell -ExecutionPolicy Bypass -File design\abertura\gerar.ps1
# Precisa do Google Chrome (ou Edge) e de internet (fontes do Google Fonts).

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$here = $PSScriptRoot
$root = Resolve-Path (Join-Path $here '..\..')
$html = (New-Object System.Uri (Join-Path $here 'abertura.html')).AbsoluteUri
$out = Join-Path $root 'assets\images'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) 'technews-abertura'
New-Item -ItemType Directory -Force $tmp | Out-Null

$browser = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw 'Chrome ou Edge não encontrado.' }

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq 'image/jpeg' }
$params = New-Object System.Drawing.Imaging.EncoderParameters 1
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
  [System.Drawing.Imaging.Encoder]::Quality, [long]88)

foreach ($layout in @(
  @{ name = 'mobile'; size = '1080,1920' },
  @{ name = 'desktop'; size = '1920,1080' }
)) {
  $png = Join-Path $tmp "$($layout.name).png"
  & $browser --headless=new --disable-gpu --hide-scrollbars `
    --virtual-time-budget=8000 --window-size=$($layout.size) `
    --screenshot="$png" "$html#$($layout.name)" | Out-Null
  Start-Sleep -Milliseconds 500
  if (-not (Test-Path $png)) { throw "Falha ao gerar $png" }

  $img = [System.Drawing.Image]::FromFile($png)
  $dest = Join-Path $out "abertura_$($layout.name).jpg"
  $img.Save($dest, $jpeg, $params)
  $img.Dispose()
  Write-Output "OK: $dest"
}
