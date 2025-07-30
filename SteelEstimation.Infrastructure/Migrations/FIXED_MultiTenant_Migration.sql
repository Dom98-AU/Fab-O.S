-- =====================================================
-- FIXED Multi-Tenant & Organization Migration Script
-- =====================================================
-- This script includes all migrations for organization support
-- Run this script to add company/organization support to your database

PRINT '========================================='
PRINT 'Starting Complete Multi-Tenant Migration'
PRINT 'Database: ' + DB_NAME()
PRINT 'Start Time: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '========================================='
PRINT ''

-- =====================================================
-- STEP 1: Create Company/Organization Tables
-- =====================================================
PRINT 'STEP 1: Creating Company/Organization Tables...'
PRINT '-----------------------------------------------'

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    -- Create Companies table
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Code] [nvarchar](50) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [SubscriptionLevel] [nvarchar](50) NOT NULL DEFAULT 'Standard',
        [MaxUsers] [int] NOT NULL DEFAULT 10,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE NONCLUSTERED ([Code] ASC)
    )
    PRINT '✓ Created Companies table'

    -- Create CompanyMaterialTypes table
    CREATE TABLE [dbo].[CompanyMaterialTypes](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [TypeName] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [HourlyRate] [decimal](10, 2) NOT NULL DEFAULT 0,
        [DefaultWeightPerFoot] [decimal](10, 3) NULL,
        [DefaultColor] [nvarchar](20) NULL,
        [DisplayOrder] [int] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_CompanyMaterialTypes] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_CompanyMaterialTypes_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [UQ_CompanyMaterialTypes_CompanyId_TypeName] UNIQUE NONCLUSTERED ([CompanyId] ASC, [TypeName] ASC)
    )
    PRINT '✓ Created CompanyMaterialTypes table'

    -- Create CompanyMbeIdMappings table
    CREATE TABLE [dbo].[CompanyMbeIdMappings](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [MbeId] [nvarchar](50) NOT NULL,
        [MaterialType] [nvarchar](100) NOT NULL,
        [WeightPerFoot] [decimal](10, 3) NULL,
        [Notes] [nvarchar](500) NULL,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_CompanyMbeIdMappings] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_CompanyMbeIdMappings_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [UQ_CompanyMbeIdMappings_CompanyId_MbeId] UNIQUE NONCLUSTERED ([CompanyId] ASC, [MbeId] ASC)
    )
    PRINT '✓ Created CompanyMbeIdMappings table'

    -- Create CompanyMaterialPatterns table
    CREATE TABLE [dbo].[CompanyMaterialPatterns](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Pattern] [nvarchar](200) NOT NULL,
        [MaterialType] [nvarchar](100) NOT NULL,
        [PatternType] [nvarchar](50) NOT NULL, -- 'StartsWith', 'Contains', 'Regex'
        [Priority] [int] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_CompanyMaterialPatterns] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_CompanyMaterialPatterns_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    )
    PRINT '✓ Created CompanyMaterialPatterns table'

    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_Companies_IsActive] ON [dbo].[Companies]([IsActive] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialTypes_CompanyId] ON [dbo].[CompanyMaterialTypes]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMbeIdMappings_CompanyId] ON [dbo].[CompanyMbeIdMappings]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialPatterns_CompanyId] ON [dbo].[CompanyMaterialPatterns]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialPatterns_CompanyId_PatternType] ON [dbo].[CompanyMaterialPatterns]([CompanyId] ASC, [PatternType] ASC)
    PRINT '✓ Created indexes'
END
ELSE
BEGIN
    PRINT '! Company tables already exist - skipping creation'
END

PRINT ''

-- =====================================================
-- STEP 2: Add CompanyId to Users Table
-- =====================================================
PRINT 'STEP 2: Adding CompanyId to Users Table...'
PRINT '------------------------------------------'

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL
    PRINT '✓ Added CompanyId column to Users table'
END
ELSE
BEGIN
    PRINT '! CompanyId already exists in Users table'
END

PRINT ''

-- =====================================================
-- STEP 3: Create Default Company
-- =====================================================
PRINT 'STEP 3: Creating Default Company...'
PRINT '-----------------------------------'

DECLARE @DefaultCompanyId INT

IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    SET @DefaultCompanyId = SCOPE_IDENTITY()
    PRINT '✓ Created default company with ID: ' + CAST(@DefaultCompanyId AS VARCHAR(10))
