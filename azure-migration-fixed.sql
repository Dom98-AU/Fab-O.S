-- Azure SQL Migration - Fixed for existing schema
-- This works with the existing Users/Roles tables instead of AspNetUsers/AspNetRoles

-- 1. First, let's check what columns exist in the Users table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PhoneNumber')
    ALTER TABLE [dbo].[Users] ADD [PhoneNumber] [nvarchar](max) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'PhoneNumberConfirmed')
    ALTER TABLE [dbo].[Users] ADD [PhoneNumberConfirmed] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'TwoFactorEnabled')
    ALTER TABLE [dbo].[Users] ADD [TwoFactorEnabled] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LockoutEnd')
    ALTER TABLE [dbo].[Users] ADD [LockoutEnd] [datetimeoffset](7) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'LockoutEnabled')
    ALTER TABLE [dbo].[Users] ADD [LockoutEnabled] [bit] NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'AccessFailedCount')
    ALTER TABLE [dbo].[Users] ADD [AccessFailedCount] [int] NOT NULL DEFAULT 0;

-- 2. Create Companies table (required for multi-tenancy)
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
    PRINT 'Created Companies table';
END

-- 3. Add CompanyId to existing tables if needed
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CompanyId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CompanyId] [int] NULL;
    -- Insert default company
    INSERT INTO [dbo].[Companies] ([Name], [Code]) VALUES ('Default Company', 'DEFAULT');
    -- Update existing projects
    UPDATE [dbo].[Projects] SET [CompanyId] = (SELECT TOP 1 Id FROM [dbo].[Companies]);
    -- Make it NOT NULL after update
    ALTER TABLE [dbo].[Projects] ALTER COLUMN [CompanyId] [int] NOT NULL;
    -- Add foreign key
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Companies] 
        FOREIGN KEY([CompanyId]) REFERENCES [dbo].[Companies]([Id]);
END

-- 4. Create Estimations table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Estimations]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Estimations](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [ProjectId] [int] NOT NULL,
        [EstimationNumber] [nvarchar](50) NOT NULL,
        [EstimationName] [nvarchar](200) NOT NULL,
        [Status] [nvarchar](50) NOT NULL DEFAULT 'Draft',
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        [CreatedBy] [nvarchar](450) NULL,
        [UpdatedBy] [nvarchar](450) NULL,
        CONSTRAINT [PK_Estimations] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Estimations_Projects] FOREIGN KEY([ProjectId]) REFERENCES [dbo].[Projects]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_Estimations_ProjectId] ON [dbo].[Estimations]([ProjectId]);
    PRINT 'Created Estimations table';
END

-- 5. Create Packages table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Packages](
        [Id] [int] IDENTITY(1,1) NOT NULL,
        [EstimationId] [int] NOT NULL,
        [PackageName] [nvarchar](200) NOT NULL,
        [Description] [nvarchar](max) NULL,
        [ProcessingEfficiency] [decimal](5, 2) NULL DEFAULT 100,
        [EfficiencyRateId] [int] NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedAt] [datetime2](7) NULL,
        CONSTRAINT [PK_Packages] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Packages_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_Packages_EstimationId] ON [dbo].[Packages]([EstimationId]);
    PRINT 'Created Packages table';
END

-- 6. Create Addresses table
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
    PRINT 'Created Addresses table';
END

-- 7. Create Customers table
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
        CONSTRAINT [FK_Customers_ShippingAddress] FOREIGN KEY([ShippingAddressId]) REFERENCES [dbo].[Addresses]([Id])
    );
    CREATE INDEX [IX_Customers_CompanyId] ON [dbo].[Customers]([CompanyId]);
    CREATE INDEX [IX_Customers_ABN] ON [dbo].[Customers]([ABN]);
    PRINT 'Created Customers table';
END

-- 8. Create Contacts table
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
    PRINT 'Created Contacts table';
END

-- 9. Add CustomerId to Projects if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CustomerId] [int] NULL;
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers] 
        FOREIGN KEY([CustomerId]) REFERENCES [dbo].[Customers]([Id]);
END

-- 10. Update ProcessingItems table structure if needed
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
BEGIN
    -- Add missing columns if they don't exist
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackageId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackageId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'DeliveryBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [DeliveryBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInBundle] [bit] NOT NULL DEFAULT 0;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleId')
        ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] [int] NULL;
    
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInPackBundle')
        ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] [bit] NOT NULL DEFAULT 0;
END

-- 11. Create DeliveryBundles table
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
    PRINT 'Created DeliveryBundles table';
END

-- 12. Create PackBundles table
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
    PRINT 'Created PackBundles table';
END

-- 13. Create EfficiencyRates table
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
    PRINT 'Created EfficiencyRates table';
END

-- 14. Create EstimationTimeLogs table
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
        CONSTRAINT [FK_EstimationTimeLogs_Estimations] FOREIGN KEY([EstimationId]) REFERENCES [dbo].[Estimations]([Id]) ON DELETE CASCADE
    );
    CREATE INDEX [IX_EstimationTimeLogs_EstimationId] ON [dbo].[EstimationTimeLogs]([EstimationId]);
    CREATE INDEX [IX_EstimationTimeLogs_UserId] ON [dbo].[EstimationTimeLogs]([UserId]);
    PRINT 'Created EstimationTimeLogs table';
END

-- 15. Create WeldingItemConnections table
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
    PRINT 'Created WeldingItemConnections table';
END

-- 16. Create Postcodes table
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

-- 17. Add foreign key constraints for ProcessingItems after all tables exist
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackageId')
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_Packages')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_Packages] 
        FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages]([Id]) ON DELETE CASCADE;
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeliveryBundles]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_DeliveryBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles] 
        FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles]([Id]);
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PackBundles]') AND type in (N'U'))
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles] 
        FOREIGN KEY([PackBundleId]) REFERENCES [dbo].[PackBundles]([Id]) ON DELETE NO ACTION;
END

-- 18. Add foreign key for Packages EfficiencyRateId
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'EfficiencyRateId')
   AND NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Packages_EfficiencyRates')
BEGIN
    ALTER TABLE [dbo].[Packages] ADD CONSTRAINT [FK_Packages_EfficiencyRates] 
        FOREIGN KEY([EfficiencyRateId]) REFERENCES [dbo].[EfficiencyRates]([Id]);
END

-- 19. Insert default efficiency rates
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EfficiencyRates]') AND type in (N'U'))
   AND EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Companies]') AND type in (N'U'))
BEGIN
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
END

PRINT 'Azure SQL Database schema update completed!';