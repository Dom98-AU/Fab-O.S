Write-Host "Updating column visibility for handling time columns..." -ForegroundColor Cyan

$serverName = "localhost"
$databaseName = "SteelEstimationDb_CloudDev"
$connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    # Update visibility for handling time columns
    $command = $connection.CreateCommand()
    $command.CommandText = @"
UPDATE WorksheetColumnOrders
SET IsVisible = 1
WHERE ColumnName IN ('UnloadTime', 'MarkMeasureCut', 'QualityCheck', 'MoveToAssembly', 'MoveAfterWeld', 'LoadingTime')
  AND WorksheetColumnViewId IN (
    SELECT Id FROM WorksheetColumnViews 
    WHERE WorksheetType = 'Processing'
  )
"@
    
    $rowsAffected = $command.ExecuteNonQuery()
    Write-Host "Updated $rowsAffected column visibility settings!" -ForegroundColor Green
    
    # Show current visibility status
    $command.CommandText = @"
SELECT wcv.ViewName, wco.ColumnName, wco.IsVisible
FROM WorksheetColumnOrders wco
INNER JOIN WorksheetColumnViews wcv ON wco.WorksheetColumnViewId = wcv.Id
WHERE wcv.WorksheetType = 'Processing'
  AND wco.ColumnName IN ('UnloadTime', 'MarkMeasureCut', 'QualityCheck', 'MoveToAssembly', 'MoveAfterWeld', 'LoadingTime')
ORDER BY wcv.ViewName, wco.DisplayOrder
"@
    
    $reader = $command.ExecuteReader()
    Write-Host "`nCurrent visibility status:" -ForegroundColor Yellow
    while ($reader.Read()) {
        $viewName = $reader['ViewName']
        $columnName = $reader['ColumnName']
        $isVisible = $reader['IsVisible']
        $visibilityText = if ($isVisible) { "Visible" } else { "Hidden" }
        Write-Host "  $viewName - $columnName`: $visibilityText" -ForegroundColor $(if ($isVisible) { "Green" } else { "Gray" })
    }
    $reader.Close()
    
    $connection.Close()
    
    Write-Host "`nColumn visibility updated successfully!" -ForegroundColor Green
    Write-Host "The handling time columns will now be visible by default." -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}