-- Check admin user details
SELECT TOP 1
    Id,
    Email,
    Username,
    CASE WHEN PasswordHash IS NULL THEN 'NULL' ELSE 'Has Value (' + CAST(LEN(PasswordHash) AS varchar(10)) + ' chars)' END AS PasswordHashStatus,
    CASE WHEN PasswordSalt IS NULL THEN 'NULL' ELSE 'Has Value (' + CAST(LEN(PasswordSalt) AS varchar(10)) + ' chars)' END AS PasswordSaltStatus,
    LEFT(PasswordHash, 50) + '...' AS PasswordHashPreview,
    PasswordSalt,
    AuthProvider,
    IsActive,
    IsEmailConfirmed,
    CompanyId
FROM dbo.Users
WHERE Email = 'admin@steelestimation.com';

-- Check if there are any roles
SELECT 
    u.Email,
    r.Name AS RoleName
FROM dbo.Users u
LEFT JOIN dbo.UserRoles ur ON u.Id = ur.UserId
LEFT JOIN dbo.Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';

-- Check exact values
SELECT 
    PasswordSalt,
    PasswordHash
FROM dbo.Users
WHERE Email = 'admin@steelestimation.com';