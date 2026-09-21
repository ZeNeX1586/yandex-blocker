# Yandex Blocker

One-shot PowerShell script that permanently blocks installation and operation of all Yandex software on Windows: Browser, Disk, Launcher, Updater and any installer named Yandex*.exe.

## What it does

Four independent layers of protection:

| # | Layer | Mechanism |
|---|-------|-----------|
| 1 | IFEO | Kills installer processes on launch |
| 2 | DisallowRun | Explorer policy forbids listed .exe |
| 3 | Services | Stops and disables any service with "Yandex" in its name |
| 4 | hosts | Redirects 26 Yandex domains to 127.0.0.1 |

## Requirements

- Windows 10 or 11
- PowerShell 5.1+
- Administrator rights

## Usage

Open PowerShell as Administrator, then:

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    .\block_yandex.ps1

Reboot after running.

## Unblocking

    .\unblock_yandex.ps1

Reboot after unblocking.

## Disclaimer

The script modifies the registry and hosts file. Antivirus may warn. Use at your own risk.

## License

MIT
