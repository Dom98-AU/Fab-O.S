Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Checking Column Ordering Tables" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection
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
    
    while ($reader.Read()) {
        Write-Host "  Table: $($reader['TableName']) - Columns: $($reader['ColumnCount'])" -ForegroundColor Green
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
    
    # Check column structure
    Write-Host ""
    Write-Host "Checking column structure..." -ForegroundColor Yellow
    $command.CommandText = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'WorksheetColumnViews' ORDER BY ORDINAL_POSITION"
    $reader = $command.ExecuteReader()
    $viewColumns = @()
    while ($reader.Read()) {
        $viewColumns += $reader['COLUMN_NAME']
    }
    $reader.Close()
    Write-Host "  WorksheetColumnViews columns: $($viewColumns -join ', ')" -ForegroundColor Gray
    
    $command.CommandText = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'WorksheetColumnOrders' ORDER BY ORDINAL_POSITION"
    $reader = $command.ExecuteReader()
    $orderColumns = @()
    while ($reader.Read()) {
        $orderColumns += $reader['COLUMN_NAME']
    }
    $reader.Close()
    Write-Host "  WorksheetColumnOrders columns: $($orderColumns -join ', ')" -ForegroundColor Gray
    
    # Check if we have any views
    Write-Host ""
    Write-Host "Checking views..." -ForegroundColor Yellow
    $command.CommandText = "SELECT TOP 5 ViewName, WorksheetType, IsDefault, UserId, CompanyId FROM WorksheetColumnViews ORDER BY Id"
    $reader = $command.ExecuteReader()
    while ($reader.Read()) {
        Write-Host "  View: $($reader['ViewName']) - Type: $($reader['WorksheetType']) - Default: $($reader['IsDefault']) - User: $($reader['UserId']) - Company: $($reader['CompanyId'])" -ForegroundColor Green
    }
    $reader.Close()
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Status Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($viewCount -gt 0 -and $orderCount -gt 0) {
        Write-Host "✓ Column ordering tables are set up correctly!" -ForegroundColor Green
        Write-Host "✓ Found $viewCount views with $orderCount column orders" -ForegroundColor Green
        Write-Host ""
        Write-Host "Note: The current setup creates user-specific views." -ForegroundColor Yellow
        Write-Host "The application may need adjustments to handle this." -ForegroundColor Yellow
    }
    else {
        Write-Host "⚠ Tables exist but may need data initialization" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "The column reordering feature should now be available." -ForegroundColor Green
    Write-Host "If you encounter issues, check that:" -ForegroundColor Cyan
    Write-Host "  - The entity models match the database schema" -ForegroundColor White
    Write-Host "  - The service is properly handling user-specific views" -ForegroundColor White
    
    $connection.Close()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}