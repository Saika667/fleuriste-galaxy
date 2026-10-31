param(
  [Parameter(Mandatory)][string]$Script,   # ex: tools\blender\characters\human_base.py
  [string[]]$ScriptArgs = @(),
  [string]$Blend = ""                      # .blend a ouvrir avant le script (sinon scene vide)
)
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$exe = "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"
if (-not (Test-Path $exe)) { Write-Error "Blender introuvable : $exe"; exit 1 }
$scriptAbs = (Resolve-Path (Join-Path $root $Script)).Path
$argList = @("--background", "--factory-startup", "--python-exit-code", "1")
if ($Blend -ne "") { $argList += (Resolve-Path (Join-Path $root $Blend)).Path }
$argList += @("--python", $scriptAbs, "--") + $ScriptArgs
& $exe @argList
exit $LASTEXITCODE
