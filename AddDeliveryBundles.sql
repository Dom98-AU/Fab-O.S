-- Add Delivery Bundles feature to Steel Estimation Platform
-- Run this script against your Steel Estimation database

-- Create DeliveryBundles table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DeliveryBundles')
BEGIN
    CREATE TABLE [dbo].[DeliveryBundles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [PackageId] INT NOT NULL,
        [BundleNumber] NVARCHAR(20) NOT NULL,
        [BundleName] NVARCHAR(100) NOT NULL,
        [TotalWeight] DECIMAL(10,3) NOT NULL,
        [ItemCount] INT NOT NULL,
        [CreatedDate] DATETIME2 NOT NULL,
        [LastModified] DATETIME2 NOT NULL,
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_DeliveryBundles_Packages_PackageId] FOREIGN KEY([PackageId]) REFERENCES [dbo].[Packages] ([Id]) ON DELETE CASCADE
    );
    
    CREATE INDEX [IX_DeliveryBundles_PackageId] ON [dbo].[DeliveryBundles] ([PackageId]);
    CREATE INDEX [IX_DeliveryBundles_BundleNumber] ON [dbo].[DeliveryBundles] ([BundleNumber]);
    
    PRINT 'DeliveryBundles table created successfully.';
END
ELSE
BEGIN
    PRINT 'DeliveryBundles table already exists.';
END

-- Add DeliveryBundleId column to ProcessingItems
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') 
    AND name = 'DeliveryBundleId'
)
BEGIN
    ALTER TABLE [dbo].[ProcessingItems]
    ADD [DeliveryBundleId] INT NULL;
    
    ALTER TABLE [dbo].[ProcessingItems]
    ADD CONSTRAINT [FK_ProcessingItems_DeliveryBundles_DeliveryBundleId] 
    FOREIGN KEY([DeliveryBundleId]) REFERENCES [dbo].[DeliveryBundles] ([Id]) ON DELETE SET NULL;
    
    CREATE INDEX [IX_ProcessingItems_DeliveryBundleId] ON [dbo].[ProcessingItems] ([DeliveryBundleId]);
    
    PRINT 'DeliveryBundleId column added to ProcessingItems successfully.';
END
ELSE
BEGIN
    PRINT 'DeliveryBundleId column already exists in ProcessingItems.';
END

-- Add IsParentInBundle column to ProcessingItems
IF NOT EXISTS (
    SELECT * 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') 
    AND name = 'IsParentInBundle'
)
BEGIN
    ALTER TABLE [dbo].[ProcessingItems]
    ADD [IsParentInBundle] BIT NOT NULL CONSTRAINT DF_ProcessingItems_IsParentInBundle DEFAULT 0;
    
    PRINT 'IsParentInBundle column added to ProcessingItems successfully.';
END
ELSE
BEGIN
    PRINT 'IsParentInBundle column already exists in ProcessingItems.';
END

-- Optional: Update __EFMigrationsHistory table to record the migration
IF NOT EXISTS (
    SELECT * 
    FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = '20250702200000_AddDeliveryBundles'
)
BEGIN
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES ('20250702200000_AddDeliveryBundles', '8.0.0');
    
    PRINT 'Migration history updated.';
END