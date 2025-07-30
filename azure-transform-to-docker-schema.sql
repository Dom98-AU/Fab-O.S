-- Azure SQL Database Schema Transformation
-- This script transforms the Azure database to match the Docker schema exactly
-- WARNING: This will rename existing tables and may require data migration

USE [sqldb-steel-estimation-prod];
GO

-- Step 1: Rename existing tables to match ASP.NET Identity schema
-- Note: We'll need to handle foreign keys carefully

-- 1.1 Drop existing foreign keys that reference Users and Roles
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRoles_Users')
    ALTER TABLE [dbo].[UserRoles] DROP CONSTRAINT [FK_UserRoles_Users];

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_UserRoles_Roles')
    ALTER TABLE [dbo].[UserRoles] DROP CONSTRAINT [FK_UserRoles_Roles];

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProjectUsers_Users')
    ALTER TABLE [dbo].[ProjectUsers] DROP CONSTRAINT [FK_ProjectUsers_Users];

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProjectUsers_Projects')
    ALTER TABLE [dbo].[ProjectUsers] DROP CONSTRAINT [FK_ProjectUsers_Projects];

-- 1.2 Rename tables
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
    AND NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND type in (N'U'))
BEGIN
    EXEC sp_rename 'dbo.Users', 'AspNetUsers';
    PRINT 'Renamed Users to AspNetUsers';
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND type in (N'U'))
    AND NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND type in (N'U'))
BEGIN
    EXEC sp_rename 'dbo.Roles', 'AspNetRoles';
    PRINT 'Renamed Roles to AspNetRoles';
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserRoles]') AND type in (N'U'))
    AND NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND type in (N'U'))
BEGIN
    EXEC sp_rename 'dbo.UserRoles', 'AspNetUserRoles';
    PRINT 'Renamed UserRoles to AspNetUserRoles';
END

GO

-- Step 2: Add missing columns to AspNetUsers
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'UserName')
    ALTER TABLE [dbo].[AspNetUsers] ADD [UserName] [nvarchar](256) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'NormalizedUserName')
    ALTER TABLE [dbo].[AspNetUsers] ADD [NormalizedUserName] [nvarchar](256) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'NormalizedEmail')
    ALTER TABLE [dbo].[AspNetUsers] ADD [NormalizedEmail] [nvarchar](256) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'EmailConfirmed')
    ALTER TABLE [dbo].[AspNetUsers] ADD [EmailConfirmed] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'PasswordHash')
    ALTER TABLE [dbo].[AspNetUsers] ADD [PasswordHash] [nvarchar](max) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'SecurityStamp')
    ALTER TABLE [dbo].[AspNetUsers] ADD [SecurityStamp] [nvarchar](max) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'ConcurrencyStamp')
    ALTER TABLE [dbo].[AspNetUsers] ADD [ConcurrencyStamp] [nvarchar](max) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'PhoneNumber')
    ALTER TABLE [dbo].[AspNetUsers] ADD [PhoneNumber] [nvarchar](max) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'PhoneNumberConfirmed')
    ALTER TABLE [dbo].[AspNetUsers] ADD [PhoneNumberConfirmed] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'TwoFactorEnabled')
    ALTER TABLE [dbo].[AspNetUsers] ADD [TwoFactorEnabled] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'LockoutEnd')
    ALTER TABLE [dbo].[AspNetUsers] ADD [LockoutEnd] [datetimeoffset](7) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'LockoutEnabled')
    ALTER TABLE [dbo].[AspNetUsers] ADD [LockoutEnabled] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'AccessFailedCount')
    ALTER TABLE [dbo].[AspNetUsers] ADD [AccessFailedCount] [int] NOT NULL DEFAULT 0;

