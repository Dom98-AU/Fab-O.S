# Run all worksheet template migrations on CloudDev database

$ErrorActionPreference = "Stop"

Write-Host "Running worksheet template migrations on SteelEstimationDb_CloudDev..." -ForegroundColor Green

# CloudDev database connection string
$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

# Migration files to run in order
$migrations = @(
    "SteelEstimation.Infrastructure\Migrations\AddWorksheetTemplates.sql",
    "SteelEstimation.Infrastructure\Migrations\AddUserWorksheetPreferences.sql"
)

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    foreach ($migrationFile in $migrations) {
        $migrationPath = Join-Path $PSScriptRoot $migrationFile
        
        if (-not (Test-Path $migrationPath)) {
            Write-Warning "Migration file not found: $migrationFile"
            continue
        }
        
        Write-Host ""
        Write-Host "Running migration: $migrationFile" -ForegroundColor Yellow
        
        # Read the migration SQL
        $migrationSql = Get-Content $migrationPath -Raw
        
        # Execute the migration
        $command = $connection.CreateCommand()
        $command.CommandText = $migrationSql
        $command.CommandTimeout = 300 # 5 minutes timeout for large migrations
        
        try {
            $command.ExecuteNonQuery()
            Write-Host "  Migration completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Warning "  Migration failed or partially applied: $($_.Exception.Message)"
        }
    }
    
    # Now add the WorksheetTemplateId column to PackageWorksheets
    Write-Host ""
    Write-Host "Adding WorksheetTemplateId column to PackageWorksheets..." -ForegroundColor Yellow
    
    # Check if column already exists
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'PackageWorksheets' 
AND COLUMN_NAME = 'WorksheetTemplateId'
"@
    
    $exists = $command.ExecuteScalar()
    
    if ($exists -eq 0) {
        # Add the column
        $command.CommandText = @"
ALTER TABLE PackageWorksheets
ADD WorksheetTemplateId INT NULL;
"@
        $command.ExecuteNonQuery()
        
        Write-Host "  Column added!" -ForegroundColor Green
        
        # Add foreign key constraint
        $command.CommandText = @"
ALTER TABLE PackageWorksheets
ADD CONSTRAINT FK_PackageWorksheets_WorksheetTemplates_WorksheetTemplateId
FOREIGN KEY (WorksheetTemplateId) REFERENCES WorksheetTemplates(Id);
"@
        $command.ExecuteNonQuery()
        
        Write-Host "  Foreign key added!" -ForegroundColor Green
        
        # Create index
        $command.CommandText = @"
CREATE INDEX IX_PackageWorksheets_WorksheetTemplateId 
ON PackageWorksheets(WorksheetTemplateId);
"@
        $command.ExecuteNonQuery()
        
        Write-Host "  Index created!" -ForegroundColor Green
        
        # Update existing records
        $command.CommandText = @"
UPDATE pw
SET pw.WorksheetTemplateId = (
    SELECT TOP 1 Id FROM WorksheetTemplates 
    WHERE IsDefault = 1 AND BaseType = 'Processing'
)
FROM PackageWorksheets pw
WHERE pw.WorksheetTemplateId IS NULL;
"@
        $affected = $command.ExecuteNonQuery()
        
        Write-Host "  Updated $affected records with default template" -ForegroundColor Green
    }
    else {
        Write-Host "  Column already exists!" -ForegroundColor Cyan
    }
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "All migrations completed successfully!" -ForegroundColor Green
    Write-Host "You can now refresh the application." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to run migrations: $($_.Exception.Message)"
    exit 1
}