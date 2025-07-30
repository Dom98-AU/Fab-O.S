-- =====================================================
-- BATCHED Multi-Tenant & Organization Migration Script
-- =====================================================
-- This version uses GO statements to separate batches
-- This helps avoid SSMS validation errors

PRINT '========================================='
PRINT 'Starting Batched Multi-Tenant Migration'
PRINT 'Database: ' + DB_NAME()
PRINT '========================================='
GO

-- Check Prerequisites
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    PRINT 'ERROR: Users table does not exist!'
    RAISERROR('Users table not found. Please run EF migrations first.', 16, 1)
    RETURN
END
GO

-- BATCH 1: Create Company Tables
PRINT 'Creating Company Tables...'

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
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE NONCLUSTERED ([Code] ASC)
    )
    
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
        CONSTRAINT [FK_CompanyMaterialTypes_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    )
    
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
        CONSTRAINT [FK_CompanyMbeIdMappings_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    )
    
    CREATE TABLE [dbo].[CompanyMaterialPatterns](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Pattern] [nvarchar](200) NOT NULL,
        [MaterialType] [nvarchar](100) NOT NULL,
        [PatternType] [nvarchar](50) NOT NULL,
        [Priority] [int] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_CompanyMaterialPatterns] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_CompanyMaterialPatterns_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    )
    
    PRINT 'Created company tables successfully'
END
GO

-- BATCH 2: Add CompanyId to Users
PRINT 'Adding CompanyId to Users table...'

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL
    PRINT 'Added CompanyId column'
END
GO

-- BATCH 3: Create Default Company
PRINT 'Creating default company...'

DECLARE @DefaultCompanyId INT

IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES ('Default Company', 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    SET @DefaultCompanyId = SCOPE_IDENTITY()
    PRINT 'Created default company'
END
ELSE
BEGIN
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
END

-- Update all users with default company
UPDATE [dbo].[Users] 
SET CompanyId = @DefaultCompanyId 
WHERE CompanyId IS NULL

PRINT 'Updated users with default company'
GO

-- BATCH 4: Add Foreign Key
PRINT 'Adding foreign key constraint...'

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
BEGIN
    ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    PRINT 'Added foreign key'
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_CompanyId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_Users_CompanyId] ON [dbo].[Users]([CompanyId] ASC)
    PRINT 'Created index'
END
GO

-- BATCH 5: Seed Material Data
PRINT 'Seeding material data...'

DECLARE @CompanyId INT
SELECT @CompanyId = Id FROM Companies WHERE Code = 'DEFAULT'

-- Material Types
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialTypes WHERE CompanyId = @CompanyId)
BEGIN
    INSERT INTO CompanyMaterialTypes (CompanyId, TypeName, Description, HourlyRate, DefaultWeightPerFoot, DefaultColor, DisplayOrder, IsActive, CreatedDate, LastModified)
    VALUES 
        (@CompanyId, 'Beam', 'Structural beams and columns', 65.00, NULL, '#007bff', 1, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'Plate', 'Steel plates and flat materials', 65.00, NULL, '#17a2b8', 2, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'Purlin', 'Roof and wall purlins', 65.00, NULL, '#28a745', 3, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'Fastener', 'Bolts, nuts, and fasteners', 65.00, NULL, '#ffc107', 4, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'Misc', 'Miscellaneous steel items', 65.00, NULL, '#6c757d', 5, 1, GETUTCDATE(), GETUTCDATE())
END

-- MBE ID Mappings
IF NOT EXISTS (SELECT 1 FROM CompanyMbeIdMappings WHERE CompanyId = @CompanyId)
BEGIN
    INSERT INTO CompanyMbeIdMappings (CompanyId, MbeId, MaterialType, WeightPerFoot, Notes, CreatedDate, LastModified)
    VALUES 
        (@CompanyId, 'B', 'Beam', NULL, 'Beam materials', GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'C', 'Beam', NULL, 'Column materials', GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'PL', 'Plate', NULL, 'Plate materials', GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'P', 'Purlin', NULL, 'Purlin materials', GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'F', 'Fastener', NULL, 'Fastener materials', GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'M', 'Misc', NULL, 'Miscellaneous materials', GETUTCDATE(), GETUTCDATE())
END

-- Material Patterns  
IF NOT EXISTS (SELECT 1 FROM CompanyMaterialPatterns WHERE CompanyId = @CompanyId)
BEGIN
    INSERT INTO CompanyMaterialPatterns (CompanyId, Pattern, MaterialType, PatternType, Priority, IsActive, CreatedDate, LastModified)
    VALUES 
        (@CompanyId, 'BEAM', 'Beam', 'Contains', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'UB', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'UC', 'Beam', 'StartsWith', 10, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'PLATE', 'Plate', 'Contains', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'FL', 'Plate', 'StartsWith', 20, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'PURLIN', 'Purlin', 'Contains', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'C15', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'C20', 'Purlin', 'StartsWith', 30, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'BOLT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE()),
        (@CompanyId, 'NUT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE())
END

PRINT 'Seeded material data'
GO

-- BATCH 6: Summary
PRINT ''
PRINT '========================================='
PRINT 'Migration Summary'
PRINT '========================================='

SELECT 
    'Companies' as TableName, COUNT(*) as Count FROM Companies
UNION ALL SELECT 
    'Users with Company', COUNT(*) FROM Users WHERE CompanyId IS NOT NULL
UNION ALL SELECT 
    'Material Types', COUNT(*) FROM CompanyMaterialTypes
UNION ALL SELECT 
    'MBE Mappings', COUNT(*) FROM CompanyMbeIdMappings
UNION ALL SELECT 
    'Material Patterns', COUNT(*) FROM CompanyMaterialPatterns

PRINT ''
PRINT 'Migration completed successfully!'
PRINT 'Next steps: Login and go to Admin > Material Settings'
GO