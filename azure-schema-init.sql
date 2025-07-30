-- Steel Estimation Database Complete Initialization Script for Docker
-- This script creates the complete database schema with all tables and initial data

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SteelEstimationDB')
BEGIN
    -- Database already exists in Azure
END
GO

USE [sqldb-steel-estimation-sandbox];
GO

-- Enable SNAPSHOT isolation for better concurrency
ALTER DATABASE [SteelEstimationDB] SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE [SteelEstimationDB] SET READ_COMMITTED_SNAPSHOT ON;
GO

-- Create Companies table (Multi-tenant support)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Companies]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Code] [nvarchar](10) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE ([Code])
    );
END
GO

-- Create AspNetRoles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoles](
        [Id] [nvarchar](450) NOT NULL,
        [Name] [nvarchar](256) NULL,
        [NormalizedName] [nvarchar](256) NULL,
        [ConcurrencyStamp] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE UNIQUE INDEX [RoleNameIndex] ON [dbo].[AspNetRoles]([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;
END
GO

-- Create AspNetUsers table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUsers](
        [Id] [nvarchar](450) NOT NULL,
        [FullName] [nvarchar](100) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [UserName] [nvarchar](256) NULL,
        [NormalizedUserName] [nvarchar](256) NULL,
        [Email] [nvarchar](256) NULL,
        [NormalizedEmail] [nvarchar](256) NULL,
        [EmailConfirmed] [bit] NOT NULL,
        [PasswordHash] [nvarchar](max) NULL,
        [SecurityStamp] [nvarchar](max) NULL,
        [ConcurrencyStamp] [nvarchar](max) NULL,
        [PhoneNumber] [nvarchar](max) NULL,
        [PhoneNumberConfirmed] [bit] NOT NULL,
        [TwoFactorEnabled] [bit] NOT NULL,
        [LockoutEnd] [datetimeoffset](7) NULL,
        [LockoutEnabled] [bit] NOT NULL,
        [AccessFailedCount] [int] NOT NULL,
        CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetUsers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id])
    );
    CREATE INDEX [EmailIndex] ON [dbo].[AspNetUsers]([NormalizedEmail]);
    CREATE UNIQUE INDEX [UserNameIndex] ON [dbo].[AspNetUsers]([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
    CREATE INDEX [IX_AspNetUsers_CompanyId] ON [dbo].[AspNetUsers]([CompanyId]);
END
GO

-- Create AspNetUserRoles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserRoles](
        [UserId] [nvarchar](450) NOT NULL,
        [RoleId] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
        CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [dbo].[AspNetUserRoles]([RoleId]);
END
GO

-- Create AspNetUserClaims table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserClaims_UserId] ON [dbo].[AspNetUserClaims]([UserId]);
END
GO

-- Create AspNetUserLogins table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserLogins]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserLogins](
        [LoginProvider] [nvarchar](450) NOT NULL,
        [ProviderKey] [nvarchar](450) NOT NULL,
        [ProviderDisplayName] [nvarchar](max) NULL,
        [UserId] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_AspNetUserLogins] PRIMARY KEY CLUSTERED ([LoginProvider] ASC, [ProviderKey] ASC),
        CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetUserLogins_UserId] ON [dbo].[AspNetUserLogins]([UserId]);
END
GO

-- Create AspNetUserTokens table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserTokens]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserTokens](
        [UserId] [nvarchar](450) NOT NULL,
        [LoginProvider] [nvarchar](450) NOT NULL,
        [Name] [nvarchar](450) NOT NULL,
        [Value] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetUserTokens] PRIMARY KEY CLUSTERED ([UserId] ASC, [LoginProvider] ASC, [Name] ASC),
        CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END
GO

-- Create AspNetRoleClaims table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoleClaims]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoleClaims](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [RoleId] [nvarchar](450) NOT NULL,
        [ClaimType] [nvarchar](max) NULL,
        [ClaimValue] [nvarchar](max) NULL,
        CONSTRAINT [PK_AspNetRoleClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AspNetRoleClaims_AspNetRoles_RoleId] FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_AspNetRoleClaims_RoleId] ON [dbo].[AspNetRoleClaims]([RoleId]);
