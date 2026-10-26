# Lance les tests headless du coeur de jeu. Code de sortie non nul si un test echoue
# ou si une erreur de script (SCRIPT ERROR / Parse Error) est detectee.
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $root "tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"

& $godot --headless --path $root --import --quit *> $null
$out = & $godot --headless --path $root -s res://tests/run_tests.gd *>&1 | ForEach-Object { "$_" }
$out | Write-Host
$code = $LASTEXITCODE
if ($out -match "SCRIPT ERROR|Parse Error") {
    Write-Host "ECHEC: erreur de script detectee"
    exit 1
}
exit $code
