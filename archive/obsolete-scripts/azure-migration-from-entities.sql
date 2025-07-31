-- Azure SQL Database Schema Migration based on SteelEstimation.Core Entities
-- This script updates Azure to match the entity definitions exactly

USE [sqldb-steel-estimation-prod];
GO

-- Step 1: Update Users table to match User entity
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'Username')
        ALTER TABLE [dbo].[Users] ADD [Username] [nvarchar](100) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PasswordHash')
        ALTER TABLE [dbo].[Users] ADD [PasswordHash] [nvarchar](500) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'SecurityStamp')
        ALTER TABLE [dbo].[Users] ADD [SecurityStamp] [nvarchar](500) NOT NULL DEFAULT NEWID();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'FirstName')
        ALTER TABLE [dbo].[Users] ADD [FirstName] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastName')
        ALTER TABLE [dbo].[Users] ADD [LastName] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyName')
        ALTER TABLE [dbo].[Users] ADD [CompanyName] [nvarchar](200) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
        ALTER TABLE [dbo].[Users] ADD [CompanyId] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'JobTitle')
        ALTER TABLE [dbo].[Users] ADD [JobTitle] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PhoneNumber')
        ALTER TABLE [dbo].[Users] ADD [PhoneNumber] [nvarchar](20) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'IsActive')
        ALTER TABLE [dbo].[Users] ADD [IsActive] [bit] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'IsEmailConfirmed')
        ALTER TABLE [dbo].[Users] ADD [IsEmailConfirmed] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'EmailConfirmationToken')
        ALTER TABLE [dbo].[Users] ADD [EmailConfirmationToken] [nvarchar](max) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PasswordResetToken')
        ALTER TABLE [dbo].[Users] ADD [PasswordResetToken] [nvarchar](max) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PasswordResetExpiry')
        ALTER TABLE [dbo].[Users] ADD [PasswordResetExpiry] [datetime2](7) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastLoginDate')
        ALTER TABLE [dbo].[Users] ADD [LastLoginDate] [datetime2](7) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'FailedLoginAttempts')
        ALTER TABLE [dbo].[Users] ADD [FailedLoginAttempts] [int] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LockedOutUntil')
        ALTER TABLE [dbo].[Users] ADD [LockedOutUntil] [datetime2](7) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CreatedDate')
        ALTER TABLE [dbo].[Users] ADD [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LastModified')
        ALTER TABLE [dbo].[Users] ADD [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    PRINT 'Updated Users table';
END

-- Step 2: Update Roles table to match Role entity
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'RoleName')
        ALTER TABLE [dbo].[Roles] ADD [RoleName] [nvarchar](50) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'Description')
        ALTER TABLE [dbo].[Roles] ADD [Description] [nvarchar](500) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanCreateProjects')
        ALTER TABLE [dbo].[Roles] ADD [CanCreateProjects] [bit] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanEditProjects')
        ALTER TABLE [dbo].[Roles] ADD [CanEditProjects] [bit] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanDeleteProjects')
        ALTER TABLE [dbo].[Roles] ADD [CanDeleteProjects] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanViewAllProjects')
        ALTER TABLE [dbo].[Roles] ADD [CanViewAllProjects] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanManageUsers')
        ALTER TABLE [dbo].[Roles] ADD [CanManageUsers] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanExportData')
        ALTER TABLE [dbo].[Roles] ADD [CanExportData] [bit] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CanImportData')
        ALTER TABLE [dbo].[Roles] ADD [CanImportData] [bit] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND name = 'CreatedDate')
        ALTER TABLE [dbo].[Roles] ADD [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    PRINT 'Updated Roles table';
END

-- Step 3: Create Companies table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Companies]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Companies](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [Name] [nvarchar](200) NOT NULL,
        [Code] [nvarchar](50) NOT NULL,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [SubscriptionLevel] [nvarchar](50) NOT NULL DEFAULT 'Standard',
        [MaxUsers] [int] NOT NULL DEFAULT 10,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Companies] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Companies_Code] UNIQUE ([Code])
    );
    
    -- Insert default company
    INSERT INTO [dbo].[Companies] ([Name], [Code]) VALUES ('Default Company', 'DEFAULT');
    
    PRINT 'Created Companies table';
END