END
GO

-- Create Projects table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Projects](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [ProjectNumber] [nvarchar](50) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [ClientName] [nvarchar](200) NULL,
        [Location] [nvarchar](200) NULL,
        [StartDate] [datetime2](7) NULL,
        [EndDate] [datetime2](7) NULL,
        [EstimatedHours] [decimal](10,2) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Active',
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Projects_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_Projects_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Projects_CompanyId] ON [dbo].[Projects]([CompanyId]);
    CREATE INDEX [IX_Projects_ProjectNumber] ON [dbo].[Projects]([ProjectNumber]);
END
GO

-- Create Estimations table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Estimations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Estimations](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [EstimationNumber] [nvarchar](50) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [PreparedBy] [nvarchar](100) NULL,
        [PreparedDate] [datetime2](7) NULL,
        [ReviewedBy] [nvarchar](100) NULL,
        [ReviewedDate] [datetime2](7) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Draft',
        [Version] [int] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Estimations] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Estimations_Projects] FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects] ([Id]),
        CONSTRAINT [FK_Estimations_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Estimations_ProjectId] ON [dbo].[Estimations]([ProjectId]);
    CREATE INDEX [IX_Estimations_EstimationNumber] ON [dbo].[Estimations]([EstimationNumber]);
END
GO

-- Create EstimationTimeLogs table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EstimationTimeLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EstimationTimeLogs](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [UserId] [nvarchar](450) NOT NULL,
        [StartTime] [datetime2](7) NOT NULL,
        [EndTime] [datetime2](7) NULL,
        [DurationMinutes] [int] NULL,
        [IsPaused] [bit] NOT NULL DEFAULT 0,
        [LastActivityTime] [datetime2](7) NOT NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EstimationTimeLogs_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations] ([Id]),
        CONSTRAINT [FK_EstimationTimeLogs_AspNetUsers] FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
END
GO

-- Create EfficiencyRates table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [Rate] [decimal](5,2) NOT NULL,
        [IsDefault] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_EfficiencyRates_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_EfficiencyRates_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates]([CompanyId]);
END
GO

-- Create Packages table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Packages](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [ProcessingEfficiency] [decimal](5,2) NOT NULL DEFAULT 75.00,
        [EfficiencyRateId] [int] NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Packages_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations] ([Id]),
        CONSTRAINT [FK_Packages_EfficiencyRates] FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates] ([Id])
    );
    CREATE INDEX [IX_Packages_EstimationId] ON [dbo].[Packages]([EstimationId]);
END
GO

-- Create ProcessingItems table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ProcessingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [MarkNumber] [nvarchar](50) NULL,
        [Quantity] [int] NOT NULL DEFAULT 1,
        [Description] [nvarchar](500) NULL,
        [Material] [nvarchar](100) NULL,
        [Width] [decimal](10,3) NULL,
        [Length] [decimal](10,3) NULL,
        [UnitWeight] [decimal](10,3) NULL,
        [TotalWeight] [decimal](10,3) NULL,
        [LaborRate] [decimal](10,2) NULL,
        [IsActiveInBundle] [bit] NOT NULL DEFAULT 1,
        [DeliveryBundleId] [int] NULL,
        [IsParentInBundle] [bit] NOT NULL DEFAULT 0,
        [PackBundleId] [int] NULL,
        [IsParentInPackBundle] [bit] NOT NULL DEFAULT 0,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_ProcessingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ProcessingItems_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages] ([Id])
    );
    CREATE INDEX [IX_ProcessingItems_PackageId] ON [dbo].[ProcessingItems]([PackageId]);
    CREATE INDEX [IX_ProcessingItems_DeliveryBundleId] ON [dbo].[ProcessingItems]([DeliveryBundleId]);
    CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems]([PackBundleId]);
END
GO

