-- Master Migration Script for Multi-Tenant Support
-- Run this script to apply all multi-tenant changes

PRINT '========================================='
PRINT 'Starting Multi-Tenant Migration'
PRINT '========================================='
PRINT ''

-- Step 1: Create multi-tenant tables
PRINT 'Step 1: Creating multi-tenant tables...'
PRINT '----------------------------------------'

-- Check if migration already applied
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    PRINT 'Multi-tenant tables already exist. Skipping table creation.'
END
ELSE
BEGIN
    -- Run the AddMultiTenantSupport migration
    :r AddMultiTenantSupport.sql
END

PRINT ''

-- Step 2: Update admin account with company
PRINT 'Step 2: Updating administrator account...'
PRINT '----------------------------------------'

-- Ensure default company exists
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default company'
END

DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

-- Update admin and all users
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

PRINT 'Updated all users with default company'

-- Show admin status
SELECT 
    u.Username,
    u.Email,
    c.Name as CompanyName,
    c.Code as CompanyCode
FROM Users u
INNER JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Email = 'admin@steelestimation.com'

PRINT ''

-- Step 3: Seed default material data
PRINT 'Step 3: Seeding default material settings...'
PRINT '--------------------------------------------'

-- Check if we need to seed data
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialTypes WHERE CompanyId = @DefaultCompanyId)
BEGIN
    -- Run the seed data migration
    :r SeedMultiTenantData.sql
END
ELSE
BEGIN
    PRINT 'Material settings already exist. Skipping seed data.'
END

PRINT ''
PRINT '========================================='
PRINT 'Multi-Tenant Migration Complete!'
PRINT '========================================='
PRINT ''
PRINT 'Summary:'
PRINT '--------'

-- Show summary
SELECT 
    (SELECT COUNT(*) FROM Companies) as 'Total Companies',
    (SELECT COUNT(*) FROM Users WHERE CompanyId IS NOT NULL) as 'Users with Company',
    (SELECT COUNT(*) FROM CompanyMaterialTypes) as 'Material Types',
    (SELECT COUNT(*) FROM CompanyMbeIdMappings) as 'MBE ID Mappings',
    (SELECT COUNT(*) FROM CompanyMaterialPatterns) as 'Material Patterns'