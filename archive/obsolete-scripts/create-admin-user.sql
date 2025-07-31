-- Create default admin user if no users exist
-- Password is: Admin@123
-- Run this ONLY in sandbox for initial setup

IF NOT EXISTS (SELECT 1 FROM [dbo].[Users])
BEGIN
    -- Insert admin user
    INSERT INTO [dbo].[Users] (
        [Username],
        [Email],
        [PasswordHash],
        [FirstName],
        [LastName],
        [IsActive],
        [IsEmailConfirmed],
        [CreatedDate],
        [LastModified],
        [SecurityStamp]
    )
    VALUES (
        'admin',
        'admin@steelestimation.com',
        'F+TJMqUPKmI7yqm7MpfP2FTjpCJfEaOCdBvPL8h8GQk=.J3KDgS/Yy8eaBCVa05q0X3KQQRNiUAa8m4DmDCVyBuQ=', -- Admin@123
        'System',
        'Administrator',
        1,
        1,
        GETUTCDATE(),
        GETUTCDATE(),
        NEWID()
    )
    
    -- Get the admin user ID
    DECLARE @AdminUserId INT = SCOPE_IDENTITY()
    
    -- Assign Administrator role (assuming RoleId 1 is Administrator)
    INSERT INTO [dbo].[UserRoles] ([UserId], [RoleId], [AssignedDate])
    VALUES (@AdminUserId, 1, GETUTCDATE())
    
    PRINT 'Admin user created successfully. Username: admin, Password: Admin@123'
END
ELSE
BEGIN
    PRINT 'Users already exist in the database. No admin user created.'
END