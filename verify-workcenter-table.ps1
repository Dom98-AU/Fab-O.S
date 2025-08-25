Write-Host "Verifying WorkCenters table structure..." -ForegroundColor Yellow

$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-sandbox;User ID=admin@nwi@nwiapps;Password=Natweigh88;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Get all columns from WorkCenters table
    $command = $connection.CreateCommand()
    $command.CommandText = @"
        SELECT 
            c.name AS ColumnName,
            t.name AS DataType,
            c.max_length,
            c.precision,
            c.scale,
            c.is_nullable
        FROM sys.columns c
        INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('WorkCenters')
        ORDER BY c.column_id
"@
    
    Write-Host "`nWorkCenters table columns:" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    $reader = $command.ExecuteReader()
    $columnList = @()
    while ($reader.Read()) {
        $name = $reader['ColumnName']
        $type = $reader['DataType']
        $nullable = if($reader['is_nullable']) { "NULL" } else { "NOT NULL" }
        
        # Format type with precision/scale for decimals
        if ($type -eq "decimal") {
            $precision = $reader['precision']
            $scale = $reader['scale']
            $type = "decimal($precision,$scale)"
        }
        
        $columnList += [PSCustomObject]@{
            Name = $name
            Type = $type
            Nullable = $nullable
        }
        
        Write-Host ("  {0,-30} {1,-20} {2}" -f $name, $type, $nullable) -ForegroundColor White
    }
    $reader.Close()
    
    # Check if maintenance columns exist
    $maintenanceCols = $columnList | Where-Object { $_.Name -in @('LastMaintenanceDate', 'NextMaintenanceDate') }
    
    Write-Host "`n----------------------------------------" -ForegroundColor Gray
    if ($maintenanceCols.Count -eq 2) {
        Write-Host "✓ Both maintenance date columns exist!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Missing maintenance columns!" -ForegroundColor Yellow
    }
    
    # Check for any sample data
    $countCommand = $connection.CreateCommand()
    $countCommand.CommandText = "SELECT COUNT(*) FROM WorkCenters"
    $count = $countCommand.ExecuteScalar()
    
    Write-Host "`nTotal WorkCenters in database: $count" -ForegroundColor Cyan
    
    $connection.Close()
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}