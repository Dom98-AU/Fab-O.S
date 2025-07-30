-- Migration: Add IsDeleted columns for soft delete support
-- Generated: 2025-01-03
-- Description: Adds IsDeleted column to ProcessingItems and WeldingItems tables

-- Add IsDeleted column to ProcessingItems table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems]
    ADD [IsDeleted] bit NOT NULL DEFAULT 0;
    
    PRINT 'Added IsDeleted column to ProcessingItems table'
END
ELSE
BEGIN
    PRINT 'IsDeleted column already exists in ProcessingItems table'
END

-- Add IsDeleted column to WeldingItems table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[WeldingItems]
    ADD [IsDeleted] bit NOT NULL DEFAULT 0;
    
    PRINT 'Added IsDeleted column to WeldingItems table'
END
ELSE
BEGIN
    PRINT 'IsDeleted column already exists in WeldingItems table'
END

-- Create indexes for better performance when filtering by IsDeleted
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IX_ProcessingItems_IsDeleted')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ProcessingItems_IsDeleted] 
    ON [dbo].[ProcessingItems] ([IsDeleted] ASC)
    INCLUDE ([Id], [PackageWorksheetId], [Quantity])
    WHERE [IsDeleted] = 0;
    
    PRINT 'Created index IX_ProcessingItems_IsDeleted'
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'IX_WeldingItems_IsDeleted')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_WeldingItems_IsDeleted] 
    ON [dbo].[WeldingItems] ([IsDeleted] ASC)
    INCLUDE ([Id], [PackageWorksheetId], [ConnectionQty])
    WHERE [IsDeleted] = 0;
    
    PRINT 'Created index IX_WeldingItems_IsDeleted'
END

PRINT 'Migration completed successfully';
GO