END
ELSE
BEGIN
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
    PRINT '! Default company already exists with ID: ' + CAST(@DefaultCompanyId AS VARCHAR(10))
END

PRINT ''

-- =====================================================
-- STEP 4: Update Users with Default Company
-- =====================================================
PRINT 'STEP 4: Updating Users with Default Company...'
PRINT '----------------------------------------------'

-- Update admin user first
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE Email = 'admin@steelestimation.com' AND CompanyId IS NULL

IF @@ROWCOUNT > 0
    PRINT '✓ Updated admin@steelestimation.com with default company'
ELSE
    PRINT '! Admin user already has a company assigned or does not exist'

-- Update all other users without a company
DECLARE @UpdatedUsers INT
UPDATE Users 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

SET @UpdatedUsers = @@ROWCOUNT
IF @UpdatedUsers > 0
    PRINT '✓ Updated ' + CAST(@UpdatedUsers AS VARCHAR(10)) + ' users with default company'
ELSE
    PRINT '! All users already have a company assigned'

PRINT ''

-- =====================================================
-- STEP 5: Add Foreign Key Constraint
-- =====================================================
PRINT 'STEP 5: Adding Foreign Key Constraint...'
PRINT '----------------------------------------'

-- Add foreign key constraint if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
BEGIN
    ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    PRINT '✓ Added foreign key constraint FK_Users_Companies'
END
ELSE
BEGIN
    PRINT '! Foreign key constraint already exists'
END

-- Create index on CompanyId if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_CompanyId' AND object_id = OBJECT_ID(N'[dbo].[Users]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Users_CompanyId] ON [dbo].[Users]([CompanyId] ASC)
    PRINT '✓ Created index on Users.CompanyId'
END
ELSE
BEGIN
    PRINT '! Index on Users.CompanyId already exists'
END

-- Show admin user status
PRINT ''
PRINT 'Admin User Status:'
PRINT '------------------'
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

PRINT ''

-- =====================================================
-- STEP 6: Seed Default Material Settings
-- =====================================================
PRINT 'STEP 6: Seeding Default Material Settings...'
PRINT '--------------------------------------------'

-- Seed material types if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialTypes WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, Description, HourlyRate, DefaultWeightPerFoot, DefaultColor, DisplayOrder, IsActive, CreatedDate, LastModified)
    VALUES 
        (@DefaultCompanyId, 'Beam', 'Structural beams and columns', 65.00, NULL, '#007bff', 1, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Plate', 'Steel plates and flat materials', 65.00, NULL, '#17a2b8', 2, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Purlin', 'Roof and wall purlins', 65.00, NULL, '#28a745', 3, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Fastener', 'Bolts, nuts, and fasteners', 65.00, NULL, '#ffc107', 4, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Misc', 'Miscellaneous steel items', 65.00, NULL, '#6c757d', 5, 1, GETUTCDATE(), GETUTCDATE())
    
    PRINT '✓ Created default material types'
END
ELSE
BEGIN
    PRINT '! Material types already exist for default company'
END

-- Seed MBE ID mappings if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMbeIdMappings WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType, WeightPerFoot, Notes, CreatedDate, LastModified)
    VALUES 
        (@DefaultCompanyId, 'B', 'Beam', NULL, 'Beam materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C', 'Beam', NULL, 'Column materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PL', 'Plate', NULL, 'Plate materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'P', 'Purlin', NULL, 'Purlin materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'F', 'Fastener', NULL, 'Fastener materials', GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'M', 'Misc', NULL, 'Miscellaneous materials', GETUTCDATE(), GETUTCDATE())
    
    PRINT '✓ Created default MBE ID mappings'
END
ELSE
BEGIN
    PRINT '! MBE ID mappings already exist for default company'
END

