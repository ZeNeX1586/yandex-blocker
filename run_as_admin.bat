@echo off
powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0block_yandex.ps1\"' -Verb RunAs"

