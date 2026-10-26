# Lance plusieurs parties e2e (tools/e2e_play.gd) en parallele, chacune dans son processus, puis resume.
# Usage : powershell -Command ".\tools\e2e_run.ps1 -Seeds (1..10) -Days 10 [-Dt 1.5] [-Mode fast|real] [-Scale 10] [-Parallel 8] [-NoSubs] [-Tag nom] [-Windowed]"
# Sortie : out\e2e\<Tag>\seed<N>.log et un resume (E2E_FAIL / SCRIPT ERROR / ERROR) + tableau d'equilibrage moyen par jour.
# Code de sortie non nul si une partie echoue ou plante.
param(
    [int[]]$Seeds = (1..10),
    [int]$Days = 10,
    [double]$Dt = 1.5,
    [string]$Mode = "fast",
    [double]$Scale = 10,
    [int]$Parallel = 8,
    [string]$Tag = "run",
    [int]$Staff = 1,
    [int]$StaffDay = 4,
    [switch]$NoSubs,
    [switch]$Windowed,
    [switch]$Verbose
)
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $root "tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
$outDir = Join-Path $root "out\e2e\$Tag"
New-Item -ItemType Directory -Force $outDir | Out-Null
& $godot --headless --path $root --import --quit *> $null

$jobs = @()
foreach ($s in $Seeds) {
    while (@($jobs | Where-Object { -not $_.Proc.HasExited }).Count -ge $Parallel) { Start-Sleep -Milliseconds 500 }
    $log = Join-Path $outDir "seed$s.log"
    $err = Join-Path $outDir "seed$s.err"
    $a = @("--path", $root)
    if (-not $Windowed) { $a = @("--headless") + $a } else { $a += @("--resolution", "1280x720") }
    $a += @("-s", "res://tools/e2e_play.gd", "--", "--seed=$s", "--days=$Days", "--dt=$Dt", "--mode=$Mode", "--scale=$Scale")
    if ($NoSubs) { $a += "--subs=0" }
    $a += @("--staff=$Staff", "--staff-day=$StaffDay")
    if ($Verbose) { $a += "--verbose" }
    $p = Start-Process -FilePath $godot -ArgumentList $a -RedirectStandardOutput $log -RedirectStandardError $err -PassThru -WindowStyle Hidden
    $null = $p.Handle
    $jobs += [pscustomobject]@{ Seed = $s; Proc = $p; Log = $log; Err = $err }
}
foreach ($j in $jobs) { $j.Proc.WaitForExit() }

$bad = 0
$rows = @()
foreach ($j in $jobs) {
    $text = (Get-Content $j.Log -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content $j.Err -Raw -ErrorAction SilentlyContinue)
    $lines = $text -split "`n"
    $fails = $lines | Where-Object { $_ -match "E2E_FAIL|SCRIPT ERROR|Parse Error" }
    $sum = $lines | Where-Object { $_ -match "E2E_SUMMARY" } | Select-Object -First 1
    Write-Host ("== seed {0} : exit {1}" -f $j.Seed, $j.Proc.ExitCode)
    if ($fails) { $bad++; $fails | Select-Object -First 8 | ForEach-Object { Write-Host ("   " + $_.Substring(0, [Math]::Min(330, $_.Length))) } }
    elseif ($j.Proc.ExitCode -ne 0) { $bad++ }
    if (-not $sum) { $bad++; Write-Host "   (pas de E2E_SUMMARY : plantage ou boucle interrompue)" }
    foreach ($l in $lines) {
        if ($l -match "^E2E_DAY seed=\d+ (\{.*\})") { $rows += ($Matches[1] | ConvertFrom-Json) }
    }
}
Write-Host ("e2e : {0} partie(s), {1} en echec" -f $jobs.Count, $bad)

# equilibrage : moyenne par jour sur toutes les parties
if ($rows.Count -gt 0) {
    function V($r, $k) { if ($r.PSObject.Properties[$k]) { [double]$r.$k } else { 0.0 } }
    Write-Host "jour  n  ventes_fleur  net_legit  stock_achete  perdu(tiges)  clandestin_produit  converti  visites_police  sanctions  voleurs  caisse_fin  caisse_min  clandestin_fin  rep  ext  charges  salaires  ventes_employes  ventes_xeno"
    foreach ($g in ($rows | Group-Object day | Sort-Object { [int]$_.Name })) {
        $n = $g.Count
        function Avg($k) { ($g.Group | ForEach-Object { V $_ $k } | Measure-Object -Average).Average }
        $cmin = ($g.Group | ForEach-Object { V $_ "legit_end" } | Measure-Object -Minimum).Minimum
        $net = ($g.Group | ForEach-Object { (V $_ "legit_end") - (V $_ "legit_start") } | Measure-Object -Average).Average
        Write-Host ("{0,4} {1,2} {2,12:N0} {3,10:N0} {4,13:N0} {5,13:N1} {6,19:N0} {7,9:N0} {8,15:N2} {9,10:N2} {10,8:N2} {11,11:N0} {12,11:N0} {13,15:N0} {14,6:N0} {15,5:N1} {16,8:N0} {17,9:N0} {18,16:N0} {19,11:N0}" -f `
            $g.Name, $n, (Avg "sales_amount"), $net, (Avg "stock_spent"), (Avg "wilted_lost"), (Avg "earn_shady_product"), (Avg "converted"), (Avg "police_visits"), (Avg "sanctions"), (Avg "thieves"), (Avg "legit_end"), $cmin, (Avg "shady_end"), (Avg "rep"), (Avg "exp_owned"), (Avg "charges_due"), (Avg "wages"), (Avg "employee_sales_amount"), (Avg "foreign_euros"))
    }
}
exit ([int]($bad -gt 0))
