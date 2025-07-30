-- Update existing admin user password to Admin@123
-- New password hash: 3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=

-- Update the password hash for the existing admin user
UPDATE Users
SET 
    PasswordHash = '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=',
    FailedLoginAttempts = 0,
    LockedOutUntil = NULL,
    LastModified = GETUTCDATE()
WHERE Email = 'admin@steelestimation.com';

-- Verify the update
SELECT 
    u.Id,
    u.Username,
    u.Email,
    u.PasswordHash,
    u.IsActive,
    u.IsEmailConfirmed,
    ur.RoleId,
    r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';

-- Show success message
SELECT 'Password updated successfully! You can now login with:' as Message
UNION ALL
SELECT 'Email: admin@steelestimation.com'
UNION ALL
SELECT 'Password: Admin@123';