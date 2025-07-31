Write-Host "Cleaning solution..." -ForegroundColor Yellow

# Clean all bin and obj folders
Get-ChildItem -Path . -Include bin,obj -Directory -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Clean NuGet packages cache for this solution
Write-Host "Clearing local NuGet cache..." -ForegroundColor Yellow
dotnet nuget locals temp -c
dotnet nuget locals http-cache -c

# Clean the solution
Write-Host "Running dotnet clean..." -ForegroundColor Yellow
dotnet clean

# Restore packages
Write-Host "Restoring packages..." -ForegroundColor Yellow
dotnet restore

# Build the solution
Write-Host "Building solution..." -ForegroundColor Yellow
dotnet build

Write-Host "Clean and rebuild completed!" -ForegroundColor Green