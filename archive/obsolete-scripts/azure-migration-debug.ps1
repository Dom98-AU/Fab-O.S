# Debug Azure SQL Migration Issues
Write-Host "=== Debugging Azure SQL Migration ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Test 1: Check Azure SQL Connection
Write-Host "`nTest 1: Testing Azure SQL connection..." -ForegroundColor Yellow
try {
    $connectionTest = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT @@VERSION" -t 30
    Write-Host "Connection successful" -ForegroundColor Green
    Write-Host $connectionTest
} catch {
    Write-Host "Connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Check current tables in Azure
Write-Host "`nTest 2: Checking existing tables in Azure SQL..." -ForegroundColor Yellow
try {
    $azureTables = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -t 30
    Write-Host "Azure SQL Tables:" -ForegroundColor Green
    Write-Host $azureTables
} catch {
    Write-Host "Failed to get tables: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check Docker SQL connection
Write-Host "`nTest 3: Testing Docker SQL connection..." -ForegroundColor Yellow
try {
    $dockerTest = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT COUNT(*) as TableCount FROM sys.tables WHERE is_ms_shipped = 0" -t 30
    Write-Host "Docker SQL Tables:" -ForegroundColor Green
    Write-Host $dockerTest
} catch {
    Write-Host "Docker connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Try creating a simple table manually
Write-Host "`nTest 4: Creating a test table..." -ForegroundColor Yellow
try {
    $createTestTable = @"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TestTable]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[TestTable] (
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        CONSTRAINT [PK_TestTable] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO
"@
    
    $createTestTable | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 30
    
    # Verify the test table was created
    $testTableCheck = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE name = 'TestTable'" -h -1 -t 30
    
    if ([int]$testTableCheck.Trim() -gt 0) {
        Write-Host "Test table created successfully" -ForegroundColor Green
    } else {
        Write-Host "Test table creation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "Test table creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Try a simple insert
Write-Host "`nTest 5: Testing simple insert..." -ForegroundColor Yellow
try {
    $insertTest = "INSERT INTO [TestTable] ([Name]) VALUES ('Test Data');"
    $insertTest | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 30
    
    $selectTest = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT * FROM [TestTable]" -t 30
    Write-Host "Insert test result:" -ForegroundColor Green
    Write-Host $selectTest
} catch {
    Write-Host "Insert test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Check if schema file exists and is readable
Write-Host "`nTest 6: Checking schema file..." -ForegroundColor Yellow
if (Test-Path "azure-schema-fixed.sql") {
    $schemaSize = (Get-Item "azure-schema-fixed.sql").Length
    Write-Host "Schema file exists, size: $schemaSize bytes" -ForegroundColor Green
    
    # Show first few lines
    $firstLines = Get-Content "azure-schema-fixed.sql" -TotalCount 10
    Write-Host "First 10 lines of schema file:" -ForegroundColor Gray
    $firstLines | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "Schema file not found!" -ForegroundColor Red
}

Write-Host "`nDebug complete!" -ForegroundColor Cyan