-- Add columns that exist in Docker but might be missing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'CompanyId')
    ALTER TABLE [dbo].[AspNetUsers] ADD [CompanyId] [int] NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'FullName')
    ALTER TABLE [dbo].[AspNetUsers] ADD [FullName] [nvarchar](100) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'IsActive')
    ALTER TABLE [dbo].[AspNetUsers] ADD [IsActive] [bit] NOT NULL DEFAULT 1;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'CreatedAt')
    ALTER TABLE [dbo].[AspNetUsers] ADD [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = 'UpdatedAt')
    ALTER TABLE [dbo].[AspNetUsers] ADD [UpdatedAt] [datetime2](7) NULL;

GO

-- Step 3: Update data to match new schema requirements
-- Copy Email to UserName and NormalizedEmail if UserName is null
UPDATE [dbo].[AspNetUsers] 
SET [UserName] = [Email] 
WHERE [UserName] IS NULL;

UPDATE [dbo].[AspNetUsers] 
SET [NormalizedUserName] = UPPER([UserName]) 
WHERE [NormalizedUserName] IS NULL;

UPDATE [dbo].[AspNetUsers] 
SET [NormalizedEmail] = UPPER([Email]) 
WHERE [NormalizedEmail] IS NULL;

-- Generate SecurityStamp for users that don't have one
UPDATE [dbo].[AspNetUsers] 
SET [SecurityStamp] = NEWID() 
WHERE [SecurityStamp] IS NULL;

-- Generate ConcurrencyStamp
UPDATE [dbo].[AspNetUsers] 
SET [ConcurrencyStamp] = NEWID() 
WHERE [ConcurrencyStamp] IS NULL;

GO

-- Step 4: Add missing columns to AspNetRoles
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND name = 'NormalizedName')
    ALTER TABLE [dbo].[AspNetRoles] ADD [NormalizedName] [nvarchar](256) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND name = 'ConcurrencyStamp')
    ALTER TABLE [dbo].[AspNetRoles] ADD [ConcurrencyStamp] [nvarchar](max) NULL;

-- Update NormalizedName
UPDATE [dbo].[AspNetRoles] 
SET [NormalizedName] = UPPER([Name]) 
WHERE [NormalizedName] IS NULL;

UPDATE [dbo].[AspNetRoles] 
SET [ConcurrencyStamp] = NEWID() 
WHERE [ConcurrencyStamp] IS NULL;

GO

-- Step 5: Create missing ASP.NET Identity tables
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
END

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
END

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
END

GO

-- Step 6: Create Companies table if it doesn't exist
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
    
    -- Insert default company
    INSERT INTO [dbo].[Companies] ([Name], [Code]) VALUES ('Default Company', 'DEFAULT');
END

GO

-- Step 7: Add CompanyId to Projects and other tables
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CompanyId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CompanyId] [int] NULL;
    UPDATE [dbo].[Projects] SET [CompanyId] = (SELECT TOP 1 Id FROM [dbo].[Companies]);
    ALTER TABLE [dbo].[Projects] ALTER COLUMN [CompanyId] [int] NOT NULL;
END

-- Update AspNetUsers with default CompanyId if needed
UPDATE [dbo].[AspNetUsers] 
SET [CompanyId] = (SELECT TOP 1 Id FROM [dbo].[Companies])
WHERE [CompanyId] IS NULL;

GO

-- Step 8: Create Estimations table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Estimations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Estimations](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [EstimationNumber] [nvarchar](50) NOT NULL,
        [EstimationName] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Draft',
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedBy] [nvarchar](450) NULL,
        [UpdatedBy] [nvarchar](450) NULL,
        [ExpectedCompletionDate] [datetime2](7) NULL,
        [TotalProcessingHours] [decimal](10, 2) NULL,
        [TotalWeldingHours] [decimal](10, 2) NULL,
        [TotalEstimatedHours] [decimal](10, 2) NULL,
        CONSTRAINT [PK_Estimations] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Estimations_ProjectId] ON [dbo].[Estimations]([ProjectId]);
END

GO

