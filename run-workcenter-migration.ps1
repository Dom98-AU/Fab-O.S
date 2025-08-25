# PowerShell script to run the Work Centers and Machine Centers migration
Write-Host "Running Work Centers and Machine Centers Migration..." -ForegroundColor Green

# Load connection string from .env file
$envPath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^SQLCONNSTR_DefaultConnection=(.*)$') {
            $env:ConnectionString = $matches[1]
            Write-Host "Connection string loaded from .env file" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Warning: .env file not found. Using connection string from appsettings.json" -ForegroundColor Yellow
    $appSettings = Get-Content (Join-Path $PSScriptRoot "SteelEstimation.Web\appsettings.json") | ConvertFrom-Json
    $env:ConnectionString = $appSettings.ConnectionStrings.DefaultConnection
}

if ([string]::IsNullOrEmpty($env:ConnectionString)) {
    Write-Host "Error: No connection string found!" -ForegroundColor Red
    exit 1
}

# Path to the migration SQL file
$migrationPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations\AddWorkAndMachineCenters.sql"

if (-not (Test-Path $migrationPath)) {
    Write-Host "Error: Migration file not found at $migrationPath" -ForegroundColor Red
    exit 1
}

Write-Host "Executing migration script..." -ForegroundColor Cyan

try {
    # Execute the SQL migration using sqlcmd
    $sqlcmdPath = "sqlcmd"
    
    # Check if sqlcmd is available
    $sqlcmdTest = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if (-not $sqlcmdTest) {
        # Try to use the Azure Data Studio sqlcmd
        $sqlcmdPath = "C:\Program Files\Azure Data Studio\bin\sqlcmd.exe"
        if (-not (Test-Path $sqlcmdPath)) {
            # Try SQL Server sqlcmd
            $sqlcmdPath = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe"
            if (-not (Test-Path $sqlcmdPath)) {
                Write-Host "Error: sqlcmd not found. Please install SQL Server command line tools." -ForegroundColor Red
                exit 1
            }
        }
    }
    
    # Parse connection string to get server and database
    $connectionParts = @{}
    $env:ConnectionString -split ';' | ForEach-Object {
        if ($_ -match '^([^=]+)=(.+)$') {
            $connectionParts[$matches[1]] = $matches[2]
        }
    }
    
    $server = $connectionParts["Server"] -replace "tcp:", ""
    $database = $connectionParts["Database"]
    $userId = $connectionParts["User ID"]
    $password = $connectionParts["Password"]
    
    Write-Host "Connecting to server: $server" -ForegroundColor Cyan
    Write-Host "Database: $database" -ForegroundColor Cyan
    
    # Execute the migration
    & $sqlcmdPath -S $server -d $database -U $userId -P $password -i $migrationPath -C
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nMigration completed successfully!" -ForegroundColor Green
        Write-Host "Work Centers and Machine Centers tables have been created." -ForegroundColor Green
        Write-Host "Sample data has been inserted for testing." -ForegroundColor Green
    } else {
        Write-Host "`nError: Migration failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} catch {
    Write-Host "`nError executing migration: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nYou can now use the Work Centers and Machine Centers features in the application." -ForegroundColor Yellow
Write-Host "Navigate to Settings -> Business Configuration to manage work and machine centers." -ForegroundColor Yellow