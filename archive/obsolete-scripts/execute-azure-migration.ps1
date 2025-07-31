# Execute Azure SQL Migration Script
param(
    [string]$Server = "nwiapps.database.windows.net",
    [string]$Database = "sqldb-steel-estimation-prod",
    [string]$Username = "sqladmin",
    [string]$Password = "7K&8b*nP$qR#5mL@"
)

$connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Connecting to Azure SQL Database..." -ForegroundColor Green

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    Write-Host "Connected successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Read the migration script
    $scriptContent = Get-Content -Path ".\azure-schema-update.sql" -Raw
    
    # Split by GO statements
    $batches = $scriptContent -split '\nGO\r?\n'
    
    $totalBatches = $batches.Count
    $currentBatch = 0
    
    foreach ($batch in $batches) {
        if ([string]::IsNullOrWhiteSpace($batch)) { continue }
        
        $currentBatch++
        Write-Host "Executing batch $currentBatch of $totalBatches..." -ForegroundColor Yellow
        
        try {
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.CommandTimeout = 300
            
            $result = $command.ExecuteNonQuery()
            
            # Check for print statements in the batch
            if ($batch -match 'PRINT') {
                Write-Host "Batch $currentBatch completed" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error in batch $currentBatch : $_" -ForegroundColor Red
            # Continue with next batch
        }
    }
    
    Write-Host ""
    Write-Host "Migration script execution completed!" -ForegroundColor Green
    
    # Verify tables were created
    Write-Host ""
    Write-Host "Verifying created tables..." -ForegroundColor Cyan
    
    $verifyCommand = $connection.CreateCommand()
    $verifyCommand.CommandText = @"
SELECT COUNT(*) as TableCount
FROM sys.tables
WHERE name IN (
    'AspNetRoleClaims', 'AspNetUserClaims', 'AspNetUserLogins', 'AspNetUserTokens',
    'Addresses', 'Customers', 'Contacts', 'ProcessingItems', 'WeldingItems',
    'WeldingItemConnections', 'DeliveryBundles', 'PackBundles', 'EfficiencyRates',
    'EstimationTimeLogs', 'Postcodes'
)
"@
    
    $reader = $verifyCommand.ExecuteReader()
    if ($reader.Read()) {
        $tableCount = $reader["TableCount"]
        Write-Host "Created/verified $tableCount tables" -ForegroundColor Green
    }
    $reader.Close()
    
    # List all tables
    Write-Host ""
    Write-Host "All tables in Azure SQL Database:" -ForegroundColor Cyan
    
    $listCommand = $connection.CreateCommand()
    $listCommand.CommandText = "SELECT name FROM sys.tables ORDER BY name"
    
    $reader = $listCommand.ExecuteReader()
    while ($reader.Read()) {
        Write-Host "  - $($reader["name"])" -ForegroundColor Gray
    }
    $reader.Close()
    
    $connection.Close()
}
catch {
    Write-Error "Failed to execute migration: $_"
}
finally {
    if ($connection.State -eq 'Open') {
        $connection.Close()
    }
}