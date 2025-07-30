# Run postcode migration script
Write-Host "Running postcode migration..." -ForegroundColor Green

# Change to the Web project directory
Set-Location "SteelEstimation.Web"

# Apply the migration using EF Core
dotnet ef database update

# Navigate back
Set-Location ".."

# Run the SQL script to add sample data
Write-Host "Adding sample postcode data..." -ForegroundColor Green
sqlcmd -S "(localdb)\MSSQLLocalDB" -d "SteelEstimationPlatform" -i "Migrations\AddPostcodes.sql"

Write-Host "Postcode migration completed successfully!" -ForegroundColor Green
Write-Host "The system now supports postcode lookup functionality." -ForegroundColor Yellow