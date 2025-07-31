USE [SteelEstimationDb];
GO

-- Check if admin user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    -- Insert admin user with correct password hash for 'Admin@123'
    INSERT INTO Users (
        Id, Username, Email, PasswordHash, PasswordSalt, 
        IsActive, IsEmailConfirmed, CreatedAt, UpdatedAt
    ) VALUES (
        NEWID(),
        'admin',
        'admin@steelestimation.com',
        'h8MjilN9rWfXn8mL3ooLGLz0M8CL+5s6EYv7FkVL4yY=',
        '4X8vHZLKVDiNPBDzPuKMBg==',
        1,
        1,
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
        PasswordSalt = '4X8vHZLKVDiNPBDzPuKMBg==',
        IsActive = 1,
        IsEmailConfirmed = 1,
        UpdatedAt = GETUTCDATE()
    WHERE Email = 'admin@steelestimation.com';
    
    PRINT 'Admin user password updated!';
END

-- Get the admin user ID
DECLARE @AdminUserId UNIQUEIDENTIFIER;
SELECT @AdminUserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';

-- Create Administrator role if not exists
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Administrator')
BEGIN
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Administrator', 'Administrator', 'Full system access', GETUTCDATE(), GETUTCDATE());
END

-- Get the Administrator role ID
DECLARE @AdminRoleId UNIQUEIDENTIFIER;
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';

-- Check if user already has admin role
IF NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    -- Assign admin role to admin user
    INSERT INTO UserRoles (UserId, RoleId, AssignedAt, AssignedBy)
    VALUES (@AdminUserId, @AdminRoleId, GETUTCDATE(), @AdminUserId);
    
    PRINT 'Admin role assigned!';
END

-- Create other default roles
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Project Manager')
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Project Manager', 'Project Manager', 'Manage projects and teams', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Senior Estimator')
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Senior Estimator', 'Senior Estimator', 'Senior estimation privileges', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Estimator')
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Estimator', 'Estimator', 'Basic estimation privileges', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Viewer')
    INSERT INTO Roles (Id, RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES (NEWID(), 'Viewer', 'Viewer', 'View-only access', GETUTCDATE(), GETUTCDATE());

PRINT 'All roles created/verified!';
GO