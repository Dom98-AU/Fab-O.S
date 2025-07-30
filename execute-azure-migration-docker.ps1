# Execute Azure SQL Migration using Docker SQL Tools
param(
    [string]$BatchFile = "azure-migration-batch1.sql"
)

Write-Host "Executing Azure SQL migration using Docker..." -ForegroundColor Green
Write-Host "Target database: sqldb-steel-estimation-prod" -ForegroundColor Yellow
Write-Host "Migration file: $BatchFile" -ForegroundColor Yellow
Write-Host ""

# Note: You'll need to provide the correct username and password
Write-Host "Please provide Azure SQL credentials:" -ForegroundColor Cyan
$username = Read-Host "Username"
$password = Read-Host "Password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Execute migration using Docker
Write-Host ""
Write-Host "Executing migration..." -ForegroundColor Green

docker run --rm -v "${PWD}:/scripts" mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-prod" `
    -U $username `
    -P $plainPassword `
    -C `
    -i "/scripts/$BatchFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Migration executed successfully!" -ForegroundColor Green
    
    # Verify tables
    Write-Host ""
    Write-Host "Verifying tables..." -ForegroundColor Cyan
    
    docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S "nwiapps.database.windows.net" `
        -d "sqldb-steel-estimation-prod" `
        -U $username `
        -P $plainPassword `
        -C `
        -Q "SELECT name FROM sys.tables ORDER BY name"
} else {
    Write-Host ""
    Write-Host "Migration failed!" -ForegroundColor Red
}

# Clear password from memory
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)