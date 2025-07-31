-- Step 1: Update admin password to Admin@123
-- New password hash: 3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=

PRINT 'Updating admin password...';

UPDATE Users
SET 
    PasswordHash = '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=',
    FailedLoginAttempts = 0,
    LockedOutUntil = NULL,
    LastModified = GETUTCDATE()
WHERE Email = 'admin@steelestimation.com';

-- Verify the password update
SELECT 
    u.Id,
    u.Username,
    u.Email,
    u.IsActive,
    u.IsEmailConfirmed,
    ur.RoleId,
    r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';

PRINT 'Admin password updated successfully!';
PRINT '';

-- Step 2: Remove the obsolete Role column from Users table
PRINT 'Removing obsolete Role column from Users table...';

-- Check if the column exists before trying to drop it
IF EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Users' 
    AND COLUMN_NAME = 'Role'
)
BEGIN
    ALTER TABLE Users DROP COLUMN Role;
    PRINT 'Role column removed successfully!';
END
ELSE
BEGIN
    PRINT 'Role column does not exist or was already removed.';
END

PRINT '';
PRINT '========================================';
PRINT 'Database cleanup complete!';
PRINT '========================================';
PRINT 'You can now login with:';
PRINT 'Email: admin@steelestimation.com';
PRINT 'Password: Admin@123';
PRINT '========================================';

-- Show final Users table structure
SELECT 'Final Users table columns:' as Info;
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Users'
ORDER BY ORDINAL_POSITION;