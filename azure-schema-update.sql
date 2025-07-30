-- Azure SQL Database Schema Update Script
-- This script adds all missing tables from Docker schema to Azure SQL Database
-- Run this script on Azure SQL Database: sqldb-steel-estimation-prod

USE [sqldb-steel-estimation-prod];
GO

-- 1. Add missing AspNetIdentity tables
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoleClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoleClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [RoleId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [dbo].[AspNetRoleClaims]([RoleId]);
    ALTER TABLE [dbo].[AspNetRoleClaims] ADD CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] 
        FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [dbo].[AspNetUserClaims]([UserId]);
    ALTER TABLE [dbo].[AspNetUserClaims] ADD CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] 
        FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserLogins]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserLogins](
        [LoginProvider] [nvarchar](450) NOT NULL,
        [ProviderKey] [nvarchar](450) NOT NULL,
        [ProviderDisplayName] [nvarchar](max) NULL,
        [UserId] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY CLUSTERED (
            [LoginProvider] ASC,
            [ProviderKey] ASC
        )
    );
    CREATE INDEX [IX_AspNetUserLogins_UserId] ON [dbo].[AspNetUserLogins]([UserId]);
    ALTER TABLE [dbo].[AspNetUserLogins] ADD CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] 
        FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserTokens]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserTokens](
        [UserId] [nvarchar](450) NOT NULL,
        [LoginProvider] [nvarchar](450) NOT NULL,
        [Name] [nvarchar](450) NOT NULL,
        [Value] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY CLUSTERED (
            [UserId] ASC,
            [LoginProvider] ASC,
            [Name] ASC
        )
    );
    ALTER TABLE [dbo].[AspNetUserTokens] ADD CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] 
        FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;
END
GO

-- 2. Create Addresses table (for Customers)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Addresses](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [AddressLine1] [nvarchar](200) NOT NULL,
        [AddressLine2] [nvarchar](200) NULL,
        [Suburb] [nvarchar](100) NOT NULL,
        [State] [nvarchar](3) NOT NULL,
        [Postcode] [nvarchar](4) NOT NULL,
        [Country] [nvarchar](50) NOT NULL DEFAULT 'Australia',
        [Latitude] [decimal](10, 8) NULL,
        [Longitude] [decimal](11, 8) NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Addresses] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

-- 3. Create Customers table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customers](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [CompanyName] [nvarchar](200) NOT NULL,
        [ABN] [nvarchar](11) NOT NULL,
        [TradingName] [nvarchar](200) NULL,
        [BillingAddressId] [int] NULL,
        [ShippingAddressId] [int] NULL,
        [Phone] [nvarchar](20) NULL,
        [Email] [nvarchar](100) NULL,
        [Website] [nvarchar](200) NULL,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedBy] [nvarchar](450) NULL,
        [UpdatedBy] [nvarchar](450) NULL,
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Customers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]),
        CONSTRAINT [FK_Customers_BillingAddress] FOREIGN KEY([BillingAddressId]) REFERENCES [dbo].[Addresses]([Id]),
        CONSTRAINT [FK_Customers_ShippingAddress] FOREIGN KEY([ShippingAddressId]) REFERENCES [dbo].[Addresses]([Id]),
        CONSTRAINT [FK_Customers_CreatedBy] FOREIGN KEY([CreatedBy]) REFERENCES [dbo].[AspNetUsers]([Id]),
        CONSTRAINT [FK_Customers_UpdatedBy] FOREIGN KEY([UpdatedBy]) REFERENCES [dbo].[AspNetUsers]([Id])
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_ABN] ON [dbo].[Customers]([ABN]);
END
GO

-- 4. Create Contacts table (for Customers)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Contacts](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CustomerId] [int] NOT NULL,
        [FirstName] [nvarchar](100) NOT NULL,
        [LastName] [nvarchar](100) NOT NULL,
        [Title] [nvarchar](50) NULL,
        [Email] [nvarchar](100) NULL,
        [Phone] [nvarchar](20) NULL,
        [Mobile] [nvarchar](20) NULL,
        [IsPrimary] [bit] NOT NULL DEFAULT 0,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Contacts_Customers] FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_Contacts_CustomerId] ON [dbo].[Contacts]([CustomerId]);
