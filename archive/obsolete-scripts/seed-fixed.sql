USE [SteelEstimationDb];
GO

-- Check if admin user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    -- Insert admin user with correct password hash for 'Admin@123'
    INSERT INTO Users (
        Username, Email, PasswordHash, SecurityStamp,
        IsActive, IsEmailConfirmed, FailedLoginAttempts,
        CreatedDate, LastModified
    ) VALUES (
        'admin',
        'admin@steelestimation.com',
        'h8MjilN9rWfXn8mL3ooLGLz0M8CL+5s6EYv7FkVL4yY=',
        '4X8vHZLKVDiNPBDzPuKMBg==',
        1,
        1,
        0,  -- FailedLoginAttempts
        GETUTCDATE(),
        GETUTCDATE()
    );
    
    PRINT 'Admin user created successfully!';
END
ELSE
BEGIN
    -- Update existing admin user password
    UPDATE Users 
    SET PasswordHash = 'h8MjilN9rWfXn8mL3ooLGLz0M8CL+5s6EYv7FkVL4yY=',
        SecurityStamp = '4X8vHZLKVDiNPBDzPuKMBg==',
        IsActive = 1,
        IsEmailConfirmed = 1,
        FailedLoginAttempts = 0,
        LastModified = GETUTCDATE()
    WHERE Email = 'admin@steelestimation.com';
    
    PRINT 'Admin user password updated!';
END

-- Get the admin user ID
DECLARE @AdminUserId INT;
SELECT @AdminUserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';
PRINT 'Admin User ID: ' + CAST(@AdminUserId AS VARCHAR(10));

-- Get the Administrator role ID
DECLARE @AdminRoleId INT;
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';

-- Only proceed if we have both IDs
IF @AdminUserId IS NOT NULL AND @AdminRoleId IS NOT NULL
BEGIN
    -- Check if user already has admin role
    IF NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
    BEGIN
        -- Assign admin role to admin user
        INSERT INTO UserRoles (UserId, RoleId, AssignedDate, AssignedBy)
        VALUES (@AdminUserId, @AdminRoleId, GETUTCDATE(), @AdminUserId);
        
        PRINT 'Admin role assigned to user!';
    END
    ELSE
    BEGIN
        PRINT 'User already has admin role!';
    END
END
ELSE
BEGIN
    PRINT 'Could not assign role - missing user or role ID';
END

-- Verify the setup
SELECT u.Id, u.Username, u.Email, u.IsActive, r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com';
GO