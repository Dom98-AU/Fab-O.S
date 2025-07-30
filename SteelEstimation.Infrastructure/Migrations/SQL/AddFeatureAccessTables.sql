-- Add Feature Access Tables for Module-based Access Control
-- This migration adds support for feature-based access control with external admin portal

BEGIN TRANSACTION;

-- Create FeatureGroups table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FeatureGroups]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FeatureGroups] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Code] nvarchar(50) NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Description] nvarchar(500) NULL,
        [DisplayOrder] int NOT NULL DEFAULT 0,
        [IsActive] bit NOT NULL DEFAULT 1,
        [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_FeatureGroups] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create indexes
    CREATE UNIQUE NONCLUSTERED INDEX [IX_FeatureGroups_Code] ON [dbo].[FeatureGroups] ([Code]);
    CREATE NONCLUSTERED INDEX [IX_FeatureGroups_DisplayOrder] ON [dbo].[FeatureGroups] ([DisplayOrder]);
    CREATE NONCLUSTERED INDEX [IX_FeatureGroups_IsActive] ON [dbo].[FeatureGroups] ([IsActive]);
    
    PRINT 'Created FeatureGroups table';
END
ELSE
BEGIN
    PRINT 'FeatureGroups table already exists';
END

-- Create FeatureCache table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FeatureCache]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[FeatureCache] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [CompanyId] int NOT NULL,
        [FeatureCode] nvarchar(100) NOT NULL,
        [FeatureName] nvarchar(200) NOT NULL DEFAULT '',
        [GroupCode] nvarchar(50) NOT NULL DEFAULT '',
        [IsEnabled] bit NOT NULL DEFAULT 0,
        [EnabledUntil] datetime2 NULL,
        [LastSyncedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        [ExpiresAt] datetime2 NULL,
        CONSTRAINT [PK_FeatureCache] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FeatureCache_Companies_CompanyId] FOREIGN KEY ([CompanyId]) 
            REFERENCES [dbo].[Companies] ([Id]) ON DELETE CASCADE
    );

    -- Create indexes
    CREATE UNIQUE NONCLUSTERED INDEX [IX_FeatureCache_CompanyId_FeatureCode] 
        ON [dbo].[FeatureCache] ([CompanyId], [FeatureCode]);
    CREATE NONCLUSTERED INDEX [IX_FeatureCache_CompanyId] ON [dbo].[FeatureCache] ([CompanyId]);
    CREATE NONCLUSTERED INDEX [IX_FeatureCache_ExpiresAt] ON [dbo].[FeatureCache] ([ExpiresAt]);
    
    PRINT 'Created FeatureCache table';
END
ELSE
BEGIN
    PRINT 'FeatureCache table already exists';
END

-- Create ApiKeys table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ApiKeys]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ApiKeys] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        [KeyHash] nvarchar(500) NOT NULL,
        [KeyPrefix] nvarchar(100) NOT NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        [ExpiresAt] datetime2 NULL,
        [LastUsedAt] datetime2 NULL,
        [RateLimitPerHour] int NULL,
        [Scopes] nvarchar(1000) NULL,
        CONSTRAINT [PK_ApiKeys] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_ApiKeys_KeyPrefix] ON [dbo].[ApiKeys] ([KeyPrefix]);
    CREATE NONCLUSTERED INDEX [IX_ApiKeys_IsActive] ON [dbo].[ApiKeys] ([IsActive]);
    CREATE NONCLUSTERED INDEX [IX_ApiKeys_ExpiresAt] ON [dbo].[ApiKeys] ([ExpiresAt]);
    
    PRINT 'Created ApiKeys table';
END
ELSE
BEGIN
    PRINT 'ApiKeys table already exists';
END

-- Seed default feature groups (examples - can be customized via admin portal)
IF NOT EXISTS (SELECT 1 FROM [dbo].[FeatureGroups])
BEGIN
    INSERT INTO [dbo].[FeatureGroups] ([Code], [Name], [Description], [DisplayOrder])
    VALUES 
        ('CORE', 'Core Features', 'Basic functionality available to all users', 1),
        ('ESTIMATION', 'Estimation Features', 'Advanced estimation capabilities', 2),
        ('ANALYTICS', 'Analytics & Reporting', 'Advanced analytics and reporting features', 3),
        ('INTEGRATION', 'Integrations', 'Third-party integrations and data import/export', 4),
        ('WORKFLOW', 'Workflow Management', 'Advanced workflow and automation features', 5);
    
    PRINT 'Seeded default feature groups';
END

COMMIT TRANSACTION;

PRINT 'Feature Access tables migration completed successfully';