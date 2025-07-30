# Export SQL Server Database to SQL Script for Docker Import
param(
    [string]$ServerInstance = "(localdb)\MSSQLLocalDB",
    [string]$DatabaseName = "SteelEstimationDB",
    [string]$OutputFile = ".\docker\sql\exported-data.sql"
)

# Ensure output directory exists
$outputDir = Split-Path $OutputFile -Parent
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "Exporting database data from $DatabaseName to SQL script..." -ForegroundColor Green

# Create the export script
$exportScript = @"
-- Exported data from $DatabaseName
-- Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
-- This script contains only the data, not the schema

USE [SteelEstimationDB];
GO

-- Disable constraints temporarily for data import
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
GO

-- Clear existing data (optional - comment out if you want to append)
-- EXEC sp_MSforeachtable 'DELETE FROM ?'
-- GO

"@

try {
    # Get list of tables in dependency order
    $tableOrderQuery = @"
WITH TableHierarchy AS (
    SELECT 
        t.TABLE_SCHEMA,
        t.TABLE_NAME,
        0 as Level
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    AND t.TABLE_NAME NOT IN (
        SELECT DISTINCT
            tc.TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
        JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc 
            ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
    )
    
    UNION ALL
    
    SELECT 
        t.TABLE_SCHEMA,
        t.TABLE_NAME,
        th.Level + 1
    FROM INFORMATION_SCHEMA.TABLES t
    JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
        ON t.TABLE_NAME = tc.TABLE_NAME
    JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc 
        ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
    JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc2 
        ON rc.UNIQUE_CONSTRAINT_NAME = tc2.CONSTRAINT_NAME
    JOIN TableHierarchy th 
        ON tc2.TABLE_NAME = th.TABLE_NAME
    WHERE t.TABLE_TYPE = 'BASE TABLE'
)
SELECT DISTINCT TABLE_SCHEMA, TABLE_NAME, MAX(Level) as MaxLevel
FROM TableHierarchy
GROUP BY TABLE_SCHEMA, TABLE_NAME
ORDER BY MaxLevel, TABLE_NAME
"@

    $tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $tableOrderQuery

    foreach ($table in $tables) {
        $schemaName = $table.TABLE_SCHEMA
        $tableName = $table.TABLE_NAME
        $fullTableName = "[$schemaName].[$tableName]"
        
        Write-Host "  Exporting $fullTableName..." -ForegroundColor Gray
        
        # Check if table has data
        $countQuery = "SELECT COUNT(*) as RecordCount FROM $fullTableName"
        $count = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $countQuery
        
        if ($count.RecordCount -gt 0) {
            $exportScript += @"

-- Data for table $fullTableName
PRINT 'Inserting data into $fullTableName...'
GO

"@
            
            # Get column information
            $columnsQuery = @"
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = '$schemaName' AND TABLE_NAME = '$tableName'
ORDER BY ORDINAL_POSITION
"@
            $columns = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $columnsQuery
            $columnNames = ($columns | ForEach-Object { "[$($_.COLUMN_NAME)]" }) -join ", "
            
            # Check for identity column
            $identityQuery = @"
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = '$schemaName' 
AND TABLE_NAME = '$tableName' 
AND COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1
"@
            $identityColumn = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $identityQuery
            
            if ($identityColumn) {
                $exportScript += "SET IDENTITY_INSERT $fullTableName ON`nGO`n`n"
            }
            
            # Export data in batches
            $offset = 0
            $batchSize = 1000
            
            do {
                $dataQuery = "SELECT * FROM $fullTableName ORDER BY 1 OFFSET $offset ROWS FETCH NEXT $batchSize ROWS ONLY"
                $data = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $dataQuery
                
                if ($data) {
                    foreach ($row in $data) {
                        $values = @()
                        foreach ($col in $columns) {
                            $value = $row.$($col.COLUMN_NAME)
                            if ($null -eq $value) {
                                $values += "NULL"
                            } elseif ($col.DATA_TYPE -in @('varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext', 'datetime', 'datetime2', 'date', 'time', 'datetimeoffset', 'uniqueidentifier')) {
                                $value = $value -replace "'", "''"
                                $values += "N'$value'"
                            } elseif ($col.DATA_TYPE -eq 'bit') {
                                $values += if ($value) { "1" } else { "0" }
                            } else {
                                $values += $value
                            }
                        }
                        $valuesString = $values -join ", "
                        $exportScript += "INSERT INTO $fullTableName ($columnNames) VALUES ($valuesString)`n"
                    }
                    $exportScript += "GO`n"
                }
                
                $offset += $batchSize
            } while ($data.Count -eq $batchSize)
            
            if ($identityColumn) {
                $exportScript += "`nSET IDENTITY_INSERT $fullTableName OFF`nGO`n"
            }
        }
    }
    
    # Re-enable constraints
    $exportScript += @"

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'
GO

PRINT 'Data import completed successfully!'
GO
"@

    # Save the script
    $exportScript | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "`nExport completed successfully!" -ForegroundColor Green
    Write-Host "Output file: $OutputFile" -ForegroundColor Yellow
    Write-Host "`nFile size: $([Math]::Round((Get-Item $OutputFile).Length / 1MB, 2)) MB" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error during export: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}