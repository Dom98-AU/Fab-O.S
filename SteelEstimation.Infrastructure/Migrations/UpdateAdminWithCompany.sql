-- Update Administrator Account with Company
-- This script ensures the admin account has a company assigned

-- First, ensure default company exists
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default company'
END

DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

-- Update admin user with company
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE Email = 'admin@steelestimation.com' AND CompanyId IS NULL

PRINT 'Updated admin user with default company'

-- Update any other users without a company
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

PRINT 'Updated all users without a company to default company'

-- Verify the update
SELECT 
    u.Id,
    u.Username,
    u.Email,
    u.CompanyId,
    c.Name as CompanyName,
    c.Code as CompanyCode
FROM Users u
LEFT JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Email = 'admin@steelestimation.com'