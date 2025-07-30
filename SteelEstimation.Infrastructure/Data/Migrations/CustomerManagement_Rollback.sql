-- =============================================
-- Rollback: Customer Management System
-- Created: 2025-07-05
-- Description: Rollback script to remove Customer Management tables
-- WARNING: This will DELETE all customer, contact, and address data!
-- =============================================

-- STEP 1: Remove foreign key from Projects to Customers
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Projects_Customers_CustomerId]'))
BEGIN
    ALTER TABLE [dbo].[Projects] DROP CONSTRAINT [FK_Projects_Customers_CustomerId];
    PRINT 'Dropped foreign key FK_Projects_Customers_CustomerId';
END
GO

-- STEP 2: Restore CustomerName column if it was dropped
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerName')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [CustomerName] nvarchar(200) NULL;
    PRINT 'Added CustomerName column back to Projects table';
END
GO

-- STEP 3: Migrate customer names back to Projects (if possible)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    UPDATE p
    SET p.CustomerName = c.CompanyName
    FROM [dbo].[Projects] p
    INNER JOIN [dbo].[Customers] c ON p.CustomerId = c.Id
    WHERE p.CustomerName IS NULL;
    
    PRINT 'Migrated ' + CAST(@@ROWCOUNT as varchar) + ' customer names back to Projects';
END
GO

-- STEP 4: Remove CustomerId column from Projects
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'CustomerId')
BEGIN
    ALTER TABLE [dbo].[Projects] DROP COLUMN [CustomerId];
    PRINT 'Dropped CustomerId column from Projects table';
END
GO

-- STEP 5: Drop Contact table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Contacts];
    PRINT 'Dropped Contacts table';
END
GO

-- STEP 6: Drop Customer table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Customers]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Customers];
    PRINT 'Dropped Customers table';
END
GO

-- STEP 7: Drop Address table
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Addresses]') AND type in (N'U'))
BEGIN
    DROP TABLE [dbo].[Addresses];
    PRINT 'Dropped Addresses table';
END
GO

PRINT 'Customer Management rollback completed!';