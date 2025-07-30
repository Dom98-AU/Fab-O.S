-- Check if admin user has CompanyId
SELECT u.Id, u.Username, u.Email, u.CompanyId, c.Name as CompanyName
FROM Users u
LEFT JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Username = 'admin' OR u.Email = 'admin@steelestimation.com';

-- If CompanyId is NULL or 0, update it to 1 (assuming Company with Id=1 exists)
UPDATE Users
SET CompanyId = 1
WHERE (Username = 'admin' OR Email = 'admin@steelestimation.com')
AND (CompanyId IS NULL OR CompanyId = 0);

-- Verify the update
SELECT u.Id, u.Username, u.Email, u.CompanyId, c.Name as CompanyName
FROM Users u
LEFT JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Username = 'admin' OR u.Email = 'admin@steelestimation.com';