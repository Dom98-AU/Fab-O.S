#!/usr/bin/env pwsh

Write-Host "Running WorkCenters Maintenance Date Migration..." -ForegroundColor Yellow

# Use the connection string from .env file
$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-sandbox;User ID=admin@nwi@nwiapps;Password=Natweigh88;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;MultipleActiveResultSets=true"

$migrationScript = @"
-- Add maintenance date columns to WorkCenters table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'LastMaintenanceDate')
BEGIN
    ALTER TABLE [dbo].[WorkCenters] ADD [LastMaintenanceDate] datetime2(7) NULL;
    PRINT 'Added LastMaintenanceDate column to WorkCenters table';
END
ELSE
BEGIN
    PRINT 'LastMaintenanceDate column already exists';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'NextMaintenanceDate')
BEGIN
    ALTER TABLE [dbo].[WorkCenters] ADD [NextMaintenanceDate] datetime2(7) NULL;
    PRINT 'Added NextMaintenanceDate column to WorkCenters table';
END
ELSE
BEGIN
    PRINT 'NextMaintenanceDate column already exists';
END
"@

try {
    Write-Host "Connecting to Azure SQL Database..." -ForegroundColor Cyan
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    Write-Host "Executing migration..." -ForegroundColor Cyan
    $command = $connection.CreateCommand()
    $command.CommandText = $migrationScript
    $command.CommandTimeout = 60
    
    # Capture info messages
    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
        param($sender, $event)
        Write-Host $event.Message -ForegroundColor Gray
    }
    $connection.add_InfoMessage($handler)
    $connection.FireInfoMessageEventOnUserErrors = $true
    
    $result = $command.ExecuteNonQuery()
    
    Write-Host "`nMigration completed successfully!" -ForegroundColor Green
    
    # Verify columns were added
    Write-Host "`nVerifying columns:" -ForegroundColor Yellow
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
        ORDER BY c.name
"@
    
    $reader = $verifyCommand.ExecuteReader()
    $foundColumns = @()
    while ($reader.Read()) {
        $columnName = $reader['ColumnName']
        $dataType = $reader['DataType']
        $nullable = if($reader['is_nullable']) { "Yes" } else { "No" }
        Write-Host "  ✓ $columnName : $dataType (Nullable: $nullable)" -ForegroundColor Green
        $foundColumns += $columnName
    }
    $reader.Close()
    
    if ($foundColumns.Count -eq 2) {
        Write-Host "`nBoth maintenance date columns verified successfully!" -ForegroundColor Green
    } elseif ($foundColumns.Count -eq 0) {
        Write-Host "`nWarning: No maintenance columns found!" -ForegroundColor Red
    } else {
        Write-Host "`nWarning: Only found $($foundColumns.Count) column(s)" -ForegroundColor Yellow
    }
    
    $connection.Close()
}
catch {
    Write-Host "`nError running migration: $_" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`nRestarting Docker container to apply changes..." -ForegroundColor Yellow
docker-compose restart web

Write-Host "`nWaiting for container to be ready (15 seconds)..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "`nMigration and restart complete!" -ForegroundColor Green
Write-Host "The WorkCenters page should now load correctly." -ForegroundColor Green