END
GO

-- 5. Add CustomerId to Projects table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CustomerId] [int] NULL;
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers] 
        FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]);
END
GO

-- 6. Create ProcessingItems table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ProcessingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [ItemNo] [int] NOT NULL,
        [MbeId] [nvarchar](50) NOT NULL,
        [MaterialId] [nvarchar](100) NULL,
        [Quantity] [int] NOT NULL,
        [UnitWeight] [decimal](10, 3) NOT NULL,
        [TotalWeight] [decimal](10, 3) NOT NULL,
        [MaterialType] [nvarchar](50) NULL,
        [ProcessCategory] [nvarchar](50) NULL,
        [Length] [decimal](10, 3) NULL,
        [Width] [decimal](10, 3) NULL,
        [Thickness] [decimal](10, 3) NULL,
        [CuttingMinutes] [decimal](10, 2) NULL,
        [WeldingMinutes] [decimal](10, 2) NULL,
        [PaintingMinutes] [decimal](10, 2) NULL,
        [HandlingMinutes] [decimal](10, 2) NULL,
        [TotalMinutes] [decimal](10, 2) NULL,
        [TotalHours] [decimal](10, 2) NULL,
        [DeliveryBundleId] [int] NULL,
        [IsParentInBundle] [bit] NOT NULL DEFAULT 0,
        [PackBundleId] [int] NULL,
        [IsParentInPackBundle] [bit] NOT NULL DEFAULT 0,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_ProcessingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ProcessingItems_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_ProcessingItems_PackageId] ON [dbo].[ProcessingItems]([PackageId]);
    CREATE INDEX [IX_ProcessingItems_DeliveryBundleId] ON [dbo].[ProcessingItems]([DeliveryBundleId]);
    CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems]([PackBundleId]);
END
GO

-- 7. Create WeldingItems table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [ItemNo] [int] NOT NULL,
        [DrawingNumber] [nvarchar](100) NULL,
        [PartNumber] [nvarchar](100) NULL,
        [Description] [nvarchar](500) NULL,
        [MainMember] [nvarchar](100) NULL,
        [AttachedMember] [nvarchar](100) NULL,
        [Quantity] [int] NOT NULL,
        [WeldLength] [decimal](10, 2) NOT NULL,
        [WeldSize] [decimal](10, 2) NOT NULL,
        [WeldType] [nvarchar](50) NULL,
        [PreparationMinutes] [decimal](10, 2) NULL,
        [WeldingMinutes] [decimal](10, 2) NULL,
        [TotalMinutes] [decimal](10, 2) NULL,
        [TotalHours] [decimal](10, 2) NULL,
        [Complexity] [nvarchar](20) NULL,
        [Position] [nvarchar](50) NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_WeldingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItems_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_WeldingItems_PackageId] ON [dbo].[WeldingItems]([PackageId]);
END
GO

-- 8. Create WeldingItemConnections table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItemConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItemConnections](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [WeldingItemId] [int] NOT NULL,
        [ConnectionType] [nvarchar](50) NOT NULL,
        [Count] [int] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_WeldingItemConnections] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItemConnections_WeldingItems] FOREIGN KEY([WeldingItemId]) 
            REFERENCES [dbo].[WeldingItems]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_WeldingItemConnections_WeldingItemId] ON [dbo].[WeldingItemConnections]([WeldingItemId]);
END
GO

-- 9. Create DeliveryBundles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeliveryBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DeliveryBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL,
        [MaxWeight] [decimal](10, 3) NOT NULL DEFAULT 3000,
        [CurrentWeight] [decimal](10, 3) NOT NULL DEFAULT 0,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_DeliveryBundles_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_DeliveryBundles_PackageId] ON [dbo].[DeliveryBundles]([PackageId]);
END
GO

-- 10. Create PackBundles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PackBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL,
        [HandlingOperation] [nvarchar](50) NOT NULL,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [TotalWeight] [decimal](10, 3) NOT NULL DEFAULT 0,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_PackBundles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_PackBundles_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles]([PackageId]);