-- Step 4: Update Projects table to match Project entity
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'ProjectName')
        ALTER TABLE [dbo].[Projects] ADD [ProjectName] [nvarchar](200) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'JobNumber')
        ALTER TABLE [dbo].[Projects] ADD [JobNumber] [nvarchar](50) NOT NULL DEFAULT '';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
        ALTER TABLE [dbo].[Projects] ADD [CustomerId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'ProjectLocation')
        ALTER TABLE [dbo].[Projects] ADD [ProjectLocation] [nvarchar](200) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'Description')
        ALTER TABLE [dbo].[Projects] ADD [Description] [nvarchar](500) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'EstimationStage')
        ALTER TABLE [dbo].[Projects] ADD [EstimationStage] [nvarchar](20) NOT NULL DEFAULT 'Preliminary';
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'LaborRate')
        ALTER TABLE [dbo].[Projects] ADD [LaborRate] [decimal](10, 2) NOT NULL DEFAULT 75.00;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'ContingencyPercentage')
        ALTER TABLE [dbo].[Projects] ADD [ContingencyPercentage] [decimal](5, 2) NOT NULL DEFAULT 10.00;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'Notes')
        ALTER TABLE [dbo].[Projects] ADD [Notes] [nvarchar](max) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'EstimatedHours')
        ALTER TABLE [dbo].[Projects] ADD [EstimatedHours] [decimal](10, 2) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'EstimatedCompletionDate')
        ALTER TABLE [dbo].[Projects] ADD [EstimatedCompletionDate] [datetime2](7) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'OwnerId')
        ALTER TABLE [dbo].[Projects] ADD [OwnerId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'LastModifiedBy')
        ALTER TABLE [dbo].[Projects] ADD [LastModifiedBy] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CreatedDate')
        ALTER TABLE [dbo].[Projects] ADD [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'LastModified')
        ALTER TABLE [dbo].[Projects] ADD [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'IsDeleted')
        ALTER TABLE [dbo].[Projects] ADD [IsDeleted] [bit] NOT NULL DEFAULT 0;
    
    PRINT 'Updated Projects table';
END

-- Step 5: Create Package table (doesn't exist in Azure yet)
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Packages](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [PackageNumber] [nvarchar](50) NOT NULL,
        [PackageName] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Draft',
        [StartDate] [datetime2](7) NULL,
        [EndDate] [datetime2](7) NULL,
        [EstimatedHours] [decimal](10, 2) NOT NULL DEFAULT 0,
        [EstimatedCost] [decimal](10, 2) NOT NULL DEFAULT 0,
        [ActualHours] [decimal](10, 2) NOT NULL DEFAULT 0,
        [ActualCost] [decimal](10, 2) NOT NULL DEFAULT 0,
        [LaborRatePerHour] [decimal](10, 2) NOT NULL DEFAULT 0,
        [ProcessingEfficiency] [decimal](5, 2) NULL,
        [EfficiencyRateId] [int] NULL,
        [CreatedBy] [int] NULL,
        [LastModifiedBy] [int] NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [IsDeleted] [bit] NOT NULL DEFAULT 0,
        CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Packages_ProjectId] ON [dbo].[Packages]([ProjectId]);
    
    PRINT 'Created Packages table';
END

-- Step 6: Create Address table
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
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Addresses] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    
    PRINT 'Created Addresses table';
END

-- Step 7: Create Customer table
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
        [CreatedBy] [int] NULL,
        [UpdatedBy] [int] NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_ABN] ON [dbo].[Customers]([ABN]);
    
    PRINT 'Created Customers table';
END

-- Step 8: Create Contact table
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
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_Contacts_CustomerId] ON [dbo].[Contacts]([CustomerId]);
    
    PRINT 'Created Contacts table';
END

-- Step 9: Create PackageWorksheet table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackageWorksheets]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PackageWorksheets](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [WorksheetName] [nvarchar](100) NOT NULL,
        [WorksheetType] [nvarchar](50) NOT NULL,
        [CreatedBy] [int] NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_PackageWorksheets] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_PackageWorksheets_PackageId] ON [dbo].[PackageWorksheets]([PackageId]);
    
    PRINT 'Created PackageWorksheets table';
END

