#!/usr/bin/env pwsh

Write-Host "Running WorkCenters Maintenance Date Migration..." -ForegroundColor Yellow

$connectionString = "Server=tcp:fabos-sqlserver.database.windows.net,1433;Initial Catalog=fabos-db;Persist Security Info=False;User ID=fabos-admin;Password=F@bOS2024Admin!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"

$migrationScript = Get-Content "./SteelEstimation.Infrastructure/Migrations/AddMaintenanceDatesToWorkCenters.sql" -Raw

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $migrationScript
    $command.CommandTimeout = 60
    
    $result = $command.ExecuteNonQuery()
    
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    
    # Verify columns were added
    $verifyCommand = $connection.CreateCommand()
    $verifyCommand.CommandText = @"
        SELECT 
            c.name AS ColumnName,
            t.name AS DataType,
            c.max_length,
            c.is_nullable
        FROM sys.columns c
        INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('WorkCenters')
        AND c.name IN ('LastMaintenanceDate', 'NextMaintenanceDate')
"@
    
    $reader = $verifyCommand.ExecuteReader()
    Write-Host "`nVerifying columns:" -ForegroundColor Cyan
    while ($reader.Read()) {
        Write-Host "  - $($reader['ColumnName']): $($reader['DataType']) (Nullable: $($reader['is_nullable']))" -ForegroundColor White
    }
    $reader.Close()
    
    $connection.Close()
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nRestarting Docker container to apply changes..." -ForegroundColor Yellow
docker-compose restart web

Write-Host "`nMigration and restart complete!" -ForegroundColor Green