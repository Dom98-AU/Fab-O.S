Write-Host "Updating column widths for better spacing..." -ForegroundColor Cyan

$serverName = "localhost"
$databaseName = "SteelEstimationDb_CloudDev"
$connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    # Update column widths for all columns
    $command = $connection.CreateCommand()
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
    ELSE Width  -- Keep existing width if not in list
END
WHERE WorksheetColumnViewId IN (
    SELECT Id FROM WorksheetColumnViews 
    WHERE WorksheetType IN ('Processing', 'Welding')
)
"@
    
    $rowsAffected = $command.ExecuteNonQuery()
    Write-Host "Updated $rowsAffected column width settings!" -ForegroundColor Green
    
    # Show current width settings for processing columns
    $command.CommandText = @"
SELECT TOP 20 wcv.ViewName, wco.ColumnName, wco.Width
FROM WorksheetColumnOrders wco
INNER JOIN WorksheetColumnViews wcv ON wco.WorksheetColumnViewId = wcv.Id
WHERE wcv.WorksheetType = 'Processing'
ORDER BY wcv.ViewName, wco.DisplayOrder
"@
    
    $reader = $command.ExecuteReader()
    Write-Host "`nProcessing worksheet column widths:" -ForegroundColor Yellow
    while ($reader.Read()) {
        $viewName = $reader['ViewName']
        $columnName = $reader['ColumnName']
        $width = $reader['Width']
        Write-Host "  $columnName`: ${width}px" -ForegroundColor Green
    }
    $reader.Close()
    
    $connection.Close()
    
    Write-Host "`nColumn widths updated successfully!" -ForegroundColor Green
    Write-Host "Tables now have proper spacing with horizontal scrolling enabled." -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}