-- Step 10: Update ProcessingItems table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'ProjectId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [ProjectId] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackageWorksheetId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackageWorksheetId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'DrawingNumber')
        ALTER TABLE [dbo].[ProcessingItems] ADD [DrawingNumber] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Description')
        ALTER TABLE [dbo].[ProcessingItems] ADD [Description] [nvarchar](500) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MaterialId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MaterialId] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Quantity')
        ALTER TABLE [dbo].[ProcessingItems] ADD [Quantity] [int] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Length')
        ALTER TABLE [dbo].[ProcessingItems] ADD [Length] [decimal](10, 2) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Weight')
        ALTER TABLE [dbo].[ProcessingItems] ADD [Weight] [decimal](10, 2) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'DeliveryBundleQty')
        ALTER TABLE [dbo].[ProcessingItems] ADD [DeliveryBundleQty] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleQty')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleQty] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'BundleGroup')
        ALTER TABLE [dbo].[ProcessingItems] ADD [BundleGroup] [nvarchar](50) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackGroup')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackGroup] [nvarchar](50) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'UnloadTimePerBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [UnloadTimePerBundle] [int] NOT NULL DEFAULT 15;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MarkMeasureCut')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MarkMeasureCut] [int] NOT NULL DEFAULT 30;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'QualityCheckClean')
        ALTER TABLE [dbo].[ProcessingItems] ADD [QualityCheckClean] [int] NOT NULL DEFAULT 15;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MoveToAssembly')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MoveToAssembly] [int] NOT NULL DEFAULT 20;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'MoveAfterWeld')
        ALTER TABLE [dbo].[ProcessingItems] ADD [MoveAfterWeld] [int] NOT NULL DEFAULT 20;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'LoadingTimePerBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [LoadingTimePerBundle] [int] NOT NULL DEFAULT 15;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'DeliveryBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [DeliveryBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInBundle] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInPackBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'CreatedDate')
        ALTER TABLE [dbo].[ProcessingItems] ADD [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'LastModified')
        ALTER TABLE [dbo].[ProcessingItems] ADD [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsDeleted')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsDeleted] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'RowVersion')
        ALTER TABLE [dbo].[ProcessingItems] ADD [RowVersion] [timestamp] NOT NULL;
    
    PRINT 'Updated ProcessingItems table';
END

-- Step 11: Update WeldingItems table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND type in (N'U'))
BEGIN
    -- Add missing columns
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'ProjectId')
        ALTER TABLE [dbo].[WeldingItems] ADD [ProjectId] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'PackageWorksheetId')
        ALTER TABLE [dbo].[WeldingItems] ADD [PackageWorksheetId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'DrawingNumber')
        ALTER TABLE [dbo].[WeldingItems] ADD [DrawingNumber] [nvarchar](100) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'ItemDescription')
        ALTER TABLE [dbo].[WeldingItems] ADD [ItemDescription] [nvarchar](500) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldType')
        ALTER TABLE [dbo].[WeldingItems] ADD [WeldType] [nvarchar](50) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldLength')
        ALTER TABLE [dbo].[WeldingItems] ADD [WeldLength] [decimal](10, 2) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'Weight')
        ALTER TABLE [dbo].[WeldingItems] ADD [Weight] [decimal](10, 2) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'LocationComments')
        ALTER TABLE [dbo].[WeldingItems] ADD [LocationComments] [nvarchar](500) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'PhotoReference')
        ALTER TABLE [dbo].[WeldingItems] ADD [PhotoReference] [nvarchar](200) NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldingConnectionId')
        ALTER TABLE [dbo].[WeldingItems] ADD [WeldingConnectionId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'ConnectionQty')
        ALTER TABLE [dbo].[WeldingItems] ADD [ConnectionQty] [int] NOT NULL DEFAULT 1;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'AssembleFitTack')
        ALTER TABLE [dbo].[WeldingItems] ADD [AssembleFitTack] [decimal](10, 2) NOT NULL DEFAULT 5;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'Weld')
        ALTER TABLE [dbo].[WeldingItems] ADD [Weld] [decimal](10, 2) NOT NULL DEFAULT 3;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldCheck')
        ALTER TABLE [dbo].[WeldingItems] ADD [WeldCheck] [decimal](10, 2) NOT NULL DEFAULT 2;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldTest')
        ALTER TABLE [dbo].[WeldingItems] ADD [WeldTest] [decimal](10, 2) NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'CreatedDate')
        ALTER TABLE [dbo].[WeldingItems] ADD [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'LastModified')
        ALTER TABLE [dbo].[WeldingItems] ADD [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE();
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'IsDeleted')
        ALTER TABLE [dbo].[WeldingItems] ADD [IsDeleted] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'RowVersion')
        ALTER TABLE [dbo].[WeldingItems] ADD [RowVersion] [timestamp] NOT NULL;
    
    PRINT 'Updated WeldingItems table';