-- Create DeliveryBundles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeliveryBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DeliveryBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [BundleNumber] [nvarchar](20) NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL DEFAULT '',
        [TotalWeight] [decimal](10,3) NOT NULL DEFAULT 0,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_DeliveryBundles_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_DeliveryBundles_PackageId] ON [dbo].[DeliveryBundles]([PackageId]);
    CREATE INDEX [IX_DeliveryBundles_BundleNumber] ON [dbo].[DeliveryBundles]([BundleNumber]);
END
GO

-- Create PackBundles table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PackBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [BundleNumber] [nvarchar](20) NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL DEFAULT '',
        [TotalWeight] [decimal](10,3) NOT NULL DEFAULT 0,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_PackBundles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_PackBundles_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles]([PackageId]);
    CREATE INDEX [IX_PackBundles_BundleNumber] ON [dbo].[PackBundles]([BundleNumber]);
END
GO

-- Add foreign key constraints for bundles
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_DeliveryBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles] 
        FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles] ([Id]) ON DELETE SET NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles] 
        FOREIGN KEY([PackBundleId]) REFERENCES [dbo].[PackBundles] ([Id]) ON DELETE SET NULL;
END
GO

-- Create WeldingItems table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItems](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [WeldId] [nvarchar](50) NULL,
        [Description] [nvarchar](500) NULL,
        [WeldType] [nvarchar](100) NULL,
        [WeldProcess] [nvarchar](100) NULL,
        [WeldLength] [decimal](10,3) NULL,
        [WeldSize] [nvarchar](50) NULL,
        [Weight] [decimal](10,3) NULL,
        [WeldTest] [bit] NOT NULL DEFAULT 0,
        [WeldTestType] [nvarchar](100) NULL,
        [TestPercentage] [decimal](5,2) NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_WeldingItems] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItems_Packages] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages] ([Id])
    );
    CREATE INDEX [IX_WeldingItems_PackageId] ON [dbo].[WeldingItems]([PackageId]);
END
GO

-- Create WeldingItemConnections table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItemConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItemConnections](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [WeldingItemId] [int] NOT NULL,
        [ConnectionType] [nvarchar](100) NOT NULL,
        [IsPrimary] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_WeldingItemConnections] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_WeldingItemConnections_WeldingItems] FOREIGN KEY([WeldingItemId]) REFERENCES [dbo].[WeldingItems] ([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_WeldingItemConnections_WeldingItemId] ON [dbo].[WeldingItemConnections]([WeldingItemId]);
END
GO

-- Create Customers table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customers](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Code] [nvarchar](50) NULL,
        [ContactPerson] [nvarchar](100) NULL,
        [Email] [nvarchar](200) NULL,
        [Phone] [nvarchar](50) NULL,
        [Address] [nvarchar](500) NULL,
        [City] [nvarchar](100) NULL,
        [State] [nvarchar](50) NULL,
        [PostCode] [nvarchar](20) NULL,
        [Country] [nvarchar](100) NULL,
        [Notes] [nvarchar](max) NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedById] [nvarchar](450) NOT NULL,
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Customers_Companies] FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies] ([Id]),
        CONSTRAINT [FK_Customers_AspNetUsers] FOREIGN KEY([CreatedById]) REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_Code] ON [dbo].[Customers]([Code]);
END
GO

-- Create Postcodes table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Postcodes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Postcodes](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Postcode] [nvarchar](10) NOT NULL,
        [Suburb] [nvarchar](100) NOT NULL,
        [State] [nvarchar](50) NOT NULL,
        [Country] [nvarchar](100) NOT NULL DEFAULT 'Australia',
        [Latitude] [decimal](10,6) NULL,
        [Longitude] [decimal](10,6) NULL,
        CONSTRAINT [PK_Postcodes] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Postcodes_Postcode] ON [dbo].[Postcodes]([Postcode]);
    CREATE INDEX [IX_Postcodes_State] ON [dbo].[Postcodes]([State]);
