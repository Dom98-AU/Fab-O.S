-- =============================================
-- Update Admin Password with Salt
-- Description: Updates admin user with properly salted password
-- Date: 2025-08-01
-- =============================================

PRINT 'Updating admin user with salted password...';
PRINT '';

-- First, set AuthProvider to 'Local' for all users who don't have it set
UPDATE Users 
SET AuthProvider = 'Local' 
WHERE AuthProvider IS NULL;

PRINT 'Set AuthProvider to Local for ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' users';

-- Update admin user with salted password
-- Password: Admin@123
UPDATE Users 
SET 
    PasswordSalt = 'nsYnK4MNzdfPHSCR3MbQnQ==',
    PasswordHash = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==',
    AuthProvider = 'Local'
WHERE Email = 'admin@steelestimation.com';

IF @@ROWCOUNT > 0
BEGIN
    PRINT '';
    PRINT '✅ SUCCESS: Admin user updated with salted password';
    PRINT '';
    PRINT '📝 Login credentials:';
    PRINT '   Email: admin@steelestimation.com';
    PRINT '   Password: Admin@123';
    PRINT '';
    
    -- Show the updated user details
    SELECT 
        Email,
        Username,
        CASE WHEN PasswordHash IS NOT NULL THEN '✅ Has Password' ELSE '❌ No Password' END AS PasswordStatus,
        CASE WHEN PasswordSalt IS NOT NULL THEN '✅ Has Salt' ELSE '❌ No Salt' END AS SaltStatus,
        AuthProvider,
        CASE WHEN IsActive = 1 THEN '✅ Active' ELSE '❌ Inactive' END AS AccountStatus
    FROM Users
    WHERE Email = 'admin@steelestimation.com';
END
ELSE
BEGIN
    PRINT '';
    PRINT '⚠️  Admin user not found. Checking existing users...';
    
    SELECT TOP 10
        Id,
        Email,
        Username,
        CASE WHEN PasswordHash IS NOT NULL THEN 'Has Password' ELSE 'No Password' END AS PasswordStatus,
        AuthProvider,
        IsActive
    FROM Users
    ORDER BY Id;
    
    PRINT '';
    PRINT 'If admin@steelestimation.com is not in the list above, you need to create the user first.';
END

-- Also update any other users that have passwords but no salt
UPDATE Users
SET PasswordSalt = CONVERT(nvarchar(100), NEWID())
WHERE PasswordHash IS NOT NULL 
  AND PasswordSalt IS NULL
  AND Email != 'admin@steelestimation.com';

IF @@ROWCOUNT > 0
    PRINT 'Generated salts for ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' other users';