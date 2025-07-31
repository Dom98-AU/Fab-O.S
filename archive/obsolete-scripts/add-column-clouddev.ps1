# Add WorksheetTemplateId column to CloudDev database

$ErrorActionPreference = "Stop"

Write-Host "Adding WorksheetTemplateId to SteelEstimationDb_CloudDev..." -ForegroundColor Green

# CloudDev database connection string
$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
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
        Write-Host "Column does not exist. Adding it now..." -ForegroundColor Yellow
        
        # Add the column
        $command.CommandText = @"
ALTER TABLE PackageWorksheets
ADD WorksheetTemplateId INT NULL;
"@
        $command.ExecuteNonQuery()
        
        Write-Host "Column added successfully!" -ForegroundColor Green
        
        # Add foreign key constraint
        $command.CommandText = @"
ALTER TABLE PackageWorksheets
ADD CONSTRAINT FK_PackageWorksheets_WorksheetTemplates_WorksheetTemplateId
FOREIGN KEY (WorksheetTemplateId) REFERENCES WorksheetTemplates(Id);
"@
        $command.ExecuteNonQuery()
        
        Write-Host "Foreign key constraint added!" -ForegroundColor Green
        
        # Create index
        $command.CommandText = @"
CREATE INDEX IX_PackageWorksheets_WorksheetTemplateId 
ON PackageWorksheets(WorksheetTemplateId);
"@
        $command.ExecuteNonQuery()
        
        Write-Host "Index created!" -ForegroundColor Green
        
        # Update existing records to use default template
        $command.CommandText = @"
UPDATE pw
SET pw.WorksheetTemplateId = wt.Id
FROM PackageWorksheets pw
INNER JOIN WorksheetTemplates wt ON wt.IsDefault = 1
WHERE pw.WorksheetTemplateId IS NULL
AND wt.BaseType = 'Processing';
"@
        $affected = $command.ExecuteNonQuery()
        
        Write-Host "Updated $affected existing records with default template" -ForegroundColor Green
    }
    else {
        Write-Host "Column already exists!" -ForegroundColor Cyan
    }
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "Database update completed successfully!" -ForegroundColor Green
    Write-Host "You can now refresh the application." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to update database: $($_.Exception.Message)"
    exit 1
}