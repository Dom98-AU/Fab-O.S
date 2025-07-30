-- Comprehensive script to ensure company setup is correct

-- Step 1: Check if Companies table exists
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    PRINT 'Creating Companies table...';
    
    CREATE TABLE [dbo].[Companies] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Code] nvarchar(50) NOT NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        [ModifiedDate] datetime2 NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE ([Code])
    );
    
    CREATE INDEX [IX_Companies_Code] ON [dbo].[Companies] ([Code]);
    CREATE INDEX [IX_Companies_IsActive] ON [dbo].[Companies] ([IsActive]);
    
    PRINT 'Companies table created successfully.';
END
ELSE
BEGIN
    PRINT 'Companies table already exists.';
END
GO

-- Step 2: Ensure default company exists
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    SET IDENTITY_INSERT Companies ON;
    INSERT INTO Companies (Id, Name, Code, IsActive, CreatedDate)
    VALUES (1, 'Default Company', 'DEFAULT', 1, GETUTCDATE());
    SET IDENTITY_INSERT Companies OFF;
    
    PRINT 'Default company created with ID 1.';
END
ELSE
BEGIN
    PRINT 'Default company already exists.';
END
GO

-- Step 3: Update Users table to allow NULL CompanyId temporarily
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'CompanyId' AND is_nullable = 0)
BEGIN
    -- Drop the foreign key constraint temporarily
    DECLARE @ConstraintName nvarchar(200);
    SELECT @ConstraintName = fk.name 
    FROM sys.foreign_keys fk
    WHERE fk.parent_object_id = OBJECT_ID('Users')
    AND fk.referenced_object_id = OBJECT_ID('Companies');
    
    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE Users DROP CONSTRAINT ' + @ConstraintName);
        PRINT 'Dropped foreign key constraint.';
    END
    
    -- Make CompanyId nullable temporarily
    ALTER TABLE Users ALTER COLUMN CompanyId int NULL;
    PRINT 'Made CompanyId nullable temporarily.';
END
GO

-- Step 4: Update all users to have the default company
DECLARE @DefaultCompanyId INT = 1;

UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL OR CompanyId = 0 OR CompanyId NOT IN (SELECT Id FROM Companies);

PRINT 'Updated all users with valid CompanyId.';
GO

-- Step 5: Make CompanyId NOT NULL again and re-add foreign key
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'CompanyId' AND is_nullable = 1)
BEGIN
    -- Make CompanyId NOT NULL
    ALTER TABLE Users ALTER COLUMN CompanyId int NOT NULL;
    
    -- Re-add the foreign key constraint
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Users') AND referenced_object_id = OBJECT_ID('Companies'))
    BEGIN
        ALTER TABLE Users ADD CONSTRAINT FK_Users_Companies_CompanyId 
        FOREIGN KEY (CompanyId) REFERENCES Companies(Id);
        PRINT 'Re-added foreign key constraint.';
    END
END
GO

-- Step 6: Verify the setup
PRINT '';
PRINT '=== VERIFICATION ===';
PRINT '';

-- Show companies
SELECT 'Companies in database:' as Info;
SELECT Id, Name, Code, IsActive FROM Companies;

-- Show user count by company
SELECT 'Users by company:' as Info;
SELECT c.Name as CompanyName, COUNT(u.Id) as UserCount
FROM Companies c
LEFT JOIN Users u ON c.Id = u.CompanyId
GROUP BY c.Id, c.Name;

-- Show admin user details
SELECT 'Admin user details:' as Info;
SELECT Id, Username, Email, CompanyId, FirstName, LastName 
FROM Users 
WHERE Email = 'admin@steelestimation.com';

-- Check for users without valid CompanyId
SELECT 'Users without valid CompanyId:' as Info;
SELECT COUNT(*) as Count FROM Users WHERE CompanyId NOT IN (SELECT Id FROM Companies);

PRINT '';
PRINT 'Company setup verification complete!';
PRINT 'You should now be able to create customers.';
GO