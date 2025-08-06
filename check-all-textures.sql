-- Check all users for texture data
SELECT COUNT(*) as TotalProfiles
FROM UserProfiles
WHERE DiceBearOptions IS NOT NULL;

SELECT COUNT(*) as ProfilesWithTexture
FROM UserProfiles
WHERE DiceBearOptions LIKE '%texture%';

-- Show any profiles that have texture
SELECT u.Email, up.DiceBearOptions
FROM UserProfiles up
JOIN Users u ON up.UserId = u.Id
WHERE up.DiceBearOptions LIKE '%texture%';