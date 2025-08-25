# PowerShell script to check and run Work Centers migration with detailed output
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Work Centers Migration Check & Execute" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Load connection string from .env file
$envPath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^SQLCONNSTR_DefaultConnection=(.*)$') {
            $connectionString = $matches[1]
            Write-Host "✓ Connection string loaded from .env file" -ForegroundColor Green
        }
    }
} else {
    Write-Host "✗ .env file not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Parse connection string
$connectionParts = @{}
$connectionString -split ';' | ForEach-Object {
    if ($_ -match '^([^=]+)=(.+)$') {
        $connectionParts[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$server = $connectionParts["Server"] -replace "tcp:", ""
$database = $connectionParts["Database"] -or $connectionParts["Initial Catalog"]
$userId = $connectionParts["User ID"]
$password = $connectionParts["Password"]

Write-Host "Server: $server" -ForegroundColor Yellow
Write-Host "Database: $database" -ForegroundColor Yellow
Write-Host ""

# Create a check query to see if tables exist
$checkQuery = @"
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WorkCenters') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS WorkCenters,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MachineCenters') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS MachineCenters,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WorkCenterSkills') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS WorkCenterSkills,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WorkCenterShifts') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS WorkCenterShifts,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MachineCapabilities') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS MachineCapabilities,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MachineOperators') 
         THEN 'EXISTS' ELSE 'NOT EXISTS' END AS MachineOperators
"@

Write-Host "Checking if tables already exist..." -ForegroundColor Cyan

try {
    # Use SqlClient to check tables
    Add-Type -AssemblyName System.Data
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = $connectionString
    $conn.Open()
    
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $checkQuery
    $reader = $cmd.ExecuteReader()
    
    $tablesExist = $false
    if ($reader.Read()) {
        Write-Host "`nTable Status:" -ForegroundColor Cyan
        Write-Host "  WorkCenters:         $($reader['WorkCenters'])" -ForegroundColor $(if ($reader['WorkCenters'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        Write-Host "  MachineCenters:      $($reader['MachineCenters'])" -ForegroundColor $(if ($reader['MachineCenters'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        Write-Host "  WorkCenterSkills:    $($reader['WorkCenterSkills'])" -ForegroundColor $(if ($reader['WorkCenterSkills'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        Write-Host "  WorkCenterShifts:    $($reader['WorkCenterShifts'])" -ForegroundColor $(if ($reader['WorkCenterShifts'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        Write-Host "  MachineCapabilities: $($reader['MachineCapabilities'])" -ForegroundColor $(if ($reader['MachineCapabilities'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        Write-Host "  MachineOperators:    $($reader['MachineOperators'])" -ForegroundColor $(if ($reader['MachineOperators'] -eq 'EXISTS') { 'Green' } else { 'Yellow' })
        
        if ($reader['WorkCenters'] -eq 'EXISTS') {
            $tablesExist = $true
        }
    }
    $reader.Close()
    
    if ($tablesExist) {
        Write-Host "`n✓ Tables already exist! Checking for data..." -ForegroundColor Green
        
        # Check if there's data
        $cmd.CommandText = "SELECT COUNT(*) as Count FROM WorkCenters"
        $count = $cmd.ExecuteScalar()
        Write-Host "  Work Centers count: $count" -ForegroundColor Cyan
        
        $cmd.CommandText = "SELECT COUNT(*) as Count FROM MachineCenters"
        $count = $cmd.ExecuteScalar()
        Write-Host "  Machine Centers count: $count" -ForegroundColor Cyan
        
        Write-Host "`nMigration appears to be already complete!" -ForegroundColor Green
        $response = Read-Host "`nDo you want to re-run the migration anyway? (y/n)"
        if ($response -ne 'y') {
            $conn.Close()
            Write-Host "Exiting without changes." -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 0
        }
    } else {
        Write-Host "`nTables do not exist. Running migration..." -ForegroundColor Yellow
    }
    
    $conn.Close()
} catch {
    Write-Host "Error checking tables: $_" -ForegroundColor Red
    Write-Host "Attempting to run migration anyway..." -ForegroundColor Yellow
}

# Path to the migration SQL file
$migrationPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations\AddWorkAndMachineCenters.sql"

if (-not (Test-Path $migrationPath)) {
    Write-Host "✗ Migration file not found at $migrationPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`nExecuting migration script..." -ForegroundColor Cyan

try {
    # Find sqlcmd
    $sqlcmdPath = $null
    
    # Check various locations for sqlcmd
    $possiblePaths = @(
        "sqlcmd",
        "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Microsoft SQL Server\150\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Microsoft SQL Server\140\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Microsoft SQL Server\120\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe",
        "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe",
        "C:\Program Files\Azure Data Studio\bin\sqlcmd.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if ($path -eq "sqlcmd") {
            $test = Get-Command sqlcmd -ErrorAction SilentlyContinue
            if ($test) {
                $sqlcmdPath = "sqlcmd"
                break
            }
        } elseif (Test-Path $path) {
            $sqlcmdPath = $path
            break
        }
    }
    
    if (-not $sqlcmdPath) {
        Write-Host "✗ sqlcmd not found. Please install SQL Server command line tools." -ForegroundColor Red
        Write-Host "Download from: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host "Using sqlcmd from: $sqlcmdPath" -ForegroundColor Gray
    
    # Execute the migration
    & $sqlcmdPath -S $server -d $database -U $userId -P $password -i $migrationPath -C -b
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "✓ Migration completed successfully!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Created tables:" -ForegroundColor Cyan
        Write-Host "  • WorkCenters" -ForegroundColor White
        Write-Host "  • MachineCenters" -ForegroundColor White
        Write-Host "  • WorkCenterSkills" -ForegroundColor White
        Write-Host "  • WorkCenterShifts" -ForegroundColor White
        Write-Host "  • MachineCapabilities" -ForegroundColor White
        Write-Host "  • MachineOperators" -ForegroundColor White
        Write-Host ""
        Write-Host "Sample data has been inserted for testing." -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Restart your application" -ForegroundColor White
        Write-Host "2. Navigate to Settings -> Business Configuration" -ForegroundColor White
        Write-Host "3. Manage Work Centers and Machine Centers" -ForegroundColor White
    } else {
        Write-Host "`n✗ Migration failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Please check the error messages above." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`n✗ Error executing migration: $_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"