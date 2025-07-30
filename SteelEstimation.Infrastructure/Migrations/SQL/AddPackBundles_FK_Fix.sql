-- Fix Pack Bundle Foreign Key Constraint
-- This fixes the cascading delete issue

-- First, check if the constraint already exists and drop it if needed
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_PackBundles_PackBundleId')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] DROP CONSTRAINT [FK_ProcessingItems_PackBundles_PackBundleId];
    PRINT 'Dropped existing FK_ProcessingItems_PackBundles_PackBundleId constraint';
END

-- Add the foreign key constraint with NO ACTION to avoid cascade conflicts
ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles_PackBundleId] 
    FOREIGN KEY ([PackBundleId]) REFERENCES [dbo].[PackBundles] ([Id]) ON DELETE NO ACTION;
PRINT 'Foreign key FK_ProcessingItems_PackBundles_PackBundleId created with NO ACTION';

-- Add index for pack bundle lookup if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProcessingItems_PackBundleId')
BEGIN
    CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems] ([PackBundleId]);
    PRINT 'Index IX_ProcessingItems_PackBundleId created';
END

PRINT 'Pack Bundle foreign key fix completed successfully';