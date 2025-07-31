# Update NULL WorksheetTemplateId values in PackageWorksheets

$ErrorActionPreference = "Stop"

Write-Host "Updating WorksheetTemplateId in PackageWorksheets..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # First check how many records need updating
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) FROM PackageWorksheets WHERE WorksheetTemplateId IS NULL"
    $nullCount = $command.ExecuteScalar()
    
    Write-Host "Records with NULL WorksheetTemplateId: $nullCount" -ForegroundColor Yellow
    
    if ($nullCount -gt 0) {
        # Get default template IDs
        $command.CommandText = @"
SELECT Id, BaseType, Name 
FROM WorksheetTemplates 
WHERE IsDefault = 1
ORDER BY BaseType
"@
        
        $reader = $command.ExecuteReader()
        $templates = @{}
        
        Write-Host ""
        Write-Host "Default templates:" -ForegroundColor Cyan
        while ($reader.Read()) {
            $id = $reader["Id"]
            $baseType = $reader["BaseType"]
            $name = $reader["Name"]
            $templates[$baseType] = $id
            Write-Host "  ${baseType}: $name (ID: $id)" -ForegroundColor White
        }
        $reader.Close()
        
        # Update PackageWorksheets based on WorksheetType
        Write-Host ""
        Write-Host "Updating PackageWorksheets..." -ForegroundColor Yellow
        
        foreach ($type in $templates.Keys) {
            $templateId = $templates[$type]
            $command.CommandText = @"
UPDATE PackageWorksheets 
SET WorksheetTemplateId = $templateId
WHERE WorksheetTemplateId IS NULL 
AND WorksheetType = '$type'
"@
            
            $affected = $command.ExecuteNonQuery()
            Write-Host "  Updated $affected $type worksheets with template ID $templateId" -ForegroundColor Green
        }
        
        # Handle any remaining nulls (set to first available template)
        if ($templates.Count -gt 0) {
            $defaultId = $templates.Values | Select-Object -First 1
            $command.CommandText = @"
UPDATE PackageWorksheets 
SET WorksheetTemplateId = $defaultId
WHERE WorksheetTemplateId IS NULL
"@
            
            $affected = $command.ExecuteNonQuery()
            if ($affected -gt 0) {
                Write-Host "  Updated $affected remaining worksheets with default template ID $defaultId" -ForegroundColor Green
            }
        }
    }
    
    # Verify final state
    $command.CommandText = "SELECT COUNT(*) FROM PackageWorksheets WHERE WorksheetTemplateId IS NULL"
    $finalNullCount = $command.ExecuteScalar()
    
    Write-Host ""
    Write-Host "Final records with NULL WorksheetTemplateId: $finalNullCount" -ForegroundColor Cyan
    
    $connection.Close()
    
    Write-Host ""
    Write-Host "Update completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to update data: $($_.Exception.Message)"
    exit 1
}