param(
  [Parameter(Mandatory)][string]$Game,   # capture du jeu
  [Parameter(Mandatory)][string]$Bar,    # capture de la barre
  [Parameter(Mandatory)][string]$PairDir,# dossier de paire (donne au critique)
  [Parameter(Mandatory)][string]$KeyFile # correspondance secrete, HORS du dossier de paire
)
if ((Split-Path ([IO.Path]::GetFullPath($KeyFile))) -eq [IO.Path]::GetFullPath($PairDir)) { Write-Error "KeyFile doit etre hors de PairDir"; exit 1 }
New-Item -ItemType Directory -Force $PairDir | Out-Null
New-Item -ItemType Directory -Force (Split-Path ([IO.Path]::GetFullPath($KeyFile))) | Out-Null
$gameIsA = (Get-Random -Maximum 2) -eq 0
$a = if ($gameIsA) { $Game } else { $Bar }
$b = if ($gameIsA) { $Bar } else { $Game }
# Les deux sont convertis en PNG pour qu'aucune extension ne trahisse la source
Add-Type -AssemblyName System.Drawing
# Meme resolution et meme reechantillonnage pour les deux : la nettete ne doit pas trahir la source
$W = 1280; $H = 720
foreach ($pair in @(@($a,"A.png"),@($b,"B.png"))) {
  $img = [Drawing.Image]::FromFile((Resolve-Path $pair[0]))
  $bmp = New-Object Drawing.Bitmap $W, $H
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($img, 0, 0, $W, $H)
  $g.Dispose()
  $bmp.Save((Join-Path ([IO.Path]::GetFullPath($PairDir)) $pair[1]), [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose(); $img.Dispose()
}
@{ A = $(if ($gameIsA) {"game"} else {"bar"}); B = $(if ($gameIsA) {"bar"} else {"game"}); game = $Game; bar = $Bar } | ConvertTo-Json | Set-Content $KeyFile -Encoding UTF8
Write-Output "Paire creee dans $PairDir ; cle dans $KeyFile (ne pas la montrer au critique)"