END
GO

-- 11. Create EfficiencyRates table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [EfficiencyPercentage] [decimal](5, 2) NOT NULL,
        [IsDefault] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EfficiencyRates_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates]([CompanyId]);
END
GO

-- 12. Create EstimationTimeLogs table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EstimationTimeLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EstimationTimeLogs](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [SessionStartTime] [datetime2](7) NOT NULL,
        [SessionEndTime] [datetime2](7) NULL,
        [DurationMinutes] [int] NOT NULL DEFAULT 0,
        [IsPaused] [bit] NOT NULL DEFAULT 0,
        [LastActivityTime] [datetime2](7) NOT NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EstimationTimeLogs_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_EstimationTimeLogs_Users] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id])
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
END
GO

-- 13. Create Postcodes table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Postcodes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Postcodes](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Postcode] [nvarchar](4) NOT NULL,
        [Suburb] [nvarchar](100) NOT NULL,
        [State] [nvarchar](3) NOT NULL,
        [Latitude] [decimal](10, 8) NULL,
        [Longitude] [decimal](11, 8) NULL,
        CONSTRAINT [PK_Postcodes] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Postcodes_Postcode] ON [dbo].[Postcodes]([Postcode]);
    CREATE INDEX [IX_Postcodes_Suburb] ON [dbo].[Postcodes]([Suburb]);
END
GO

-- 14. Add new columns to Packages table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'ProcessingEfficiency')
BEGIN
    ALTER TABLE [dbo].[Packages] ADD [ProcessingEfficiency] [decimal](5, 2) NULL DEFAULT 100;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'EfficiencyRateId')
BEGIN
    ALTER TABLE [dbo].[Packages] ADD [EfficiencyRateId] [int] NULL;
    ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_EfficiencyRates] 
        FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates]([Id]);
END
GO

-- 15. Add foreign key constraints for ProcessingItems after tables are created
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeliveryBundles]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_DeliveryBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles] 
        FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles]([Id]);
END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackBundles]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles] 
        FOREIGN KEY([PackBundleId]) REFERENCES [dbo].[PackBundles]([Id]) ON DELETE NO ACTION;
END
GO

-- 16. Insert default efficiency rates for existing companies
INSERT INTO [dbo].[EfficiencyRates] ([CompanyId], [Name], [EfficiencyPercentage], [IsDefault], [IsActive])
SELECT c.Id, '100% Efficiency', 100.00, 1, 1
FROM [dbo].[Companies] c
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] er WHERE er.CompanyId = c.Id AND er.Name = '100% Efficiency');

INSERT INTO [dbo].[EfficiencyRates] ([CompanyId], [Name], [EfficiencyPercentage], [IsDefault], [IsActive])
SELECT c.Id, '85% Efficiency', 85.00, 0, 1
FROM [dbo].[Companies] c
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] er WHERE er.CompanyId = c.Id AND er.Name = '85% Efficiency');

INSERT INTO [dbo].[EfficiencyRates] ([CompanyId], [Name], [EfficiencyPercentage], [IsDefault], [IsActive])
SELECT c.Id, '75% Efficiency', 75.00, 0, 1
FROM [dbo].[Companies] c
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] er WHERE er.CompanyId = c.Id AND er.Name = '75% Efficiency');
GO

-- 17. Add missing columns to AspNetUsers if they don't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'PhoneNumber')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [PhoneNumber] [nvarchar](max) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'PhoneNumberConfirmed')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [PhoneNumberConfirmed] [bit] NOT NULL DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'TwoFactorEnabled')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [TwoFactorEnabled] [bit] NOT NULL DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'LockoutEnd')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [LockoutEnd] [datetimeoffset](7) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'LockoutEnabled')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [LockoutEnabled] [bit] NOT NULL DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'AccessFailedCount')
BEGIN
    ALTER TABLE [dbo].[AspNetUsers] ADD [AccessFailedCount] [int] NOT NULL DEFAULT 0;
END
GO

PRINT 'Azure SQL Database schema update completed successfully!'
PRINT 'All missing tables and columns have been added.'