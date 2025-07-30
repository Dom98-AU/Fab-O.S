# PowerShell script to sync existing database with EF migrations
param(
    [Parameter(Mandatory=$false)]
    [switch]$ForceSync,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SqlPassword
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sync Staging Database with EF Migrations" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "This script helps when tables exist but migrations aren't tracked" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# SQL to add migration history for existing database
$syncSql = @"
-- Create migrations history table if it doesn't exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '__EFMigrationsHistory')
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
    PRINT 'Created __EFMigrationsHistory table'
END
ELSE
BEGIN
    PRINT '__EFMigrationsHistory table already exists'
END

-- Check if InitialCreate migration is already recorded
IF NOT EXISTS (SELECT * FROM __EFMigrationsHistory WHERE MigrationId = '20250630054245_InitialCreate')
BEGIN
    -- Insert the migration record to mark it as applied
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
    VALUES ('20250630054245_InitialCreate', '8.0.0');
    PRINT 'Added InitialCreate migration to history'
END
ELSE
BEGIN
    PRINT 'InitialCreate migration already in history'
END

-- Verify the result
SELECT * FROM __EFMigrationsHistory;
"@

if ($ForceSync) {
    if (-not $SqlPassword) {
        $SqlPassword = Read-Host "Enter SQL Password for $SqlUsername" -AsSecureString
    }
    
    Write-Host "`nConnecting to staging database..." -ForegroundColor Yellow
    
    try {
        # Save sync SQL to file
        $syncSql | Out-File -FilePath "sync-migration-history.sql" -Encoding UTF8
        Write-Host "SQL script saved to: sync-migration-history.sql" -ForegroundColor Green
        
        # Execute using sqlcmd if available
        $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
        
        Write-Host "`nExecuting sync script..." -ForegroundColor Yellow
        
        # Try to execute via .NET
        Add-Type -AssemblyName "System.Data"
        $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = $syncSql
        $result = $command.ExecuteNonQuery()
        
        Write-Host "`nSync completed successfully!" -ForegroundColor Green
        
        # Get the results
        $command.CommandText = "SELECT * FROM __EFMigrationsHistory"
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        
        Write-Host "`nCurrent migration history:" -ForegroundColor Cyan
        $dataset.Tables[0] | Format-Table -AutoSize
        
        $connection.Close()
        
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Sync Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Your database now thinks the InitialCreate migration has been applied." -ForegroundColor Green
        Write-Host "You can now deploy the application without migration errors." -ForegroundColor Green
        
    } catch {
        Write-Host "`nError executing sync:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`nYou can manually run the SQL script: sync-migration-history.sql" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nThis script will:" -ForegroundColor Yellow
    Write-Host "1. Create the __EFMigrationsHistory table (if missing)" -ForegroundColor White
    Write-Host "2. Add the InitialCreate migration entry" -ForegroundColor White
    Write-Host "3. Mark your existing database as 'migrated'" -ForegroundColor White
    
    Write-Host "`nSQL Script Preview:" -ForegroundColor Cyan
    Write-Host $syncSql -ForegroundColor Gray
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "To execute this sync:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Option 1: Run with -ForceSync parameter" -ForegroundColor White
    Write-Host "  .\sync-staging-migrations.ps1 -ForceSync" -ForegroundColor Cyan
    
    Write-Host "`nOption 2: Copy the SQL above and run in Azure Portal Query Editor" -ForegroundColor White
    
    Write-Host "`nOption 3: Use the generated SQL file" -ForegroundColor White
    Write-Host "  The SQL has been saved to: sync-migration-history.sql" -ForegroundColor Cyan
    
    # Save the SQL to file
    $syncSql | Out-File -FilePath "sync-migration-history.sql" -Encoding UTF8
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")