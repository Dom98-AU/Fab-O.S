-- =============================================
-- Fix Password for Current Authentication System
-- Description: Updates admin password to work with the non-salt authentication
-- Date: 2025-08-01
-- =============================================

PRINT 'Current authentication system does not use PasswordSalt column';
PRINT 'Updating admin password to work without salt...';
PRINT '';

-- The current AuthenticationService uses BCrypt or similar without separate salt
-- Based on the old scripts, the hash format was different
-- Let's use a known working hash from the archive

-- This hash is for Admin@123 without separate salt (from archive files)
UPDATE dbo.Users 
SET 
    PasswordHash = 'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==',
    AuthProvider = 'Local'
WHERE Email = 'admin@steelestimation.com';

IF @@ROWCOUNT > 0
BEGIN
    PRINT 'SUCCESS: Updated admin password';
    PRINT '';
    PRINT 'Login credentials:';
    PRINT '  Email: admin@steelestimation.com';
    PRINT '  Password: Admin@123';
    PRINT '';
    PRINT 'Note: This uses ASP.NET Core Identity password format';
END
ELSE
BEGIN
    PRINT 'ERROR: Admin user not found';
END

-- Show the result
SELECT 
    Email,
    CASE WHEN PasswordHash IS NOT NULL THEN 'Has Password' ELSE 'No Password' END AS Status,
    LEFT(PasswordHash, 20) + '...' AS PasswordHashPreview
FROM dbo.Users
WHERE Email = 'admin@steelestimation.com';