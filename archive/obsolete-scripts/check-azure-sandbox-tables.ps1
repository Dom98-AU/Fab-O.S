# Check all tables in Azure SQL Database (sqldb-steel-estimation-sandbox)
param(
    [Parameter(Mandatory=$false)]
    [switch]$UseSqlAuth,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SqlPassword
)

$ErrorActionPreference = "Stop"

Write-Host "Checking all tables in Azure SQL Database (sqldb-steel-estimation-sandbox)..." -ForegroundColor Green

# Build connection string based on authentication method
if ($UseSqlAuth) {
    if (-not $SqlPassword) {
        $SqlPassword = Read-Host "Enter SQL Password" -AsSecureString
    }
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
    
    $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Write-Host "Using SQL Authentication" -ForegroundColor Yellow
} else {
    # Use Azure AD authentication
    $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Write-Host "Using Azure AD Authentication" -ForegroundColor Yellow
}

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Query to list all tables with row counts
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCount,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) as ColumnCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1) -- Heap or clustered index
ORDER BY s.name, t.name
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Tables in Azure SQL Database:" -ForegroundColor Cyan
    Write-Host "----------------------------" -ForegroundColor Cyan
    Write-Host "Schema | Table Name | Rows | Columns" -ForegroundColor White
    Write-Host "-------------------------------------" -ForegroundColor White
    
    $tableList = @()
    $totalTables = 0
    $totalRows = 0
    
    while ($reader.Read()) {
        $schemaName = $reader["SchemaName"]
        $tableName = $reader["TableName"]
        $rowCount = $reader["RowCount"]
        $columnCount = $reader["ColumnCount"]
        
        $fullTableName = "$schemaName.$tableName"
        $tableList += $tableName
        $totalTables++
        $totalRows += $rowCount
        
        Write-Host "$schemaName | $tableName | $rowCount | $columnCount" -ForegroundColor White
    }
    
    $reader.Close()
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "Total Tables: $totalTables" -ForegroundColor Green
    Write-Host "Total Rows: $totalRows" -ForegroundColor Green
    
    # Check for specific expected tables
    Write-Host ""
    Write-Host "Checking for core tables..." -ForegroundColor Yellow
    
    $coreTablesExpected = @(
        "Companies",
        "Users", 
        "Roles",
        "UserRoles",
        "Projects",
        "Estimations",
        "Packages",
        "ProcessingItems",
        "WeldingItems",
        "PackageWorksheets",
        "EstimationPackages"
    )
    
    foreach ($table in $coreTablesExpected) {
        if ($tableList -contains $table) {
            Write-Host "✓ $table exists" -ForegroundColor Green
        } else {
            Write-Host "✗ $table is MISSING" -ForegroundColor Red
        }
    }
    
    # Check for new feature tables
    Write-Host ""
    Write-Host "Checking for new feature tables..." -ForegroundColor Yellow
    
    $newFeatureTables = @(
        "EstimationTimeLogs",
        "WeldingItemConnections", 
        "EfficiencyRates",
        "PackBundles",
        "DeliveryBundles"
    )
    
    foreach ($table in $newFeatureTables) {
        if ($tableList -contains $table) {
            Write-Host "✓ $table exists" -ForegroundColor Green
        } else {
            Write-Host "✗ $table is MISSING" -ForegroundColor Red
        }
    }
    
    # Get database size information
    Write-Host ""
    Write-Host "Database Size Information:" -ForegroundColor Yellow
    
    $sizeCommand = $connection.CreateCommand()
    $sizeCommand.CommandText = @"
SELECT 
    DB_NAME() AS DatabaseName,
    SUM(size * 8.0 / 1024) AS SizeMB
FROM sys.database_files
WHERE type = 0 -- Data files only
"@
    
    $sizeReader = $sizeCommand.ExecuteReader()
    if ($sizeReader.Read()) {
        $dbName = $sizeReader["DatabaseName"]
        $sizeMB = [math]::Round($sizeReader["SizeMB"], 2)
        Write-Host "Database: $dbName" -ForegroundColor White
        Write-Host "Size: $sizeMB MB" -ForegroundColor White
    }
    $sizeReader.Close()
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "Database check completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to check tables: $_"
    Write-Host ""
    Write-Host "If you're getting authentication errors, try:" -ForegroundColor Yellow
    Write-Host "  1. Use SQL authentication: .\check-azure-sandbox-tables.ps1 -UseSqlAuth" -ForegroundColor Cyan
    Write-Host "  2. Ensure you're logged into Azure CLI: az login" -ForegroundColor Cyan
    Write-Host "  3. Check your Azure AD permissions on the database" -ForegroundColor Cyan
    exit 1
}