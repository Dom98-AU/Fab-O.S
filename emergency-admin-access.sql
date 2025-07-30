-- Emergency Admin Access Script
-- Use this if you get locked out of the system
-- Replace the email with your actual email address

DECLARE @NewUserId INT;

-- Create emergency admin user
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
    [SecurityStamp],
    [FailedLoginAttempts],
    [IsLockedOut]
)
VALUES (
    'emergency_admin',
    'your-email@company.com', -- CHANGE THIS
    'F+TJMqUPKmI7yqm7MpfP2FTjpCJfEaOCdBvPL8h8GQk=.J3KDgS/Yy8eaBCVa05q0X3KQQRNiUAa8m4DmDCVyBuQ=', -- Password: Admin@123
    'Emergency',
    'Admin',
    1,
    1,
    GETUTCDATE(),
    GETUTCDATE(),
    NEWID(),
    0,
    0
);

SET @NewUserId = SCOPE_IDENTITY();

-- Assign Administrator role
INSERT INTO [dbo].[UserRoles] ([UserId], [RoleId], [AssignedDate])
VALUES (@NewUserId, 1, GETUTCDATE());

PRINT 'Emergency admin created. Username: emergency_admin, Password: Admin@123';
PRINT 'IMPORTANT: Change this password immediately after login!';