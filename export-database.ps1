# Export SQL Server Database for Docker
param(
    [string]$ServerInstance = "(localdb)\MSSQLLocalDB",
    [string]$DatabaseName = "SteelEstimationDB",
    [string]$OutputPath = ".\docker\sql"
)

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

Write-Host "Exporting database schema and data from $DatabaseName..." -ForegroundColor Green

# Export schema and data using SqlPackage
$sqlPackagePath = "${env:ProgramFiles}\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe"
if (-not (Test-Path $sqlPackagePath)) {
    $sqlPackagePath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe"
}

if (Test-Path $sqlPackagePath) {
    # Export to BACPAC (includes schema and data)
    & $sqlPackagePath /Action:Export /SourceServerName:$ServerInstance /SourceDatabaseName:$DatabaseName /TargetFile:"$OutputPath\SteelEstimationDB.bacpac"
    Write-Host "Database exported to BACPAC format" -ForegroundColor Green
} else {
    Write-Host "SqlPackage not found. Using SQL scripts instead..." -ForegroundColor Yellow
    
    # Alternative: Generate SQL scripts
    $scriptPath = "$OutputPath\init-database.sql"
    
    $connectionString = "Server=$ServerInstance;Database=$DatabaseName;Integrated Security=True;TrustServerCertificate=True"
    
    # Create SQL script with schema and data
    $script = @"
-- Steel Estimation Database Initialization Script
-- Generated for Docker deployment

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SteelEstimationDB')
BEGIN
    ALTER DATABASE SteelEstimationDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SteelEstimationDB;
END
GO

CREATE DATABASE SteelEstimationDB;
GO

USE SteelEstimationDB;
GO

"@

    # Export using SQL Server Management Objects
    try {
        Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=16.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
        Add-Type -AssemblyName "Microsoft.SqlServer.ConnectionInfo, Version=16.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
        
        $server = New-Object Microsoft.SqlServer.Management.Smo.Server($ServerInstance)
        $database = $server.Databases[$DatabaseName]
        
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter($server)
        $scripter.Options.ScriptData = $true
        $scripter.Options.ScriptSchema = $true
        $scripter.Options.ScriptIndexes = $true
        $scripter.Options.ScriptConstraints = $true
        $scripter.Options.IncludeIfNotExists = $true
        
        # Script all objects
        $allObjects = $database.Tables + $database.Views + $database.StoredProcedures + $database.UserDefinedFunctions
        $scripts = $scripter.Script($allObjects)
        
        $script += $scripts -join "`nGO`n"
        
    } catch {
        Write-Host "Error using SMO. Creating basic export..." -ForegroundColor Red
        
        # Fallback: Use sqlcmd to generate scripts
        $queries = @(
            "SELECT 'CREATE TABLE ' + TABLE_SCHEMA + '.' + TABLE_NAME + ' (' + CHAR(13) + CHAR(10) + 
             STUFF((SELECT ', ' + COLUMN_NAME + ' ' + DATA_TYPE + 
                    CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL 
                         THEN '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')' 
                         ELSE '' END +
                    CASE WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END
             FROM INFORMATION_SCHEMA.COLUMNS c
             WHERE c.TABLE_NAME = t.TABLE_NAME AND c.TABLE_SCHEMA = t.TABLE_SCHEMA
             FOR XML PATH('')), 1, 2, '') + CHAR(13) + CHAR(10) + ');'
             FROM INFORMATION_SCHEMA.TABLES t
             WHERE TABLE_TYPE = 'BASE TABLE'"
        )
        
        foreach ($query in $queries) {
            $result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query
            $script += $result[0] + "`nGO`n"
        }
    }
    
    # Save script
    $script | Out-File -FilePath $scriptPath -Encoding UTF8
    Write-Host "Database script saved to $scriptPath" -ForegroundColor Green
}

# Also export data as CSV for each table (backup method)
Write-Host "Exporting table data as CSV files..." -ForegroundColor Green
$tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"

foreach ($table in $tables) {
    $tableName = $table.TABLE_NAME
    $csvPath = "$OutputPath\data_$tableName.csv"
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query "SELECT * FROM $tableName" | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "  Exported $tableName" -ForegroundColor Gray
}

Write-Host "Database export completed!" -ForegroundColor Green