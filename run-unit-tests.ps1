$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$part1Backend = Join-Path $repoRoot "parts\part-1-web-app-backend-integration\backend"
$part1Frontend = Join-Path $repoRoot "parts\part-1-web-app-backend-integration\frontend"
$part2Script = Join-Path $repoRoot "parts\part-2-tools-reports-automation\wisper.sh"
$part3Root = Join-Path $repoRoot "parts\part-3-database-dashboard-final-report"
$gitBash = "C:\Program Files\Git\bin\bash.exe"
$failed = $false

function Run-Step {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    try {
        & $Action
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    catch {
        Write-Host "[FAIL] $Name`n$($_.Exception.Message)" -ForegroundColor Red
        $script:failed = $true
    }
}

Run-Step "Part 1 backend unit tests" {
    Set-Location $part1Backend
    if (-not (Test-Path ".venv\Scripts\python.exe")) {
        python -m venv .venv
    }
    .\.venv\Scripts\python.exe -m pip install -r requirements.txt
    .\.venv\Scripts\python.exe -m pytest -q
}

Run-Step "Part 1 frontend build check" {
    Set-Location $part1Frontend
    npm install --silent
    npm run build --silent
}

Run-Step "Part 2 script syntax validation" {
    if (-not (Test-Path $gitBash)) {
        throw "Git Bash not found: $gitBash"
    }
    & $gitBash -n $part2Script
}

Run-Step "Part 3 deliverable structure validation" {
    Set-Location $part3Root
    $required = @(
        "01-scope-and-deliverables.md",
        "02-technical-structure.md",
        "03-execution-plan.md",
        "04-data-contract-plan.md",
        "README.md",
        "pentest.zip"
    )
    foreach ($item in $required) {
        if (-not (Test-Path (Join-Path $part3Root $item))) {
            throw "Missing required Part 3 artifact: $item"
        }
    }
}

Write-Host ""
if ($failed) {
    Write-Host "Some checks failed." -ForegroundColor Red
    exit 1
}

Write-Host "All part checks passed." -ForegroundColor Green
