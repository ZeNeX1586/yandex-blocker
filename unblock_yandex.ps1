# Yandex Blocker - rollback script
# Run as Administrator!
$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Yandex Unblocker v1.0 ===" -ForegroundColor Magenta
Write-Host ""

$yandexInstallers = @(
    "Yandex.exe","YandexSetup.exe","YandexBrowserSetup.exe","YandexInstaller.exe",
    "YandexBrowser.exe","YandexLauncher.exe","YandexUpdater.exe","YandexDiskSetup.exe","browser.exe"
)
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
foreach ($exe in $yandexInstallers) {
    $keyPath = Join-Path $ifeoPath $exe
    if (Test-Path $keyPath) {
        Remove-Item -Path $keyPath -Recurse -Force
        Write-Host "  Removed: $exe" -ForegroundColor Green
    }
}

$disallowPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (Test-Path $disallowPath) {
    Set-ItemProperty -Path $disallowPath -Name "DisallowRun" -Value 0 -Type DWord -Force
    $disallowRunPath = Join-Path $disallowPath "DisallowRun"
    if (Test-Path $disallowRunPath) { Remove-Item -Path $disallowRunPath -Recurse -Force }
}

$yandexServiceKeywords = @("Yandex","YandexBrowser","YandexUpdater","YandexDisk")
Get-Service | Where-Object {
    $svc = $_
    $m = $false
    foreach ($kw in $yandexServiceKeywords) {
        if ($svc.Name -like "*$kw*" -or $svc.DisplayName -like "*$kw*") { $m = $true; break }
    }
    $m
} | ForEach-Object {
    Set-Service -Name $_.Name -StartupType Manual -ErrorAction SilentlyContinue
    Write-Host "  Restored: $($_.Name) -> Manual" -ForegroundColor Green
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
$hostsContent = $hostsContent -replace "(?s)`r?`n?# --- YANDEX BLOCK START ---.*?# --- YANDEX BLOCK END ---", ""
Set-Content -Path $hostsPath -Value ($hostsContent.TrimEnd() + "`r`n") -Force
ipconfig /flushdns | Out-Null

Write-Host ""
Write-Host "=== Done! Reboot your PC. ===" -ForegroundColor Magenta
