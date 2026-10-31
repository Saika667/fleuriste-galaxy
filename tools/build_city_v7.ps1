# Regenerate prepared building scenes and distance LODs from their editable sources.
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEngine=Join-Path $taskRoot 'tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA=Join-Path $taskRoot '.runtime/appdata'
& $taskEngine --headless --path $taskRoot --editor --import
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
$taskLog=Join-Path $taskRoot 'out/city_v7/rebuild.log'
New-Item -ItemType Directory -Force (Split-Path -Parent $taskLog) | Out-Null
& $taskEngine --headless --fixed-fps 60 --path $taskRoot res://scenes/shop/city_v7_checks.tscn -- bake-lods bake-buildings bake-props bake-catalog *> $taskLog
if ($LASTEXITCODE -ne 0 -or (Select-String -Path $taskLog -Pattern 'SCRIPT ERROR|V7_FAIL')) { throw "Build verification failed: $taskLog" }
Write-Host "Prepared city assets and checks completed: $taskLog"
