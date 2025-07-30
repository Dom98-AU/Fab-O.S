Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Checking Column Ordering Tables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection - using the correct database name from appsettings
$serverName = "localhost"
$databaseName = "SteelEstimationDb_CloudDev"
$connectionString = "Server=$serverName;Database=$databaseName;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    # Connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    Write-Host "Connected to database: $databaseName" -ForegroundColor Green
    Write-Host ""
    
    # Check if tables exist
    Write-Host "Checking tables..." -ForegroundColor Yellow
    
    $checkTablesQuery = "SELECT t.name AS TableName, (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) AS ColumnCount FROM sys.tables t WHERE t.name IN ('WorksheetColumnViews', 'WorksheetColumnOrders') ORDER BY t.name"
    
    $command = $connection.CreateCommand()
    $command.CommandText = $checkTablesQuery
    $reader = $command.ExecuteReader()
    
    $tableCount = 0
    while ($reader.Read()) {
        $tableCount++
        Write-Host "  Table: $($reader['TableName']) - Columns: $($reader['ColumnCount'])" -ForegroundColor Green
    }
    $reader.Close()
    
    if ($tableCount -eq 0) {
        Write-Host "  Tables do not exist yet. Please run the migration first." -ForegroundColor Yellow
        Write-Host "  Run: .\run-column-ordering-migration.ps1" -ForegroundColor Yellow
        $connection.Close()
        return
    }
    
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
    $command.CommandText = "SELECT ViewName, WorksheetType, COUNT(*) as ColumnCount FROM WorksheetColumnViews v INNER JOIN WorksheetColumnOrders o ON v.Id = o.ViewId WHERE v.ViewName = 'Default' GROUP BY ViewName, WorksheetType"
    
    $reader = $command.ExecuteReader()
    $hasDefaults = $false
    while ($reader.Read()) {
        $hasDefaults = $true
        Write-Host "  $($reader['WorksheetType']) worksheet - $($reader['ColumnCount']) columns configured" -ForegroundColor Green
    }
    $reader.Close()
    
    if (-not $hasDefaults) {
        Write-Host "  No default column orders found - inserting defaults..." -ForegroundColor Yellow
        
        # Insert default views
        $command.CommandText = "INSERT INTO WorksheetColumnViews (ViewName, WorksheetType, UserId, CompanyId, IsDefault, CreatedDate) VALUES ('Default', 'Processing', NULL, NULL, 1, GETUTCDATE()), ('Default', 'Welding', NULL, NULL, 1, GETUTCDATE())"
        $command.ExecuteNonQuery() | Out-Null
        
        # Get the view IDs and insert column orders
        $command.CommandText = "SELECT Id, WorksheetType FROM WorksheetColumnViews WHERE ViewName = 'Default'"
        $reader = $command.ExecuteReader()
        $viewIds = @{}
        while ($reader.Read()) {
            $viewIds[$reader['WorksheetType']] = $reader['Id']
        }
        $reader.Close()
        
        # Insert Processing columns
        if ($viewIds.ContainsKey('Processing')) {
            $processingViewId = $viewIds['Processing']
            $processingColumns = @(
                "($processingViewId, 'Selection', 1, 1, 50)",
                "($processingViewId, 'RowNumber', 2, 1, 60)",
                "($processingViewId, 'DrawingNumber', 3, 1, 150)",
                "($processingViewId, 'Quantity', 4, 1, 80)",
                "($processingViewId, 'Description', 5, 1, 300)",
                "($processingViewId, 'Material', 6, 1, 150)",
                "($processingViewId, 'MaterialType', 7, 1, 100)",
                "($processingViewId, 'Weight', 8, 1, 100)",
                "($processingViewId, 'TotalWeight', 9, 1, 120)",
                "($processingViewId, 'DeliveryBundle', 10, 1, 150)",
                "($processingViewId, 'PackBundle', 11, 1, 150)",
                "($processingViewId, 'HandlingTime', 12, 1, 120)",
                "($processingViewId, 'UnloadTime', 13, 0, 100)",
                "($processingViewId, 'MarkMeasureCut', 14, 0, 120)",
                "($processingViewId, 'QualityCheckClean', 15, 0, 120)",
                "($processingViewId, 'MoveToAssembly', 16, 0, 120)",
                "($processingViewId, 'MoveAfterWeld', 17, 0, 120)",
                "($processingViewId, 'LoadingTime', 18, 0, 100)",
                "($processingViewId, 'Actions', 19, 1, 100)"
            )
            $command.CommandText = "INSERT INTO WorksheetColumnOrders (ViewId, ColumnName, DisplayOrder, IsVisible, Width) VALUES " + ($processingColumns -join ", ")
            $command.ExecuteNonQuery() | Out-Null
        }
        
        # Insert Welding columns
        if ($viewIds.ContainsKey('Welding')) {
            $weldingViewId = $viewIds['Welding']
            $weldingColumns = @(
                "($weldingViewId, 'RowNumber', 1, 1, 60)",
                "($weldingViewId, 'DrawingNumber', 2, 1, 150)",
                "($weldingViewId, 'ItemDescription', 3, 1, 300)",
                "($weldingViewId, 'WeldType', 4, 1, 120)",
                "($weldingViewId, 'ConnectionQty', 5, 1, 100)",
                "($weldingViewId, 'WeldingConnections', 6, 1, 200)",
                "($weldingViewId, 'TotalMinutes', 7, 1, 120)",
                "($weldingViewId, 'Images', 8, 1, 200)",
                "($weldingViewId, 'Actions', 9, 1, 100)"
            )
            $command.CommandText = "INSERT INTO WorksheetColumnOrders (ViewId, ColumnName, DisplayOrder, IsVisible, Width) VALUES " + ($weldingColumns -join ", ")
            $command.ExecuteNonQuery() | Out-Null
        }
        
        Write-Host "  Default column orders inserted" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Column ordering tables are ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The column reordering feature is now available." -ForegroundColor Green
    Write-Host "Run your application and try:" -ForegroundColor Cyan
    Write-Host "  - Drag column headers to reorder" -ForegroundColor White
    Write-Host "  - Use 'Column Views' dropdown to save/load views" -ForegroundColor White
    Write-Host "  - Set a default view with the star icon" -ForegroundColor White
    
    $connection.Close()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}