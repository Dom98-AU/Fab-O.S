# Fix the schema file for Azure SQL
$content = Get-Content "./azure-schema-init.sql" -Raw

# Remove problematic statements
$content = $content -replace "USE master;.*?GO", ""
$content = $content -replace "IF NOT EXISTS.*?END.*?GO", ""
$content = $content -replace "ALTER DATABASE.*?GO", ""
$content = $content -replace "USE \[SteelEstimationDB\].*?GO", ""

# Ensure we're using the right database
$content = "-- Azure SQL Schema`nUSE [sqldb-steel-estimation-sandbox];`nGO`n`n" + $content

# Save the fixed file
$content | Out-File -FilePath "./azure-schema-fixed.sql" -Encoding UTF8

Write-Host "Schema file fixed for Azure SQL" -ForegroundColor Green