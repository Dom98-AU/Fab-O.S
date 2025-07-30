# Check items linked to worksheets

$ErrorActionPreference = "Stop"

Write-Host "Checking worksheet items in CloudDev database..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check ProcessingItems
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    COUNT(*) as TotalItems,
    COUNT(DISTINCT PackageWorksheetId) as WorksheetsWithItems,
    COUNT(CASE WHEN PackageWorksheetId IS NULL THEN 1 END) as ItemsWithoutWorksheet
FROM ProcessingItems
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Processing Items Summary:" -ForegroundColor Cyan
    
    if ($reader.Read()) {
        $totalItems = $reader["TotalItems"]
        $worksheetsWithItems = $reader["WorksheetsWithItems"]
        $itemsWithoutWorksheet = $reader["ItemsWithoutWorksheet"]
        
        Write-Host "  Total Processing Items: $totalItems" -ForegroundColor White
        Write-Host "  Worksheets with items: $worksheetsWithItems" -ForegroundColor White
        Write-Host "  Items without worksheet: $itemsWithoutWorksheet" -ForegroundColor White
    }
    
    $reader.Close()
    
    # Check WeldingItems
    $command.CommandText = @"
SELECT 
    COUNT(*) as TotalItems,
    COUNT(DISTINCT PackageWorksheetId) as WorksheetsWithItems,
    COUNT(CASE WHEN PackageWorksheetId IS NULL THEN 1 END) as ItemsWithoutWorksheet
FROM WeldingItems
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Welding Items Summary:" -ForegroundColor Cyan
    
    if ($reader.Read()) {
        $totalItems = $reader["TotalItems"]
        $worksheetsWithItems = $reader["WorksheetsWithItems"]
        $itemsWithoutWorksheet = $reader["ItemsWithoutWorksheet"]
        
        Write-Host "  Total Welding Items: $totalItems" -ForegroundColor White
        Write-Host "  Worksheets with items: $worksheetsWithItems" -ForegroundColor White
        Write-Host "  Items without worksheet: $itemsWithoutWorksheet" -ForegroundColor White
    }
    
    $reader.Close()
    
    # Check if PackageWorksheetId column exists in ProcessingItems
    $command.CommandText = @"
SELECT COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'ProcessingItems' 
AND COLUMN_NAME = 'PackageWorksheetId'
"@
    
    $exists = $command.ExecuteScalar()
    
    Write-Host ""
    Write-Host "Database Structure:" -ForegroundColor Yellow
    Write-Host "  ProcessingItems.PackageWorksheetId column exists: $($exists -gt 0)" -ForegroundColor White
    
    # Check if PackageWorksheetId column exists in WeldingItems
    $command.CommandText = @"
SELECT COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'WeldingItems' 
AND COLUMN_NAME = 'PackageWorksheetId'
"@
    
    $exists = $command.ExecuteScalar()
    
    Write-Host "  WeldingItems.PackageWorksheetId column exists: $($exists -gt 0)" -ForegroundColor White
    
    # Get sample ProcessingItems with their ProjectId
    $command.CommandText = @"
SELECT TOP 5
    Id,
    ProjectId,
    PackageWorksheetId,
    DrawingNumber
FROM ProcessingItems
ORDER BY Id
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Sample ProcessingItems:" -ForegroundColor Yellow
    
    while ($reader.Read()) {
        $id = $reader["Id"]
        $projectId = $reader["ProjectId"]
        $worksheetId = if ($reader["PackageWorksheetId"] -eq [DBNull]::Value) { "NULL" } else { $reader["PackageWorksheetId"] }
        $drawingNumber = if ($reader["DrawingNumber"] -eq [DBNull]::Value) { "NULL" } else { $reader["DrawingNumber"] }
        
        Write-Host "  ID: $id | ProjectId: $projectId | WorksheetId: $worksheetId | Drawing: $drawingNumber" -ForegroundColor White
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Error "Failed to check items: $($_.Exception.Message)"
    exit 1
}