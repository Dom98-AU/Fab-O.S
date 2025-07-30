-- =============================================
-- Migration: Complete Customer Management System
-- Created: 2025-07-05
-- Description: Adds Customer, Contact, and Address tables with full relationships
-- =============================================

-- STEP 1: Create Address table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Addresses] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [AddressLine1] nvarchar(200) NOT NULL,
        [AddressLine2] nvarchar(200) NULL,
        [Suburb] nvarchar(100) NOT NULL,
        [State] nvarchar(50) NOT NULL,
        [PostCode] nvarchar(10) NOT NULL,
        [Country] nvarchar(100) NOT NULL DEFAULT 'Australia',
        [AddressType] int NOT NULL,
        CONSTRAINT [PK_Addresses] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create indexes on Address table
    CREATE NONCLUSTERED INDEX [IX_Addresses_PostCode] ON [dbo].[Addresses] ([PostCode]);
    CREATE NONCLUSTERED INDEX [IX_Addresses_State] ON [dbo].[Addresses] ([State]);
    
    PRINT 'Created Addresses table';
END
ELSE
BEGIN
    PRINT 'Addresses table already exists';
END
GO

-- STEP 2: Create Customer table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Customers] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [CompanyId] int NOT NULL,
        [CompanyName] nvarchar(200) NOT NULL,
        [TradingName] nvarchar(200) NULL,
        [ABN] nvarchar(11) NOT NULL,
        [ACN] nvarchar(9) NULL,
        [IsActive] bit NOT NULL DEFAULT 1,
        [BillingAddressId] int NULL,
        [ShippingAddressId] int NULL,
        [Notes] nvarchar(1000) NULL,
        [CreatedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [ModifiedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [CreatedById] int NOT NULL,
        [ModifiedById] int NULL,
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Customers_Companies_CompanyId] FOREIGN KEY ([CompanyId]) REFERENCES [dbo].[Companies] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Customers_Addresses_BillingAddressId] FOREIGN KEY ([BillingAddressId]) REFERENCES [dbo].[Addresses] ([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_Customers_Addresses_ShippingAddressId] FOREIGN KEY ([ShippingAddressId]) REFERENCES [dbo].[Addresses] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Customers_Users_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Customers_Users_ModifiedById] FOREIGN KEY ([ModifiedById]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [CK_Customers_ABN] CHECK (LEN([ABN]) = 11 AND [ABN] NOT LIKE '%[^0-9]%'),
        CONSTRAINT [CK_Customers_ACN] CHECK ([ACN] IS NULL OR (LEN([ACN]) = 9 AND [ACN] NOT LIKE '%[^0-9]%'))
    );

    -- Create indexes on Customer table
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Customers_CompanyId_ABN] ON [dbo].[Customers] ([CompanyId], [ABN]);
    CREATE NONCLUSTERED INDEX [IX_Customers_CompanyId] ON [dbo].[Customers] ([CompanyId]);
    CREATE NONCLUSTERED INDEX [IX_Customers_IsActive] ON [dbo].[Customers] ([IsActive]);
    CREATE NONCLUSTERED INDEX [IX_Customers_CompanyName] ON [dbo].[Customers] ([CompanyName]);
    
    PRINT 'Created Customers table';
END
ELSE
BEGIN
    PRINT 'Customers table already exists';
END
GO

