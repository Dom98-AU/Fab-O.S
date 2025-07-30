-- Add Pack Bundles Feature
-- This migration adds pack bundle functionality to group processing items for handling operations

-- Create PackBundles table
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

-- Add indexes to PackBundles
CREATE INDEX [IX_PackBundles_PackageId] ON [dbo].[PackBundles] ([PackageId]);
CREATE INDEX [IX_PackBundles_BundleNumber] ON [dbo].[PackBundles] ([BundleNumber]);

-- Add pack bundle fields to ProcessingItems
ALTER TABLE [dbo].[ProcessingItems] ADD [PackBundleId] int NULL;
ALTER TABLE [dbo].[ProcessingItems] ADD [IsParentInPackBundle] bit NOT NULL DEFAULT 0;

-- Add foreign key constraint
ALTER TABLE [dbo].[ProcessingItems] ADD CONSTRAINT [FK_ProcessingItems_PackBundles_PackBundleId] 
    FOREIGN KEY ([PackBundleId]) REFERENCES [dbo].[PackBundles] ([Id]) ON DELETE SET NULL;

-- Add index for pack bundle lookup
CREATE INDEX [IX_ProcessingItems_PackBundleId] ON [dbo].[ProcessingItems] ([PackBundleId]);

-- Update existing data to ensure consistency
UPDATE [dbo].[ProcessingItems] SET [IsParentInPackBundle] = 0 WHERE [IsParentInPackBundle] IS NULL;

PRINT 'Pack Bundles feature added successfully';