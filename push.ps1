$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$git = "D:\Program Files\Git\cmd\git.exe"

if (-not (Test-Path $git)) {
    Write-Host "[ERROR] Git not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Init repo if needed
if (-not (Test-Path ".git")) {
    Write-Host "[INIT] Initializing git repository..." -ForegroundColor Yellow
    & $git init
    & $git remote add origin "https://github.com/kicky001/kicky-customs.git"
    & $git branch -M main
}

& $git config user.email "kicky001@users.noreply.github.com"
& $git config user.name "kicky001"

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Pushing to GitHub..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

& $git add index.html worker.js server.ps1 start.bat push.bat push.ps1
& $git commit -m "update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
& $git push origin main --force

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Done! Wait ~1 min then visit:" -ForegroundColor Green
Write-Host "  https://kicky001.github.io/kicky-customs/" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
