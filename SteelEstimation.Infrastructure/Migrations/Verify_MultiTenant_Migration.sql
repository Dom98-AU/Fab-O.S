-- =====================================================
-- Verify Multi-Tenant Migration Status
-- =====================================================
-- Run this script to check if the migration has been applied correctly

PRINT '========================================='
PRINT 'Multi-Tenant Migration Status Check'
PRINT 'Database: ' + DB_NAME()
PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '========================================='
PRINT ''

-- Check for Companies table
PRINT 'Checking for Company Tables...'
PRINT '------------------------------'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
    PRINT '✓ Companies table exists'
ELSE
    PRINT '✗ Companies table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialTypes')
    PRINT '✓ CompanyMaterialTypes table exists'
ELSE
    PRINT '✗ CompanyMaterialTypes table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMbeIdMappings')
    PRINT '✓ CompanyMbeIdMappings table exists'
ELSE
    PRINT '✗ CompanyMbeIdMappings table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialPatterns')
    PRINT '✓ CompanyMaterialPatterns table exists'
ELSE
    PRINT '✗ CompanyMaterialPatterns table NOT FOUND'

-- Check Users table modifications
PRINT ''
PRINT 'Checking Users Table Modifications...'
PRINT '-------------------------------------'

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
    PRINT '✓ CompanyId column exists in Users table'
ELSE
    PRINT '✗ CompanyId column NOT FOUND in Users table'

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
    PRINT '✓ Foreign key FK_Users_Companies exists'
ELSE
    PRINT '✗ Foreign key FK_Users_Companies NOT FOUND'

-- Check for default company
PRINT ''
PRINT 'Checking Default Company...'
PRINT '---------------------------'

IF EXISTS (SELECT * FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    PRINT '✓ Default company exists'
    SELECT Id, Name, Code, SubscriptionLevel, MaxUsers, IsActive 
    FROM Companies 
    WHERE Code = 'DEFAULT'
END
ELSE
    PRINT '✗ Default company NOT FOUND'

-- Check admin user
PRINT ''
PRINT 'Checking Admin User...'
PRINT '----------------------'

IF EXISTS (SELECT * FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    DECLARE @AdminCompanyId INT
    SELECT @AdminCompanyId = CompanyId FROM Users WHERE Email = 'admin@steelestimation.com'
    
    IF @AdminCompanyId IS NOT NULL
    BEGIN
        PRINT '✓ Admin user has company assigned (CompanyId: ' + CAST(@AdminCompanyId AS VARCHAR) + ')'
        
        SELECT 
            u.Id as UserId,
            u.Username,
            u.Email,
            u.CompanyId,
            c.Name as CompanyName,
            c.Code as CompanyCode
        FROM Users u
        LEFT JOIN Companies c ON u.CompanyId = c.Id
        WHERE u.Email = 'admin@steelestimation.com'
    END
    ELSE
        PRINT '✗ Admin user exists but has NO company assigned'
END
ELSE
    PRINT '✗ Admin user NOT FOUND'

-- Data summary
PRINT ''
PRINT 'Data Summary'
PRINT '============'

SELECT 
    'Companies' as TableName, COUNT(*) as RecordCount 
FROM Companies
UNION ALL
SELECT 
    'Users with Company', COUNT(*) 
FROM Users 
WHERE CompanyId IS NOT NULL
UNION ALL
SELECT 
    'Users without Company', COUNT(*) 
FROM Users 
WHERE CompanyId IS NULL
UNION ALL
SELECT 
    'Material Types', COUNT(*) 
FROM CompanyMaterialTypes
UNION ALL
SELECT 
    'MBE ID Mappings', COUNT(*) 
FROM CompanyMbeIdMappings
UNION ALL
SELECT 
    'Material Patterns', COUNT(*) 
FROM CompanyMaterialPatterns

-- Check for orphaned data
PRINT ''
PRINT 'Data Integrity Checks'
PRINT '====================='

DECLARE @OrphanedUsers INT = (SELECT COUNT(*) FROM Users WHERE CompanyId IS NULL)
IF @OrphanedUsers > 0
    PRINT '⚠ WARNING: ' + CAST(@OrphanedUsers AS VARCHAR) + ' users without a company!'
ELSE
    PRINT '✓ All users have a company assigned'

-- Check for tenant registry tables (optional)
PRINT ''
PRINT 'Multi-Tenant Registry Tables (Optional)'
PRINT '---------------------------------------'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TenantRegistries')
    PRINT '✓ TenantRegistries table exists (multi-tenant mode ready)'
ELSE
    PRINT '- TenantRegistries table not found (single-tenant mode)'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'TenantUsageLogs')
    PRINT '✓ TenantUsageLogs table exists (multi-tenant mode ready)'
ELSE
    PRINT '- TenantUsageLogs table not found (single-tenant mode)'

-- Final status
PRINT ''
PRINT '========================================='
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies') 
   AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT 'RESULT: ✓ Multi-tenant migration APPLIED'
    
    IF @OrphanedUsers > 0
        PRINT 'ACTION REQUIRED: Run UpdateAdminUser_Only.sql to fix orphaned users'
END
ELSE
BEGIN
    PRINT 'RESULT: ✗ Multi-tenant migration NOT APPLIED'
    PRINT 'ACTION REQUIRED: Run COMPLETE_MultiTenant_Migration.sql'
END
PRINT '========================================='