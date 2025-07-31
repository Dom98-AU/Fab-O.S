# Check all tables in the database

$ErrorActionPreference = "Stop"

Write-Host "Checking all tables in SteelEstimationDb..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) as ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Tables in database:" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Cyan
    
    $tableList = @()
    while ($reader.Read()) {
        $tableName = $reader["TABLE_NAME"]
        $columnCount = $reader["ColumnCount"]
        $tableList += $tableName
        Write-Host "$tableName ($columnCount columns)" -ForegroundColor White
    }
    
    $reader.Close()
    
    # Check for specific expected tables
    Write-Host ""
    Write-Host "Checking for expected tables..." -ForegroundColor Yellow
    
    $expectedTables = @("Estimations", "Packages", "ProcessingItems", "WeldingItems", "Users", "Companies")
    
    foreach ($table in $expectedTables) {
        if ($tableList -contains $table) {
            Write-Host "✓ $table exists" -ForegroundColor Green
        } else {
            Write-Host "✗ $table is MISSING" -ForegroundColor Red
        }
    }
    
    $connection.Close()
}
catch {
    Write-Error "Failed to check tables: $_"
    exit 1
}