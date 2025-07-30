-- Migration: Add Welding Connections, Image Support, and Worksheet Change Tracking
-- Generated: 2025-01-03
-- Description: Adds support for welding connections, image uploads, and undo/redo functionality

-- Create WeldingConnections table
CREATE TABLE [dbo].[WeldingConnections] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(200) NOT NULL,
    [Category] nvarchar(100) NOT NULL,
    [DefaultAssembleFitTack] decimal(18,2) NOT NULL DEFAULT 0,
    [DefaultWeld] decimal(18,2) NOT NULL DEFAULT 0,
    [DefaultWeldCheck] decimal(18,2) NOT NULL DEFAULT 0,
    [IsActive] bit NOT NULL DEFAULT 1,
    [DisplayOrder] int NOT NULL DEFAULT 0,
    [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    [ModifiedDate] datetime2 NULL,
    CONSTRAINT [PK_WeldingConnections] PRIMARY KEY CLUSTERED ([Id] ASC)
);

-- Create index on Category for filtering
CREATE NONCLUSTERED INDEX [IX_WeldingConnections_Category] 
ON [dbo].[WeldingConnections] ([Category] ASC)
INCLUDE ([Name], [DisplayOrder], [IsActive]);

-- Create ImageUploads table
CREATE TABLE [dbo].[ImageUploads] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [FileName] nvarchar(255) NOT NULL,
    [OriginalFileName] nvarchar(255) NOT NULL,
    [FilePath] nvarchar(500) NOT NULL,
    [ThumbnailPath] nvarchar(500) NULL,
    [FileSize] bigint NOT NULL,
    [ContentType] nvarchar(100) NOT NULL,
    [Width] int NULL,
    [Height] int NULL,
    [WeldingItemId] int NULL,
    [UploadedByUserId] int NULL,
    [UploadedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    [IsDeleted] bit NOT NULL DEFAULT 0,
    CONSTRAINT [PK_ImageUploads] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ImageUploads_WeldingItems] FOREIGN KEY ([WeldingItemId]) 
        REFERENCES [dbo].[WeldingItems] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ImageUploads_Users] FOREIGN KEY ([UploadedByUserId]) 
        REFERENCES [dbo].[Users] ([Id]) ON DELETE SET NULL
);

-- Create index for WeldingItemId lookups
CREATE NONCLUSTERED INDEX [IX_ImageUploads_WeldingItemId] 
ON [dbo].[ImageUploads] ([WeldingItemId] ASC)
WHERE [IsDeleted] = 0;

-- Create WorksheetChanges table for undo/redo functionality
CREATE TABLE [dbo].[WorksheetChanges] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [PackageWorksheetId] int NOT NULL,
    [UserId] int NULL,
    [ChangeType] nvarchar(50) NOT NULL, -- Add, Update, Delete
    [EntityType] nvarchar(50) NOT NULL, -- ProcessingItem, WeldingItem, FabricationItem
    [EntityId] int NOT NULL,
    [OldValues] nvarchar(max) NULL, -- JSON serialized old values
    [NewValues] nvarchar(max) NULL, -- JSON serialized new values
    [Description] nvarchar(500) NULL,
    [IsUndone] bit NOT NULL DEFAULT 0,
    [Timestamp] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_WorksheetChanges] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorksheetChanges_PackageWorksheets] FOREIGN KEY ([PackageWorksheetId]) 
        REFERENCES [dbo].[PackageWorksheets] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_WorksheetChanges_Users] FOREIGN KEY ([UserId]) 
        REFERENCES [dbo].[Users] ([Id]) ON DELETE SET NULL
);

-- Create indexes for worksheet changes
CREATE NONCLUSTERED INDEX [IX_WorksheetChanges_WorksheetUser] 
ON [dbo].[WorksheetChanges] ([PackageWorksheetId] ASC, [UserId] ASC, [Timestamp] DESC)
INCLUDE ([IsUndone], [ChangeType]);

-- Add WeldingConnectionId to WeldingItems table
ALTER TABLE [dbo].[WeldingItems]
ADD [WeldingConnectionId] int NULL;

-- Add foreign key constraint
ALTER TABLE [dbo].[WeldingItems]
ADD CONSTRAINT [FK_WeldingItems_WeldingConnections] 
FOREIGN KEY ([WeldingConnectionId]) REFERENCES [dbo].[WeldingConnections] ([Id]) 
ON DELETE SET NULL;

-- Create index for connection lookups
CREATE NONCLUSTERED INDEX [IX_WeldingItems_WeldingConnectionId] 
ON [dbo].[WeldingItems] ([WeldingConnectionId] ASC);

