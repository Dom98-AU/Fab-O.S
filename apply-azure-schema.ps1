# Apply the fixed Azure schema
Write-Host "=== Applying Azure SQL Schema ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Step 1: Drop all foreign keys first
Write-Host "`n[1/3] Dropping existing foreign keys..." -ForegroundColor Green

$dropFKScript = @"
-- Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + ']; '
FROM sys.foreign_keys;
IF @sql != ''
    EXEC sp_executesql @sql;
GO
"@

$dropFKScript | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword 2>$null

# Step 2: Apply the schema
Write-Host "`n[2/3] Applying schema..." -ForegroundColor Green

# Use the fixed schema file
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -i /scripts/azure-schema-fixed.sql `
    -I 2>&1 | ForEach-Object {
        if ($_ -match "error|failed" -and $_ -notmatch "already exists") {
            Write-Host "Error: $_" -ForegroundColor Red
        } elseif ($_ -match "successfully|completed") {
            Write-Host $_ -ForegroundColor Green
        }
    }

# Step 3: Verify tables created
Write-Host "`n[3/3] Verifying tables..." -ForegroundColor Green

$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1

Write-Host "Total tables in Azure SQL: $($tableCount.Trim())" -ForegroundColor Cyan

# List all tables
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name"

Write-Host "`nSchema application complete!" -ForegroundColor Green