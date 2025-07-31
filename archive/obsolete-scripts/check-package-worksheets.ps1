# Check PackageWorksheets data for a specific package

$ErrorActionPreference = "Stop"

Write-Host "Checking PackageWorksheets in CloudDev database..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Get all packages
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT TOP 10
    p.Id,
    p.PackageName,
    p.ProjectId,
    proj.ProjectName,
    (SELECT COUNT(*) FROM PackageWorksheets WHERE PackageId = p.Id) as WorksheetCount
FROM Packages p
INNER JOIN Projects proj ON p.ProjectId = proj.Id
ORDER BY p.Id
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Packages and their worksheet counts:" -ForegroundColor Cyan
    Write-Host "------------------------------------" -ForegroundColor Cyan
    
    while ($reader.Read()) {
        $packageId = $reader["Id"]
        $packageName = $reader["PackageName"]
        $projectName = $reader["ProjectName"]
        $worksheetCount = $reader["WorksheetCount"]
        
        Write-Host "Package $packageId : $packageName (Project: $projectName) - $worksheetCount worksheets" -ForegroundColor White
    }
    
    $reader.Close()
    
    # Get details of worksheets for first package with worksheets
    $command.CommandText = @"
SELECT TOP 1 Id FROM Packages WHERE Id IN (SELECT DISTINCT PackageId FROM PackageWorksheets)
"@
    $firstPackageId = $command.ExecuteScalar()
    
    if ($firstPackageId -ne $null) {
        Write-Host ""
        Write-Host "Worksheets for Package $firstPackageId :" -ForegroundColor Yellow
        
        $command.CommandText = @"
SELECT 
    pw.Id,
    pw.Name,
    pw.WorksheetType,
    pw.WorksheetTemplateId,
    wt.Name as TemplateName,
    pw.ItemCount,
    pw.DisplayOrder
FROM PackageWorksheets pw
LEFT JOIN WorksheetTemplates wt ON pw.WorksheetTemplateId = wt.Id
WHERE pw.PackageId = $firstPackageId
ORDER BY pw.DisplayOrder
"@
        
        $reader = $command.ExecuteReader()
        
        while ($reader.Read()) {
            $id = $reader["Id"]
            $name = $reader["Name"]
            $type = $reader["WorksheetType"]
            $templateId = if ($reader["WorksheetTemplateId"] -eq [DBNull]::Value) { "NULL" } else { $reader["WorksheetTemplateId"] }
            $templateName = if ($reader["TemplateName"] -eq [DBNull]::Value) { "NULL" } else { $reader["TemplateName"] }
            $itemCount = $reader["ItemCount"]
            
            Write-Host "  ID: $id | Name: $name | Type: $type | Template: $templateName (ID: $templateId) | Items: $itemCount" -ForegroundColor White
        }
        
        $reader.Close()
    }
    
    # Check worksheet templates
    Write-Host ""
    Write-Host "Available Worksheet Templates:" -ForegroundColor Yellow
    
    $command.CommandText = @"
SELECT Id, Name, BaseType, IsDefault 
FROM WorksheetTemplates 
ORDER BY DisplayOrder
"@
    
    $reader = $command.ExecuteReader()
    
    while ($reader.Read()) {
        $id = $reader["Id"]
        $name = $reader["Name"]
        $baseType = $reader["BaseType"]
        $isDefault = $reader["IsDefault"]
        
        Write-Host "  ID: $id | $name ($baseType) | Default: $isDefault" -ForegroundColor White
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Error "Failed to check data: $($_.Exception.Message)"
    exit 1
}