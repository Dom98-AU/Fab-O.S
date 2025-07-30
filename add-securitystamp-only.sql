-- Add just the SecurityStamp column
ALTER TABLE [dbo].[Users] ADD [SecurityStamp] NVARCHAR(200) NULL;

-- Set a value for existing users
UPDATE [dbo].[Users] 
SET [SecurityStamp] = CONVERT(NVARCHAR(200), NEWID())
WHERE [SecurityStamp] IS NULL;