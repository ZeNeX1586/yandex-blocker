# Full block of Yandex services and installers
# Run as Administrator!

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Blocking Yandex installers (IFEO) ===" -ForegroundColor Cyan

$yandexInstallers = @(
    "Yandex.exe",
    "YandexSetup.exe",
    "YandexBrowserSetup.exe",
    "YandexInstaller.exe",
    "YandexBrowser.exe",
    "YandexLauncher.exe",
    "YandexUpdater.exe",
    "YandexDiskSetup.exe",
    "browser.exe"
)

$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"

foreach ($exe in $yandexInstallers) {
    $keyPath = Join-Path $ifeoPath $exe
    if (-not (Test-Path $keyPath)) {
        New-Item -Path $keyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $keyPath -Name "Debugger" -Value "cmd.exe /c exit" -Type String -Force
    Write-Host "  Blocked: $exe" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Blocking via registry (DisallowRun) ===" -ForegroundColor Cyan

$disallowPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (-not (Test-Path $disallowPath)) {
    New-Item -Path $disallowPath -Force | Out-Null
}
Set-ItemProperty -Path $disallowPath -Name "DisallowRun" -Value 1 -Type DWord -Force

$disallowRunPath = Join-Path $disallowPath "DisallowRun"
if (-not (Test-Path $disallowRunPath)) {
    New-Item -Path $disallowRunPath -Force | Out-Null
}

$blockedNames = @(
    "browser.exe", "Yandex.exe", "YandexSetup.exe", "YandexBrowserSetup.exe",
    "YandexInstaller.exe", "YandexBrowser.exe", "YandexLauncher.exe",
    "YandexUpdater.exe", "YandexDiskSetup.exe"
)

$i = 1
foreach ($name in $blockedNames) {
    Set-ItemProperty -Path $disallowRunPath -Name "$i" -Value $name -Type String -Force
    $i++
}
Write-Host "  Added to DisallowRun: $($blockedNames.Count) entries" -ForegroundColor Green

Write-Host ""
Write-Host "=== Disabling Yandex services ===" -ForegroundColor Cyan

$yandexServiceKeywords = @("Yandex", "YandexBrowser", "YandexUpdater", "YandexDisk")

$allServices = Get-Service | Where-Object {
    $svc = $_
    $match = $false
    foreach ($kw in $yandexServiceKeywords) {
        if ($svc.Name -like "*$kw*" -or $svc.DisplayName -like "*$kw*") {
            $match = $true
            break
        }
    }
    $match
}

if ($allServices) {
    foreach ($svc in $allServices) {
        Write-Host "  Found service: $($svc.Name) ($($svc.DisplayName))" -ForegroundColor Yellow
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "    -> Stopped and disabled." -ForegroundColor Green
    }
} else {
    Write-Host "  No Yandex services found." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Blocking Yandex domains via hosts ===" -ForegroundColor Cyan

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$yandexDomains = @(
    "yandex.ru", "yandex.net", "yandex.com", "ya.ru",
    "yandex.st", "yastatic.net", "yandexcloud.net",
    "browser.yandex.ru", "updater.yandex.ru", "api.yandex.ru",
    "clck.yandex.ru", "mc.yandex.ru", "an.yandex.ru"
)

$hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
if (-not $hostsContent) { $hostsContent = "" }

$markerStart = "# --- YANDEX BLOCK START ---"
$markerEnd = "# --- YANDEX BLOCK END ---"

$hostsContent = $hostsContent -replace "(?s)$markerStart.*?$markerEnd", ""

$blockLines = @($markerStart)
foreach ($domain in $yandexDomains) {
    $blockLines += "127.0.0.1 $domain"
    $blockLines += "127.0.0.1 www.$domain"
}
$blockLines += $markerEnd
$blockText = $blockLines -join "`r`n"

$newHosts = $hostsContent.TrimEnd() + "`r`n`r`n" + $blockText + "`r`n"
Set-Content -Path $hostsPath -Value $newHosts -Force -ErrorAction SilentlyContinue

Write-Host "  Yandex domains added to hosts (127.0.0.1)." -ForegroundColor Green
Write-Host "  Note: some domains may be used by other services." -ForegroundColor Gray

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Magenta
Write-Host "Reboot may be required for some changes to take effect." -ForegroundColor Yellow
Write-Host "To revert, use the unblock script (see instructions)." -ForegroundColor Yellow