END
GO

-- Insert initial data
PRINT 'Inserting initial data...';

-- Insert default company
SET IDENTITY_INSERT [dbo].[Companies] ON;
INSERT INTO [dbo].[Companies] ([Id], [Name], [Code], [IsActive]) 
SELECT 1, 'Default Company', 'DEFAULT', 1
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Companies] WHERE [Id] = 1);
SET IDENTITY_INSERT [dbo].[Companies] OFF;
GO

-- Insert roles
INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '1', 'Administrator', 'ADMINISTRATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '1');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '2', 'Project Manager', 'PROJECT MANAGER'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '2');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '3', 'Senior Estimator', 'SENIOR ESTIMATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '3');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '4', 'Estimator', 'ESTIMATOR'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '4');

INSERT INTO [dbo].[AspNetRoles] ([Id], [Name], [NormalizedName]) 
SELECT '5', 'Viewer', 'VIEWER'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '5');
GO

-- Insert admin user (password: Admin@123)
INSERT INTO [dbo].[AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount])
SELECT 
    '00000000-0000-0000-0000-000000000001',
    'System Administrator',
    1,
    'admin@steelestimation.com',
    'ADMIN@STEELESTIMATION.COM',
    'admin@steelestimation.com',
    'ADMIN@STEELESTIMATION.COM',
    1,
    'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', -- Admin@123
    'QWERTYUIOPASDFGHJKLZXCVBNM123456',
    'abcdef01-2345-6789-abcd-ef0123456789',
    0,
    0,
    1,
    0
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUsers] WHERE [Id] = '00000000-0000-0000-0000-000000000001');
GO

-- Assign admin role
INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId])
SELECT '00000000-0000-0000-0000-000000000001', '1'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUserRoles] WHERE [UserId] = '00000000-0000-0000-0000-000000000001' AND [RoleId] = '1');
GO

-- Insert default efficiency rates
SET IDENTITY_INSERT [dbo].[EfficiencyRates] ON;
INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 1, 1, 'Standard (75%)', 'Standard efficiency rate for normal operations', 75.00, 1, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 1);

INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 2, 1, 'High Efficiency (85%)', 'For optimized operations with experienced teams', 85.00, 0, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 2);

INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 3, 1, 'Complex Work (65%)', 'For complex operations requiring extra care', 65.00, 0, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 3);

INSERT INTO [dbo].[EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
SELECT 4, 1, 'Rush Job (55%)', 'For urgent projects with tight deadlines', 55.00, 0, 1, '00000000-0000-0000-0000-000000000001'
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[EfficiencyRates] WHERE [Id] = 4);
SET IDENTITY_INSERT [dbo].[EfficiencyRates] OFF;
GO

-- Insert sample Australian postcodes
INSERT INTO [dbo].[Postcodes] ([Postcode], [Suburb], [State])
SELECT '2000', 'Sydney', 'NSW' WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Postcodes] WHERE [Postcode] = '2000');
INSERT INTO [dbo].[Postcodes] ([Postcode], [Suburb], [State])
SELECT '3000', 'Melbourne', 'VIC' WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Postcodes] WHERE [Postcode] = '3000');
INSERT INTO [dbo].[Postcodes] ([Postcode], [Suburb], [State])
SELECT '4000', 'Brisbane', 'QLD' WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Postcodes] WHERE [Postcode] = '4000');
INSERT INTO [dbo].[Postcodes] ([Postcode], [Suburb], [State])
SELECT '5000', 'Adelaide', 'SA' WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Postcodes] WHERE [Postcode] = '5000');
INSERT INTO [dbo].[Postcodes] ([Postcode], [Suburb], [State])
SELECT '6000', 'Perth', 'WA' WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Postcodes] WHERE [Postcode] = '6000');
GO

PRINT 'Database initialization completed successfully!';
PRINT '';
PRINT 'Default login credentials:';
PRINT 'Email: admin@steelestimation.com';
PRINT 'Password: Admin@123';
GO