# Check tables in LocalDB
$connectionString = "Server=(localdb)\mssqllocaldb;Database=SteelEstimationDb;Trusted_Connection=True;"

Write-Host "Checking LocalDB database..." -ForegroundColor Green
Write-Host ""

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Get all tables
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    t.name AS TableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
ORDER BY t.name
"@
    
    $reader = $command.ExecuteReader()
    
    $tables = @()
    while ($reader.Read()) {
        $tables += [PSCustomObject]@{
            TableName = $reader["TableName"]
            RowCount = $reader["RowCount"]
        }
    }
    $reader.Close()
    
    Write-Host "Tables in LocalDB:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    $tables | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "Total tables: $($tables.Count)" -ForegroundColor Green
    Write-Host "Total rows: $(($tables | Measure-Object -Property RowCount -Sum).Sum)" -ForegroundColor Green
    
    $connection.Close()
}
catch {
    Write-Error "Failed to connect to LocalDB: $_"
    Write-Host ""
    Write-Host "Make sure SQL Server LocalDB is installed and the database exists." -ForegroundColor Yellow
    Write-Host "You can create the database by running:" -ForegroundColor Yellow
    Write-Host "  dotnet ef database update" -ForegroundColor Cyan
}