-- Add Pack Bundles Feature (Safe Version)
-- This migration adds pack bundle functionality to group processing items for handling operations

-- Check and create PackBundles table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PackBundles')
BEGIN
    CREATE TABLE [dbo].[PackBundles] (
        [Id] int NOT NULL IDENTITY(1,1),
        [PackageId] int NOT NULL,
        [BundleNumber] nvarchar(20) NOT NULL,
        [BundleName] nvarchar(100) NOT NULL DEFAULT '',
        [TotalWeight] decimal(10,3) NOT NULL DEFAULT 0,
        [ItemCount] int NOT NULL DEFAULT 0,
        [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        [LastModified] datetime2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_PackBundles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_PackBundles_Packages_PackageId] FOREIGN KEY ([PackageId]) REFERENCES [dbo].[Packages] ([Id]) ON DELETE CASCADE
    );
    PRINT 'PackBundles table created successfully';
END
ELSE
BEGIN
    PRINT 'PackBundles table already exists';
END

-- Add indexes to PackBundles if they don't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PackBundles_PackageId')
BEGIN
    CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles] ([PackageId]);
    PRINT 'Index IX_PackBundles_PackageId created';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_PackBundles_BundleNumber')
BEGIN
    CREATE INDEX [IX_PackBundles_BundleNumber] ON [dbo].[PackBundles] ([BundleNumber]);
    PRINT 'Index IX_PackBundles_BundleNumber created';
END

-- Add PackBundleId column to ProcessingItems if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'PackBundleId')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] int NULL;
    PRINT 'PackBundleId column added to ProcessingItems';
END
ELSE
BEGIN
    PRINT 'PackBundleId column already exists in ProcessingItems';
END

-- Add IsParentInPackBundle column to ProcessingItems if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'IsParentInPackBundle')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] bit NOT NULL DEFAULT 0;
    PRINT 'IsParentInPackBundle column added to ProcessingItems';
END
ELSE
BEGIN
    PRINT 'IsParentInPackBundle column already exists in ProcessingItems';
END

-- Add foreign key constraint if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles_PackBundleId')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles_PackBundleId] 
        FOREIGN KEY ([PackBundleId]) REFERENCES [dbo].[PackBundles] ([Id]) ON DELETE SET NULL;
    PRINT 'Foreign key FK_ProcessingItems_PackBundles_PackBundleId created';
END

-- Add index for pack bundle lookup if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItems_PackBundleId')
BEGIN
    CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems] ([PackBundleId]);
    PRINT 'Index IX_ProcessingItems_PackBundleId created';
END

PRINT 'Pack Bundles feature migration completed';