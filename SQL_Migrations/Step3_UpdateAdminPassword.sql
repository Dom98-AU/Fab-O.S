-- =============================================
-- Step 3: Update Admin Password
-- Description: Updates admin user with salted password
-- Date: 2025-08-01
-- =============================================

-- Check what columns exist in Users table
PRINT 'Existing columns in Users table:';
SELECT 
    c.name AS ColumnName,
    t.name AS DataType
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Users')
ORDER BY c.column_id;

PRINT '';
PRINT 'Updating admin user...';

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
    PRINT 'SUCCESS: Admin user updated with salted password';
    PRINT '';
    PRINT 'Login credentials:';
    PRINT '  Email: admin@steelestimation.com';
    PRINT '  Password: Admin@123';
    
    -- Show the updated user
    SELECT 
        Email,
        Username,
        CASE WHEN PasswordHash IS NOT NULL THEN 'Has Password' ELSE 'No Password' END AS PasswordStatus,
        CASE WHEN PasswordSalt IS NOT NULL THEN 'Has Salt' ELSE 'No Salt' END AS SaltStatus,
        AuthProvider,
        IsActive
    FROM Users
    WHERE Email = 'admin@steelestimation.com';
END
ELSE
BEGIN
    PRINT '';
    PRINT 'WARNING: Admin user not found.';
    PRINT 'Checking if any users exist...';
    
    SELECT TOP 5
        Email,
        Username,
        IsActive
    FROM Users
    ORDER BY Id;
END