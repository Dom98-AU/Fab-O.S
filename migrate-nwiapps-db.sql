-- Migration: Increase DiceBearOptions column length from 500 to 2000 characters
-- This allows for more complex avatar customization options to be stored

-- Update UserProfiles table to increase DiceBearOptions column length
ALTER TABLE [dbo].[UserProfiles]
ALTER COLUMN [DiceBearOptions] NVARCHAR(2000) NULL
GO

PRINT 'Successfully increased DiceBearOptions column length to 2000 characters'
GO