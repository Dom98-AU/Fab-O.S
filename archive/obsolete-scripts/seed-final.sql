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
PRINT 'Admin User ID: ' + CAST(@AdminUserId AS VARCHAR(10));

-- Create Administrator role if not exists
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Administrator')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, 
                      CanDeleteProjects, CanViewAllProjects, CanManageUsers, 
                      CanExportData, CanImportData, CreatedDate)
    VALUES ('Administrator', 'Full system access', 1, 1, 1, 1, 1, 1, 1, GETUTCDATE());
    PRINT 'Administrator role created!';
END

-- Get the Administrator role ID
DECLARE @AdminRoleId INT;
SELECT @AdminRoleId = Id FROM Roles WHERE RoleName = 'Administrator';
PRINT 'Admin Role ID: ' + CAST(@AdminRoleId AS VARCHAR(10));

-- Check if user already has admin role
IF NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @AdminUserId AND RoleId = @AdminRoleId)
BEGIN
    -- Assign admin role to admin user
    INSERT INTO UserRoles (UserId, RoleId)
    VALUES (@AdminUserId, @AdminRoleId);
    
    PRINT 'Admin role assigned to user!';
END
ELSE
BEGIN
    PRINT 'User already has admin role!';
END

-- Create other default roles
IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Project Manager')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, 
                      CanDeleteProjects, CanViewAllProjects, CanManageUsers, 
                      CanExportData, CanImportData, CreatedDate)
    VALUES ('Project Manager', 'Manage projects and teams', 1, 1, 1, 1, 0, 1, 1, GETUTCDATE());
    PRINT 'Project Manager role created!';
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Senior Estimator')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, 
                      CanDeleteProjects, CanViewAllProjects, CanManageUsers, 
                      CanExportData, CanImportData, CreatedDate)
    VALUES ('Senior Estimator', 'Senior estimation privileges', 1, 1, 0, 0, 0, 1, 1, GETUTCDATE());
    PRINT 'Senior Estimator role created!';
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Estimator')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, 
                      CanDeleteProjects, CanViewAllProjects, CanManageUsers, 
                      CanExportData, CanImportData, CreatedDate)
    VALUES ('Estimator', 'Basic estimation privileges', 1, 1, 0, 0, 0, 1, 0, GETUTCDATE());
    PRINT 'Estimator role created!';
END

IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = 'Viewer')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, 
                      CanDeleteProjects, CanViewAllProjects, CanManageUsers, 
                      CanExportData, CanImportData, CreatedDate)
    VALUES ('Viewer', 'View-only access', 0, 0, 0, 0, 0, 0, 0, GETUTCDATE());
    PRINT 'Viewer role created!';
END

PRINT 'All roles created/verified!';
GO