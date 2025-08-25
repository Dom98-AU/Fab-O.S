$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-sandbox;User ID=admin@nwi@nwiapps;Password=Natweigh88;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$connection.Open()

$command = $connection.CreateCommand()
$command.CommandText = "SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('WorkCenters') AND name IN ('LastMaintenanceDate', 'NextMaintenanceDate')"

$reader = $command.ExecuteReader()
Write-Host "Maintenance columns found:" -ForegroundColor Green
while ($reader.Read()) {
    Write-Host "  - $($reader['name'])" -ForegroundColor White
}
$reader.Close()

$countCmd = $connection.CreateCommand()
$countCmd.CommandText = "SELECT COUNT(*) FROM WorkCenters"
$count = $countCmd.ExecuteScalar()
Write-Host "Total WorkCenters: $count" -ForegroundColor Cyan

$connection.Close()
Write-Host "WorkCenters table is ready!" -ForegroundColor Green