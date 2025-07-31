# Test database connection for staging
Write-Host "Testing database connection for staging environment..." -ForegroundColor Yellow

# Get the connection string
$connString = az webapp config connection-string list `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --slot "staging" `
    --query "[0].value" -o tsv

Write-Host "`nConnection String:" -ForegroundColor Cyan
Write-Host $connString

# Test with sqlcmd if available
Write-Host "`nTesting connection..." -ForegroundColor Yellow

# Create a simple test script
$testSql = @"
SELECT 
    DB_NAME() as DatabaseName,
    CURRENT_USER as CurrentUser,
    @@VERSION as ServerVersion
"@

# Try to connect using Azure CLI
Write-Host "`nAttempting to query database..." -ForegroundColor Yellow
az sql db show --resource-group "NWIApps" `
    --server "nwiapps" `
    --name "sqldb-steel-estimation-sandbox" `
    --query "{name:name, status:status, edition:edition}" -o table

Write-Host "`nIf the app is still failing to start, try these steps:" -ForegroundColor Yellow
Write-Host "1. Check if there are any missing tables in the sandbox database" -ForegroundColor White
Write-Host "2. Verify the JWT secret key is long enough (32+ characters)" -ForegroundColor White
Write-Host "3. Consider switching to SQL authentication temporarily" -ForegroundColor White

Write-Host "`nTo switch to SQL authentication, run:" -ForegroundColor Cyan
Write-Host ".\use-sql-auth-staging.ps1" -ForegroundColor Green