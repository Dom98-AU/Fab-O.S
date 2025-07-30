-- =====================================================
-- Update Admin User with Company (Standalone Script)
-- =====================================================
-- Use this script if you've already created the company tables
-- and just need to update the admin user

PRINT 'Updating Admin User with Company'
PRINT '================================'
PRINT ''

-- Check if Companies table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    PRINT 'ERROR: Companies table does not exist!'
    PRINT 'Please run COMPLETE_MultiTenant_Migration.sql first.'
    RETURN
END

-- Check if Users table has CompanyId column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT 'ERROR: Users table does not have CompanyId column!'
    PRINT 'Please run COMPLETE_MultiTenant_Migration.sql first.'
    RETURN
END

-- Get or create default company
DECLARE @DefaultCompanyId INT

IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    SET @DefaultCompanyId = SCOPE_IDENTITY()
    PRINT 'Created default company with ID: ' + CAST(@DefaultCompanyId AS VARCHAR(10))
END
ELSE
BEGIN
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
    PRINT 'Using existing default company with ID: ' + CAST(@DefaultCompanyId AS VARCHAR(10))
END

-- Check if admin user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@steelestimation.com')
BEGIN
    PRINT 'WARNING: Admin user (admin@steelestimation.com) does not exist in the database!'
    PRINT 'You may need to create the admin user first.'
END
ELSE
BEGIN
    -- Update admin user
    UPDATE Users 
    SET CompanyId = @DefaultCompanyId 
    WHERE Email = 'admin@steelestimation.com' AND CompanyId IS NULL

    IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'Successfully updated admin user with default company'
    END
    ELSE
    BEGIN
        PRINT 'Admin user already has a company assigned or update failed'
    END
END

-- Update any other users without a company
DECLARE @UpdatedUsers INT
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

SET @UpdatedUsers = @@ROWCOUNT
IF @UpdatedUsers > 0
    PRINT 'Updated ' + CAST(@UpdatedUsers AS VARCHAR(10)) + ' other users with default company'

-- Show admin user details
PRINT ''
PRINT 'Admin User Details:'
PRINT '==================='
SELECT 
    u.Id as UserId,
    u.Username,
    u.Email,
    u.FirstName + ' ' + u.LastName as FullName,
    u.IsActive,
    u.CompanyId,
    c.Name as CompanyName,
    c.Code as CompanyCode,
    c.SubscriptionLevel
FROM Users u
LEFT JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Email = 'admin@steelestimation.com'

-- Show summary
PRINT ''
PRINT 'Summary:'
PRINT '--------'
SELECT 
    (SELECT COUNT(*) FROM Users WHERE CompanyId IS NOT NULL) as 'Users with Company',
    (SELECT COUNT(*) FROM Users WHERE CompanyId IS NULL) as 'Users without Company',
    (SELECT COUNT(*) FROM Companies) as 'Total Companies'

PRINT ''
PRINT 'Update completed!'