END

-- Step 12: Create remaining tables
-- DeliveryBundle
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeliveryBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DeliveryBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL,
        [BundleGroup] [nvarchar](50) NULL,
        [MaxWeight] [decimal](10, 2) NOT NULL DEFAULT 3000,
        [CurrentWeight] [decimal](10, 2) NOT NULL DEFAULT 0,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_DeliveryBundles_ProjectId] ON [dbo].[DeliveryBundles]([ProjectId]);
    PRINT 'Created DeliveryBundles table';
END

-- PackBundle
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackBundles]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PackBundles](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [BundleName] [nvarchar](100) NOT NULL,
        [HandlingOperation] [nvarchar](50) NOT NULL,
        [ItemCount] [int] NOT NULL DEFAULT 0,
        [TotalWeight] [decimal](10, 3) NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_PackBundles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles]([PackageId]);
    PRINT 'Created PackBundles table';
END

-- WeldingConnection
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingConnections](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [PackageId] [int] NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [Description] [nvarchar](500) NULL,
        [AssembleFitTack] [decimal](10, 2) NOT NULL DEFAULT 5,
        [Weld] [decimal](10, 2) NOT NULL DEFAULT 3,
        [WeldCheck] [decimal](10, 2) NOT NULL DEFAULT 2,
        [WeldTest] [decimal](10, 2) NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_WeldingConnections] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_WeldingConnections_PackageId] ON [dbo].[WeldingConnections]([PackageId]);
    PRINT 'Created WeldingConnections table';
END

-- WeldingItemConnection
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItemConnections]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[WeldingItemConnections](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [WeldingItemId] [int] NOT NULL,
        [ConnectionType] [nvarchar](100) NOT NULL,
        [ConnectionCount] [int] NOT NULL DEFAULT 1,
        [AssembleFitTack] [decimal](10, 2) NOT NULL DEFAULT 5,
        [Weld] [decimal](10, 2) NOT NULL DEFAULT 3,
        [WeldCheck] [decimal](10, 2) NOT NULL DEFAULT 2,
        [WeldTest] [decimal](10, 2) NOT NULL DEFAULT 0,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_WeldingItemConnections] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_WeldingItemConnections_WeldingItemId] ON [dbo].[WeldingItemConnections]([WeldingItemId]);
    PRINT 'Created WeldingItemConnections table';
END

-- EfficiencyRate
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [CompanyId] [int] NOT NULL,
        [Name] [nvarchar](100) NOT NULL,
        [EfficiencyPercentage] [decimal](5, 2) NOT NULL,
        [IsDefault] [bit] NOT NULL DEFAULT 0,
        [IsActive] [bit] NOT NULL DEFAULT 1,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_EfficiencyRates_CompanyId] ON [dbo].[EfficiencyRates]([CompanyId]);
    PRINT 'Created EfficiencyRates table';
END

-- EstimationTimeLog
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EstimationTimeLogs]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[EstimationTimeLogs](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL, -- This references Project.Id
        [UserId] [int] NOT NULL,
        [StartTime] [datetime2](7) NOT NULL,
        [EndTime] [datetime2](7) NULL,
        [Duration] [int] NOT NULL DEFAULT 0, -- in seconds
        [IsActive] [bit] NOT NULL DEFAULT 0,
        [SessionId] [uniqueidentifier] NOT NULL,
        [PageName] [nvarchar](100) NULL,
        [CreatedDate] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EstimationTimeLogs] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
    PRINT 'Created EstimationTimeLogs table';
END

-- Postcode
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
    PRINT 'Created Postcodes table';
END

GO

-- Step 13: Add Foreign Key Constraints
-- Users and Company
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Users_Companies')
    ALTER TABLE [dbo].[Users] ADD CONSTRAINT [FK_Users_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);

