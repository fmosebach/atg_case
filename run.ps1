#Requires -Version 5.1
<#
.SYNOPSIS
  Runs the full pipeline: SWAPI ingestion -> dbt build.
#>
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Fail([string]$Message, [int]$Code = 1) {
    if ($Code -eq 0) { $Code = 1 }
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit $Code
}

# Load .env into the process environment (read by ingestion and dbt profiles.yml).
# Like python-dotenv, variables already set in the environment win; empty values are skipped.
$envFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envFile)) {
    Fail ".env not found. Copy .env.example to .env and fill it in."
}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $name, $value = $line -split '=', 2
    if ($null -eq $value) { return }
    $name = $name.Trim()
    $value = $value.Trim().Trim('"').Trim("'")
    if ($value -eq '' -or [Environment]::GetEnvironmentVariable($name, 'Process')) { return }
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

# Fail fast: otherwise a missing variable is only discovered after all SWAPI data has been fetched
$missing = 'SNOWFLAKE_ACCOUNT', 'SNOWFLAKE_USER', 'SNOWFLAKE_ROLE', 'SNOWFLAKE_WAREHOUSE', 'SNOWFLAKE_DATABASE' |
    Where-Object { -not [Environment]::GetEnvironmentVariable($_, 'Process') }
if ($missing) {
    Fail "Missing required variables in .env: $($missing -join ', ')"
}
if ($env:SWAPI_BASE_URL -match 'swapi\.tech') {
    Fail "SWAPI_BASE_URL points to swapi.tech, whose response format is not supported. Use https://swapi.dev/api or leave it unset."
}

# Activate venv unless one is already active
if (-not $env:VIRTUAL_ENV) {
    $activate = Join-Path $PSScriptRoot '.venv\Scripts\Activate.ps1'
    if (-not (Test-Path $activate)) {
        Fail ".venv not found. Create it with: python -m venv .venv; then pip install -r requirements.txt"
    }
    . $activate
}
if (-not (Get-Command dbt -ErrorAction SilentlyContinue)) {
    Fail "dbt not found in the active environment. Run: pip install -r requirements.txt"
}

# Native tools (python logging, dbt) write progress to stderr; with 'Stop' PowerShell 5.1 can turn that into
# a terminating error. Run them with 'Continue' and rely on $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'

Write-Host "Note: Snowflake SSO opens a browser tab for login, once for ingestion and once for dbt." -ForegroundColor Yellow

Write-Host "`n[1/3] Ingestion: python ingestion/run.py" -ForegroundColor Cyan
python ingestion/run.py
if ($LASTEXITCODE -ne 0) {
    Fail "Ingestion failed (exit code $LASTEXITCODE). dbt was NOT run." $LASTEXITCODE
}

Push-Location (Join-Path $PSScriptRoot 'dbt_projects\swapi_dbt')
try {
    Write-Host "`n[2/3] Packages: dbt deps" -ForegroundColor Cyan
    dbt deps
    if ($LASTEXITCODE -ne 0) {
        Fail "dbt deps failed (exit code $LASTEXITCODE)." $LASTEXITCODE
    }

    Write-Host "`n[3/3] Transformation: dbt build" -ForegroundColor Cyan
    dbt build
    if ($LASTEXITCODE -ne 0) {
        Fail "dbt build failed (exit code $LASTEXITCODE)." $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

Write-Host "`nPipeline completed successfully." -ForegroundColor Green
exit 0