-- Step 9: Create Packages table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Packages](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [PackageName] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [ProcessingEfficiency] [decimal](5, 2) NULL DEFAULT 100,
        [EfficiencyRateId] [int] NULL,
        [TotalProcessingHours] [decimal](10, 2) NULL,
        [TotalWeldingHours] [decimal](10, 2) NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Packages_EstimationId] ON [dbo].[Packages]([EstimationId]);
END

GO

-- Step 10: Now create all the remaining tables from Docker schema
-- (Continue with all other tables from the Docker schema...)

-- Create Addresses table
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

-- Create Customers table
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
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_ABN] ON [dbo].[Customers]([ABN]);
END

-- Create Contacts table
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
        CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Contacts_CustomerId] ON [dbo].[Contacts]([CustomerId]);
END

-- Add CustomerId to Projects
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CustomerId] [int] NULL;
END

-- Create DeliveryBundles table
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
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_DeliveryBundles_PackageId] ON [dbo].[DeliveryBundles]([PackageId]);
END

-- Create EfficiencyRates table
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
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates]([CompanyId]);
END

-- Create EstimationTimeLogs table
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
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
END

-- Create PackBundles table
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
        CONSTRAINT [PK_PackBundles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles]([PackageId]);
END

-- Create Postcodes table
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

-- Update ProcessingItems structure
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackageId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackageId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'ItemNo')
        ALTER TABLE [dbo].[ProcessingItems] ADD [ItemNo] [int] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MbeId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MbeId] [nvarchar](50) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MaterialId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MaterialId] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Quantity')
        ALTER TABLE [dbo].[ProcessingItems] ADD [Quantity] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'UnitWeight')
        ALTER TABLE [dbo].[ProcessingItems] ADD [UnitWeight] [decimal](10, 3) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'TotalWeight')
        ALTER TABLE [dbo].[ProcessingItems] ADD [TotalWeight] [decimal](10, 3) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MaterialType')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MaterialType] [nvarchar](50) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'ProcessCategory')
        ALTER TABLE [dbo].[ProcessingItems] ADD [ProcessCategory] [nvarchar](50) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'DeliveryBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [DeliveryBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInBundle] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInPackBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'CreatedAt')
        ALTER TABLE [dbo].[ProcessingItems] ADD [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'UpdatedAt')
        ALTER TABLE [dbo].[ProcessingItems] ADD [UpdatedAt] [datetime2](7) NULL;
END

-- Create WeldingItemConnections table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItemConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItemConnections](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [WeldingItemId] [int] NOT NULL,
        [ConnectionType] [nvarchar](50) NOT NULL,
        [Count] [int] NOT NULL DEFAULT 1,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_WeldingItemConnections] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_WeldingItemConnections_WeldingItemId] ON [dbo].[WeldingItemConnections]([WeldingItemId]);
END

-- Update WeldingItems structure
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'PackageId')
        ALTER TABLE [dbo].[WeldingItems] ADD [PackageId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'ItemNo')
        ALTER TABLE [dbo].[WeldingItems] ADD [ItemNo] [int] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'CreatedAt')
        ALTER TABLE [dbo].[WeldingItems] ADD [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'UpdatedAt')
        ALTER TABLE [dbo].[WeldingItems] ADD [UpdatedAt] [datetime2](7) NULL;
END

GO

-- Step 11: Re-create all foreign key constraints with new table names
-- Add foreign keys for ASP.NET Identity tables
ALTER TABLE [dbo].[AspNetUserRoles] ADD CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] 
    FOREIGN KEY([RoleId]) REFERENCES [dbo].[AspNetRoles]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[AspNetUserRoles] ADD CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] 
    FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[AspNetUserClaims] ADD CONSTRAINT [FK_AspNetUserClaims_AspNetUsers_UserId] 
    FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[AspNetUserLogins] ADD CONSTRAINT [FK_AspNetUserLogins_AspNetUsers_UserId] 
    FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[AspNetUserTokens] ADD CONSTRAINT [FK_AspNetUserTokens_AspNetUsers_UserId] 
    FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]) ON DELETE CASCADE;