-- Projects
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Projects_Customers')
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers] 
        FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Projects_Owner')
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Owner] 
        FOREIGN KEY([OwnerId]) REFERENCES [dbo].[Users]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Projects_LastModifiedBy')
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_LastModifiedBy] 
        FOREIGN KEY([LastModifiedBy]) REFERENCES [dbo].[Users]([Id]);

-- Packages
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Packages_Projects')
    ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_Projects] 
        FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Packages_EfficiencyRates')
    ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_EfficiencyRates] 
        FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates]([Id]);

-- ProcessingItems
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_Projects')
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_Projects] 
        FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackageWorksheets')
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackageWorksheets] 
        FOREIGN KEY([PackageWorksheetId]) REFERENCES [dbo].[PackageWorksheets]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_DeliveryBundles')
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles] 
        FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles')
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles] 
        FOREIGN KEY([PackBundleId]) REFERENCES [dbo].[PackBundles]([Id]) ON DELETE NO ACTION;

-- WeldingItems
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_WeldingItems_Projects')
    ALTER TABLE [dbo].[WeldingItems] ADD CONSTRAINT [FK_WeldingItems_Projects] 
        FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_WeldingItems_PackageWorksheets')
    ALTER TABLE [dbo].[WeldingItems] ADD CONSTRAINT [FK_WeldingItems_PackageWorksheets] 
        FOREIGN KEY([PackageWorksheetId]) REFERENCES [dbo].[PackageWorksheets]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_WeldingItems_WeldingConnections')
    ALTER TABLE [dbo].[WeldingItems] ADD CONSTRAINT [FK_WeldingItems_WeldingConnections] 
        FOREIGN KEY([WeldingConnectionId]) REFERENCES [dbo].[WeldingConnections]([Id]);

-- Other tables
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_Companies')
    ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_BillingAddress')
    ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_BillingAddress] 
        FOREIGN KEY([BillingAddressId]) REFERENCES [dbo].[Addresses]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Customers_ShippingAddress')
    ALTER TABLE [dbo].[Customers] ADD CONSTRAINT [FK_Customers_ShippingAddress] 
        FOREIGN KEY([ShippingAddressId]) REFERENCES [dbo].[Addresses]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contacts_Customers')
    ALTER TABLE [dbo].[Contacts] ADD CONSTRAINT [FK_Contacts_Customers] 
        FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_WeldingItemConnections_WeldingItems')
    ALTER TABLE [dbo].[WeldingItemConnections] ADD CONSTRAINT [FK_WeldingItemConnections_WeldingItems] 
        FOREIGN KEY([WeldingItemId]) REFERENCES [dbo].[WeldingItems]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_EstimationTimeLogs_Projects')
    ALTER TABLE [dbo].[EstimationTimeLogs] ADD CONSTRAINT [FK_EstimationTimeLogs_Projects] 
        FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_EstimationTimeLogs_Users')
    ALTER TABLE [dbo].[EstimationTimeLogs] ADD CONSTRAINT [FK_EstimationTimeLogs_Users] 
        FOREIGN KEY([UserId]) REFERENCES [dbo].[Users]([Id]);

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_EfficiencyRates_Companies')
    ALTER TABLE [dbo].[EfficiencyRates] ADD CONSTRAINT [FK_EfficiencyRates_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PackageWorksheets_Packages')
    ALTER TABLE [dbo].[PackageWorksheets] ADD CONSTRAINT [FK_PackageWorksheets_Packages] 
        FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DeliveryBundles_Projects')
    ALTER TABLE [dbo].[DeliveryBundles] ADD CONSTRAINT [FK_DeliveryBundles_Projects] 
        FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PackBundles_Packages')
    ALTER TABLE [dbo].[PackBundles] ADD CONSTRAINT [FK_PackBundles_Packages] 
        FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_WeldingConnections_Packages')
    ALTER TABLE [dbo].[WeldingConnections] ADD CONSTRAINT [FK_WeldingConnections_Packages] 
        FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;

GO

-- Step 14: Insert default data
-- Default efficiency rates for all companies
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

PRINT 'Azure SQL Database migration based on Core entities completed!';
PRINT 'The database now matches the entity definitions from SteelEstimation.Core.';