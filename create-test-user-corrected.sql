-- First check if test user already exists and delete if so
DELETE FROM UserRoles WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'test@test.com');
DELETE FROM Users WHERE Email = 'test@test.com';

-- Create a test user with a simple password to verify authentication works
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
    'testuser',
    'test@test.com',
    '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=', -- Admin@123
    CONVERT(NVARCHAR(200), NEWID()),
    'Test',
    'User',
    1,
    1,
    0,
    GETUTCDATE(),
    GETUTCDATE()
);

-- Get IDs
DECLARE @TestUserId INT;
DECLARE @AdminRoleId INT;

SELECT @TestUserId = Id FROM Users WHERE Email = 'test@test.com';
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';

-- Check if AssignedBy is INT or VARCHAR
DECLARE @sql NVARCHAR(MAX);
DECLARE @AssignedByType NVARCHAR(50);

SELECT @AssignedByType = DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'UserRoles' AND COLUMN_NAME = 'AssignedBy';

IF @AssignedByType = 'int'
BEGIN
    -- If AssignedBy is INT, use user ID
    INSERT INTO UserRoles (UserId, RoleId, AssignedDate, AssignedBy)
    VALUES (@TestUserId, @AdminRoleId, GETUTCDATE(), @TestUserId);
END
ELSE
BEGIN
    -- If AssignedBy is VARCHAR, use 'System'
    INSERT INTO UserRoles (UserId, RoleId, AssignedDate, AssignedBy)
    VALUES (@TestUserId, @AdminRoleId, GETUTCDATE(), 'System');
END

-- Verify
SELECT 
    u.Username,
    u.Email,
    u.IsActive,
    u.IsEmailConfirmed,
    r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'test@test.com';

PRINT '';
PRINT 'Test user created successfully!';
PRINT 'Try logging in with:';
PRINT 'Email: test@test.com';
PRINT 'Password: Admin@123';