# Fix WorksheetTemplateId values in CloudDev database

$ErrorActionPreference = "Stop"

Write-Host "Fixing WorksheetTemplateId values in SteelEstimationDb_CloudDev..." -ForegroundColor Green

# CloudDev database connection string
$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # First check how many templates we have
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) FROM WorksheetTemplates"
    $templateCount = $command.ExecuteScalar()
    
    Write-Host "Found $templateCount worksheet templates" -ForegroundColor Cyan
    
    if ($templateCount -gt 0) {
        # Check how many PackageWorksheets have NULL WorksheetTemplateId
        $command.CommandText = "SELECT COUNT(*) FROM PackageWorksheets WHERE WorksheetTemplateId IS NULL"
        $nullCount = $command.ExecuteScalar()
        
        Write-Host "PackageWorksheets with NULL WorksheetTemplateId: $nullCount" -ForegroundColor Yellow
        
        if ($nullCount -gt 0) {
            # Get the default template ID
            $command.CommandText = @"
SELECT TOP 1 Id 
FROM WorksheetTemplates 
WHERE IsDefault = 1 
ORDER BY BaseType
"@
            $defaultTemplateId = $command.ExecuteScalar()
            
            if ($defaultTemplateId -ne $null) {
                Write-Host "Using default template ID: $defaultTemplateId" -ForegroundColor Cyan
                
                # Update all NULL WorksheetTemplateId values
                $command.CommandText = @"
UPDATE PackageWorksheets 
SET WorksheetTemplateId = $defaultTemplateId
WHERE WorksheetTemplateId IS NULL
"@
                $affected = $command.ExecuteNonQuery()
                
                Write-Host "Updated $affected records with default template" -ForegroundColor Green
            }
            else {
                Write-Host "No default template found, using first available template" -ForegroundColor Yellow
                
                # Get first template ID
                $command.CommandText = "SELECT TOP 1 Id FROM WorksheetTemplates ORDER BY Id"
                $firstTemplateId = $command.ExecuteScalar()
                
                if ($firstTemplateId -ne $null) {
                    $command.CommandText = @"
UPDATE PackageWorksheets 
SET WorksheetTemplateId = $firstTemplateId
WHERE WorksheetTemplateId IS NULL
"@
                    $affected = $command.ExecuteNonQuery()
                    
                    Write-Host "Updated $affected records with template ID $firstTemplateId" -ForegroundColor Green
                }
            }
        }
        
        # Verify final state
        $command.CommandText = "SELECT COUNT(*) FROM PackageWorksheets WHERE WorksheetTemplateId IS NULL"
        $finalNullCount = $command.ExecuteScalar()
        
        Write-Host ""
        Write-Host "Final PackageWorksheets with NULL WorksheetTemplateId: $finalNullCount" -ForegroundColor Cyan
    }
    else {
        Write-Host "No worksheet templates found in database!" -ForegroundColor Red
        Write-Host "Running template seed data..." -ForegroundColor Yellow
        
        # Insert default templates
        $command.CommandText = @"
-- Insert default worksheet templates
INSERT INTO WorksheetTemplates (Name, Description, BaseType, CreatedByUserId, IsPublished, IsGlobal, IsDefault, AllowColumnReorder, DisplayOrder)
VALUES 
    ('Standard Processing', 'Default processing worksheet with all standard fields', 'Processing', 1, 1, 1, 1, 1, 1),
    ('Standard Welding', 'Default welding worksheet with all standard fields', 'Welding', 1, 1, 1, 1, 1, 2),
    ('Quick Processing', 'Simplified processing worksheet with essential fields only', 'Processing', 1, 1, 1, 0, 1, 3),
    ('Packing & Shipping', 'Worksheet focused on packing and shipping operations', 'Processing', 1, 1, 1, 0, 1, 4);
"@
        $command.ExecuteNonQuery()
        
        Write-Host "Default templates inserted!" -ForegroundColor Green
        
        # Now update PackageWorksheets
        $command.CommandText = @"
UPDATE PackageWorksheets 
SET WorksheetTemplateId = (SELECT TOP 1 Id FROM WorksheetTemplates WHERE IsDefault = 1)
WHERE WorksheetTemplateId IS NULL
"@
        $affected = $command.ExecuteNonQuery()
        
        Write-Host "Updated $affected PackageWorksheets with default template" -ForegroundColor Green
    }
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "Database fix completed successfully!" -ForegroundColor Green
    Write-Host "Please refresh your browser now." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to fix database: $($_.Exception.Message)"
    exit 1
}