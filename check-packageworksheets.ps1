# Check PackageWorksheets table structure

$ErrorActionPreference = "Stop"

Write-Host "Checking PackageWorksheets table structure..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check columns in PackageWorksheets table
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PackageWorksheets'
ORDER BY ORDINAL_POSITION
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Columns in PackageWorksheets table:" -ForegroundColor Cyan
    Write-Host "------------------------------------" -ForegroundColor Cyan
    
    while ($reader.Read()) {
        $columnName = $reader["COLUMN_NAME"]
        $dataType = $reader["DATA_TYPE"]
        $nullable = $reader["IS_NULLABLE"]
        $maxLength = $reader["CHARACTER_MAXIMUM_LENGTH"]
        
        $columnInfo = "$columnName ($dataType"
        if ($maxLength -ne [DBNull]::Value) {
            $columnInfo += "($maxLength)"
        }
        $columnInfo += ", $nullable)"
        
        Write-Host $columnInfo -ForegroundColor White
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Error "Failed to check table structure: $_"
    exit 1
}