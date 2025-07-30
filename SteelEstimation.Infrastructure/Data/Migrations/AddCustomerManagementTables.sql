-- Migration: Add Customer Management Tables
-- Created: 2025-07-05
-- Description: Adds Customer, Contact, and Address tables for comprehensive customer management

-- Create Address table
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

-- Create Customer table
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

-- Create Contact table
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

-- Add CustomerId to Projects table
ALTER TABLE [dbo].[Projects] ADD [CustomerId] int NULL;

-- Create foreign key for Projects to Customers
ALTER TABLE [dbo].[Projects] ADD CONSTRAINT [FK_Projects_Customers_CustomerId] 
    FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customers] ([Id]) ON DELETE SET NULL;

-- Migrate existing CustomerName data to Customer table
-- This script creates customers from unique CustomerName values in Projects
-- Note: Run this only if you have existing data to migrate
/*
INSERT INTO [dbo].[Customers] (CompanyId, CompanyName, ABN, IsActive, CreatedById, CreatedDate, ModifiedDate)
SELECT DISTINCT 
    p.CompanyId,
    p.CustomerName,
    '00000000000' as ABN, -- Placeholder ABN, needs to be updated
    1 as IsActive,
    ISNULL(p.OwnerId, 1) as CreatedById,
    MIN(p.CreatedDate) as CreatedDate,
    MIN(p.CreatedDate) as ModifiedDate
FROM [dbo].[Projects] p
INNER JOIN [dbo].[Users] u ON p.OwnerId = u.Id
WHERE p.CustomerName IS NOT NULL AND p.CustomerName != ''
GROUP BY p.CompanyId, p.CustomerName, p.OwnerId;

-- Update Projects with the new CustomerId
UPDATE p
SET p.CustomerId = c.Id
FROM [dbo].[Projects] p
INNER JOIN [dbo].[Customers] c ON p.CustomerName = c.CompanyName AND p.CompanyId = c.CompanyId;
*/

-- After migration is complete and verified, you can drop the CustomerName column
-- ALTER TABLE [dbo].[Projects] DROP COLUMN [CustomerName];