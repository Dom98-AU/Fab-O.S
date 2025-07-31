-- Update Users table to add missing columns
-- Run this if you get errors about missing columns

-- Add IsEmailConfirmed column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'IsEmailConfirmed')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [IsEmailConfirmed] BIT NOT NULL DEFAULT 0
    PRINT 'Added IsEmailConfirmed column'
END

-- Add EmailConfirmationToken column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'EmailConfirmationToken')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [EmailConfirmationToken] NVARCHAR(200) NULL
    PRINT 'Added EmailConfirmationToken column'
END

-- Add LastModified column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastModified')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [LastModified] DATETIME2 NOT NULL DEFAULT GETUTCDATE()
    PRINT 'Added LastModified column'
END

-- Add SecurityStamp column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'SecurityStamp')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [SecurityStamp] NVARCHAR(200) NULL
    PRINT 'Added SecurityStamp column'
END

-- Add PasswordResetToken column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PasswordResetToken')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [PasswordResetToken] NVARCHAR(200) NULL
    PRINT 'Added PasswordResetToken column'
END

-- Add PasswordResetExpiry column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PasswordResetExpiry')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [PasswordResetExpiry] DATETIME2 NULL
    PRINT 'Added PasswordResetExpiry column'
END

-- Add RefreshToken column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'RefreshToken')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [RefreshToken] NVARCHAR(200) NULL
    PRINT 'Added RefreshToken column'
END

-- Add RefreshTokenExpiry column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'RefreshTokenExpiry')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [RefreshTokenExpiry] DATETIME2 NULL
    PRINT 'Added RefreshTokenExpiry column'
END

-- Add LastLoginDate column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastLoginDate')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [LastLoginDate] DATETIME2 NULL
    PRINT 'Added LastLoginDate column'
END

-- Add FailedLoginAttempts column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'FailedLoginAttempts')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [FailedLoginAttempts] INT NOT NULL DEFAULT 0
    PRINT 'Added FailedLoginAttempts column'
END

-- Add LockedOutUntil column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LockedOutUntil')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [LockedOutUntil] DATETIME2 NULL
    PRINT 'Added LockedOutUntil column'
END

-- Update existing users to have SecurityStamp if null
UPDATE [dbo].[Users] 
SET [SecurityStamp] = CONVERT(NVARCHAR(200), NEWID())
WHERE [SecurityStamp] IS NULL

PRINT 'Users table update complete!'