-- Seed material patterns if none exist
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialPatterns WHERE CompanyId = @DefaultCompanyId)
BEGIN
    INSERT INTO CompanyMaterialPatterns (CompanyId, Pattern, MaterialType, PatternType, Priority, IsActive, CreatedDate, LastModified)
    VALUES 
        -- Beam patterns
        (@DefaultCompanyId, 'BEAM', 'Beam', 'Contains', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UB', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PFC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'RSJ', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'HE', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'IPE', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UKB', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'UKC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Plate patterns
        (@DefaultCompanyId, 'PLATE', 'Plate', 'Contains', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FLT', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PLT', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Purlin patterns
        (@DefaultCompanyId, 'PURLIN', 'Purlin', 'Contains', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C25', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C30', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z25', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z30', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Fastener patterns
        (@DefaultCompanyId, 'BOLT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'NUT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'WASHER', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'SCREW', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FASTENER', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE())
    
    PRINT '✓ Created default material patterns'
END
ELSE
BEGIN
    PRINT '! Material patterns already exist for default company'
END

PRINT ''

-- =====================================================
-- STEP 7: Create Stored Procedure for Copying Settings
-- =====================================================
PRINT 'STEP 7: Creating Utility Stored Procedures...'
PRINT '---------------------------------------------'

-- Drop procedure if exists
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_CopyCompanySettings')
    DROP PROCEDURE sp_CopyCompanySettings

-- Create procedure for copying settings between companies
EXEC('
CREATE PROCEDURE sp_CopyCompanySettings
    @SourceCompanyId INT,
    @TargetCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        -- Copy material types
        INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, Description, HourlyRate, DefaultWeightPerFoot, DefaultColor, DisplayOrder, IsActive, CreatedDate, LastModified)
        SELECT @TargetCompanyId, TypeName, Description, HourlyRate, DefaultWeightPerFoot, DefaultColor, DisplayOrder, IsActive, GETUTCDATE(), GETUTCDATE()
        FROM CompanyMaterialTypes
        WHERE CompanyId = @SourceCompanyId
        
        -- Copy MBE ID mappings
        INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType, WeightPerFoot, Notes, CreatedDate, LastModified)
        SELECT @TargetCompanyId, MbeId, MaterialType, WeightPerFoot, Notes, GETUTCDATE(), GETUTCDATE()
        FROM CompanyMbeIdMappings
        WHERE CompanyId = @SourceCompanyId
        
        -- Copy material patterns
        INSERT INTO CompanyMaterialPatterns (CompanyId, Pattern, MaterialType, PatternType, Priority, IsActive, CreatedDate, LastModified)
        SELECT @TargetCompanyId, Pattern, MaterialType, PatternType, Priority, IsActive, GETUTCDATE(), GETUTCDATE()
        FROM CompanyMaterialPatterns
        WHERE CompanyId = @SourceCompanyId
        
        COMMIT TRANSACTION
        
        PRINT ''✓ Successfully copied settings from company '' + CAST(@SourceCompanyId AS VARCHAR) + '' to company '' + CAST(@TargetCompanyId AS VARCHAR)
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        THROW;
    END CATCH
END
')

PRINT '✓ Created sp_CopyCompanySettings stored procedure'

PRINT ''

-- =====================================================
-- FINAL: Show Migration Summary
-- =====================================================
PRINT '========================================='
PRINT 'Migration Summary'
PRINT '========================================='

SELECT 
    (SELECT COUNT(*) FROM Companies) as 'Total Companies',
    (SELECT COUNT(*) FROM Users WHERE CompanyId IS NOT NULL) as 'Users with Company',
    (SELECT COUNT(*) FROM Users WHERE CompanyId IS NULL) as 'Users without Company',
    (SELECT COUNT(*) FROM CompanyMaterialTypes) as 'Material Types',
    (SELECT COUNT(*) FROM CompanyMbeIdMappings) as 'MBE ID Mappings',
    (SELECT COUNT(*) FROM CompanyMaterialPatterns) as 'Material Patterns'

PRINT ''
PRINT 'Top 5 Companies by User Count:'
PRINT '-------------------------------'
SELECT TOP 5
    c.Name as CompanyName,
    c.Code as CompanyCode,
    COUNT(u.Id) as UserCount,
    c.SubscriptionLevel,
    c.MaxUsers
FROM Companies c
LEFT JOIN Users u ON c.Id = u.CompanyId
GROUP BY c.Id, c.Name, c.Code, c.SubscriptionLevel, c.MaxUsers
ORDER BY COUNT(u.Id) DESC

PRINT ''
PRINT '========================================='
PRINT 'Migration Completed Successfully!'
PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '========================================='
PRINT ''
PRINT 'Next Steps:'
PRINT '-----------'
PRINT '1. Restart the application'
PRINT '2. Login as admin@steelestimation.com'
PRINT '3. Navigate to Admin > Material Settings'
PRINT '4. Configure material types for your company'
PRINT ''
PRINT 'To create a new company:'
PRINT 'INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)'
PRINT 'VALUES (''Your Company'', ''YOURCODE'', 1, ''Standard'', 10, GETUTCDATE(), GETUTCDATE())'
PRINT ''