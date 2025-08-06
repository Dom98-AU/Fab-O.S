-- Check current admin DiceBear options
SELECT u.Email, up.DiceBearOptions 
FROM UserProfiles up 
JOIN Users u ON up.UserId = u.Id 
WHERE u.Email = 'admin@steelestimation.com';