-- =====================================================
-- Step-by-Step Migration - Add CompanyId Only
-- =====================================================
-- This script focuses just on adding CompanyId to Users

PRINT '========================================='
PRINT 'Step-by-Step CompanyId Migration'
PRINT '========================================='
PRINT ''

-- STEP 1: Check current state
PRINT 'STEP 1: Checking current database state...'
PRINT '------------------------------------------'

-- Check if Users table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    PRINT 'ERROR: Users table not found!'
    PRINT 'Please ensure Entity Framework migrations have been run.'
    RETURN
END
ELSE
BEGIN
    PRINT '✓ Users table found'
END

-- Check if CompanyId already exists
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT '! CompanyId column already exists in Users table'
    PRINT 'Skipping column creation...'
END
ELSE
BEGIN
    PRINT '- CompanyId column does not exist yet'
END

PRINT ''

-- STEP 2: Create Companies table first
PRINT 'STEP 2: Creating Companies table...'
PRINT '-----------------------------------'

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Code] [nvarchar](50) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [SubscriptionLevel] [nvarchar](50) NOT NULL DEFAULT 'Standard',
        [MaxUsers] [int] NOT NULL DEFAULT 10,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    PRINT '✓ Created Companies table'
END
ELSE
BEGIN
    PRINT '✓ Companies table already exists'
END

-- Add unique constraint if not exists
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_Companies_Code')
BEGIN
    ALTER TABLE [dbo].[Companies] ADD CONSTRAINT [UQ_Companies_Code] UNIQUE NONCLUSTERED ([Code] ASC)
    PRINT '✓ Added unique constraint on Companies.Code'
END

PRINT ''

-- STEP 3: Add default company
PRINT 'STEP 3: Creating default company...'
PRINT '-----------------------------------'

IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    PRINT '✓ Created default company'
END
ELSE
BEGIN
    PRINT '✓ Default company already exists'
END

-- Get the default company ID
DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
PRINT 'Default Company ID: ' + CAST(@DefaultCompanyId AS VARCHAR)

PRINT ''

-- STEP 4: Add CompanyId column
PRINT 'STEP 4: Adding CompanyId to Users table...'
PRINT '------------------------------------------'

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    -- Add the column as nullable first
    ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL
    PRINT '✓ Added CompanyId column to Users table'
    
    -- Update all existing users with default company
    UPDATE [dbo].[Users] SET CompanyId = @DefaultCompanyId
    PRINT '✓ Updated all users with default company'
    
    -- Now add the foreign key
    ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    PRINT '✓ Added foreign key constraint'
END
ELSE
BEGIN
    PRINT '✓ CompanyId column already exists'
    
    -- Update any null values
    UPDATE [dbo].[Users] SET CompanyId = @DefaultCompanyId WHERE CompanyId IS NULL
    PRINT '✓ Updated any users with null CompanyId'
END

PRINT ''

-- STEP 5: Verify the changes
PRINT 'STEP 5: Verifying changes...'
PRINT '----------------------------'

-- Show Users table structure
PRINT 'Users table structure (showing CompanyId and related columns):'
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[Users]') 
    AND c.name IN ('Id', 'Username', 'Email', 'CompanyId')
ORDER BY c.column_id

PRINT ''

-- Show user count by company
PRINT 'User count by company:'
SELECT 
    c.Name as CompanyName,
    COUNT(u.Id) as UserCount
FROM Companies c
LEFT JOIN Users u ON c.Id = u.CompanyId
GROUP BY c.Id, c.Name

PRINT ''
PRINT '========================================='
PRINT 'CompanyId Migration Complete!'
PRINT '========================================='
PRINT ''
PRINT 'Next: Run SAFE_MultiTenant_Migration.sql to add material settings tables'