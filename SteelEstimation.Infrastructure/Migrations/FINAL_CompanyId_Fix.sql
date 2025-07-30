-- =====================================================
-- FINAL Fix: Add CompanyId Column to Users Table
-- =====================================================
-- This script specifically handles adding the CompanyId column

PRINT '========================================='
PRINT 'Final CompanyId Column Addition'
PRINT '========================================='
PRINT ''

-- First, let's check the current state
PRINT 'Current state check:'
PRINT '-------------------'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
    PRINT '✓ Companies table exists'
ELSE
    PRINT '✗ Companies table missing'

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
    PRINT '✓ CompanyId column already exists'
ELSE
    PRINT '✗ CompanyId column missing - will add it now'

PRINT ''

-- Add CompanyId column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT 'Adding CompanyId column...'
    
    -- Add the column without any constraints first
    EXEC('ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL')
    
    PRINT 'CompanyId column added successfully'
END
GO

-- Now update with default company
PRINT ''
PRINT 'Updating users with default company...'

DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

IF @DefaultCompanyId IS NOT NULL
BEGIN
    UPDATE [dbo].[Users] 
    SET CompanyId = @DefaultCompanyId 
    WHERE CompanyId IS NULL
    
    PRINT 'Updated users with company ID: ' + CAST(@DefaultCompanyId AS VARCHAR)
END
ELSE
BEGIN
    PRINT 'Warning: Default company not found'
END
GO

-- Add foreign key constraint
PRINT ''
PRINT 'Adding foreign key constraint...'

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
BEGIN
    ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    PRINT 'Foreign key constraint added'
END
ELSE
BEGIN
    PRINT 'Foreign key already exists'
END
GO

-- Add index
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_CompanyId' AND object_id = OBJECT_ID(N'[dbo].[Users]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Users_CompanyId] ON [dbo].[Users]([CompanyId] ASC)
    PRINT 'Index added'
END
GO

-- Final verification
PRINT ''
PRINT '========================================='
PRINT 'Final Verification'
PRINT '========================================='

-- Check if CompanyId exists now
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT '✓ SUCCESS: CompanyId column now exists!'
    
    -- Show user count
    DECLARE @UserCount INT, @UsersWithCompany INT
    SELECT @UserCount = COUNT(*) FROM Users
    SELECT @UsersWithCompany = COUNT(*) FROM Users WHERE CompanyId IS NOT NULL
    
    PRINT 'Total users: ' + CAST(@UserCount AS VARCHAR)
    PRINT 'Users with company: ' + CAST(@UsersWithCompany AS VARCHAR)
    
    -- Show sample data
    PRINT ''
    PRINT 'Sample user data:'
    SELECT TOP 5 
        Id, 
        Username, 
        Email, 
        CompanyId,
        CompanyName as OldCompanyName
    FROM Users
    ORDER BY Id
END
ELSE
BEGIN
    PRINT '✗ ERROR: CompanyId column still missing!'
    PRINT 'Please check for errors above'
END

PRINT ''
PRINT 'Script completed. Check results above.'
PRINT '========================================='