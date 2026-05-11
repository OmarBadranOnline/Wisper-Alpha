$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$part1 = Join-Path $repoRoot "parts\part-1-web-app-backend-integration"
$backendPath = Join-Path $part1 "backend"
$frontendPath = Join-Path $part1 "frontend"
$part2Script = Join-Path $repoRoot "parts\part-2-tools-reports-automation\wisper.sh"
$gitBash = "C:\Program Files\Git\bin\bash.exe"

function Wait-ForUrl {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 120
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) {
                return $true
            }
        }
        catch {}
        Start-Sleep -Seconds 2
    }
    return $false
}

Write-Host ""
Write-Host "Wisper-Alpha Launcher" -ForegroundColor Cyan
Write-Host "1) Terminal Mode  (Part 2 orchestrator)"
Write-Host "2) Web Monitor Mode (Part 1 backend + frontend)"
Write-Host ""
$choice = Read-Host "Select option (1 or 2)"

switch ($choice) {
    "1" {
        if (-not (Test-Path $gitBash)) {
            throw "Git Bash is required for Terminal Mode. Expected at: $gitBash"
        }
        if (-not (Test-Path $part2Script)) {
            throw "Missing script: $part2Script"
        }
        Write-Host "Starting Terminal Mode..." -ForegroundColor Green
        & $gitBash $part2Script
        break
    }
    "2" {
        Write-Host "Starting backend on http://localhost:8000 ..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-NoExit","-Command","Set-Location '$backendPath'; if (-not (Test-Path '.venv\Scripts\python.exe')) { python -m venv .venv }; .\.venv\Scripts\python.exe -m pip install -r requirements.txt; .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

        Write-Host "Starting frontend on http://localhost:5173 ..." -ForegroundColor Green
        Start-Process powershell -ArgumentList "-NoExit","-Command","Set-Location '$frontendPath'; npm install; npm run dev -- --host 0.0.0.0 --port 5173"

        Write-Host "Waiting for backend and GUI to become ready..." -ForegroundColor Yellow
        $backendReady = Wait-ForUrl -Url "http://localhost:8000/api/v1/health" -TimeoutSeconds 180
        $frontendReady = Wait-ForUrl -Url "http://localhost:5173" -TimeoutSeconds 180

        if (-not $backendReady) {
            throw "Backend did not become ready on http://localhost:8000/api/v1/health"
        }
        if (-not $frontendReady) {
            throw "Frontend GUI did not become ready on http://localhost:5173"
        }

        Write-Host "Web monitor is ready. Opening GUI..." -ForegroundColor Green
        Start-Process "http://localhost:5173"
        break
    }
    default {
        throw "Invalid option. Run again and choose 1 or 2."
    }
}
