# Check worksheets in CloudDev database

$ErrorActionPreference = "Stop"

Write-Host "Checking worksheets in SteelEstimationDb_CloudDev..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check Packages
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT 
    p.Id,
    p.PackageName,
    p.ProjectId,
    proj.ProjectName
FROM Packages p
INNER JOIN Projects proj ON p.ProjectId = proj.Id
ORDER BY p.Id
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Packages:" -ForegroundColor Cyan
    Write-Host "---------" -ForegroundColor Cyan
    
    $packageIds = @()
    while ($reader.Read()) {
        $id = $reader["Id"]
        $packageIds += $id
        $name = $reader["PackageName"]
        $projectId = $reader["ProjectId"]
        $projectName = $reader["ProjectName"]
        
        Write-Host "ID: $id | Package: $name | Project: $projectName (ID: $projectId)" -ForegroundColor White
    }
    $reader.Close()
    
    # Check PackageWorksheets
    Write-Host ""
    Write-Host "Package Worksheets:" -ForegroundColor Cyan
    Write-Host "------------------" -ForegroundColor Cyan
    
    $command.CommandText = @"
SELECT 
    pw.Id,
    pw.PackageId,
    pw.Name,
    pw.WorksheetType,
    pw.WorksheetTemplateId,
    wt.Name as TemplateName,
    pw.ItemCount,
    pw.TotalHours
FROM PackageWorksheets pw
LEFT JOIN WorksheetTemplates wt ON pw.WorksheetTemplateId = wt.Id
ORDER BY pw.PackageId, pw.DisplayOrder
"@
    
    $reader = $command.ExecuteReader()
    
    $worksheetCount = 0
    while ($reader.Read()) {
        $worksheetCount++
        $id = $reader["Id"]
        $packageId = $reader["PackageId"]
        $name = $reader["Name"]
        $type = $reader["WorksheetType"]
        $templateId = if ($reader["WorksheetTemplateId"] -eq [DBNull]::Value) { "NULL" } else { $reader["WorksheetTemplateId"] }
        $templateName = if ($reader["TemplateName"] -eq [DBNull]::Value) { "NULL" } else { $reader["TemplateName"] }
        $itemCount = $reader["ItemCount"]
        $totalHours = $reader["TotalHours"]
        
        Write-Host "ID: $id | Package: $packageId | Name: $name | Type: $type | Template: $templateName | Items: $itemCount | Hours: $totalHours" -ForegroundColor White
    }
    $reader.Close()
    
    Write-Host ""
    Write-Host "Total worksheets: $worksheetCount" -ForegroundColor Yellow
    
    # Check if we need to create worksheets for packages
    if ($packageIds.Count -gt 0 -and $worksheetCount -eq 0) {
        Write-Host ""
        Write-Host "No worksheets found! Creating default worksheets for packages..." -ForegroundColor Yellow
        
        foreach ($packageId in $packageIds) {
            # Create Processing worksheet
            $command.CommandText = @"
INSERT INTO PackageWorksheets (PackageId, WorksheetType, Name, Description, TotalHours, TotalCost, ItemCount, DisplayOrder, WorksheetTemplateId)
VALUES ($packageId, 'Processing', 'Processing', 'Processing operations worksheet', 0, 0, 0, 1, 
    (SELECT TOP 1 Id FROM WorksheetTemplates WHERE BaseType = 'Processing' AND IsDefault = 1))
"@
            $command.ExecuteNonQuery()
            
            # Create Welding worksheet
            $command.CommandText = @"
INSERT INTO PackageWorksheets (PackageId, WorksheetType, Name, Description, TotalHours, TotalCost, ItemCount, DisplayOrder, WorksheetTemplateId)
VALUES ($packageId, 'Welding', 'Welding', 'Welding operations worksheet', 0, 0, 0, 2,
    (SELECT TOP 1 Id FROM WorksheetTemplates WHERE BaseType = 'Welding' AND IsDefault = 1))
"@
            $command.ExecuteNonQuery()
        }
        
        Write-Host "Default worksheets created for all packages!" -ForegroundColor Green
    }
    
    $connection.Close()
}
catch {
    Write-Error "Failed to check worksheets: $($_.Exception.Message)"
    exit 1
}