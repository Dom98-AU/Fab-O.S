#!/usr/bin/env pwsh
# Fix Admin User Login Script

Write-Host "Fixing admin user authentication..." -ForegroundColor Yellow

# Read connection string from appsettings
$configPath = "./SteelEstimation.Web/appsettings.json"
$config = Get-Content $configPath | ConvertFrom-Json
$connectionString = $config.ConnectionStrings.DefaultConnection

if (-not $connectionString) {
    Write-Host "Error: Could not find connection string" -ForegroundColor Red
    exit 1
}

# Extract server and database
if ($connectionString -match "Server=([^;]+);.*Database=([^;]+)") {
    $server = $Matches[1]
    $database = $Matches[2]
} else {
    Write-Host "Error: Could not parse connection string" -ForegroundColor Red
    exit 1
}

Write-Host "Server: $server" -ForegroundColor Cyan
Write-Host "Database: $database" -ForegroundColor Cyan

# Run the fix script
$sqlScript = @"
-- Fix Admin User Authentication
-- Ensure PasswordSalt column exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
END

-- Update admin user with correct password hash for Admin@123
-- Using HMACSHA512 with salt
UPDATE Users 
SET 
    PasswordHash = '0kHs0FTVHDuKO7iqQqrjErGp5HVt1pqOlGZ2WCzrGxJo1jkoaZGxvkXDdpW3w0oNkHs3tDTmHWYlHlYRjcCFrg==',
    PasswordSalt = 'hJ0rD8KlJ1YhF6MJ8+GJ6w==',
    AuthProvider = ISNULL(AuthProvider, 'Local'),
    IsActive = 1,
    IsEmailConfirmed = 1
WHERE Email = 'admin@steelestimation.com';

IF @@ROWCOUNT = 0
BEGIN
    -- Create admin user if doesn't exist
    DECLARE @CompanyId int;
    SELECT @CompanyId = Id FROM Companies WHERE Name = 'NWI Group';
    
    IF @CompanyId IS NULL
    BEGIN
        INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
        VALUES ('NWI Group', 'NWI', 1, GETUTCDATE());
        SET @CompanyId = SCOPE_IDENTITY();
    END
    
    INSERT INTO Users (
        Username, Email, PasswordHash, PasswordSalt,
        FirstName, LastName, CompanyId, IsActive,
        IsEmailConfirmed, AuthProvider, CreatedAt
    )
    VALUES (
        'admin', 'admin@steelestimation.com',
        '0kHs0FTVHDuKO7iqQqrjErGp5HVt1pqOlGZ2WCzrGxJo1jkoaZGxvkXDdpW3w0oNkHs3tDTmHWYlHlYRjcCFrg==',
        'hJ0rD8KlJ1YhF6MJ8+GJ6w==',
        'System', 'Administrator', @CompanyId, 1, 1, 'Local', GETUTCDATE()
    );
    
    -- Add admin role
    DECLARE @UserId int = SCOPE_IDENTITY();
    DECLARE @AdminRoleId int;
    SELECT @AdminRoleId = Id FROM Roles WHERE Name = 'Administrator';
    
    IF @AdminRoleId IS NOT NULL
    BEGIN
        INSERT INTO UserRoles (UserId, RoleId)
        SELECT @UserId, @AdminRoleId
        WHERE NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @UserId AND RoleId = @AdminRoleId);
    END
END

-- Verify the result
SELECT Email, FirstName, LastName, IsActive, IsEmailConfirmed, AuthProvider
FROM Users WHERE Email = 'admin@steelestimation.com';
"@

# Execute using sqlcmd
try {
    $result = $sqlScript | sqlcmd -S $server -d $database -U "azureadmin" -P "Azure@NWI2024!" -Q $sqlScript -b 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Admin user fixed successfully!" -ForegroundColor Green
        Write-Host "`nYou can now login with:" -ForegroundColor Yellow
        Write-Host "  Email: admin@steelestimation.com" -ForegroundColor Cyan
        Write-Host "  Password: Admin@123" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Error executing SQL:" -ForegroundColor Red
        Write-Host $result
    }
} catch {
    Write-Host "`n❌ Error: $_" -ForegroundColor Red
}