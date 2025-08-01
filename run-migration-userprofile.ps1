# User Profile System Migration Script

Write-Host "======================================"
Write-Host "Running User Profile System Migration"
Write-Host "======================================`n"

# Connection details from appsettings.json
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=admin@nwi@nwiapps;Password=Natweigh88;TrustServerCertificate=True;Encrypt=True;"

# SQL file to execute
$sqlFile = "SQL_Migrations\AddUserProfileSystem.sql"

# Check if file exists
if (!(Test-Path $sqlFile)) {
    Write-Host "Error: SQL file not found at $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "Executing migration: $sqlFile" -ForegroundColor Cyan

try {
    # Execute the SQL file
    Invoke-Sqlcmd -ConnectionString $connectionString -InputFile $sqlFile -ErrorAction Stop
    
    Write-Host "`nMigration completed successfully!" -ForegroundColor Green
    Write-Host "Created tables:" -ForegroundColor Yellow
    Write-Host "  - UserProfiles" -ForegroundColor White
    Write-Host "  - UserPreferences" -ForegroundColor White
    Write-Host "  - Comments" -ForegroundColor White
    Write-Host "  - CommentMentions" -ForegroundColor White
    Write-Host "  - CommentReactions" -ForegroundColor White
    Write-Host "  - Notifications" -ForegroundColor White
    Write-Host "  - UserActivities" -ForegroundColor White
    
    # Query to check results
    $userCount = Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT COUNT(*) as Count FROM UserProfiles" -ErrorAction Stop
    $prefCount = Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT COUNT(*) as Count FROM UserPreferences" -ErrorAction Stop
    $notifCount = Invoke-Sqlcmd -ConnectionString $connectionString -Query "SELECT COUNT(*) as Count FROM Notifications" -ErrorAction Stop
    
    Write-Host "`nMigration Results:" -ForegroundColor Yellow
    Write-Host "  User Profiles created: $($userCount.Count)" -ForegroundColor White
    Write-Host "  User Preferences created: $($prefCount.Count)" -ForegroundColor White
    Write-Host "  Welcome notifications sent: $($notifCount.Count)" -ForegroundColor White
}
catch {
    Write-Host "`nError executing migration:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}