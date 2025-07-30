-- Comprehensive authentication diagnosis

-- 1. Check admin user details
SELECT 'Admin User Details:' as Section;
SELECT 
    Id,
    Username,
    Email,
    LEN(PasswordHash) as PasswordHashLength,
    LEFT(PasswordHash, 50) as PasswordHashPrefix,
    IsActive,
    IsEmailConfirmed,
    FailedLoginAttempts,
    LockedOutUntil,
    SecurityStamp
FROM Users
WHERE Email = 'admin@steelestimation.com';

-- 2. Check user roles
SELECT '';
SELECT 'Admin User Roles:' as Section;
SELECT 
    u.Id as UserId,
    u.Email,
    ur.RoleId,
    r.RoleName,
    ur.AssignedDate
FROM Users u
JOIN UserRoles ur ON u.Id = ur.UserId
JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';

-- 3. Verify password hash format
SELECT '';
SELECT 'Password Hash Analysis:' as Section;
SELECT 
    CASE 
        WHEN CHARINDEX('.', PasswordHash) > 0 THEN 'Valid format (contains salt separator)'
        ELSE 'Invalid format (missing salt separator)'
    END as HashFormat,
    CHARINDEX('.', PasswordHash) as DotPosition,
    LEN(PasswordHash) as TotalLength
FROM Users
WHERE Email = 'admin@steelestimation.com';

-- 4. Check all roles
SELECT '';
SELECT 'All Available Roles:' as Section;
SELECT * FROM Roles ORDER BY Id;

-- 5. Check for any recent login attempts
SELECT '';
SELECT 'Recent Login Activity:' as Section;
SELECT TOP 5
    Username,
    Email,
    LastLoginDate,
    FailedLoginAttempts,
    LockedOutUntil,
    LastModified
FROM Users
ORDER BY LastModified DESC;