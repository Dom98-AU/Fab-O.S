Write-Host "Adding maintenance date columns to WorkCenters table..." -ForegroundColor Yellow

$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-sandbox;User ID=admin@nwi@nwiapps;Password=Natweigh88;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check if columns exist
    $checkCommand = $connection.CreateCommand()
    $checkCommand.CommandText = "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name IN ('LastMaintenanceDate', 'NextMaintenanceDate')"
    $existingColumns = $checkCommand.ExecuteScalar()
    
    if ($existingColumns -lt 2) {
        Write-Host "Adding missing columns..." -ForegroundColor Cyan
        
        # Add LastMaintenanceDate if missing
        $cmd1 = $connection.CreateCommand()
        $cmd1.CommandText = "IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'LastMaintenanceDate') ALTER TABLE [dbo].[WorkCenters] ADD [LastMaintenanceDate] datetime2(7) NULL"
        $cmd1.ExecuteNonQuery() | Out-Null
        
        # Add NextMaintenanceDate if missing
        $cmd2 = $connection.CreateCommand()
        $cmd2.CommandText = "IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WorkCenters]') AND name = 'NextMaintenanceDate') ALTER TABLE [dbo].[WorkCenters] ADD [NextMaintenanceDate] datetime2(7) NULL"
        $cmd2.ExecuteNonQuery() | Out-Null
        
        Write-Host "Columns added successfully!" -ForegroundColor Green
    } else {
        Write-Host "Columns already exist." -ForegroundColor Green
    }
    
    $connection.Close()
    
    Write-Host "Restarting container..." -ForegroundColor Yellow
    docker-compose restart web
    
    Write-Host "Complete! Wait 10-15 seconds for container to restart." -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}