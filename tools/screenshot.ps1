param(
  [Parameter(Mandatory)][string]$Scene,   # ex: res://scenes/main.tscn
  [Parameter(Mandatory)][string]$Out,     # chemin du PNG
  [string]$Resolution = "1920x1080",
  [int]$Frames = 30
)
$root = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $PSScriptRoot "godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
$outAbs = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
New-Item -ItemType Directory -Force (Split-Path $outAbs) | Out-Null
if (Test-Path $outAbs) { Remove-Item $outAbs }
$p = Start-Process -FilePath $exe -Wait -PassThru -ArgumentList @(
  "--path", "`"$root`"", "--resolution", $Resolution, "--script", "res://tools/screenshot.gd",
  "--", $Scene, "`"$outAbs`"", $Frames)
if (-not (Test-Path $outAbs) -or (Get-Item $outAbs).Length -eq 0) { Write-Error "Pas de PNG produit (exit $($p.ExitCode))"; exit 1 }
Write-Output $outAbs

