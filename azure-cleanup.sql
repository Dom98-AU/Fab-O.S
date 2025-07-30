-- Complete cleanup of Azure SQL Database
-- This will remove ALL objects

USE [sqldb-steel-estimation-sandbox];
GO

-- Disable all constraints
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'
GO

-- Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + '];' + CHAR(13)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

-- Drop all tables
DECLARE @sql2 NVARCHAR(MAX) = '';
SELECT @sql2 = @sql2 + 'DROP TABLE [' + SCHEMA_NAME(schema_id) + '].[' + name + '];' + CHAR(13)
FROM sys.tables WHERE is_ms_shipped = 0;
EXEC sp_executesql @sql2;
GO

PRINT 'All tables dropped successfully';
GO
