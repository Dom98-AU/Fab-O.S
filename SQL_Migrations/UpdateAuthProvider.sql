-- Update all existing users to have 'Local' as AuthProvider
UPDATE Users SET AuthProvider = 'Local' WHERE AuthProvider IS NULL;
GO

-- Check the update
SELECT COUNT(*) as UsersUpdated FROM Users WHERE AuthProvider = 'Local';