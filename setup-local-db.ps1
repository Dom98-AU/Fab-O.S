# Setup Local Database for Steel Estimation Platform
Write-Host "Setting up Steel Estimation Local Database..." -ForegroundColor Green

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script requires Administrator privileges to create the database." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Variables
$ServerInstance = "localhost"
$DatabaseName = "SteelEstimationDb"
$ProjectPath = $PSScriptRoot

# Check if SQL Server is running
try {
    $sqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction Stop
    if ($sqlService.Status -ne "Running") {
        Write-Host "Starting SQL Server service..." -ForegroundColor Yellow
        Start-Service -Name "MSSQLSERVER"
        Start-Sleep -Seconds 5
    }
    Write-Host "SQL Server service is running." -ForegroundColor Green
} catch {
    Write-Host "SQL Server service not found. Please ensure SQL Server 2022 is installed." -ForegroundColor Red
    exit 1
}

# Create database using sqlcmd
Write-Host "`nCreating database '$DatabaseName'..." -ForegroundColor Yellow
$createDbScript = @"
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$DatabaseName')
BEGIN
    ALTER DATABASE [$DatabaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$DatabaseName];
END
CREATE DATABASE [$DatabaseName];
GO
"@

try {
    sqlcmd -S $ServerInstance -E -Q $createDbScript
    Write-Host "Database created successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to create database. Error: $_" -ForegroundColor Red
    exit 1
}

# Run Entity Framework migrations
Write-Host "`nRunning Entity Framework migrations..." -ForegroundColor Yellow
Push-Location "$ProjectPath\SteelEstimation.Web"

try {
    # Install EF tools if not present
    dotnet tool install --global dotnet-ef --version 8.* 2>$null
    
    # Run migrations
    dotnet ef database update --startup-project . --project ..\SteelEstimation.Infrastructure\SteelEstimation.Infrastructure.csproj
    
    Write-Host "Migrations completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to run migrations. Error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Seed initial data
Write-Host "`nSeeding initial data..." -ForegroundColor Yellow
$seedScript = @"
USE [$DatabaseName];
GO

-- Check if admin user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    -- Insert admin user with correct password hash for 'Admin@123'
    -- Password: Admin@123, Salt: 4X8vHZLKVDiNPBDzPuKMBg==, Hash: computed using PBKDF2-HMACSHA256
    INSERT INTO Users (
        Id, Username, Email, PasswordHash, PasswordSalt, 
        IsActive, IsEmailConfirmed, CreatedAt, UpdatedAt
    ) VALUES (
        NEWID(),
        'admin',
        'admin@steelestimation.com',
        'h8MjilN9rWfXn8mL3ooLGLz0M8CL+5s6EYv7FkVL4yY=',
        '4X8vHZLKVDiNPBDzPuKMBg==',
        1,
        1,
        GETUTCDATE(),
        GETUTCDATE()
    );
    
    -- Get the admin user ID
    DECLARE @AdminUserId UNIQUEIDENTIFIER;
    SELECT @AdminUserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';
    
    -- Create Administrator role if not exists
    IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Administrator')
    BEGIN
        INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
        VALUES (NEWID(), 'Administrator', 'Administrator', 'Full system access', GETUTCDATE(), GETUTCDATE());
    END
    
    -- Get the Administrator role ID
    DECLARE @AdminRoleId UNIQUEIDENTIFIER;
    SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';
    
    -- Assign admin role to admin user
    INSERT INTO UserRoles (UserId, RoleId, AssignedAt, AssignedBy)
    VALUES (@AdminUserId, @AdminRoleId, GETUTCDATE(), @AdminUserId);
    
    PRINT 'Admin user created successfully!';
END
ELSE
BEGIN
    -- Update existing admin user password
    UPDATE Users 
    SET PasswordHash = 'h8MjilN9rWfXn8mL3ooLGLz0M8CL+5s6EYv7FkVL4yY=',
        PasswordSalt = '4X8vHZLKVDiNPBDzPuKMBg==',
        IsActive = 1,
        IsEmailConfirmed = 1,
        UpdatedAt = GETUTCDATE()
    WHERE Email = 'admin@steelestimation.com';
    
    PRINT 'Admin user password updated!';
END

-- Create other default roles if they don't exist
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Project Manager')
BEGIN
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Project Manager', 'Project Manager', 'Manage projects and teams', GETUTCDATE(), GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Senior Estimator')
BEGIN
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Senior Estimator', 'Senior Estimator', 'Senior estimation privileges', GETUTCDATE(), GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Estimator')
BEGIN
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Estimator', 'Estimator', 'Basic estimation privileges', GETUTCDATE(), GETUTCDATE());
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Viewer')
BEGIN
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Viewer', 'Viewer', 'View-only access', GETUTCDATE(), GETUTCDATE());
END

PRINT 'Initial data seeded successfully!';
GO
"@

try {
    sqlcmd -S $ServerInstance -E -d $DatabaseName -Q $seedScript
    Write-Host "Initial data seeded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to seed initial data. Error: $_" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Local database setup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nDatabase Details:" -ForegroundColor Yellow
Write-Host "  Server: $ServerInstance" -ForegroundColor White
Write-Host "  Database: $DatabaseName" -ForegroundColor White
Write-Host "  Authentication: Windows Authentication" -ForegroundColor White
Write-Host "`nAdmin Credentials:" -ForegroundColor Yellow
Write-Host "  Email: admin@steelestimation.com" -ForegroundColor White
Write-Host "  Password: Admin@123" -ForegroundColor White
Write-Host "`nTo run the application:" -ForegroundColor Yellow
Write-Host "  cd SteelEstimation.Web" -ForegroundColor White
Write-Host "  dotnet run" -ForegroundColor White
Write-Host "`nThen navigate to: https://localhost:5001" -ForegroundColor Green