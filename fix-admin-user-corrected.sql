-- Fix admin user with correct password hash for Admin@123
-- Hash: 3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=

-- First, delete any existing admin user
DELETE FROM Users WHERE Email = 'admin@steelestimation.com';

-- Create the admin user with the correct schema
INSERT INTO Users (
    Username,
    Email,
    PasswordHash,
    SecurityStamp,
    FirstName,
    LastName,
    Role,
    IsActive,
    IsEmailConfirmed,
    EmailConfirmationToken,
    PasswordResetToken,
    PasswordResetExpiry,
    RefreshToken,
    RefreshTokenExpiry,
    FailedLoginAttempts,
    LockedOutUntil,
    LastLoginDate,
    CreatedDate,
    LastModified
) VALUES (
    'admin',
    'admin@steelestimation.com',
    '3kzC6Af+VkkxJKHRaFk8OQ==.VVDKYW8nYJpfGMVdvnQUQJ7C7dLojLW72vDqxQSz/pA=',
    CONVERT(NVARCHAR(200), NEWID()),
    'System',
    'Administrator',
    'Administrator',  -- Role is stored directly in Users table
    1,  -- IsActive
    1,  -- IsEmailConfirmed
    NULL,  -- EmailConfirmationToken
    NULL,  -- PasswordResetToken
    NULL,  -- PasswordResetExpiry
    NULL,  -- RefreshToken
    NULL,  -- RefreshTokenExpiry
    0,  -- FailedLoginAttempts
    NULL,  -- LockedOutUntil
    NULL,  -- LastLoginDate
    GETUTCDATE(),  -- CreatedDate
    GETUTCDATE()   -- LastModified
);

-- Verify the user was created
SELECT 
    Id,
    Username,
    Email,
    FirstName,
    LastName,
    Role,
    IsActive,
    IsEmailConfirmed,
    PasswordHash
FROM Users
WHERE Email = 'admin@steelestimation.com';