-- STEP 3: Create Contact table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Contacts] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [CustomerId] int NOT NULL,
        [FirstName] nvarchar(100) NOT NULL,
        [LastName] nvarchar(100) NOT NULL,
        [Email] nvarchar(200) NULL,
        [Phone] nvarchar(20) NULL,
        [Mobile] nvarchar(20) NULL,
        [Position] nvarchar(100) NULL,
        [IsPrimary] bit NOT NULL DEFAULT 0,
        [IsBillingContact] bit NOT NULL DEFAULT 0,
        [IsActive] bit NOT NULL DEFAULT 1,
        [Notes] nvarchar(500) NULL,
        [CreatedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        [ModifiedDate] datetime2(7) NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Contacts_Customers_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([Id]) ON DELETE CASCADE
    );

    -- Create indexes on Contact table
    CREATE NONCLUSTERED INDEX [IX_Contacts_CustomerId] ON [dbo].[Contacts] ([CustomerId]);
    CREATE NONCLUSTERED INDEX [IX_Contacts_Email] ON [dbo].[Contacts] ([Email]);
    CREATE NONCLUSTERED INDEX [IX_Contacts_IsActive] ON [dbo].[Contacts] ([IsActive]);
    
    PRINT 'Created Contacts table';
END
ELSE
BEGIN
    PRINT 'Contacts table already exists';
END
GO

-- STEP 4: Add CustomerId to Projects table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CustomerId] int NULL;
    PRINT 'Added CustomerId column to Projects table';
END
ELSE
BEGIN
    PRINT 'CustomerId column already exists in Projects table';
END
GO

-- STEP 5: Create foreign key for Projects to Customers
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Projects_Customers_CustomerId]'))
BEGIN
    ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers_CustomerId] 
        FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([Id]) ON DELETE SET NULL;
    PRINT 'Added foreign key FK_Projects_Customers_CustomerId';
END
ELSE
BEGIN
    PRINT 'Foreign key FK_Projects_Customers_CustomerId already exists';
END
GO

-- STEP 6: Data Migration (OPTIONAL - Uncomment if you have existing CustomerName data)
-- This migrates existing CustomerName values from Projects to the new Customer table
/*
-- Check if there are any projects with CustomerName that need migration
IF EXISTS (SELECT 1 FROM [dbo].[Projects] WHERE CustomerName IS NOT NULL AND CustomerName != '' AND CustomerId IS NULL)
BEGIN
    PRINT 'Starting customer data migration...';
    
    -- Insert unique customers from projects
    INSERT INTO [dbo].[Customers] (CompanyId, CompanyName, ABN, IsActive, CreatedById, CreatedDate, ModifiedDate)
    SELECT DISTINCT 
        p.CompanyId,
        p.CustomerName,
        '00000000000' as ABN, -- Placeholder ABN - you'll need to update these manually
        1 as IsActive,
        ISNULL(p.OwnerId, 1) as CreatedById,
        MIN(p.CreatedDate) as CreatedDate,
        MIN(p.CreatedDate) as ModifiedDate
    FROM [dbo].[Projects] p
    LEFT JOIN [dbo].[Customers] c ON p.CustomerName = c.CompanyName AND p.CompanyId = c.CompanyId
    WHERE p.CustomerName IS NOT NULL 
        AND p.CustomerName != ''
        AND c.Id IS NULL -- Only insert if customer doesn't already exist
    GROUP BY p.CompanyId, p.CustomerName, p.OwnerId;
    
    PRINT 'Inserted ' + CAST(@@ROWCOUNT as varchar) + ' customers';
    
    -- Update Projects with the new CustomerId
    UPDATE p
    SET p.CustomerId = c.Id
    FROM [dbo].[Projects] p
    INNER JOIN [dbo].[Customers] c ON p.CustomerName = c.CompanyName AND p.CompanyId = c.CompanyId
    WHERE p.CustomerId IS NULL;
    
    PRINT 'Updated ' + CAST(@@ROWCOUNT as varchar) + ' projects with CustomerId';
END
ELSE
BEGIN
    PRINT 'No customer data migration needed';
END
*/

-- STEP 7: Drop CustomerName column (OPTIONAL - Only after verifying migration)
-- WARNING: This is irreversible! Only run after confirming all data is migrated
/*
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerName')
BEGIN
    ALTER TABLE [dbo].[Projects] DROP COLUMN [CustomerName];
    PRINT 'Dropped CustomerName column from Projects table';
END
*/

PRINT 'Customer Management migration completed successfully!';