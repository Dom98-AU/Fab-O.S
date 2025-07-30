-- =====================================================
-- Fix Migration: Add CompanyId to Users Table
-- =====================================================
-- This script safely adds CompanyId to the existing Users table

PRINT '========================================='
PRINT 'Adding CompanyId to Users Table'
PRINT '========================================='
PRINT ''

-- STEP 1: Create Companies table if it doesn't exist
PRINT 'STEP 1: Creating Companies table...'

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
    PRINT 'Created Companies table'
END
ELSE
BEGIN
    PRINT 'Companies table already exists'
END
GO

-- STEP 2: Create default company
PRINT ''
PRINT 'STEP 2: Creating default company...'

DECLARE @DefaultCompanyId INT

IF NOT EXISTS (SELECT 1 FROM Companies WHERE Code = 'DEFAULT')
BEGIN
    -- Use the existing CompanyName from the first user if available
    DECLARE @CompanyNameFromUser NVARCHAR(200)
    SELECT TOP 1 @CompanyNameFromUser = CompanyName 
    FROM Users 
    WHERE CompanyName IS NOT NULL AND CompanyName != ''
    
    SET @CompanyNameFromUser = ISNULL(@CompanyNameFromUser, 'Default Company')
    
    INSERT INTO Companies (Name, Code, IsActive, SubscriptionLevel, MaxUsers, CreatedDate, LastModified)
    VALUES (@CompanyNameFromUser, 'DEFAULT', 1, 'Standard', 10, GETUTCDATE(), GETUTCDATE())
    
    SET @DefaultCompanyId = SCOPE_IDENTITY()
    PRINT 'Created default company: ' + @CompanyNameFromUser
END
ELSE
BEGIN
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
    PRINT 'Using existing default company'
END

PRINT 'Default Company ID: ' + CAST(@DefaultCompanyId AS VARCHAR)
GO

-- STEP 3: Add CompanyId column
PRINT ''
PRINT 'STEP 3: Adding CompanyId column to Users table...'

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    -- Get default company ID again (variable scope)
    DECLARE @DefaultCompanyId INT
    SELECT @DefaultCompanyId = Id FROM Companies WHERE Code = 'DEFAULT'
    
    -- Add the column
    ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NULL
    PRINT 'Added CompanyId column'
    
    -- Set default value for all existing users
    UPDATE [dbo].[Users] SET CompanyId = @DefaultCompanyId
    PRINT 'Updated all users with default company ID: ' + CAST(@DefaultCompanyId AS VARCHAR)
    
    -- Add foreign key constraint
    ALTER TABLE [dbo].[Users] WITH CHECK ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    PRINT 'Added foreign key constraint'
    
    -- Add index
    CREATE NONCLUSTERED INDEX [IX_Users_CompanyId] ON [dbo].[Users]([CompanyId] ASC)
    PRINT 'Added index on CompanyId'
END
ELSE
BEGIN
    PRINT 'CompanyId column already exists'
END
GO

-- STEP 4: Create remaining company tables
PRINT ''
PRINT 'STEP 4: Creating company settings tables...'

-- CompanyMaterialTypes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialTypes')
BEGIN
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
    PRINT 'Created CompanyMaterialTypes table'
END

-- CompanyMbeIdMappings
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMbeIdMappings')
BEGIN
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
    PRINT 'Created CompanyMbeIdMappings table'
END

-- CompanyMaterialPatterns
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialPatterns')
BEGIN
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
    PRINT 'Created CompanyMaterialPatterns table'
END
GO

-- STEP 5: Seed default data
PRINT ''
PRINT 'STEP 5: Seeding default material data...'

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
    PRINT 'Added default material types'
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
    PRINT 'Added default MBE ID mappings'
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
        (@CompanyId, 'BOLT', 'Fastener', 'Contains', 40, 1, GETUTCDATE(), GETUTCDATE())
    PRINT 'Added default material patterns'
END
GO

-- STEP 6: Verify
PRINT ''
PRINT 'STEP 6: Verification...'
PRINT '======================='

-- Check CompanyId was added
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
    PRINT '✓ CompanyId column exists in Users table'
ELSE
    PRINT '✗ ERROR: CompanyId column was not added!'

-- Show summary
PRINT ''
PRINT 'Summary:'
SELECT 
    'Companies' as [Table], COUNT(*) as [Count] FROM Companies
UNION ALL SELECT 
    'Users with Company', COUNT(*) FROM Users WHERE CompanyId IS NOT NULL
UNION ALL SELECT 
    'Material Types', COUNT(*) FROM CompanyMaterialTypes
UNION ALL SELECT 
    'MBE Mappings', COUNT(*) FROM CompanyMbeIdMappings
UNION ALL SELECT 
    'Material Patterns', COUNT(*) FROM CompanyMaterialPatterns

PRINT ''
PRINT '========================================='
PRINT 'Migration Complete!'
PRINT '========================================='