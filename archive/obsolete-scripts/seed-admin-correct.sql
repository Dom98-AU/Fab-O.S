USE [SteelEstimationDb];
GO

-- Check if admin user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    -- Insert admin user with correct password hash for 'Admin@123'
    INSERT INTO Users (
        Username, Email, PasswordHash, SecurityStamp,
        IsActive, IsEmailConfirmed, CreatedDate, LastModified
    ) VALUES (
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
        SecurityStamp = '4X8vHZLKVDiNPBDzPuKMBg==',
        IsActive = 1,
        IsEmailConfirmed = 1,
        LastModified = GETUTCDATE()
    WHERE Email = 'admin@steelestimation.com';
    
    PRINT 'Admin user password updated!';
END

-- Get the admin user ID
DECLARE @AdminUserId INT;
SELECT @AdminUserId = Id FROM Users WHERE Email = 'admin@steelestimation.com';

-- Create Administrator role if not exists
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Administrator')
BEGIN
    INSERT INTO Roles (RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES ('Administrator', 'Administrator', 'Full system access', GETUTCDATE(), GETUTCDATE());
END

-- Get the Administrator role ID
DECLARE @AdminRoleId INT;
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';

-- Check if user already has admin role
IF NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    -- Assign admin role to admin user
    INSERT INTO UserRoles (UserId, RoleId)
    VALUES (@AdminUserId, @AdminRoleId);
    
    PRINT 'Admin role assigned!';
END

-- Create other default roles
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Project Manager')
    INSERT INTO Roles (RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES ('Project Manager', 'Project Manager', 'Manage projects and teams', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Senior Estimator')
    INSERT INTO Roles (RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES ('Senior Estimator', 'Senior Estimator', 'Senior estimation privileges', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Estimator')
    INSERT INTO Roles (RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES ('Estimator', 'Estimator', 'Basic estimation privileges', GETUTCDATE(), GETUTCDATE());

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Viewer')
    INSERT INTO Roles (RoleName, Name, Description, CreatedAt, UpdatedAt)
    VALUES ('Viewer', 'Viewer', 'View-only access', GETUTCDATE(), GETUTCDATE());

PRINT 'All roles created/verified!';
GO