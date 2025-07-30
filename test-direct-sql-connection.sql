-- Test if we can query data directly with the managed identity
-- This will confirm the database connection works

-- 1. Simple test query
SELECT TOP 5
    Id,
    Username,
    Email,
    IsActive,
    LEFT(PasswordHash, 20) as PasswordHashStart
FROM Users
ORDER BY Id;

-- 2. Check if password verification would work
SELECT 
    Username,
    Email,
    CASE 
        WHEN PasswordHash = '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA='
        THEN 'Password matches Admin@123 hash'
        ELSE 'Password does not match'
    END as PasswordCheck
FROM Users
WHERE Email IN ('admin@steelestimation.com', 'test@test.com');

-- 3. Test join query like the app would use
SELECT 
    u.Username,
    u.Email,
    u.IsActive,
    STRING_AGG(r.RoleName, ', ') as Roles
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email IN ('admin@steelestimation.com', 'test@test.com')
GROUP BY u.Username, u.Email, u.IsActive;