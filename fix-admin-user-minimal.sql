-- Fix admin user with correct password hash for Admin@123
-- Hash: 3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=

-- First, delete any existing admin user
DELETE FROM UserRoles WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'admin@steelestimation.com');
DELETE FROM Users WHERE Email = 'admin@steelestimation.com';

-- Get the Administrator role ID
DECLARE @AdminRoleId INT;
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';

-- Create the admin user with only required columns
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
    '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=',
    NEWID(),
    'System',
    'Administrator',
    1,
    1,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Get the new user ID
DECLARE @UserId INT;
SELECT @UserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';

-- Assign Administrator role
INSERT INTO UserRoles (UserId, RoleId, AssignedDate, AssignedBy)
VALUES (@UserId, @AdminRoleId, GETUTCDATE(), 'System');

-- Verify the user was created
SELECT 
    u.Id,
    u.Username,
    u.Email,
    u.FirstName,
    u.LastName,
    u.IsActive,
    u.IsEmailConfirmed,
    r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';