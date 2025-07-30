-- Delete all existing admin users
DELETE FROM UserRoles WHERE UserId IN (SELECT Id FROM Users WHERE Email LIKE '%admin%@steelestimation.com');
DELETE FROM Users WHERE Email LIKE '%admin%@steelestimation.com';

-- Create fresh admin user with known working password hash
-- Password: Admin@123
INSERT INTO Users (
    Username, 
    Email, 
    PasswordHash, 
    SecurityStamp,
    FirstName,
    LastName,
    IsActive,
    IsEmailConfirmed,
    FailedLoginAttempts,
    CreatedDate,
    LastModified
) VALUES (
    'admin',
    'admin@steelestimation.com',
    'wP1rLqKmVl0H9x3J5Zz8rQ==.Y3ODVrm6Ii+ySsJEzZO9p6tcC7TYZK3LRpCRKrfRaHE=',
    NEWID(),
    'System',
    'Administrator',
    1,
    1,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Get the user ID and assign admin role
DECLARE @UserId INT = SCOPE_IDENTITY();
DECLARE @AdminRoleId INT = (SELECT TOP 1 Id FROM Roles WHERE RoleName = 'Administrator');

INSERT INTO UserRoles (UserId, RoleId, AssignedDate, AssignedBy)
VALUES (@UserId, @AdminRoleId, GETUTCDATE(), @UserId);

-- Verify the user was created
SELECT u.Id, u.Username, u.Email, u.IsActive, u.IsEmailConfirmed, r.RoleName
FROM Users u
JOIN UserRoles ur ON u.Id = ur.UserId
JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';