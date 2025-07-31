-- Update admin password to a more secure one
-- New password will be: AdminPass123!

UPDATE [dbo].[Users]
SET [PasswordHash] = 'Uxe9UqIQEcLEHDDa+HF+vBFQFkGR+QrCvgU5HpMuV3Y=.zEqVrmzY6lOH8scVn0k4qvjxlnCQGt6VcyT4EeU4v14='
WHERE [Email] = 'admin@steelestimation.com'

PRINT 'Admin password updated successfully'
PRINT 'New credentials:'
PRINT 'Username: admin@steelestimation.com'  
PRINT 'Password: AdminPass123!'