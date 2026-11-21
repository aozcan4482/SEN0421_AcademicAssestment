<#
.SYNOPSIS
    Applies the database migrations (and optionally the seed data) in order.

.DESCRIPTION
    Every schema change goes through this single script (RSK-04), so all team
    members end up with an identical database. Applied migrations are recorded
    in the schema_migrations table; running the script again only applies the
    new ones. Each migration runs in its own transaction: if it fails, nothing
    from that file is kept.

.EXAMPLE
    .\database\scripts\migrate.ps1
    .\database\scripts\migrate.ps1 -WithSeed
    .\database\scripts\migrate.ps1 -DbHost localhost -Port 5432 -Database academic_assessment -User aams_app
#>
param(
    [string]$DbHost   = "localhost",
    [int]   $Port     = 5432,
    [string]$Database = "academic_assessment",
    [string]$User     = "aams_app",
    [switch]$WithSeed
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Error "psql was not found. Add the PostgreSQL 'bin' folder to PATH (see database/README.md)."
}

# Ask for the password once instead of at every psql call.
if (-not $env:PGPASSWORD) {
    $secure = Read-Host "Password for '$User'" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    $clearAfter = $true
}
$env:PGCLIENTENCODING = "UTF8"
# Hide informational NOTICE messages (e.g. "already exists, skipping").
$env:PGOPTIONS = "-c client_min_messages=warning"

$conn = @("-h", $DbHost, "-p", $Port, "-d", $Database, "-U", $User, "-v", "ON_ERROR_STOP=1", "-q")

function Invoke-Psql {
    param([string[]]$Arguments)
    # Windows PowerShell 5.1 turns anything a native program writes to stderr
    # into an error; psql's exit code is the reliable success signal instead.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & psql @conn @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
    if ($exitCode -ne 0) { throw ($output | Out-String) }
    return $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
}

try {
    Invoke-Psql @("-c", "CREATE TABLE IF NOT EXISTS schema_migrations (
        version    VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP    NOT NULL DEFAULT NOW());") | Out-Null

    $applied = @(Invoke-Psql @("-tA", "-c", "SELECT version FROM schema_migrations;") |
                 ForEach-Object { "$_".Trim() } | Where-Object { $_ })

    $migrations = Get-ChildItem (Join-Path $root "migrations") -Filter "*.sql" | Sort-Object Name
    $count = 0
    foreach ($file in $migrations) {
        if ($applied -contains $file.Name) { continue }
        Write-Host "Applying $($file.Name) ..." -ForegroundColor Cyan
        # -1 runs the file and the bookkeeping insert in one transaction.
        Invoke-Psql @("-1", "-f", $file.FullName,
                      "-c", "INSERT INTO schema_migrations (version) VALUES ('$($file.Name)');") | Out-Null
        $count++
    }
    if ($count -eq 0) { Write-Host "Database is up to date." -ForegroundColor Green }
    else              { Write-Host "$count migration(s) applied." -ForegroundColor Green }

    if ($WithSeed) {
        foreach ($file in Get-ChildItem (Join-Path $root "seeds") -Filter "*.sql" | Sort-Object Name) {
            Write-Host "Seeding $($file.Name) ..." -ForegroundColor Cyan
            Invoke-Psql @("-1", "-f", $file.FullName) | Out-Null
        }
        Write-Host "Seed data loaded." -ForegroundColor Green
    }
}
catch {
    Write-Host "Migration failed:" -ForegroundColor Red
    Write-Host $_
    exit 1
}
finally {
    if ($clearAfter) { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue }
}
