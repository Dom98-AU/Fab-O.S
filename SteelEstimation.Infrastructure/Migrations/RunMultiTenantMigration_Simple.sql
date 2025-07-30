-- Master Migration Script for Multi-Tenant Support (Simple Version)
-- Run this script to apply all multi-tenant changes
-- This version includes all migrations inline

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

    -- Add CompanyId to Users table if not exists
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
    BEGIN
        ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL
        
        -- Add foreign key after adding the column
        ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
            FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    END

    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_Companies_IsActive] ON [dbo].[Companies]([IsActive] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialTypes_CompanyId] ON [dbo].[CompanyMaterialTypes]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMbeIdMappings_CompanyId] ON [dbo].[CompanyMbeIdMappings]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialPatterns_CompanyId] ON [dbo].[CompanyMaterialPatterns]([CompanyId] ASC)
    CREATE NONCLUSTERED INDEX [IX_CompanyMaterialPatterns_CompanyId_PatternType] ON [dbo].[CompanyMaterialPatterns]([CompanyId] ASC, [PatternType] ASC)
    CREATE NONCLUSTERED INDEX [IX_Users_CompanyId] ON [dbo].[Users]([CompanyId] ASC)

    PRINT 'Multi-tenant tables created successfully'
END

PRINT ''

-- Step 2: Create default company and update users
PRINT 'Step 2: Creating default company and updating users...'
PRINT '------------------------------------------------------'

-- Ensure default company exists
IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default company'
END

DECLARE @DefaultCompanyId INT
SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

-- Update all users without a company
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
    
    PRINT 'Created default material types'
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
    
    PRINT 'Created default MBE ID mappings'
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
        
        -- Plate patterns
        (@DefaultCompanyId, 'PLATE', 'Plate', 'Contains', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'FL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'PL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Purlin patterns
        (@DefaultCompanyId, 'PURLIN', 'Purlin', 'Contains', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'C20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'Z20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        
        -- Fastener patterns
        (@DefaultCompanyId, 'BOLT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'NUT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@DefaultCompanyId, 'WASHER', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE())
    
    PRINT 'Created default material patterns'
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

PRINT ''
PRINT 'Next Steps:'
PRINT '-----------'
PRINT '1. Test the application with the new multi-tenant features'
PRINT '2. Navigate to /admin/material-settings to manage material configurations'
PRINT '3. Each company can now have their own material type settings'