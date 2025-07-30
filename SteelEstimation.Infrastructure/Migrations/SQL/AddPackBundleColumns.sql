-- Add Pack Bundle columns to ProcessingItems table
-- This script adds the missing columns for pack bundle functionality

-- Add PackBundleId column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleId')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] int NULL;
    PRINT 'Added PackBundleId column to ProcessingItems table';
END
ELSE
BEGIN
    PRINT 'PackBundleId column already exists';
END

-- Add IsParentInPackBundle column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsParentInPackBundle')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] bit NOT NULL DEFAULT 0;
    PRINT 'Added IsParentInPackBundle column to ProcessingItems table';
END
ELSE
BEGIN
    PRINT 'IsParentInPackBundle column already exists';
END

-- Add PackBundleQty column if it doesn't exist (for future use)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackBundleQty')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleQty] int NULL;
    PRINT 'Added PackBundleQty column to ProcessingItems table';
END
ELSE
BEGIN
    PRINT 'PackBundleQty column already exists';
END

-- Add PackGroup column if it doesn't exist (for future use)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'PackGroup')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [PackGroup] nvarchar(50) NULL;
    PRINT 'Added PackGroup column to ProcessingItems table';
END
ELSE
BEGIN
    PRINT 'PackGroup column already exists';
END

-- Add foreign key constraint if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles_PackBundleId')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles_PackBundleId] 
        FOREIGN KEY ([PackBundleId]) REFERENCES [dbo].[PackBundles] ([Id]) ON DELETE NO ACTION;
    PRINT 'Added foreign key FK_ProcessingItems_PackBundles_PackBundleId';
END
ELSE
BEGIN
    PRINT 'Foreign key FK_ProcessingItems_PackBundles_PackBundleId already exists';
END

-- Add index for pack bundle lookup if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItems_PackBundleId')
BEGIN
    CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems] ([PackBundleId]);
    PRINT 'Added index IX_ProcessingItems_PackBundleId';
END
ELSE
BEGIN
    PRINT 'Index IX_ProcessingItems_PackBundleId already exists';
END

PRINT 'Pack Bundle columns migration completed successfully';