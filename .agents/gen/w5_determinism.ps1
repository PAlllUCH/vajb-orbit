# W5 evidence: regenerate the theme twice and compare the .tres sha256.
# Run: powershell -ExecutionPolicy Bypass -File .agents/gen/w5_determinism.ps1
# Paths are derived from this script's own location, so no non-ASCII literal is needed.
$ErrorActionPreference = "Stop"
$godot = "C:\Godot_4_7_2\Godot_v4.7.2-stable_win64_console.exe"
$log = Split-Path -Parent $PSCommandPath
$workspace = Split-Path -Parent (Split-Path -Parent $log)
$proj = Join-Path $workspace "vajb-orbit"
$theme = Join-Path $proj "ui\theme\vajb_theme.tres"

$runs = @()
foreach ($n in 1, 2) {
    $out = Join-Path $log ("w5_theme_run{0}.txt" -f $n)
    & $godot --headless --path $proj --script res://tools/build_theme.gd *> $out
    $exit = $LASTEXITCODE
    $hash = (Get-FileHash -Algorithm SHA256 $theme).Hash
    $size = (Get-Item $theme).Length
    $runs += [pscustomobject]@{ Run = $n; Exit = $exit; Sha256 = $hash; Size = $size; Log = $out }
}
$runs | Format-Table -AutoSize
if ($runs[0].Sha256 -eq $runs[1].Sha256) {
    Write-Output "DETERMINISTIC: run1 and run2 .tres sha256 identical"
} else {
    Write-Output "NOT DETERMINISTIC: sha256 differs between runs"
}
