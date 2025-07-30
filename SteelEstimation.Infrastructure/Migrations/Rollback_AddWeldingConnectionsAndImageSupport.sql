-- Rollback Migration: Remove Welding Connections, Image Support, and Worksheet Change Tracking
-- Generated: 2025-01-03
-- Description: Removes support for welding connections, image uploads, and undo/redo functionality

-- Drop foreign key constraints first
ALTER TABLE [dbo].[WeldingItems]
DROP CONSTRAINT IF EXISTS [FK_WeldingItems_WeldingConnections];

ALTER TABLE [dbo].[ImageUploads]
DROP CONSTRAINT IF EXISTS [FK_ImageUploads_WeldingItems];

ALTER TABLE [dbo].[ImageUploads]
DROP CONSTRAINT IF EXISTS [FK_ImageUploads_Users];

ALTER TABLE [dbo].[WorksheetChanges]
DROP CONSTRAINT IF EXISTS [FK_WorksheetChanges_PackageWorksheets];

ALTER TABLE [dbo].[WorksheetChanges]
DROP CONSTRAINT IF EXISTS [FK_WorksheetChanges_Users];

ALTER TABLE [dbo].[PackageWeldingConnections]
DROP CONSTRAINT IF EXISTS [FK_PackageWeldingConnections_Packages];

ALTER TABLE [dbo].[PackageWeldingConnections]
DROP CONSTRAINT IF EXISTS [FK_PackageWeldingConnections_WeldingConnections];

-- Drop indexes
DROP INDEX IF EXISTS [IX_WeldingItems_WeldingConnectionId] ON [dbo].[WeldingItems];
DROP INDEX IF EXISTS [IX_WeldingConnections_Category] ON [dbo].[WeldingConnections];
DROP INDEX IF EXISTS [IX_ImageUploads_WeldingItemId] ON [dbo].[ImageUploads];
DROP INDEX IF EXISTS [IX_WorksheetChanges_WorksheetUser] ON [dbo].[WorksheetChanges];
DROP INDEX IF EXISTS [IX_PackageWeldingConnections_PackageId] ON [dbo].[PackageWeldingConnections];

-- Remove WeldingConnectionId column from WeldingItems
ALTER TABLE [dbo].[WeldingItems]
DROP COLUMN IF EXISTS [WeldingConnectionId];

-- Revert WeldingItem time fields back to int
ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [AssembleFitTack] int NOT NULL;

ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [Weld] int NOT NULL;

ALTER TABLE [dbo].[WeldingItems]
ALTER COLUMN [WeldCheck] int NOT NULL;

-- Drop tables
DROP TABLE IF EXISTS [dbo].[PackageWeldingConnections];
DROP TABLE IF EXISTS [dbo].[WorksheetChanges];
DROP TABLE IF EXISTS [dbo].[ImageUploads];
DROP TABLE IF EXISTS [dbo].[WeldingConnections];

-- Remove Description field from Projects table if you want to rollback that too
-- ALTER TABLE [dbo].[Projects]
-- DROP COLUMN IF EXISTS [Description];

PRINT 'Rollback completed successfully';
GO