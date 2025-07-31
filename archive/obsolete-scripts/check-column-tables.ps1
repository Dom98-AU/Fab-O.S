Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Checking Column Ordering Tables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection
$serverName = "(localdb)\MSSQLLocalDB"
$databaseName = "SteelEstimationDev"
$connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;"

try {
    # Connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    Write-Host "✓ Connected to database" -ForegroundColor Green
    Write-Host ""
    
    # Check if tables exist
    Write-Host "Checking tables..." -ForegroundColor Yellow
    
    $checkTablesQuery = @"
SELECT 
    t.name AS TableName,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS ColumnCount
FROM sys.tables t
WHERE t.name IN ('WorksheetColumnViews', 'WorksheetColumnOrders')
ORDER BY t.name
"@
    
    $command = $connection.CreateCommand()
    $command.CommandText = $checkTablesQuery
    $reader = $command.ExecuteReader()
    
    while ($reader.Read()) {
        Write-Host "  ✓ Table: $($reader['TableName']) - Columns: $($reader['ColumnCount'])" -ForegroundColor Green
    }
    $reader.Close()
    
    Write-Host ""
    Write-Host "Checking data..." -ForegroundColor Yellow
    
    # Check WorksheetColumnViews
    $command.CommandText = "SELECT COUNT(*) FROM WorksheetColumnViews"
    $viewCount = $command.ExecuteScalar()
    Write-Host "  WorksheetColumnViews: $viewCount records" -ForegroundColor Cyan
    
    # Check WorksheetColumnOrders
    $command.CommandText = "SELECT COUNT(*) FROM WorksheetColumnOrders"
    $orderCount = $command.ExecuteScalar()
    Write-Host "  WorksheetColumnOrders: $orderCount records" -ForegroundColor Cyan
    
    # Check if default data exists
    Write-Host ""
    Write-Host "Checking default column orders..." -ForegroundColor Yellow
    $command.CommandText = @"
SELECT ViewName, WorksheetType, COUNT(*) as ColumnCount
FROM WorksheetColumnViews v
INNER JOIN WorksheetColumnOrders o ON v.Id = o.ViewId
WHERE v.ViewName = 'Default'
GROUP BY ViewName, WorksheetType
"@
    
    $reader = $command.ExecuteReader()
    $hasDefaults = $false
    while ($reader.Read()) {
        $hasDefaults = $true
        Write-Host "  ✓ $($reader['WorksheetType']) worksheet - $($reader['ColumnCount']) columns configured" -ForegroundColor Green
    }
    $reader.Close()
    
    if (-not $hasDefaults) {
        Write-Host "  ⚠ No default column orders found - inserting defaults..." -ForegroundColor Yellow
        
        # Insert default data
        $insertDefaultsQuery = @"
-- Insert default views
INSERT INTO WorksheetColumnViews (ViewName, WorksheetType, UserId, CompanyId, IsDefault, CreatedDate)
VALUES 
    ('Default', 'Processing', NULL, NULL, 1, GETUTCDATE()),
    ('Default', 'Welding', NULL, NULL, 1, GETUTCDATE());

-- Get the view IDs
DECLARE @ProcessingViewId INT = (SELECT Id FROM WorksheetColumnViews WHERE ViewName = 'Default' AND WorksheetType = 'Processing');
DECLARE @WeldingViewId INT = (SELECT Id FROM WorksheetColumnViews WHERE ViewName = 'Default' AND WorksheetType = 'Welding');

-- Insert default column orders for Processing worksheet
INSERT INTO WorksheetColumnOrders (ViewId, ColumnName, DisplayOrder, IsVisible, Width)
VALUES 
    (@ProcessingViewId, 'Selection', 1, 1, 50),
    (@ProcessingViewId, 'RowNumber', 2, 1, 60),
    (@ProcessingViewId, 'DrawingNumber', 3, 1, 150),
    (@ProcessingViewId, 'Quantity', 4, 1, 80),
    (@ProcessingViewId, 'Description', 5, 1, 300),
    (@ProcessingViewId, 'Material', 6, 1, 150),
    (@ProcessingViewId, 'MaterialType', 7, 1, 100),
    (@ProcessingViewId, 'Weight', 8, 1, 100),
    (@ProcessingViewId, 'TotalWeight', 9, 1, 120),
    (@ProcessingViewId, 'DeliveryBundle', 10, 1, 150),
    (@ProcessingViewId, 'PackBundle', 11, 1, 150),
    (@ProcessingViewId, 'HandlingTime', 12, 1, 120),
    (@ProcessingViewId, 'UnloadTime', 13, 0, 100),
    (@ProcessingViewId, 'MarkMeasureCut', 14, 0, 120),
    (@ProcessingViewId, 'QualityCheckClean', 15, 0, 120),
    (@ProcessingViewId, 'MoveToAssembly', 16, 0, 120),
    (@ProcessingViewId, 'MoveAfterWeld', 17, 0, 120),
    (@ProcessingViewId, 'LoadingTime', 18, 0, 100),
    (@ProcessingViewId, 'Actions', 19, 1, 100);

-- Insert default column orders for Welding worksheet
INSERT INTO WorksheetColumnOrders (ViewId, ColumnName, DisplayOrder, IsVisible, Width)
VALUES 
    (@WeldingViewId, 'RowNumber', 1, 1, 60),
    (@WeldingViewId, 'DrawingNumber', 2, 1, 150),
    (@WeldingViewId, 'ItemDescription', 3, 1, 300),
    (@WeldingViewId, 'WeldType', 4, 1, 120),
    (@WeldingViewId, 'ConnectionQty', 5, 1, 100),
    (@WeldingViewId, 'WeldingConnections', 6, 1, 200),
    (@WeldingViewId, 'TotalMinutes', 7, 1, 120),
    (@WeldingViewId, 'Images', 8, 1, 200),
    (@WeldingViewId, 'Actions', 9, 1, 100);
"@
        
        $command.CommandText = $insertDefaultsQuery
        $command.ExecuteNonQuery() | Out-Null
        Write-Host "  ✓ Default column orders inserted" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " ✓ Column ordering tables are ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    $connection.Close()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection.State -eq 'Open') {
        $connection.Close()
    }
}