-- Add DiceBear avatar support to UserProfiles table
-- Migration: AddDiceBearAvatars (Fixed)
-- Date: January 2025

-- Add AvatarType column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'AvatarType')
BEGIN
    ALTER TABLE UserProfiles ADD AvatarType NVARCHAR(50) NULL;
    PRINT 'Added AvatarType column to UserProfiles table';
END
ELSE
BEGIN
    PRINT 'AvatarType column already exists in UserProfiles table';
END
GO

-- Add DiceBearStyle column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'DiceBearStyle')
BEGIN
    ALTER TABLE UserProfiles ADD DiceBearStyle NVARCHAR(100) NULL;
    PRINT 'Added DiceBearStyle column to UserProfiles table';
END
ELSE
BEGIN
    PRINT 'DiceBearStyle column already exists in UserProfiles table';
END
GO

-- Add DiceBearSeed column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'DiceBearSeed')
BEGIN
    ALTER TABLE UserProfiles ADD DiceBearSeed NVARCHAR(100) NULL;
    PRINT 'Added DiceBearSeed column to UserProfiles table';
END
ELSE
BEGIN
    PRINT 'DiceBearSeed column already exists in UserProfiles table';
END
GO

-- Add DiceBearOptions column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'UserProfiles' AND COLUMN_NAME = 'DiceBearOptions')
BEGIN
    ALTER TABLE UserProfiles ADD DiceBearOptions NVARCHAR(500) NULL;
    PRINT 'Added DiceBearOptions column to UserProfiles table';
END
ELSE
BEGIN
    PRINT 'DiceBearOptions column already exists in UserProfiles table';
END
GO

-- Update existing records to have default avatar type if they have an AvatarUrl
UPDATE UserProfiles 
SET AvatarType = 'font-awesome' 
WHERE AvatarUrl IS NOT NULL 
  AND AvatarType IS NULL;

PRINT 'Updated existing records with default avatar type';
GO

PRINT 'Successfully added DiceBear avatar support to UserProfiles table';