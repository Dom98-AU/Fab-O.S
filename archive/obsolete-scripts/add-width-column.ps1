Write-Host "Adding Width column to WorksheetColumnOrders table..." -ForegroundColor Cyan

$serverName = "localhost"
$databaseName = "SteelEstimationDb_CloudDev"
$connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    # Check if Width column already exists
    $checkQuery = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'WorksheetColumnOrders' AND COLUMN_NAME = 'Width'"
    $command = $connection.CreateCommand()
    $command.CommandText = $checkQuery
    $exists = $command.ExecuteScalar()
    
    if ($exists -eq 0) {
        # Add Width column
        $command.CommandText = "ALTER TABLE WorksheetColumnOrders ADD Width INT NULL"
        $command.ExecuteNonQuery() | Out-Null
        Write-Host "Width column added successfully!" -ForegroundColor Green
        
        # Update existing rows with default widths
        $command.CommandText = @"
UPDATE WorksheetColumnOrders
SET Width = CASE 
    WHEN ColumnName = 'DrawingNumber' THEN 120
    WHEN ColumnName = 'Quantity' THEN 80
    WHEN ColumnName = 'Description' THEN 250
    WHEN ColumnName = 'Material' THEN 150
    WHEN ColumnName = 'MaterialType' THEN 100
    WHEN ColumnName = 'Weight' THEN 100
    WHEN ColumnName = 'TotalWeight' THEN 100
    WHEN ColumnName = 'DeliveryBundle' THEN 150
    WHEN ColumnName = 'PackBundle' THEN 150
    WHEN ColumnName = 'HandlingTime' THEN 120
    WHEN ColumnName = 'UnloadTime' THEN 140
    WHEN ColumnName = 'MarkMeasureCut' THEN 140
    WHEN ColumnName = 'QualityCheck' THEN 150
    WHEN ColumnName = 'MoveToAssembly' THEN 140
    WHEN ColumnName = 'MoveAfterWeld' THEN 140
    WHEN ColumnName = 'LoadingTime' THEN 150
    WHEN ColumnName = 'ItemDescription' THEN 300
    WHEN ColumnName = 'WeldType' THEN 120
    WHEN ColumnName = 'ConnectionQty' THEN 100
    WHEN ColumnName = 'WeldingConnections' THEN 200
    WHEN ColumnName = 'TotalMinutes' THEN 120
    WHEN ColumnName = 'Images' THEN 200
    ELSE 120
END
WHERE Width IS NULL
"@
        $command.ExecuteNonQuery() | Out-Null
        Write-Host "Default widths set for existing columns!" -ForegroundColor Green
    }
    else {
        Write-Host "Width column already exists." -ForegroundColor Yellow
    }
    
    $connection.Close()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}