-- Add other foreign keys
ALTER TABLE [dbo].[AspNetUsers] ADD CONSTRAINT [FK_AspNetUsers_Companies] 
    FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);

ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Companies] 
    FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);

ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers] 
    FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]);

ALTER TABLE [dbo].[Estimations] ADD CONSTRAINT [FK_Estimations_Projects] 
    FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[Estimations] ADD CONSTRAINT [FK_Estimations_CreatedBy] 
    FOREIGN KEY([CreatedBy]) REFERENCES [dbo].[AspNetUsers]([Id]);

ALTER TABLE [dbo].[Estimations] ADD CONSTRAINT [FK_Estimations_UpdatedBy] 
    FOREIGN KEY([UpdatedBy]) REFERENCES [dbo].[AspNetUsers]([Id]);

ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_Estimations] 
    FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_Packages] 
    FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles] 
    FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles]([Id]);

ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles] 
    FOREIGN KEY([PackBundleId]) REFERENCES [dbo].[PackBundles]([Id]) ON DELETE NO ACTION;

ALTER TABLE [dbo].[WeldingItems] ADD CONSTRAINT [FK_WeldingItems_Packages] 
    FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[WeldingItemConnections] ADD CONSTRAINT [FK_WeldingItemConnections_WeldingItems] 
    FOREIGN KEY([WeldingItemId]) REFERENCES [dbo].[WeldingItems]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[DeliveryBundles] ADD CONSTRAINT [FK_DeliveryBundles_Packages] 
    FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[PackBundles] ADD CONSTRAINT [FK_PackBundles_Packages] 
    FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[EstimationTimeLogs] ADD CONSTRAINT [FK_EstimationTimeLogs_Estimations] 
    FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[EstimationTimeLogs] ADD CONSTRAINT [FK_EstimationTimeLogs_Users] 
    FOREIGN KEY([UserId]) REFERENCES [dbo].[AspNetUsers]([Id]);

ALTER TABLE [dbo].[EfficiencyRates] ADD CONSTRAINT [FK_EfficiencyRates_Companies] 
    FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]) ON DELETE CASCADE;

ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_EfficiencyRates] 
    FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates]([Id]);

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_Companies] 
    FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_BillingAddress] 
    FOREIGN KEY([BillingAddressId]) REFERENCES [dbo].[Addresses]([Id]);

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_ShippingAddress] 
    FOREIGN KEY([ShippingAddressId]) REFERENCES [dbo].[Addresses]([Id]);

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_CreatedBy] 
    FOREIGN KEY([CreatedBy]) REFERENCES [dbo].[AspNetUsers]([Id]);

ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_UpdatedBy] 
    FOREIGN KEY([UpdatedBy]) REFERENCES [dbo].[AspNetUsers]([Id]);

ALTER TABLE [dbo].[Contacts] ADD CONSTRAINT [FK_Contacts_Customers] 
    FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]) ON DELETE CASCADE;

GO

-- Step 12: Drop ProjectUsers table as it's replaced by AspNetUserRoles
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProjectUsers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[ProjectUsers];
    PRINT 'Dropped ProjectUsers table';
END

GO

-- Step 13: Create indexes to match Docker schema
CREATE UNIQUE INDEX [UserNameIndex] ON [dbo].[AspNetUsers]([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL;
CREATE INDEX [EmailIndex] ON [dbo].[AspNetUsers]([NormalizedEmail]);
CREATE UNIQUE INDEX [RoleNameIndex] ON [dbo].[AspNetRoles]([NormalizedName]) WHERE [NormalizedName] IS NOT NULL;

GO

-- Step 14: Insert default data
-- Insert default efficiency rates for all companies
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

PRINT 'Azure SQL Database transformation to Docker schema completed!';
PRINT 'The database now matches the Docker schema with ASP.NET Identity tables.';