-- Change WeldingItem time fields from int to decimal to match connections
ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [AssembleFitTack] decimal(18,2) NOT NULL;

ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [Weld] decimal(18,2) NOT NULL;

ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [WeldCheck] decimal(18,2) NOT NULL;

-- Add Description field to Projects table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'Description')
BEGIN
    ALTER TABLE [dbo].[Projects]
    ADD [Description] nvarchar(max) NULL;
END

-- Insert default welding connections
INSERT INTO [dbo].[WeldingConnections] ([Name], [Category], [DefaultAssembleFitTack], [DefaultWeld], [DefaultWeldCheck], [DisplayOrder])
VALUES 
-- Baseplate Connections
('Small Baseplate Connection', 'Baseplate', 2.0, 1.5, 1.0, 1),
('Medium Baseplate Connection', 'Baseplate', 3.0, 2.5, 1.5, 2),
('Large Baseplate Connection', 'Baseplate', 4.0, 3.5, 2.0, 3),

-- Stiffener Connections
('Single Stiffener Connection', 'Stiffener', 1.5, 1.0, 0.5, 4),
('Double Stiffener Connection', 'Stiffener', 2.5, 2.0, 1.0, 5),
('Multiple Stiffener Connection', 'Stiffener', 4.0, 3.0, 1.5, 6),

-- Gusset Connections
('Small Gusset Plate Connection', 'Gusset', 2.0, 1.5, 1.0, 7),
('Large Gusset Plate Connection', 'Gusset', 3.5, 3.0, 1.5, 8),

-- Cleat Connections
('Single Cleat Connection', 'Cleat', 1.5, 1.0, 0.5, 9),
('Double Cleat Connection', 'Cleat', 2.5, 2.0, 1.0, 10),

-- Splice Connections
('Beam Splice Connection', 'Splice', 4.0, 3.5, 2.0, 11),
('Column Splice Connection', 'Splice', 5.0, 4.0, 2.5, 12),

-- Moment Connections
('Simple Moment Connection', 'Moment', 5.0, 4.5, 2.5, 13),
('Full Moment Connection', 'Moment', 7.0, 6.0, 3.0, 14),

-- Brace Connections
('Light Brace Connection', 'Brace', 2.0, 1.5, 1.0, 15),
('Heavy Brace Connection', 'Brace', 3.0, 2.5, 1.5, 16),

-- Special Connections
('Embed Plate Connection', 'Special', 3.0, 2.0, 1.5, 17),
('Knife Plate Connection', 'Special', 2.5, 2.0, 1.0, 18),
('Shear Tab Connection', 'Special', 2.0, 1.5, 1.0, 19),

-- Complex Connections
('Complex Multi-Part Connection', 'Complex', 8.0, 7.0, 4.0, 20),
('Built-up Section Connection', 'Complex', 6.0, 5.0, 3.0, 21),
('Custom Fabricated Connection', 'Complex', 10.0, 8.0, 5.0, 22);

-- Create table for package-level connection overrides (future feature)
CREATE TABLE [dbo].[PackageWeldingConnections] (
    [Id] int IDENTITY(1,1) NOT NULL,
    [PackageId] int NOT NULL,
    [WeldingConnectionId] int NOT NULL,
    [OverrideAssembleFitTack] decimal(18,2) NULL,
    [OverrideWeld] decimal(18,2) NULL,
    [OverrideWeldCheck] decimal(18,2) NULL,
    [CreatedDate] datetime2 NOT NULL DEFAULT GETUTCDATE(),
    [ModifiedDate] datetime2 NULL,
    CONSTRAINT [PK_PackageWeldingConnections] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PackageWeldingConnections_Packages] FOREIGN KEY ([PackageId]) 
        REFERENCES [dbo].[Packages] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_PackageWeldingConnections_WeldingConnections] FOREIGN KEY ([WeldingConnectionId]) 
        REFERENCES [dbo].[WeldingConnections] ([Id]) ON DELETE CASCADE,
    CONSTRAINT [UQ_PackageWeldingConnections] UNIQUE ([PackageId], [WeldingConnectionId])
);

-- Add indexes for package connection lookups
CREATE NONCLUSTERED INDEX [IX_PackageWeldingConnections_PackageId] 
ON [dbo].[PackageWeldingConnections] ([PackageId] ASC)
INCLUDE ([WeldingConnectionId], [OverrideAssembleFitTack], [OverrideWeld], [OverrideWeldCheck]);

PRINT 'Migration completed successfully';
GO