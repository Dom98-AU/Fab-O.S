#!/usr/bin/env pwsh

Write-Host "=== Running DiceBear Avatar Migration ===" -ForegroundColor Green
Write-Host "This migration adds DiceBear avatar support to the UserProfiles table" -ForegroundColor Yellow
Write-Host ""

# Connection details
$Server = "tcp:nwiapps.database.windows.net,1433"
$Database = "sqldb-steel-estimation-sandbox"
$Username = "admin@nwi@nwiapps"
$Password = "Natweigh88"

# Migration file
$MigrationFile = "SQL_Migrations/AddDiceBearAvatars.sql"

# Check if migration file exists
if (-not (Test-Path $MigrationFile)) {
    Write-Host "❌ Migration file not found: $MigrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Migration file found: $MigrationFile" -ForegroundColor Green
Write-Host "📡 Connecting to: $Server" -ForegroundColor Cyan
Write-Host "🗄️  Database: $Database" -ForegroundColor Cyan
Write-Host ""

try {
    # Read the migration file
    $SqlScript = Get-Content -Path $MigrationFile -Raw
    
    # Execute the migration
    Write-Host "🚀 Executing DiceBear avatar migration..." -ForegroundColor Yellow
    
    $connectionString = "Server=$Server;Database=$Database;User ID=$Username;Password=$Password;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    # Use sqlcmd if available, otherwise use Invoke-Sqlcmd
    if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        Write-Host "Using sqlcmd..." -ForegroundColor Gray
        sqlcmd -S $Server -d $Database -U $Username -P $Password -i $MigrationFile -e
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ DiceBear avatar migration completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Migration failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "❌ sqlcmd not found. Please install SQL Server Command Line Tools." -ForegroundColor Red
        Write-Host "Download from: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "❌ Error running migration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Migration completed! The application now supports:" -ForegroundColor Green
Write-Host "   • Font Awesome icon avatars" -ForegroundColor White
Write-Host "   • DiceBear generated avatars with 18+ styles" -ForegroundColor White
Write-Host "   • Custom avatar URLs" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Rebuild and restart the application" -ForegroundColor White
Write-Host "2. Test avatar selection in user profiles" -ForegroundColor White
Write-Host "3. Try different DiceBear styles and seeds" -ForegroundColor White