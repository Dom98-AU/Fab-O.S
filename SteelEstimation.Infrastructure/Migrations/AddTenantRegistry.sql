-- Migration: Add Tenant Registry for Multi-Tenant Support
-- This creates the master database tables for managing tenants
-- Note: This is only needed when EnableDatabasePerTenant is true

-- Check if we're setting up multi-tenant mode
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TenantRegistries')
BEGIN
    PRINT 'Creating multi-tenant registry tables...'
    
    -- Create TenantRegistries table
    CREATE TABLE [dbo].[TenantRegistries](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [TenantId] [nvarchar](50) NOT NULL,
        [DatabaseName] [nvarchar](128) NOT NULL,
        [CompanyName] [nvarchar](200) NOT NULL,
        [CompanyCode] [nvarchar](50) NOT NULL,
        [AdminEmail] [nvarchar](256) NOT NULL,
        [CreatedAt] [datetime2](7) NOT NULL,
        [LastModified] [datetime2](7) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [SubscriptionTier] [nvarchar](50) NOT NULL DEFAULT 'Standard',
        [MaxUsers] [int] NOT NULL DEFAULT 10,
        [SubscriptionExpiryDate] [datetime2](7) NULL,
        [ConnectionStringKeyVaultName] [nvarchar](200) NULL,
        [DatabaseServer] [nvarchar](200) NULL,
        [ElasticPoolName] [nvarchar](128) NULL,
        [Settings] [nvarchar](max) NULL, -- JSON column for additional settings
        CONSTRAINT [PK_TenantRegistries] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_TenantRegistries_TenantId] UNIQUE NONCLUSTERED ([TenantId] ASC),
        CONSTRAINT [UQ_TenantRegistries_CompanyCode] UNIQUE NONCLUSTERED ([CompanyCode] ASC)
    )
    
    -- Create TenantUsageLogs table
    CREATE TABLE [dbo].[TenantUsageLogs](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [TenantRegistryId] [int] NOT NULL,
        [TenantId] [nvarchar](50) NOT NULL,
        [LogDate] [datetime2](7) NOT NULL,
        [ActiveUsers] [int] NOT NULL DEFAULT 0,
        [StorageUsedBytes] [bigint] NOT NULL DEFAULT 0,
        [ProjectCount] [int] NOT NULL DEFAULT 0,
        [EstimationCount] [int] NOT NULL DEFAULT 0,
        [DatabaseSizeGB] [decimal](10, 3) NOT NULL DEFAULT 0,
        [ApiCallCount] [int] NOT NULL DEFAULT 0,
        [CreatedAt] [datetime2](7) NOT NULL,
        CONSTRAINT [PK_TenantUsageLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_TenantUsageLogs_TenantRegistries] FOREIGN KEY([TenantRegistryId]) 
            REFERENCES [dbo].[TenantRegistries] ([Id]) ON DELETE CASCADE
    )
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_TenantRegistries_IsActive] ON [dbo].[TenantRegistries]([IsActive] ASC)
    CREATE NONCLUSTERED INDEX [IX_TenantRegistries_CreatedAt] ON [dbo].[TenantRegistries]([CreatedAt] ASC)
    CREATE NONCLUSTERED INDEX [IX_TenantUsageLogs_TenantId] ON [dbo].[TenantUsageLogs]([TenantId] ASC)
    CREATE NONCLUSTERED INDEX [IX_TenantUsageLogs_LogDate] ON [dbo].[TenantUsageLogs]([LogDate] ASC)
    CREATE NONCLUSTERED INDEX [IX_TenantUsageLogs_TenantId_LogDate] ON [dbo].[TenantUsageLogs]([TenantId] ASC, [LogDate] ASC)
    
    PRINT 'Multi-tenant registry tables created successfully'
END
ELSE
BEGIN
    PRINT 'Multi-tenant registry tables already exist'
END

-- Add SystemAdministrator role if it doesn't exist
IF NOT EXISTS (SELECT * FROM Roles WHERE RoleName = 'SystemAdministrator')
BEGIN
    INSERT INTO Roles (RoleName, Description, CanCreateProjects, CanEditProjects, CanDeleteProjects, 
                      CanViewAllProjects, CanManageUsers, CanExportData, CanImportData)
    VALUES ('SystemAdministrator', 'System-wide administrator with tenant management capabilities', 
            1, 1, 1, 1, 1, 1, 1)
    
    PRINT 'Created SystemAdministrator role'
END

PRINT ''
PRINT 'Multi-tenant registry migration complete'
PRINT ''
PRINT 'Note: This migration only creates the registry tables.'
PRINT 'Tenant provisioning requires:'
PRINT '  1. Azure SQL Elastic Pool configuration'
PRINT '  2. Azure Key Vault for connection string storage'
PRINT '  3. EnableDatabasePerTenant = true in configuration'